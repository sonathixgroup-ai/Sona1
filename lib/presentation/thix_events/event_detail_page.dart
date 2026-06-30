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
      SnackBar(content: Text(_isFavorite ? 'Ajouté aux favoris' : 'Retiré des favoris'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _shareEvent() async {
    await Share.share(
      '${_event.title}\n\n${_event.description}\n\n📅 ${_event.formattedDate}\n📍 ${_event.location}\n💰 ${_event.formattedPrice}\n\nRéservez sur THIX ÉVÉNEMENT !'
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
        title: const Text('Complet !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.queue, size: 48, color: Colors.orange),
            const SizedBox(height: 12),
            const Text('Cet événement est complet.'),
            const SizedBox(height: 8),
            Text(
              '${_event.remainingTickets ?? 0} places disponibles',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            const Text('Voulez-vous rejoindre la file d\'attente ?', textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
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
    
    if (isSoldOut) {
      return ElevatedButton(
        onPressed: _isCheckingQueue ? null : _joinWaitingQueue,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: _isCheckingQueue
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('FILE D\'ATTENTE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }
    
    if (_hasSeatMap) {
      return ElevatedButton(
        onPressed: _goToSeatSelection,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4AF37),
          foregroundColor: const Color(0xFF0B1B3D),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: const Text('CHOISIR MES PLACES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }
    
    return ElevatedButton(
      onPressed: _goToReservation,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: const Color(0xFF0B1B3D),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: const Text('RÉSERVER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red, size: 22),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black87),
            onPressed: _shareEvent,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.black87),
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
                  return Container(height: 220, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator()));
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 220,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _event.categoryLabel.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFD4AF37)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _event.isFree ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _event.isFree ? 'GRATUIT' : 'PAYANT',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _event.isFree ? Colors.green : Colors.blue),
                        ),
                      ),
                      if (_event.remainingTickets != null && _event.remainingTickets! < 50)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Plus que ${_event.remainingTickets} places',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.orange),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_event.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.2)),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.calendar_today, _event.formattedDate),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.access_time, _event.timeRange),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.location_on, _event.location),
                  if (_event.address != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.map, _event.address!),
                  ],
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey[200]),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Prix', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Text(_event.formattedPrice, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                        ],
                      ),
                      _buildBookingButton(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_event.description, style: const TextStyle(fontSize: 13, height: 1.5)),
                  const SizedBox(height: 24),
                  if (_event.organizerName != null) ...[
                    const Text('Organisateur', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFFD4AF37),
                            child: Icon(Icons.business, size: 20, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_event.organizerName!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                if (_event.contactPhone != null)
                                  Text(_event.contactPhone!, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.phone, size: 18, color: Color(0xFFD4AF37)),
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
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Maximum ${_bookingLimit!.maxPerPerson} places par personne.',
                              style: TextStyle(fontSize: 11, color: Colors.blue[700]),
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
      ],
    );
  }
}
