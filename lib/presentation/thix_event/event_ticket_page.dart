import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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

class EventTicketPage extends StatefulWidget {
  final String bookingId;
  const EventTicketPage({super.key, required this.bookingId});
  @override
  State<EventTicketPage> createState() => _EventTicketPageState();
}

class _EventTicketPageState extends State<EventTicketPage> with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _qrVisible = false;
  Map<String, dynamic>? _booking;
  Map<String, dynamic>? _event;
  late AnimationController _holo;

  @override
  void initState() {
    super.initState();
    _holo = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _fetch();
  }

  @override
  void dispose() { _holo.dispose(); super.dispose(); }

  Future<void> _fetch() async {
    try {
      final res = await Supabase.instance.client.from('event_bookings').select('*, events(*)').eq('id', widget.bookingId).single();
      if (mounted) setState(() { _booking = res; _event = res['events']; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  void _askPin() {
    final ctrl = TextEditingController();
    final correct = _booking!['pin_code']?.toString()?? '';
    showDialog(context: context, builder: (_) => Dialog(backgroundColor: _ThixColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: _ThixColors.cardBorder)), child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Row(children: [Icon(Icons.lock_rounded, color: _ThixColors.primary, size: 18), SizedBox(width: 8), Text('Sécurité', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))]),
      const SizedBox(height: 12), const Text('Entrez votre PIN 4 chiffres pour déverrouiller', style: TextStyle(color: _ThixColors.textSecondary, fontSize: 12)),
      const SizedBox(height: 14),
      TextField(controller: ctrl, keyboardType: TextInputType.number, maxLength: 4, obscureText: true, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 4), decoration: InputDecoration(counterText: '', hintText: '••••', filled: true, fillColor: _ThixColors.surfaceAlt, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _ThixColors.primary)))),
      const SizedBox(height: 16),
      Row(children: [Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(side: const BorderSide(color: _ThixColors.cardBorder), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Annuler', style: TextStyle(color: _ThixColors.textMuted)))), const SizedBox(width: 10), Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(context); if (ctrl.text.trim()==correct) { setState(() => _qrVisible = true); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN incorrect'), backgroundColor: Colors.red)); } }, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Confirmer', style: TextStyle(fontWeight: FontWeight.w800))))]),
    ]))));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: _ThixColors.bg, body: Center(child: CircularProgressIndicator(color: _ThixColors.primary)));
    if (_booking== null || _event== null) return Scaffold(backgroundColor: _ThixColors.bg, appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: () => context.go('/thix-event'))), body: const Center(child: Text('Billet introuvable', style: TextStyle(color: Colors.white))));

    final title = _event!['title']?? 'Événement';
    final dateStr = _event!['date']?? _event!['start_date'];
    final dt = dateStr!= null? DateTime.tryParse(dateStr.toString())?? DateTime.now() : DateTime.now();
    final dateFmt = DateFormat('dd MMM yyyy • HH:mm', 'fr').format(dt);
    final loc = _event!['location']?? '';
    final img = _event!['image_url'];
    final qty = _booking!['ticket_quantity']?? 1;
    final cat = _booking!['ticket_category']?? 'Standard';
    final pin = _booking!['pin_code']?.toString()?? '****';
    final qr = _booking!['id'].toString();
    final masked = '****-****-${qr.length>=4? qr.substring(qr.length-4).toUpperCase() : qr}';

    final rawStatus = (_booking!['status']?? 'confirmed').toString().toLowerCase();
    final isPaid = (_booking!['payment_status']?? 'paid').toString().toLowerCase()=='paid';
    String label = 'VALIDE'; Color c = Colors.green;
    if (rawStatus=='used' || rawStatus=='scanned') { label='UTILISÉ'; c=Colors.grey; }
    else if (rawStatus=='cancelled') { label='ANNULÉ'; c=Colors.red; }
    else if (dt.isBefore(DateTime.now())) { label='EXPIRÉ'; c=Colors.orange; }
    else if (!isPaid) { label='EN ATTENTE'; c=Colors.blue; }

    return Scaffold(
      backgroundColor: _ThixColors.bg,
      appBar: PreferredSize(preferredSize: const Size.fromHeight(52), child: ClipRRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: AppBar(backgroundColor: _ThixColors.bg.withOpacity(0.85), elevation: 0, leading: IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: () => context.go('/thix-event')), title: const Text('Billet Sécurisé', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)), centerTitle: true)))),
      body: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), child: Column(children: [
        Stack(children: [
          Container(decoration: BoxDecoration(color: _ThixColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: _ThixColors.cardBorder)), child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (img!= null) ClipRRect(borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)), child: Image.network(img, height: 160, width: double.infinity, fit: BoxFit.cover))
            else Container(height: 120, decoration: const BoxDecoration(color: _ThixColors.surfaceAlt, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))), child: const Center(child: Icon(Icons.event, color: _ThixColors.textMuted))),
            Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
              const SizedBox(height: 14),
              _info(Icons.calendar_today_rounded, 'Date', dateFmt),
              const SizedBox(height: 10), _info(Icons.location_on_rounded, 'Lieu', loc),
              const SizedBox(height: 18),
              Row(children: [Expanded(child: _detail('Billets', '$qty')), Expanded(child: _detail('Type', cat)), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Statut', style: TextStyle(fontSize: 10, color: _ThixColors.textMuted)), const SizedBox(height: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.withOpacity(0.3))), child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: c)))]))]),
              const SizedBox(height: 14),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: _ThixColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: _ThixColors.cardBorder)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Row(children: [Icon(Icons.lock_rounded, size: 14, color: _ThixColors.textSecondary), SizedBox(width: 6), Text('PIN', style: TextStyle(fontSize: 11, color: _ThixColors.textSecondary, fontWeight: FontWeight.w700))]), Text(_qrVisible? pin : '••••', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 14))])),
            ])),
            Stack(children: [const Divider(color: _ThixColors.cardBorder, height: 1, indent: 16, endIndent: 16), Positioned(left: -10, top: -10, child: Container(height: 20, width: 20, decoration: const BoxDecoration(color: _ThixColors.bg, shape: BoxShape.circle))), Positioned(right: -10, top: -10, child: Container(height: 20, width: 20, decoration: const BoxDecoration(color: _ThixColors.bg, shape: BoxShape.circle)))]),
            Padding(padding: const EdgeInsets.all(18), child: Column(children: [
              _qrVisible? Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: QrImageView(data: qr, version: QrVersions.auto, size: 150, foregroundColor: Colors.black)) : Container(height: 170, width: double.infinity, decoration: BoxDecoration(color: _ThixColors.surfaceAlt, borderRadius: BorderRadius.circular(16), border: Border.all(color: _ThixColors.cardBorder)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.lock_outline_rounded, size: 28, color: _ThixColors.textMuted), const SizedBox(height: 8), const Text('QR masqué', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)), const SizedBox(height: 10), ElevatedButton.icon(onPressed: _askPin, icon: const Icon(Icons.visibility_rounded, size: 14), label: const Text('Afficher', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8))])) ,
              const SizedBox(height: 10), Text('ID: ${_qrVisible? qr.split('-').first.toUpperCase() : masked}', style: const TextStyle(color: _ThixColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
            ])),
          ])),
          // Hologramme
          Positioned.fill(child: IgnorePointer(child: ClipRRect(borderRadius: BorderRadius.circular(24), child: AnimatedBuilder(animation: _holo, builder: (_, child) {
            final slide = _holo.value * 2 - 0.5;
            return ShaderMask(blendMode: BlendMode.srcIn, shaderCallback: (b) => LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.transparent, const Color(0xFF3B82F6).withOpacity(0.18), const Color(0xFFFF0A54).withOpacity(0.22), const Color(0xFF10B981).withOpacity(0.18), Colors.transparent], stops: [0.0, (slide-0.1).clamp(0,1), slide.clamp(0,1), (slide+0.1).clamp(0,1), 1.0]).createShader(b), child: child);
          }, child: Transform.rotate(angle: -0.2, child: Wrap(spacing: 30, runSpacing: 40, children: List.generate(80, (_) => const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.verified_user_rounded, size: 10, color: Colors.white), SizedBox(width: 4), Text('THIX SECURE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1))])))))))),
        ]),
        const SizedBox(height: 24),
        SizedBox(height: 46, child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download_rounded, size: 16), label: const Text('Télécharger', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: _ThixColors.cardBorderStrong), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)), padding: const EdgeInsets.symmetric(horizontal: 24)))),
      ])),
    );
  }

  Widget _info(IconData icon, String label, String value) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 14, color: _ThixColors.textMuted), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, color: _ThixColors.textMuted)), const SizedBox(height: 2), Text(value, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600))]))]);
  Widget _detail(String l, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(fontSize: 10, color: _ThixColors.textMuted)), const SizedBox(height: 3), Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white))]);
}
