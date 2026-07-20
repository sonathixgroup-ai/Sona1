// lib/presentation/thix_event/event_reservation_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import '../../models/event_seat.dart';
import '../../services/event_booking_limit_service.dart';
import '../../services/event_seat_service.dart';

class _ThixColors {
  static const Color primary = Color(0xFF6B3CE2);
  static const Color primaryLight = Color(0xFF8B5CF6);
  static const Color lightBg = Color(0xFFF8F7FF);
  static const Color darkText = Color(0xFF1E1B4B);
  static const Color mutedText = Color(0xFF8B8BA7);
  static const Color cardBorder = Color(0xFFEEE9FF);
}

class EventReservationPage extends StatefulWidget {
  final String eventId;
  final List<EventSeat>? selectedSeats;
  final double? totalPrice;
  final int quantity;

  const EventReservationPage({
    super.key,
    required this.eventId,
    this.selectedSeats,
    this.totalPrice,
    this.quantity = 1,
  });

  @override
  State<EventReservationPage> createState() => _EventReservationPageState();
}

class _EventReservationPageState extends State<EventReservationPage> {
  late Event _event;
  bool _isLoading = true;
  int _quantity = 1;
  bool _isProcessing = false;
  bool _isCheckingLimits = false;
  Map<String, dynamic>? _bookingLimit;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEvent();
    _quantity = widget.quantity;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadEvent() async {
    final provider = context.read<EventProvider>();
    final event = await provider.fetchEventById(widget.eventId);
    if (event != null) {
      setState(() {
        _event = event;
        _isLoading = false;
      });
      await _loadBookingLimit();
    }
  }

  Future<void> _loadBookingLimit() async {
    try {
      final limitService = EventBookingLimitService(Supabase.instance.client);
      final limit = await limitService.getBookingLimit(widget.eventId);
      if (limit != null) {
        setState(() {
          _bookingLimit = {
            'eventId': limit.eventId,
            'maxPerPerson': limit.maxPerPerson,
            'maxPerTransaction': limit.maxPerTransaction,
            'requireIdVerification': limit.requireIdVerification,
            'memberOnlyLimit': limit.memberOnlyLimit,
            'restrictedZones': limit.restrictedZones,
          };
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading booking limit: $e');
    }
  }

  double get _totalPrice {
    if (widget.totalPrice != null) return widget.totalPrice!;
    return _event.price * _quantity;
  }

  String get _formattedTotal {
    if (_totalPrice == 0) return 'Gratuit';
    final priceString = _totalPrice.truncateToDouble() == _totalPrice 
        ? _totalPrice.toInt().toString() 
        : _totalPrice.toStringAsFixed(2);
    return '$priceString ${_event.priceCurrency}';
  }

  Future<bool> _checkBookingLimits() async {
    setState(() => _isCheckingLimits = true);
    
    final limitService = EventBookingLimitService(Supabase.instance.client);
    final result = await limitService.canUserBook(widget.eventId, _quantity);
    
    setState(() => _isCheckingLimits = false);
    
    if (result['allowed'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['reason']), backgroundColor: Colors.red),
      );
      return false;
    }
    
    return true;
  }

  Future<void> _processReservation() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir correctement vos informations.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!await _checkBookingLimits()) return;
    
    setState(() => _isProcessing = true);
    
    final provider = context.read<EventProvider>();
    String? bookingId;
    
    try {
      if (widget.selectedSeats != null && widget.selectedSeats!.isNotEmpty) {
        final seatService = EventSeatService(Supabase.instance.client);
        
        final booking = await provider.bookTicket(
          eventId: widget.eventId,
          quantity: widget.selectedSeats!.length,
          totalPrice: widget.totalPrice ?? _totalPrice,
        );
        
        if (booking != null) {
          final seatIds = widget.selectedSeats!.map((s) => s.id).toList();
          final numericId = int.tryParse(booking.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          await seatService.confirmSeats(widget.eventId, seatIds, numericId);
          bookingId = booking.id;
        }
      } else {
        final booking = await provider.bookTicket(
          eventId: widget.eventId,
          quantity: _quantity,
          totalPrice: _totalPrice,
        );
        bookingId = booking?.id;
      }
      
      if (bookingId != null && mounted) {
        final limitService = EventBookingLimitService(Supabase.instance.client);
        await limitService.recordBookingAttempt(widget.eventId, _quantity);
        
        // 🚀 NOUVELLE LOGIQUE DE REDIRECTION VERS LE PAIEMENT
        // Au lieu d'aller sur '/my-tickets', on pousse vers la page de paiement
        // en passant les informations nécessaires via 'extra'
        context.push('/thix-event/payment', extra: {
          'bookingId': bookingId,
          'amount': _totalPrice,
          'currency': _event.priceCurrency,
        });

      } else {
        throw Exception('Erreur lors de la création de la réservation');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _ThixColors.lightBg, 
        body: Center(child: CircularProgressIndicator(color: _ThixColors.primary))
      );
    }

    return Scaffold(
      backgroundColor: _ThixColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(color: _ThixColors.lightBg, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: _ThixColors.darkText, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text('Confirmation', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ThixColors.darkText)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _ThixColors.cardBorder, width: 1.5),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_event.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(_event.imageUrl!, width: 60, height: 60, fit: BoxFit.cover),
                        )
                      else
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(color: _ThixColors.primaryLight.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.event_rounded, color: _ThixColors.primary),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_event.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ThixColors.darkText)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 12, color: _ThixColors.mutedText),
                                const SizedBox(width: 4),
                                Text(_event.formattedDate, style: const TextStyle(fontSize: 11, color: _ThixColors.mutedText, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: _ThixColors.cardBorder)),
                  
                  if (widget.selectedSeats != null && widget.selectedSeats!.isNotEmpty) ...[
                    _buildInfoRow('Places sélectionnées', widget.selectedSeats!.map((s) => s.displayName).join(', ')),
                    const SizedBox(height: 8),
                    _buildInfoRow('Catégorie', widget.selectedSeats!.first.category.toString().split('.').last),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Prix unitaire', style: TextStyle(fontSize: 13, color: _ThixColors.mutedText, fontWeight: FontWeight.w600)),
                        Text(_event.formattedPrice, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _ThixColors.darkText)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Nombre de billets', style: TextStyle(fontSize: 13, color: _ThixColors.mutedText, fontWeight: FontWeight.w600)),
                        Container(
                          decoration: BoxDecoration(
                            color: _ThixColors.lightBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _ThixColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_rounded, size: 18),
                                color: _quantity > 1 ? _ThixColors.darkText : Colors.grey,
                                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                              ),
                              Text('$_quantity', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ThixColors.primary)),
                              IconButton(
                                icon: const Icon(Icons.add_rounded, size: 18),
                                color: (_event.remainingTickets == null || _quantity < _event.remainingTickets!) ? _ThixColors.darkText : Colors.grey,
                                onPressed: (_event.remainingTickets == null || _quantity < _event.remainingTickets!)
                                    ? () => setState(() => _quantity++)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            const Text('Vos informations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ThixColors.darkText)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _ThixColors.cardBorder, width: 1.5),
              ),
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nom complet',
                      icon: Icons.person_outline_rounded,
                      validator: (val) => val == null || val.isEmpty ? 'Veuillez entrer votre nom' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Adresse email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) => val == null || !val.contains('@') ? 'Veuillez entrer un email valide' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Numéro de téléphone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (val) => val == null || val.length < 8 ? 'Veuillez entrer un numéro valide' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_bookingLimit != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _ThixColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: _ThixColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Maximum ${_bookingLimit!['maxPerPerson']} places par personne.',
                        style: const TextStyle(fontSize: 11, color: _ThixColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total à payer', style: TextStyle(fontSize: 11, color: _ThixColors.mutedText, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  _formattedTotal,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _ThixColors.darkText),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: (_isProcessing || _isCheckingLimits) ? null : _processReservation,
              style: ElevatedButton.styleFrom(
                backgroundColor: _ThixColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isProcessing || _isCheckingLimits
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('CONFIRMER', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _ThixColors.mutedText, fontWeight: FontWeight.w600)),
        const SizedBox(width: 16),
        Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _ThixColors.darkText))),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ThixColors.darkText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _ThixColors.mutedText),
        prefixIcon: Icon(icon, size: 18, color: _ThixColors.mutedText),
        filled: true,
        fillColor: _ThixColors.lightBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _ThixColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
