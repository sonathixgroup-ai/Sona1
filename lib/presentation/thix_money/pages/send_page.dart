// lib/presentation/thix_money/pages/send_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/payment_service.dart';
import '../utils/validators.dart';
import '../utils/constants.dart';
import '../utils/formatter.dart';
import '../providers/wallet_provider.dart';

class SendPage extends ConsumerStatefulWidget {
  const SendPage({super.key});
  @override
  ConsumerState<SendPage> createState() => _SendPageState();
}

class _SendPageState extends ConsumerState<SendPage> {
  final _formKey = GlobalKey<FormState>();
  final _destCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _motifCtrl = TextEditingController();
  String _devise = 'CDF';
  bool _loading = false;
  Map<String, dynamic>? _recipientProfile;
  bool _verifying = false;
  final _payment = PaymentService();

  Future<void> _verifyRecipient() async {
    final input = _destCtrl.text.trim();
    if (input.length < 3) return;
    setState(() => _verifying = true);
    try {
      // Vérifie si c'est un thix_id ou téléphone dans profiles
      var res = await Supabase.instance.client.from('profiles').select('thix_id, display_name, photo_url, thix_chat').or('thix_id.eq.$input,contact_phone.eq.$input,thix_chat.eq.$input').maybeSingle();
      setState(() => _recipientProfile = res);
    } catch (_) {} finally { setState(() => _verifying = false); }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_recipientProfile == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vérifiez le destinataire d\'abord'))); return; }
    setState(() => _loading = true);
    try {
      final montant = int.parse(_amountCtrl.text.replaceAll(RegExp(r'\D'), ''));
      await _payment.send(montant: montant, devise: _devise, phoneDest: _destCtrl.text, destThixId: _recipientProfile!['thix_id']);
      if (!mounted) return;
      showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Envoi réussi'), content: Text('Vous avez envoyé ${ThixFormatter.formatAmount(montant, _devise)} à ${_recipientProfile!['display_name']}'), actions: [TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('OK'))]));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Envoyer')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        wallet.when(data: (w) => Text('Solde dispo: ${ThixFormatter.formatAmount(_devise == 'CDF'? w.soldeCdf : w.soldeUsd, _devise)}', style: const TextStyle(color: Colors.grey)), loading: () => const SizedBox(), error: (_, __) => const SizedBox()),
        const SizedBox(height: 16),
        SegmentedButton<String>(segments: const [ButtonSegment(value: 'CDF', label: Text('CDF')), ButtonSegment(value: 'USD', label: Text('USD'))], selected: {_devise}, onSelectionChanged: (s) => setState(() => _devise = s.first)),
        const SizedBox(height: 16),
        TextFormField(controller: _destCtrl, decoration: InputDecoration(labelText: 'THIX ID, @thix_chat ou téléphone', suffixIcon: _verifying? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : IconButton(icon: const Icon(Icons.search), onPressed: _verifyRecipient), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => v!.isEmpty? 'Destinataire requis' : null, onChanged: (_) { if (_destCtrl.text.length > 5) _verifyRecipient(); }),
        const SizedBox(height: 12),
        if (_recipientProfile!= null) Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)), child: Row(children: [CircleAvatar(backgroundImage: _recipientProfile!['photo_url']!= null? NetworkImage(_recipientProfile!['photo_url']) : null, child: _recipientProfile!['photo_url'] == null? Text(_recipientProfile!['display_name'][0]) : null), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_recipientProfile!['display_name'], style: const TextStyle(fontWeight: FontWeight.bold)), Text(_recipientProfile!['thix_id'], style: const TextStyle(fontSize: 10, color: Colors.green)), Text(_recipientProfile!['thix_chat']?? '', style: const TextStyle(fontSize: 11))]), const Spacer(), const Icon(Icons.verified, color: Colors.green)])),
        const SizedBox(height: 16),
        TextFormField(controller: _amountCtrl, decoration: InputDecoration(labelText: 'Montant ($_devise)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => ThixValidators.montant(v, _devise), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        TextFormField(controller: _motifCtrl, decoration: InputDecoration(labelText: 'Motif (optionnel)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 2),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _loading? null : _send, style: ElevatedButton.styleFrom(backgroundColor: ThixConstants.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: _loading? const CircularProgressIndicator(color: Colors.white) : Text('Envoyer $_devise', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
      ]))),
    );
  }
}
