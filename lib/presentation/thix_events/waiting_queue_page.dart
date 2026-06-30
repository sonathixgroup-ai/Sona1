// lib/presentation/thix_event/waiting_queue_page.dart
import 'dart:async';  // ← AJOUTER CET IMPORT pour Timer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';  // ← AJOUTER CET IMPORT

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

class _WaitingQueuePageState extends State<WaitingQueuePage> {
  late EventQueueService _queueService;
  int _position = -1;
  int _queueSize = 0;
  bool _isLoading = true;
  bool _isProcessing = false;
  Timer? _timer;
  String? _error;
  Event? _event;

  @override
  void initState() {
    super.initState();
    _queueService = EventQueueService(Supabase.instance.client);
    _loadEvent();
    _joinQueue();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadEvent() async {
    final provider = context.read<EventProvider>();
    final event = await provider.fetchEventById(widget.eventId);
    if (event != null && mounted) {
      setState(() => _event = event);
    }
  }

  Future<void> _joinQueue() async {
    setState(() => _isLoading = true);
    
    final queue = await _queueService.joinWaitingQueue(
      widget.eventId,
      widget.requestedQuantity,
    );
    
    if (queue != null) {
      setState(() {
        _position = queue.position;
        _isLoading = false;
      });
      await _updateQueueInfo();
    } else {
      setState(() {
        _error = "Impossible de rejoindre la file d'attente";
        _isLoading = false;
      });
    }
  }

  Future<void> _updateQueueInfo() async {
    final size = await _queueService.getQueueSize(widget.eventId);
    final currentPosition = await _queueService.getQueuePosition(widget.eventId);
    
    if (mounted) {
      setState(() {
        _queueSize = size;
        if (currentPosition > 0) {
          _position = currentPosition;
        }
      });
    }
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _updateQueueInfo();
      
      // Vérifier si c'est au tour de l'utilisateur
      if (_position == 1 && !_isProcessing) {
        _timer?.cancel();
        _onYourTurn();
      }
    });
  }

  void _onYourTurn() {
    setState(() => _isProcessing = true);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('C\'est à votre tour !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_empty, size: 48, color: Color(0xFFD4AF37)),
            const SizedBox(height: 16),
            Text(
              'Vous avez ${widget.requestedQuantity} place(s) en attente.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vous avez 10 minutes pour finaliser votre réservation.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
              _proceedToBooking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: const Color(0xFF0B1B3D),
            ),
            child: const Text('RÉSERVER MAINTENANT'),
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToBooking() async {
    setState(() => _isProcessing = true);
    
    if (mounted) {
      context.push('/thix-event/reservation/${widget.eventId}');
      _leaveQueue();
    }
  }

  Future<void> _leaveQueue() async {
    await _queueService.leaveQueue(widget.eventId);
  }

  String _formatEstimatedTime() {
    if (_position <= 0) return 'Calcul...';
    final minutes = ((_position - 1) * 0.5).round();
    if (minutes < 1) return 'Moins d\'une minute';
    if (minutes == 1) return 'Environ 1 minute';
    return 'Environ $minutes minutes';
  }

  double _getProgressValue() {
    if (_queueSize <= 0) return 0;
    return (_queueSize - _position) / _queueSize;
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
            _leaveQueue();
            Navigator.pop(context);
          },
        ),
        title: const Text('File d\'attente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
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
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '$_position',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                      ),
                      const Text('position', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Vous êtes en file d\'attente',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${_queueSize - _position} personne(s) devant vous',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, size: 14, color: Color(0xFFD4AF37)),
                    const SizedBox(width: 4),
                    Text(
                      _formatEstimatedTime(),
                      style: const TextStyle(fontSize: 11, color: Color(0xFFD4AF37)),
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
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ne quittez pas cette page. Vous serez automatiquement redirigé(e) quand ce sera votre tour.',
                  style: TextStyle(fontSize: 12, color: Colors.blue[700], height: 1.3),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Récapitulatif
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Récapitulatif', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildInfoRow('Événement', _event?.title ?? 'Chargement...'),
              const SizedBox(height: 8),
              _buildInfoRow('Quantité demandée', '${widget.requestedQuantity} place(s)'),
              const SizedBox(height: 8),
              _buildInfoRow('Position actuelle', '$_position/${_queueSize}'),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Bouton quitter
        TextButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Quitter la file ?'),
                content: const Text('Si vous quittez, vous perdrez votre position.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Rester'),
                  ),
                  TextButton(
                    onPressed: () {
                      _leaveQueue();
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('Quitter', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.exit_to_app, size: 18),
          label: const Text('Quitter la file d\'attente'),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
                _isLoading = true;
              });
              _joinQueue();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
