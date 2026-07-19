// lib/presentation/thix_event/event_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import '../../services/event_seat_service.dart';
import '../../services/event_queue_service.dart';
import '../../services/event_booking_limit_service.dart';
import 'event_reservation_page.dart';
import 'seat_selection_page.dart';
import 'waiting_queue_page.dart';

class _ThixColors {
  static const Color primary = Color(0xFF6B3BFF);
  static const Color primaryLight = Color(0xFF7C3AED);
  static const Color lightBg = Color(0xFFF8F7FF);
  static const Color darkText = Color(0xFF1E1B4B);
  static const Color mutedText = Color(0xFF8B8BA7);
  static const Color cardBorder = Color(0xFFEEE9FF);

  // Même palette par catégorie que EventCard, pour cohérence visuelle globale
  static const Map<String, Color> categoryColors = {
    'musique': Color(0xFF6B3BFF),
    'concert': Color(0xFF6B3BFF),
    'conference': Color(0xFFF59E0B),
    'culture': Color(0xFF3B82F6),
    'sport': Color(0xFF10B981),
    'match': Color(0xFF10B981),
    'festival': Color(0xFFEC4899),
    'spectacle': Color(0xFF7C3AED),
    'exposition': Color(0xFF3B82F6),
  };

  static Color accentFor(String category) => categoryColors[category.toLowerCase()] ?? primary;
}

// Définition temporaire de EventBookingLimit
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

  void _goToReservation() {
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

    final isSoldOut = (_event.remainingTickets ?? 0) == 0;
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
      onPressed: _goToReservation,
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _ThixColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? const Color(0xFFEC4899) : _ThixColors.mutedText,
              size: 22,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: _ThixColors.darkText),
            onPressed: _shareEvent,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, color: _ThixColors.darkText),
            onPressed: _addToCalendar,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_event.imageUrl != null && _event.imageUrl!.isNotEmpty)
              Image.network(
                _event.imageUrl!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 220,
                    color: const Color(0xFFF3F0FF),
                    child: Center(child: CircularProgressIndicator(color: accent, strokeWidth: 2)),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 220,
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [accent.withOpacity(0.85), accent])),
                  child: const Icon(Icons.event_rounded, size: 50, color: Colors.white70),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [accent.withOpacity(0.85), accent])),
                child: const Icon(Icons.event_rounded, size: 50, color: Colors.white70),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
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
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _event.categoryLabel.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accent),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _event.isFree ? const Color(0xFF10B981).withOpacity(0.12) : _ThixColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _event.isFree ? 'GRATUIT' : 'PAYANT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _event.isFree ? const Color(0xFF10B981) : _ThixColors.primary,
                          ),
                        ),
                      ),
                      if (_event.remainingTickets != null && _event.remainingTickets! < 50)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Plus que ${_event.remainingTickets} places',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _event.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, height: 1.2, color: _ThixColors.darkText),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.calendar_today_rounded, _event.formattedDate, accent),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.access_time_rounded, _event.timeRange, accent),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.location_on_rounded, _event.location, accent),
                  if (_event.address != null) ...[
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
                          Text(
                            _event.formattedPrice,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accent),
                          ),
                        ],
                      ),
                      _buildBookingButton(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ThixColors.darkText)),
                  const SizedBox(height: 8),
                  Text(_event.description, style: const TextStyle(fontSize: 13, height: 1.5, color: _ThixColors.mutedText)),
                  const SizedBox(height: 24),
                  if (_event.organizerName != null) ...[
                    const Text('Organisateur', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ThixColors.darkText)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _ThixColors.lightBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _ThixColors.cardBorder, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: accent,
                            child: const Icon(Icons.business_rounded, size: 20, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_event.organizerName!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ThixColors.darkText)),
                                if (_event.contactPhone != null)
                                  Text(_event.contactPhone!, style: const TextStyle(fontSize: 11, color: _ThixColors.mutedText)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.phone_rounded, size: 18, color: accent),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_bookingLimit != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _ThixColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: _ThixColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Maximum ${_bookingLimit!.maxPerPerson} places par personne.',
                              style: const TextStyle(fontSize: 11, color: _ThixColors.primary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color accent) {
    return Row(
      children: [
        Icon(icon, size: 16, color: accent),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: _ThixColors.mutedText, fontWeight: FontWeight.w600))),
      ],
    );
  }
}
