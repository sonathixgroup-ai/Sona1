import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import '../../models/event_seat.dart';
import '../../services/event_booking_limit_service.dart';
import '../../services/event_seat_service.dart';

class _ThixColors {
  static const bg = Color(0xFF050508);
  static const surface = Color(0xFF0C0C12);
  static const surfaceAlt = Color(0xFF111118);
  static const cardBorder = Color(0x14FFFFFF);
  static const cardBorderStrong = Color(0x26FFFFFF);
  static const primary = Color(0xFFFF0A54);
  static const textSecondary = Color(0x99FFFFFF);
  static const textMuted = Color(0x66FFFFFF);
}

class EventReservationPage extends ConsumerStatefulWidget {
  final String eventId;
  final List<EventSeat>? selectedSeats;
  final double? totalPrice;
  final int quantity;
  final String? ticketCategory;
  final double? ticketPrice;
  const EventReservationPage({super.key, required this.eventId, this.selectedSeats, this.totalPrice, this.quantity = 1, this.ticketCategory, this.ticketPrice});
  @override
  ConsumerState<EventReservationPage> createState() => _EventReservationPageState();
}

class _EventReservationPageState extends ConsumerState<EventReservationPage> {
  late Event _event;
  bool _loading = true;
  int _qty = 1;
  bool _processing = false;
  bool _checking = false;
  Map<String, dynamic>? _limit;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pin = TextEditingController();

  @override
  void initState() {
    super.initState();
    _qty = widget.quantity;
    _pin.text = (1000 + Random().nextInt(9000)).toString();
    _load();
  }

  @override
  void dispose() { _name.dispose(); _email.dispose(); _phone.dispose(); _pin.dispose(); super.dispose(); }

  Future<void> _load() async {
    final ev = await ref.read(eventServiceProvider).getEventById(widget.eventId);
    if (ev!= null && mounted) { setState(() { _event = ev; _loading = false; }); _loadLimit(); }
  }

  Future<void> _loadLimit() async {
    try {
      final l = await EventBookingLimitService(Supabase.instance.client).getBookingLimit(widget.eventId);
      if (l!= null && mounted) setState(() => _limit = {'maxPerPerson': l.maxPerPerson});
    } catch (_) {}
  }

  double get _unit => widget.ticketPrice?? widget.totalPrice?? _event.price;
  double get _total => _unit * _qty;
  String get _formattedTotal => _total==0? 'Gratuit' : '${_total.toInt()} ${_event.priceCurrency}';

  Future<bool> _checkLimits() async {
    setState(() => _checking = true);
    final res = await EventBookingLimitService(Supabase.instance.client).canUserBook(widget.eventId, _qty);
    setState(() => _checking = false);
    if (res['allowed']== false) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['reason']), backgroundColor: Colors.red)); return false; }
    return true;
  }

  Future<void> _reserve() async {
    if (!_formKey.currentState!.validate()) return;
    if (!await _checkLimits()) return;
    setState(() => _processing = true);
    try {
      String? bookingId;
      if (widget.selectedSeats!= null && widget.selectedSeats!.isNotEmpty) {
        final b = await ref.read(eventServiceProvider).bookTicket(eventId: widget.eventId, quantity: widget.selectedSeats!.length, totalPrice: _total);
        if (b!= null) { await EventSeatService(Supabase.instance.client).confirmSeats(widget.eventId, widget.selectedSeats!.map((s) => s.id).toList(), int.tryParse(b.id.replaceAll(RegExp(r'[^0-9]'), ''))?? 0); bookingId = b.id; }
      } else {
        final b = await ref.read(eventServiceProvider).bookTicket(eventId: widget.eventId, quantity: _qty, totalPrice: _total);
        bookingId = b?.id;
      }
      if (bookingId!= null) {
        try { await Supabase.instance.client.from('event_bookings').update({'pin_code': _pin.text.trim(), 'ticket_category': widget.ticketCategory?? 'Standard'}).eq('id', bookingId); } catch (_) {}
        await EventBookingLimitService(Supabase.instance.client).recordBookingAttempt(widget.eventId, _qty);
        if (mounted) context.push('/thix-event/payment', extra: {'bookingId': bookingId, 'amount': _total, 'currency': _event.priceCurrency});
      } else { throw Exception('Réservation échouée'); }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally { if (mounted) setState(() => _processing = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: _ThixColors.bg, body: Center(child: CircularProgressIndicator(color: _ThixColors.primary)));
    return Scaffold(
      backgroundColor: _ThixColors.bg,
      appBar: PreferredSize(preferredSize: const Size.fromHeight(52), child: ClipRRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: AppBar(backgroundColor: _ThixColors.bg.withOpacity(0.85), elevation: 0, leading: Padding(padding: const EdgeInsets.all(8), child: InkWell(onTap: () => context.pop(), child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle, border: Border.all(color: _ThixColors.cardBorder)), child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18)))), title: const Text('Confirmation', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)), centerTitle: true)))),
      body: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(decoration: BoxDecoration(color: _ThixColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: _ThixColors.cardBorder)), padding: const EdgeInsets.all(16), child: Column(children: [
          Row(children: [ClipRRect(borderRadius: BorderRadius.circular(12), child: _event.imageUrl!= null? Image.network(_event.imageUrl!, width: 56, height: 56, fit: BoxFit.cover) : Container(width: 56, height: 56, color: _ThixColors.surfaceAlt, child: const Icon(Icons.event_rounded, color: _ThixColors.textMuted))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_event.title, maxLines: 2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)), const SizedBox(height: 4), Text(_event.formattedDate, style: const TextStyle(fontSize: 11, color: _ThixColors.textMuted))]))]),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: _ThixColors.cardBorder)),
          if (widget.ticketCategory!= null)...[_rowInfo('Catégorie', widget.ticketCategory!), const SizedBox(height: 8)],
          if (widget.selectedSeats!= null && widget.selectedSeats!.isNotEmpty) _rowInfo('Places', widget.selectedSeats!.map((s) => s.displayName).join(', '))
          else...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Prix unitaire', style: TextStyle(fontSize: 12, color: _ThixColors.textMuted)), Text('${_unit.toInt()} ${_event.priceCurrency}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white))]),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Quantité', style: TextStyle(fontSize: 12, color: _ThixColors.textMuted)), Container(decoration: BoxDecoration(color: _ThixColors.surfaceAlt, borderRadius: BorderRadius.circular(20), border: Border.all(color: _ThixColors.cardBorder)), child: Row(children: [IconButton(icon: const Icon(Icons.remove_rounded, size: 16), color: _qty>1? Colors.white : _ThixColors.textMuted, onPressed: _qty>1? () => setState(() => _qty--) : null), Text('$_qty', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)), IconButton(icon: const Icon(Icons.add_rounded, size: 16), color: Colors.white, onPressed: () => setState(() => _qty++))]))]),
          ],
        ])),
        const SizedBox(height: 20),
        const Text('Vos informations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 10),
        Container(decoration: BoxDecoration(color: _ThixColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: _ThixColors.cardBorder)), padding: const EdgeInsets.all(16), child: Form(key: _formKey, child: Column(children: [
          _field(_name, 'Nom complet', Icons.person_outline_rounded, autofill: AutofillHints.name, validator: (v) => (v?? '').trim().isEmpty? 'Requis' : null),
          const SizedBox(height: 12),
          _field(_email, 'Email', Icons.email_outlined, type: TextInputType.emailAddress, autofill: AutofillHints.email, validator: (v) =>!(v?? '').contains('@')? 'Email invalide' : null),
          const SizedBox(height: 12),
          _field(_phone, 'Téléphone', Icons.phone_outlined, type: TextInputType.phone, autofill: AutofillHints.telephoneNumber, validator: (v) => (v?? '').length<8? 'Numéro court' : null),
          const SizedBox(height: 12),
          _field(_pin, 'PIN 4 chiffres', Icons.lock_outline_rounded, type: TextInputType.number, max: 4, validator: (v) => (v?? '').length!=4? '4 chiffres' : null),
        ]))),
        if (_limit!= null)...[const SizedBox(height: 14), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _ThixColors.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(12), border: Border.all(color: _ThixColors.primary.withOpacity(0.2))), child: Row(children: [const Icon(Icons.info_outline_rounded, size: 16, color: _ThixColors.primary), const SizedBox(width: 8), Text('Max ${_limit!['maxPerPerson']} places / personne', style: const TextStyle(fontSize: 11, color: _ThixColors.primary, fontWeight: FontWeight.w700))]))],
      ])),
      bottomNavigationBar: Container(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), decoration: BoxDecoration(color: _ThixColors.surfaceAlt.withOpacity(0.96), border: Border(top: BorderSide(color: _ThixColors.cardBorder))), child: SafeArea(top: false, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Total', style: TextStyle(color: _ThixColors.textMuted, fontSize: 10)), Text(_formattedTotal, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))]),
        SizedBox(height: 46, child: ElevatedButton(onPressed: (_processing||_checking)? null : _reserve, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)), elevation: 0), child: (_processing||_checking)? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('PAYER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12))))),
      ]))),
    );
  }

  Widget _rowInfo(String l, String v) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(fontSize: 11, color: _ThixColors.textMuted)), const SizedBox(width: 12), Expanded(child: Text(v, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)))]);

  Widget _field(TextEditingController c, String label, IconData icon, {TextInputType? type, int? max, String? Function(String?)? validator, String? autofill}) {
    return TextFormField(controller: c, keyboardType: type, maxLength: max, autofillHints: autofill!= null? [autofill] : null, validator: validator, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: _ThixColors.textMuted, fontSize: 12), prefixIcon: Icon(icon, size: 16, color: _ThixColors.textMuted), filled: true, fillColor: _ThixColors.surfaceAlt, counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _ThixColors.cardBorder)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _ThixColors.primary)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)));
  }
}
