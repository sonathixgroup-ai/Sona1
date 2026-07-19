// lib/presentation/thix_event/waiting_queue_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import '../../services/event_queue_service.dart';

class WaitingQueuePage extends StatefulWidget {
  final String eventId;
  final int requestedQuantity;

  const WaitingQueuePage({
    super.key,
    required this.eventId,
    required this.requestedQuantity,
  });

  @override
  State<WaitingQueuePage> createState() => _WaitingQueuePageState();
}

class _WaitingQueuePageState extends State<WaitingQueuePage> with WidgetsBindingObserver {
  late EventQueueService _queueService;
  
  int _position = -1;
  int _queueSize = 0;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;
  Event? _event;
  
  StreamSubscription<List<Map<String, dynamic>>>? _queueSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _queueService = EventQueueService(Supabase.instance.client);
    _initialSetup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _queueSubscription?.cancel(); // 🔴 TRÈS IMPORTANT : Couper l'écoute temps réel
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Si l'app revient au premier plan, on relance une vérification manuelle légère
    if (state == AppLifecycleState.resumed && !_isProcessing) {
      _fetchInitialQueueInfo();
    }
  }

  Future<void> _initialSetup() async {
    await _loadEvent();
    await _joinQueue();
  }

  Future<void> _loadEvent() async {
    final provider = context.read<EventProvider>();
    final event = await provider.fetchEventById(widget.eventId);
    if (event != null && mounted) {
      setState(() => _event = event);
    }
  }

  Future<void> _joinQueue() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // 1. Rejoindre la file côté DB
      final queue = await _queueService.joinWaitingQueue(
        widget.eventId,
        widget.requestedQuantity,
      );
      
      if (queue != null) {
        await _fetchInitialQueueInfo();
        _listenToMyPosition(); // 🟢 Démarrer l'écoute Temps Réel (0 polling)
      } else {
        throw Exception("Impossible de rejoindre la file d'attente");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Requête unique au démarrage pour avoir la taille totale (pas de polling là-dessus)
  Future<void> _fetchInitialQueueInfo() async {
    try {
      final size = await _queueService.getQueueSize(widget.eventId);
      final currentPosition = await _queueService.getQueuePosition(widget.eventId);
      
      if (mounted) {
        setState(() {
          _queueSize = size;
          if (currentPosition > 0) _position = currentPosition;
          _isLoading = false;
        });
        
        // Si par chance on est déjà premier au chargement
        if (_position == 1 && !_isProcessing) {
          _onYourTurn();
        }
      }
    } catch (e) {
      debugPrint("Erreur récupération infos: $e");
    }
  }

  // 🟢 OPTIMISATION : Supabase Realtime (Aucune surcharge base de données)
    void _listenToMyPosition() {
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser!.id;

    // 🟢 La requête doit être construite dans cet ordre :
    // 1. from()
    // 2. eq() (les filtres)
    // 3. stream()
    _queueSubscription = supabase
        .from('waiting_queue')
        .stream(primaryKey: ['id']) // 'id' doit être ta clé primaire
        .eq('event_id', widget.eventId)
        .eq('user_id', currentUserId)
        .listen((data) {
      
      if (data.isEmpty || !mounted) return;

      final newPosition = data.first['position'] as int?;
      if (newPosition != null && newPosition != _position) {
        setState(() {
          _position = newPosition;
        });

        if (_position == 1 && !_isProcessing) {
          _onYourTurn();
        }
      }
    }, onError: (error) {
      debugPrint("Erreur Stream File d'attente: $error");
    });
  }


  void _onYourTurn() {
    setState(() => _isProcessing = true);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('C\'est à votre tour !', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.confirmation_number, size: 48, color: Color(0xFFD4AF37)),
            const SizedBox(height: 16),
            Text(
              'Vous avez ${widget.requestedQuantity} place(s) réservée(s).',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vous avez 10 minutes pour finaliser votre réservation.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveQueue();
              context.go('/thix-event');
            },
            child: const Text('Annuler', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _claimAndProceed(); // 🟢 Appel de la transaction atomique
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: const Color(0xFF0B1B3D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('RÉSERVER MAINTENANT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 🟢 OPTIMISATION : Verrouillage Atomique pour éviter la surréservation
  Future<void> _claimAndProceed() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser!.id;

      // Appel de la procédure stockée (RPC) avec FOR UPDATE
      final bool success = await supabase.rpc('try_claim_spot', params: {
        'p_user_id': currentUserId,
        'p_event_id': widget.eventId,
      });

      if (success && mounted) {
        // La place est verrouillée pour ce user, on va au paiement
        _queueSubscription?.cancel();
        context.push('/thix-event/reservation/${widget.eventId}');
      } else {
        // Échec atomique : la place n'est plus dispo ou le rang a changé in extremis
        throw Exception("Délai expiré ou place prise. Veuillez réessayer.");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isProcessing = false;
          _error = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Une erreur est survenue, impossible de sécuriser la place."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _leaveQueue() async {
    _queueSubscription?.cancel();
    await _queueService.leaveQueue(widget.eventId);
  }

  String _formatEstimatedTime() {
    if (_position <= 0) return 'Calcul...';
    // Approximation légère : 30 secondes par personne devant
    final minutes = ((_position - 1) * 0.5).round();
    if (minutes < 1) return 'Moins d\'une minute';
    if (minutes == 1) return 'Environ 1 minute';
    return 'Environ $minutes minutes';
  }

  double _getProgressValue() {
    if (_queueSize <= 0 || _position <= 0) return 0;
    // Si la file est grande, on fait un ratio. Si je suis 1er, c'est 1.0 (100%)
    final progress = (_queueSize - _position + 1) / _queueSize;
    return progress.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Quitter la file ?', style: TextStyle(fontWeight: FontWeight.bold)),
                content: const Text('Si vous quittez, vous perdrez votre position actuelle.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Rester')),
                  TextButton(
                    onPressed: () {
                      _leaveQueue();
                      Navigator.pop(context); // Ferme modale
                      Navigator.pop(context); // Quitte page
                    },
                    child: const Text('Quitter', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
        title: const Text('File d\'attente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: const Color(0xFFD4AF37)))
          : _error != null
              ? _buildErrorState()
              : _buildQueueContent(),
    );
  }

  Widget _buildQueueContent() {
    return Column(
      children: [
        // Animation et statut
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: _getProgressValue(),
                      strokeWidth: 6,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '$_position',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37), height: 1),
                      ),
                      const Text('position', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Vous êtes en file d\'attente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1B3D)),
              ),
              const SizedBox(height: 6),
              Text(
                '${(_queueSize - _position).clamp(0, 999999)} personne(s) devant vous',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, size: 16, color: Color(0xFFD4AF37)),
                    const SizedBox(width: 6),
                    Text(
                      _formatEstimatedTime(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFD4AF37)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Informations
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ne quittez pas cette page. Vous serez automatiquement redirigé(e) quand ce sera votre tour.',
                  style: TextStyle(fontSize: 13, color: Colors.blue.shade800, height: 1.4),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Récapitulatif
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Récapitulatif', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0B1B3D))),
              const SizedBox(height: 16),
              _buildInfoRow('Événement', _event?.title ?? 'Chargement...'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1),
              ),
              _buildInfoRow('Quantité demandée', '${widget.requestedQuantity} place(s)'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1),
              ),
              _buildInfoRow('Position actuelle', '$_position / $_queueSize'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Une erreur est survenue',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isLoading = true;
                });
                _joinQueue();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
