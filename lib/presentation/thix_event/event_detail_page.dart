// lib/presentation/thix_event/event_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import '../../models/ticket_tier.dart';
import '../../services/event_seat_service.dart';
import '../../services/event_queue_service.dart';
import '../../services/event_booking_limit_service.dart';
import 'event_reservation_page.dart';
import 'seat_selection_page.dart';
import 'waiting_queue_page.dart';

class _ThixColors {
  static const Color primary = Color(0xFF6B3CE2); // Violet THIX mis à jour
  static const Color primaryLight = Color(0xFF8B5CF6);
  static const Color lightBg = Color(0xFFF8F7FF);
  static const Color darkText = Color(0xFF1E1B4B);
  static const Color mutedText = Color(0xFF8B8BA7);
  static const Color cardBorder = Color(0xFFEEE9FF);

  static const Map<String, Color> categoryColors = {
    'musique': Color(0xFF6B3CE2),
    'concert': Color(0xFF6B3CE2),
    'conference': Color(0xFFF59E0B),
    'culture': Color(0xFF3B82F6),
    'sport': Color(0xFF10B981),
    'match': Color(0xFF10B981),
    'festival': Color(0xFFEC4899),
    'spectacle': Color(0xFF8B5CF6),
    'exposition': Color(0xFF3B82F6),
  };

  static Color accentFor(String category) => categoryColors[category.toLowerCase()] ?? primary;
}

class EventBookingLimit {
  final String eventId;
  final int maxPerPerson;
  final int maxPerTransaction;
  final bool requireIdVerification;
  final int? memberOnlyLimit;
  final List<String> restrictedZones;

  EventBookingLimit({
    required this.eventId,
    required this.maxPerPerson,
    required this.maxPerTransaction,
    this.requireIdVerification = false,
    this.memberOnlyLimit,
    this.restrictedZones = const [],
  });
}

class EventDetailPage extends StatefulWidget {
  final String eventId;
  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late Event _event;
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _hasSeatMap = false;
  int _availableSeats = 0;
  EventBookingLimit? _bookingLimit;
  bool _isCheckingQueue = false;

  Color get _accent => _isLoading ? _ThixColors.primary : _ThixColors.accentFor(_event.category);

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    final provider = context.read<EventProvider>();
    final event = await provider.fetchEventById(widget.eventId);
    if (event != null) {
      setState(() {
        _event = event;
        _isLoading = false;
        _isFavorite = event.isLiked;
      });
      await provider.incrementViews(widget.eventId);
      await _loadAdditionalInfo();
    }
  }

  Future<void> _loadAdditionalInfo() async {
    try {
      final seatService = EventSeatService(Supabase.instance.client);
      final seats = await seatService.getSeatMap(widget.eventId);
      setState(() {
        _hasSeatMap = seats.isNotEmpty;
        _availableSeats = seats.where((s) => s.isAvailable).length;
      });

      final limitService = EventBookingLimitService(Supabase.instance.client);
      final limit = await limitService.getBookingLimit(widget.eventId);
      if (limit != null) {
        setState(() {
          _bookingLimit = EventBookingLimit(
            eventId: limit.eventId,
            maxPerPerson: limit.maxPerPerson,
            maxPerTransaction: limit.maxPerTransaction,
            requireIdVerification: limit.requireIdVerification,
            memberOnlyLimit: limit.memberOnlyLimit,
            restrictedZones: limit.restrictedZones,
          );
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading additional info: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    final provider = context.read<EventProvider>();
    if (_isFavorite) {
      await provider.unlikeEvent(widget.eventId);
    } else {
      await provider.likeEvent(widget.eventId);
    }
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isFavorite ? 'Ajouté aux favoris' : 'Retiré des favoris'), duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _shareEvent() async {
    await Share.share(
      '${_event.title}\n\n${_event.description}\n\n📅 ${_event.formattedDate}\n📍 ${_event.location}\n💰 ${_event.formattedPrice}\n\nRéservez sur THIX ÉVÉNEMENT !',
    );
  }

  void _addToCalendar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajout au calendrier (bientôt disponible)'), duration: Duration(seconds: 1)),
    );
  }

  // 🟢 NOUVELLE FONCTION : Choix de la classe de billet via BottomSheet
  void _showTicketTierSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 20),
            const Text('Choisissez votre billet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ThixColors.darkText)),
            const SizedBox(height: 6),
            const Text('Sélectionnez la catégorie qui vous correspond.', style: TextStyle(fontSize: 12, color: _ThixColors.mutedText)),
            const SizedBox(height: 20),
            ..._event.ticketTiers.map((tier) => _buildTierOption(tier)),
          ],
        ),
      ),
    );
  }

  Widget _buildTierOption(TicketTier tier) {
    bool isSoldOut = tier.capacity > 0 && (tier.remaining ?? tier.capacity) == 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isSoldOut ? null : () {
          Navigator.pop(context);
          _goToReservation(selectedTier: tier);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSoldOut ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSoldOut ? Colors.grey.shade200 : _ThixColors.primary.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_activity_rounded, size: 16, color: isSoldOut ? Colors.grey : _ThixColors.primary),
                      const SizedBox(width: 8),
                      Text(tier.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isSoldOut ? Colors.grey : _ThixColors.darkText)),
                    ],
                  ),
                  if (tier.capacity > 0 && !isSoldOut) ...[
                    const SizedBox(height: 4),
                    Text('Plus que ${tier.remaining ?? tier.capacity} places', style: const TextStyle(fontSize: 10, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                  ]
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    tier.price == 0 ? 'Gratuit' : '${tier.price.toInt()} ${_event.priceCurrency}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isSoldOut ? Colors.grey : _ThixColors.primary),
                  ),
                  if (isSoldOut)
                    const Text('Épuisé', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🟢 MISE À JOUR : Navigation vers réservation avec la classe choisie
  void _goToReservation({TicketTier? selectedTier}) {
    // Si l'événement a des classes et qu'on a pas choisi, on ouvre le Sheet
    if (_event.ticketTiers.isNotEmpty && selectedTier == null) {
      _showTicketTierSelection();
      return;
    }

    // Navigue vers la page de paiement en passant le tier choisi en paramètre (ou via le provider)
    // context.push('/thix-event/reservation/${_event.id}', extra: selectedTier);
    
    // Pour l'instant on garde votre routing actuel (à adapter si vous utilisez extra dans GoRouter)
    context.push('/thix-event/reservation/${_event.id}'); 
  }

  void _goToSeatSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeatSelectionPage(eventId: _event.id, event: _event),
      ),
    );
  }

  Future<void> _joinWaitingQueue() async {
    setState(() => _isCheckingQueue = true);

    final showQueue = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Complet !', style: TextStyle(fontWeight: FontWeight.w800, color: _ThixColors.darkText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.queue_rounded, size: 48, color: _accent),
            const SizedBox(height: 12),
            const Text('Cet événement est complet.', style: TextStyle(color: _ThixColors.mutedText)),
            const SizedBox(height: 8),
            Text(
              '${_event.remainingTickets ?? 0} places disponibles',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEC4899)),
            ),
            const SizedBox(height: 8),
            const Text('Voulez-vous rejoindre la file d\'attente ?', textAlign: TextAlign.center, style: TextStyle(color: _ThixColors.mutedText)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: _ThixColors.mutedText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('File d\'attente'),
          ),
        ],
      ),
    );

    setState(() => _isCheckingQueue = false);

    if (showQueue == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WaitingQueuePage(
            eventId: _event.id,
            requestedQuantity: 1,
          ),
        ),
      );
    }
  }

  Widget _buildBookingButton() {
    if (_isLoading) return const SizedBox.shrink();

    final isSoldOut = (_event.remainingTickets != null && _event.remainingTickets! == 0);
    final accent = _accent;

    if (isSoldOut) {
      return ElevatedButton(
        onPressed: _isCheckingQueue ? null : _joinWaitingQueue,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF59E0B),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: _isCheckingQueue
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('FILE D\'ATTENTE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
      );
    }

    if (_hasSeatMap) {
      return ElevatedButton(
        onPressed: _goToSeatSelection,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: const Text('CHOISIR MES PLACES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
      );
    }

    return ElevatedButton(
      onPressed: _goToReservation, // 🟢 Appelle la nouvelle logique (avec ou sans sheet)
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: const Text('RÉSERVER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _ThixColors.lightBg,
        body: Center(child: CircularProgressIndicator(color: _ThixColors.primary, strokeWidth: 2)),
      );
    }

    final accent = _accent;

    // 🟢 Affichage du prix : Si classes dispo, on ajoute "À partir de"
    String displayPrice = _event.formattedPrice;
    if (_event.ticketTiers.length > 1) {
      displayPrice = 'Dès $displayPrice';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: _ThixColors.darkText, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: IconButton(
                    icon: Icon(_isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: _isFavorite ? const Color(0xFFEC4899) : _ThixColors.mutedText, size: 20),
                    onPressed: _toggleFavorite,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: IconButton(icon: const Icon(Icons.share_rounded, color: _ThixColors.darkText, size: 20), onPressed: _shareEvent),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _event.imageUrl != null && _event.imageUrl!.isNotEmpty
                  ? Image.network(_event.imageUrl!, fit: BoxFit.cover)
                  : Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [accent.withOpacity(0.85), accent])), child: const Center(child: Icon(Icons.event_rounded, size: 50, color: Colors.white70))),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text(_event.categoryLabel.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accent)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: _event.isFree ? const Color(0xFF10B981).withOpacity(0.12) : _ThixColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text(_event.isFree ? 'GRATUIT' : 'PAYANT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _event.isFree ? const Color(0xFF10B981) : _ThixColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_event.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.2, color: _ThixColors.darkText)),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.calendar_today_rounded, _event.formattedDate, accent),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.access_time_rounded, _event.timeRange, accent),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.location_on_rounded, _event.location, accent),
                  if (_event.address != null && _event.address!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.map_rounded, _event.address!, accent),
                  ],
                  const SizedBox(height: 16),
                  Divider(color: _ThixColors.cardBorder),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Prix', style: TextStyle(fontSize: 12, color: _ThixColors.mutedText)),
                          const SizedBox(height: 4),
                          Text(displayPrice, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accent)), // 🟢 Affichage géré
                        ],
                      ),
                      _buildBookingButton(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Description', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ThixColors.darkText)),
                  const SizedBox(height: 8),
                  Text(_event.description, style: const TextStyle(fontSize: 13, height: 1.5, color: _ThixColors.mutedText)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: accent),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: _ThixColors.mutedText, fontWeight: FontWeight.w600))),
      ],
    );
  }
}
