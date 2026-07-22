// lib/presentation/thix_money/pages/send_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/payment_service.dart';
import '../utils/validators.dart';
import '../utils/constants.dart';
import '../utils/formatter.dart';
import '../providers/wallet_provider.dart';

class SendPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData; // vient du scanner QR
  const SendPage({super.key, this.initialData});

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
  bool _verifying = false;
  Map<String, dynamic>? _recipientProfile;
  Timer? _debounce;
  final _payment = PaymentService();

  @override
  void initState() {
    super.initState();
    // Pré-remplissage depuis scanner QR THIX
    if (widget.initialData!= null) {
      final d = widget.initialData!;
      _destCtrl.text = d['thix_id']?? d['phone']?? d['thix_chat']?? '';
      if (_destCtrl.text.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _verifyRecipient());
      }
    }
    _destCtrl.addListener(_onDestChanged);
  }

  void _onDestChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (_destCtrl.text.trim().length >= 3) _verifyRecipient();
    });
  }

  Future<void> _verifyRecipient() async {
    final input = _destCtrl.text.trim().replaceAll('@', '');
    if (input.length < 3) return;
    setState(() => _verifying = true);
    try {
      // Vérifie en base profiles : thix_id, thix_chat, contact_phone - SOURCE DE VÉRITÉ
      final res = await Supabase.instance.client
         .from('profiles')
         .select('thix_id, display_name, photo_url, thix_chat, contact_phone')
         .or('thix_id.eq.$input,thix_chat.eq.$input,contact_phone.eq.$input,thix_chat.eq.@${input}')
         .maybeSingle();

      // Anti auto-envoi : ne peut pas s'envoyer à soi-même
      final myThixId = await ref.read(currentThixIdProvider.future);
      if (res!= null && res['thix_id'] == myThixId) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vous ne pouvez pas vous envoyer à vous-même'), backgroundColor: Colors.orange));
        setState(() => _recipientProfile = null);
        return;
      }

      if (!mounted) return;
      setState(() => _recipientProfile = res);
      if (res == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Aucun compte THIX trouvé pour "$input"'), backgroundColor: Colors.red.shade400));
      }
    } catch (e) {
      debugPrint('Verify error: $e');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_recipientProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vérifiez le destinataire d\'abord'), backgroundColor: Colors.red));
      return;
    }

    // Confirmation PIN/BottomSheet pro
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ConfirmSheet(
        amount: _amountCtrl.text,
        devise: _devise,
        recipient: _recipientProfile!['display_name'],
        thixId: _recipientProfile!['thix_id'],
      ),
    );
    if (confirmed!= true) return;

    setState(() => _loading = true);
    try {
      final montant = int.parse(_amountCtrl.text.replaceAll(RegExp(r'\D'), ''));
      final refTransa = await _payment.send(
        montant: montant,
        devise: _devise,
        phoneDest: _recipientProfile!['contact_phone']?? _destCtrl.text,
        destThixId: _recipientProfile!['thix_id'],
      );

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white)), const SizedBox(width: 12), const Text('Envoi réussi')]),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Vous avez envoyé ${ThixFormatter.formatAmount(montant, _devise)} à ${_recipientProfile!['display_name']}'),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Ref: $refTransa', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), Text('THIX ID: ${_recipientProfile!['thix_id']}', style: const TextStyle(fontSize: 10, color: Colors.green))])),
          ]),
          actions: [TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Fermer'))],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red.shade600));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _destCtrl.removeListener(_onDestChanged);
    _destCtrl.dispose();
    _amountCtrl.dispose();
    _motifCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletStreamProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(title: const Text('Envoyer'), backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            wallet.when(
              data: (w) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)), child: Row(children: [const Icon(Icons.account_balance_wallet, color: ThixConstants.primary), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Solde disponible', style: TextStyle(fontSize: 11, color: Colors.grey)), Text(ThixFormatter.formatAmount(_devise == 'CDF'? w.soldeCdf : w.soldeUsd, _devise), style: const TextStyle(fontWeight: FontWeight.bold))])])),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 20),
            const Text('Devise', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 8),
            SegmentedButton<String>(segments: const [ButtonSegment(value: 'CDF', label: Text('CDF 🇨🇩')), ButtonSegment(value: 'USD', label: Text('USD \$'))], selected: {_devise}, onSelectionChanged: (s) => setState(() => _devise = s.first), style: ButtonStyle(backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected)? ThixConstants.primary : Colors.white))),
            const SizedBox(height: 20),
            TextFormField(
              controller: _destCtrl,
              decoration: InputDecoration(
                labelText: 'THIX ID, @thix_chat ou téléphone',
                hintText: 'THIX-CD-... ou @john ou 099...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _verifying? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) : IconButton(icon: const Icon(Icons.verified_user), onPressed: _verifyRecipient),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: Colors.white,
              ),
              validator: (v) => v!.isEmpty? 'Destinataire requis' : null,
            ),
            const SizedBox(height: 12),
            if (_recipientProfile!= null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.green.shade200)),
                child: Row(children: [
                  CircleAvatar(radius: 24, backgroundImage: _recipientProfile!['photo_url']!= null? NetworkImage(_recipientProfile!['photo_url']) : null, child: _recipientProfile!['photo_url'] == null? Text(_recipientProfile!['display_name'][0].toUpperCase()) : null),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_recipientProfile!['display_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 2), Text(_recipientProfile!['thix_id'], style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)), Text(_recipientProfile!['thix_chat']?? _recipientProfile!['contact_phone']?? '', style: const TextStyle(fontSize: 11, color: Colors.grey))])),
                  const Icon(Icons.verified, color: Colors.green, size: 22),
                ]),
              ),
            if (_recipientProfile == null && _destCtrl.text.length > 5 &&!_verifying)
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(Icons.error_outline, color: Colors.red.shade400, size: 18), const SizedBox(width: 8), Expanded(child: Text('Aucun THIX ID trouvé. Vérifiez en base profiles.', style: TextStyle(color: Colors.red.shade700, fontSize: 12)))])),
            const SizedBox(height: 20),
            TextFormField(controller: _amountCtrl, decoration: InputDecoration(labelText: 'Montant ($_devise)', prefixText: '$_devise ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: Colors.white), validator: (v) => ThixValidators.montant(v, _devise), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextFormField(controller: _motifCtrl, decoration: InputDecoration(labelText: 'Motif (optionnel)', hintText: 'Ex: Loyer, soutien...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: Colors.white), maxLines: 2),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _loading || _recipientProfile == null? null : _send, style: ElevatedButton.styleFrom(backgroundColor: ThixConstants.primary, disabledBackgroundColor: Colors.grey.shade300, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: _loading? const CircularProgressIndicator(color: Colors.white) : Text('Envoyer $_devise', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
            const SizedBox(height: 12),
            const Center(child: Text('Chaque envoi est lié à votre THIX ID et vérifié dans profiles.thix_id', style: TextStyle(fontSize: 10, color: Colors.grey))),
          ]),
        ),
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  final String amount; final String devise; final String recipient; final String thixId;
  const _ConfirmSheet({required this.amount, required this.devise, required this.recipient, required this.thixId});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
        const SizedBox(height: 20),
        const Text('Confirmer l\'envoi?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF6F8FF), borderRadius: BorderRadius.circular(14)), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Destinataire'), Text(recipient, style: const TextStyle(fontWeight: FontWeight.bold))]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('THIX ID'), Text(thixId, style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold))]),
          const Divider(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Montant'), Text('$amount $devise', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ThixConstants.primary))]),
        ])),
        const SizedBox(height: 24),
        Row(children: [Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler'))), const SizedBox(width: 12), Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: ThixConstants.primary), child: const Text('Confirmer', style: TextStyle(color: Colors.white))))]),
        const SizedBox(height: 12),
      ]),
    );
  }
}
