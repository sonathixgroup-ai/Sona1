import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/event_payment_provider.dart';

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

final _paymentProvider = Provider<EventPaymentProvider>((ref) => EventPaymentProvider(Supabase.instance.client));

class EventPaymentPage extends ConsumerStatefulWidget {
  final String bookingId;
  final double amount;
  final String currency;
  const EventPaymentPage({super.key, required this.bookingId, required this.amount, required this.currency});
  @override
  ConsumerState<EventPaymentPage> createState() => _EventPaymentPageState();
}

class _EventPaymentPageState extends ConsumerState<EventPaymentPage> {
  String _selected = 'airtel';
  final _phone = TextEditingController();
  StreamSubscription? _sub;
  bool _processing = false;
  String? _error;

  final _methods = const [
    {'id': 'mpesa', 'name': 'M-Pesa', 'brand': 'Vodacom', 'color': Color(0xFF00A651), 'icon': Icons.phone_android_rounded},
    {'id': 'airtel', 'name': 'Airtel Money', 'brand': 'Airtel', 'color': Color(0xFFFF0000), 'icon': Icons.phone_android_rounded},
    {'id': 'orange', 'name': 'Orange Money', 'brand': 'Orange', 'color': Color(0xFFFF6600), 'icon': Icons.phone_android_rounded},
    {'id': 'visa_master', 'name': 'Visa & Mastercard', 'brand': 'Carte Bancaire', 'color': Color(0xFF1A1F71), 'icon': Icons.credit_card_rounded},
  ];

  @override
  void dispose() { _phone.dispose(); _sub?.cancel(); super.dispose(); }

  Future<void> _pay() async {
    final m = _methods.firstWhere((e) => e['id'] == _selected);
    final needPhone = m['id'] != 'visa_master';
    if (needPhone && _phone.text.trim().length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Numéro invalide'), backgroundColor: Colors.orange));
      return;
    }
    setState(() { _processing = true; _error = null; });
    final svc = ref.read(_paymentProvider);
    final ok = await svc.makePayment(bookingId: widget.bookingId, amount: widget.amount, currency: widget.currency, paymentMethod: _selected, phoneNumber: needPhone ? _phone.text.trim() : null);
    setState(() => _processing = false);
    if (ok && mounted) { _waitingDialog(); } else if (mounted && svc.errorMessage!= null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${svc.errorMessage}'), backgroundColor: Colors.red));
    }
  }

  void _waitingDialog() {
    showDialog(barrierDismissible: false, context: context, builder: (_) => Dialog(backgroundColor: _ThixColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: _ThixColors.cardBorder)), child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: const [CircularProgressIndicator(color: _ThixColors.primary), SizedBox(height: 20), Text('Validation en cours...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)), SizedBox(height: 8), Text('Confirmez le PIN sur votre téléphone', textAlign: TextAlign.center, style: TextStyle(color: _ThixColors.textSecondary, fontSize: 12))]))));
    _sub = Supabase.instance.client.from('event_bookings').stream(primaryKey: ['id']).eq('id', widget.bookingId).listen((data) {
      if (data.isEmpty) return;
      final status = data.first['payment_status'];
      if (status == 'paid') {
        _sub?.cancel();
        if (mounted) { Navigator.of(context, rootNavigator: true).pop(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Paiement confirmé'), backgroundColor: Colors.green)); context.pushReplacement('/thix-event/ticket/${widget.bookingId}'); }
      } else if (status == 'failed' || status == 'cancelled') {
        _sub?.cancel();
        if (mounted) { Navigator.of(context, rootNavigator: true).pop(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Transaction échouée'), backgroundColor: Colors.red)); }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedObj = _methods.firstWhere((e) => e['id'] == _selected);
    final needPhone = selectedObj['id'] != 'visa_master';

    return Scaffold(
      backgroundColor: _ThixColors.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: ClipRRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: AppBar(backgroundColor: _ThixColors.bg.withOpacity(0.85), elevation: 0, leading: Padding(padding: const EdgeInsets.all(8), child: InkWell(onTap: () => context.pop(), child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle, border: Border.all(color: _ThixColors.cardBorder)), child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18)))), title: const Text('Paiement', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)), centerTitle: true)))),
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Column(children: [const Text('Montant à payer', style: TextStyle(color: _ThixColors.textMuted, fontSize: 12)), const SizedBox(height: 6), Text('${widget.amount.toStringAsFixed(0)} ${widget.currency}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white)) ])),
        const SizedBox(height: 28),
        const Text('Moyen de paiement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 12),
        ..._methods.map((m) => _option(m)).toList(),
        const SizedBox(height: 18),
        if (needPhone) ...[
          const Text('Numéro Mobile Money', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 8),
          TextField(controller: _phone, keyboardType: TextInputType.phone, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), decoration: InputDecoration(hintText: '+243...', hintStyle: const TextStyle(color: _ThixColors.textMuted), filled: true, fillColor: _ThixColors.surface, prefixIcon: const Icon(Icons.phone_iphone_rounded, color: _ThixColors.textSecondary), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _ThixColors.cardBorder)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _ThixColors.cardBorder)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _ThixColors.primary, width: 1.2)))),
        ],
      ])),
      bottomNavigationBar: Container(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), decoration: BoxDecoration(color: _ThixColors.surfaceAlt.withOpacity(0.96), border: Border(top: BorderSide(color: _ThixColors.cardBorder))), child: SafeArea(top: false, child: SizedBox(height: 46, width: double.infinity, child: ElevatedButton(onPressed: _processing ? null : _pay, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)), elevation: 0), child: _processing ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : Text('PAYER ${widget.amount.toStringAsFixed(0)} ${widget.currency}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)))))),
    );
  }

  Widget _option(Map<String, dynamic> m) {
    final sel = _selected == m['id'];
    final color = m['color'] as Color;
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: InkWell(onTap: () => setState(() => _selected = m['id'] as String), borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: sel ? _ThixColors.primary.withOpacity(0.10) : _ThixColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: sel ? _ThixColors.primary : _ThixColors.cardBorder, width: sel ? 1.2 : 1)), child: Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.18), shape: BoxShape.circle), child: Icon(m['icon'] as IconData, color: color, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)), const SizedBox(height: 2), Text(m['brand'] as String, style: const TextStyle(color: _ThixColors.textMuted, fontSize: 11))])),
      Icon(sel ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: sel ? _ThixColors.primary : _ThixColors.textMuted, size: 20),
    ]))));
  }
}
