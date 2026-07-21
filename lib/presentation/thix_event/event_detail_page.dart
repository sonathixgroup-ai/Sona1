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
  static const Color primary = Color(0xFF6B3CE2); 
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
      '${_event.title}\n\n📅 ${_event.formattedDate}\n📍 ${_event.location}\n\nRéservez sur THIX ÉVÉNEMENT !',
    );
  }

  // 🟢 CORRECTION : Passage explicite des données de la catégorie à la page de réservation
  void _goToReservation({TicketTier? selectedTier}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventReservationPage(
          eventId: _event.id,
          ticketCategory: selectedTier?.name, // Transmet 'GOLD', 'VIPP', etc.
          ticketPrice: selectedTier?.price,   // Transmet le prix exact de la catégorie
        ),
      ),
    );
  }

  void _goToSeatSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SeatSelectionPage(eventId: _event.id, event: _event)),
    );
  }

  Future<void> _joinWaitingQueue() async {
    setState(() => _isCheckingQueue = true);

    final showQueue = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Catégorie épuisée', style: TextStyle(fontWeight: FontWeight.w800, color: _ThixColors.darkText)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.queue_rounded, size: 48, color: Color(0xFFF59E0B)),
            SizedBox(height: 12),
            Text('Il n\'y a plus de billets disponibles pour cette catégorie.', textAlign: TextAlign.center, style: TextStyle(color: _ThixColors.mutedText)),
            SizedBox(height: 16),
            Text('Voulez-vous rejoindre la file d\'attente ?', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: _ThixColors.darkText)),
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
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Rejoindre'),
          ),
        ],
      ),
    );

    setState(() => _isCheckingQueue = false);

    if (showQueue == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WaitingQueuePage(eventId: _event.id, requestedQuantity: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: _ThixColors.primary, strokeWidth: 2)),
      );
    }

    final accent = _accent;

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
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
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
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                  child: IconButton(
                    icon: Icon(_isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: _isFavorite ? const Color(0xFFEC4899) : _ThixColors.darkText, size: 20),
                    onPressed: _toggleFavorite,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                  child: IconButton(icon: const Icon(Icons.share_rounded, color: _ThixColors.darkText, size: 20), onPressed: _shareEvent),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _event.imageUrl != null && _event.imageUrl!.isNotEmpty
                  ? Image.network(_event.imageUrl!, fit: BoxFit.cover)
                  : Container(
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [accent.withOpacity(0.85), accent])), 
                      child: const Center(child: Icon(Icons.event_rounded, size: 50, color: Colors.white70))
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🏷️ TAGS
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text(_event.categoryLabel.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: accent)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: _event.isFree ? const Color(0xFF10B981).withOpacity(0.12) : _ThixColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text(_event.isFree ? 'GRATUIT' : 'PAYANT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: _event.isFree ? const Color(0xFF10B981) : _ThixColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 📌 TITRE ET INFOS DE BASE
                  Text(_event.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.2, color: _ThixColors.darkText)),
                  const SizedBox(height: 20),
                  _buildInfoRow(Icons.calendar_month_rounded, _event.formattedDate, accent),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.access_time_filled_rounded, _event.timeRange, accent),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_on_rounded, _event.location, accent),
                  if (_event.address != null && _event.address!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.map_rounded, _event.address!, accent),
                  ],
                  const SizedBox(height: 24),
                  Divider(color: Colors.grey.shade200, thickness: 1.5),
                  const SizedBox(height: 24),

                  // 👤 ORGANISATEUR
                  if ((_event.organizerName != null && _event.organizerName!.isNotEmpty) || (_event.contactPhone != null && _event.contactPhone!.isNotEmpty))
                    _buildOrganizerSection(),

                  // 📝 DESCRIPTION
                  const Text('À propos de l\'événement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ThixColors.darkText)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100)
                    ),
                    child: Text(
                      _event.description, 
                      style: const TextStyle(fontSize: 14, height: 1.6, color: _ThixColors.mutedText, fontWeight: FontWeight.w500)
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 🎟️ BILLETS & CATÉGORIES
                  const Text('Billets & Réservation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ThixColors.darkText)),
                  const SizedBox(height: 16),
                  if (_hasSeatMap)
                    _buildSeatMapCard(accent)
                  else if (_event.ticketTiers.isNotEmpty)
                    ..._event.ticketTiers.map((tier) => _buildCategoryCard(tier))
                  else
                    _buildDefaultTicketCard(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS INTERNES ---

  Widget _buildInfoRow(IconData icon, String text, Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: accent.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(text, style: const TextStyle(fontSize: 14, color: _ThixColors.darkText, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Organisateur', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ThixColors.darkText)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _accent.withOpacity(0.1),
                child: Icon(Icons.business_center_rounded, color: _accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_event.organizerName ?? 'Anonyme', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _ThixColors.darkText)),
                    if (_event.contactPhone != null && _event.contactPhone!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(_event.contactPhone!, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                    if (_event.contactEmail != null && _event.contactEmail!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.email, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(_event.contactEmail!, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCategoryCard(TicketTier tier) {
    // 🟢 VÉRIFICATION STRICTE DU STOCK RESTANT
    final int remainingSeats = tier.remaining ?? tier.capacity;
    // Vérifie que le stock est à 0 ET que la capacité n'est pas illimitée (0 ou null)
    final bool isSoldOut = (tier.capacity > 0 && remainingSeats <= 0) || (tier.remaining != null && tier.remaining! <= 0);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSoldOut ? Colors.grey.shade300 : _ThixColors.primary.withOpacity(0.3), width: 1.5),
        boxShadow: [
          if (!isSoldOut) BoxShadow(color: _ThixColors.primary.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))
        ]
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.confirmation_num_rounded, size: 20, color: isSoldOut ? Colors.grey : _ThixColors.primary),
                        const SizedBox(width: 8),
                        Text(tier.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isSoldOut ? Colors.grey : _ThixColors.darkText)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (tier.capacity > 0)
                      Text(
                        isSoldOut ? 'Toutes les places ont été vendues' : 'Il reste $remainingSeats place(s)', 
                        style: TextStyle(fontSize: 12, color: isSoldOut ? Colors.red : const Color(0xFFF59E0B), fontWeight: FontWeight.bold)
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    tier.price == 0 ? 'Gratuit' : '${tier.price.toInt()} ${_event.priceCurrency}',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isSoldOut ? Colors.grey : _ThixColors.primary),
                  ),
                  if (isSoldOut)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('ÉPUISÉ', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSoldOut ? _joinWaitingQueue : () => _goToReservation(selectedTier: tier),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSoldOut ? const Color(0xFFF59E0B).withOpacity(0.1) : _ThixColors.primary,
                foregroundColor: isSoldOut ? const Color(0xFFF59E0B) : Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSoldOut ? const BorderSide(color: Color(0xFFF59E0B), width: 1.5) : BorderSide.none,
                ),
              ),
              child: Text(
                isSoldOut ? 'REJOINDRE LA FILE D\'ATTENTE' : 'RÉSERVER CE BILLET',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultTicketCard() {
    // 🟢 VÉRIFICATION STRICTE DU STOCK RESTANT PAR DÉFAUT
    bool isSoldOut = (_event.remainingTickets != null && _event.remainingTickets! <= 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSoldOut ? Colors.grey.shade300 : _ThixColors.primary.withOpacity(0.3), width: 1.5),
        boxShadow: [if (!isSoldOut) BoxShadow(color: _ThixColors.primary.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Entrée', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isSoldOut ? Colors.grey : _ThixColors.darkText)),
                  const SizedBox(height: 4),
                  if (_event.remainingTickets != null)
                    Text(
                      isSoldOut ? 'Toutes les places ont été vendues' : 'Places limitées', 
                      style: TextStyle(fontSize: 12, color: isSoldOut ? Colors.red : const Color(0xFFF59E0B), fontWeight: FontWeight.bold)
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _event.formattedPrice,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isSoldOut ? Colors.grey : _ThixColors.primary),
                  ),
                  if (isSoldOut)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('ÉPUISÉ', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSoldOut ? _joinWaitingQueue : () => _goToReservation(),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSoldOut ? const Color(0xFFF59E0B).withOpacity(0.1) : _ThixColors.primary,
                foregroundColor: isSoldOut ? const Color(0xFFF59E0B) : Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSoldOut ? const BorderSide(color: Color(0xFFF59E0B), width: 1.5) : BorderSide.none,
                ),
              ),
              child: Text(
                isSoldOut ? 'REJOINDRE LA FILE D\'ATTENTE' : 'RÉSERVER MAINTENANT',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatMapCard(Color accent) {
    bool isSoldOut = _availableSeats <= 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSoldOut ? Colors.grey.shade300 : accent.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.event_seat_rounded, color: isSoldOut ? Colors.grey : accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Places Numérotées', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isSoldOut ? Colors.grey : _ThixColors.darkText)),
                    const SizedBox(height: 4),
                    Text(
                      isSoldOut ? 'Toutes les places sont réservées' : '$_availableSeats places disponibles', 
                      style: TextStyle(fontSize: 12, color: isSoldOut ? Colors.red : const Color(0xFFF59E0B), fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSoldOut ? _joinWaitingQueue : _goToSeatSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: isSoldOut ? const Color(0xFFF59E0B).withOpacity(0.1) : accent,
                foregroundColor: isSoldOut ? const Color(0xFFF59E0B) : Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSoldOut ? const BorderSide(color: Color(0xFFF59E0B), width: 1.5) : BorderSide.none,
                ),
              ),
              child: Text(
                isSoldOut ? 'REJOINDRE LA FILE D\'ATTENTE' : 'CHOISIR MES PLACES',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
