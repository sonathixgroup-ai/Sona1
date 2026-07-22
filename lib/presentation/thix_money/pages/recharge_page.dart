// lib/presentation/thix_money/pages/recharge_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/payment_service.dart';
import '../services/notification_service.dart';
import '../utils/validators.dart';
import '../utils/constants.dart';
import '../utils/formatter.dart';
import '../providers/wallet_provider.dart';

class RechargePage extends ConsumerStatefulWidget {
  const RechargePage({super.key});
  @override
  ConsumerState<RechargePage> createState() => _RechargePageState();
}

class _RechargePageState extends ConsumerState<RechargePage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController(text: '099');
  final _amount = TextEditingController();
  String _devise = 'CDF';
  String _operator = 'M-Pesa';
  bool _loading = false;
  final _payment = PaymentService();

  final operators = [
    {'name': 'M-Pesa', 'color': Colors.red, 'logo': 'M'},
    {'name': 'Airtel Money', 'color': Colors.redAccent, 'logo': 'A'},
    {'name': 'Orange Money', 'color': Colors.orange, 'logo': 'O'},
  ];

  double get _fees => _devise == 'CDF'? 0 : 0; // 0% pour lancement

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final thixId = await ref.read(currentThixIdProvider.future);
      // Vérifie que thix_id existe vraiment
      final exists = await Supabase.instance.client.from('profiles').select('id').eq('thix_id', thixId).maybeSingle();
      if (exists == null) throw Exception('THIX ID invalide, compte bloqué');

      final montant = int.parse(_amount.text.replaceAll(RegExp(r'\D'), ''));
      final refTransa = await _payment.recharge(montant: montant, devise: _devise, phone: _phone.text);

      if (!mounted) return;
      showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (_) => _SuccessSheet(refTransa: refTransa, montant: montant, devise: _devise, phone: _phone.text));
    } catch (e) {
      NotificationService.showSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletStreamProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Recharger'), centerTitle: true, backgroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF6F8FF), borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.account_balance_wallet, color: ThixConstants.primary), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Solde actuel', style: TextStyle(fontSize: 11, color: Colors.grey)), wallet.when(data: (w) => Text(ThixFormatter.formatAmount(_devise == 'CDF'? w.soldeCdf : w.soldeUsd, _devise), style: const TextStyle(fontWeight: FontWeight.bold)), loading: () => const Text('...'), error: (_, __) => const Text('Erreur'))])])),
            const SizedBox(height: 24),
            const Text('Opérateur', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8),
            Row(children: operators.map((op) => Expanded(child: GestureDetector(onTap: () => setState(() => _operator = op['name'] as String), child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: _operator == op['name']? ThixConstants.primary : Colors.grey.shade300, width: _operator == op['name']? 2 : 1), borderRadius: BorderRadius.circular(12), color: _operator == op['name']? ThixConstants.primary.withOpacity(0.05) : Colors.white), child: Column(children: [CircleAvatar(backgroundColor: op['color'] as Color, radius: 18, child: Text(op['logo'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))), const SizedBox(height: 6), Text(op['name'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)]))))).toList()),
            const SizedBox(height: 20),
            SegmentedButton<String>(segments: const [ButtonSegment(value: 'CDF', label: Text('CDF')), ButtonSegment(value: 'USD', label: Text('USD'))], selected: {_devise}, onSelectionChanged: (s) => setState(() => _devise = s.first)),
            const SizedBox(height: 16),
            TextFormField(controller: _phone, decoration: InputDecoration(labelText: 'Numéro $_operator', prefixIcon: const Icon(Icons.phone), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey.shade50), validator: ThixValidators.phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            TextFormField(controller: _amount, decoration: InputDecoration(labelText: 'Montant ($_devise)', prefixText: '$_devise ', prefixIcon: const Icon(Icons.money), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey.shade50), validator: (v) => ThixValidators.montant(v, _devise), keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            if (_amount.text.isNotEmpty) Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Montant'), Text('${_amount.text} $_devise')]), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Frais'), Text('$_fees $_devise', style: const TextStyle(color: Colors.green))]), const Divider(), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total à recevoir', style: TextStyle(fontWeight: FontWeight.bold)), Text('${_amount.text} $_devise', style: const TextStyle(fontWeight: FontWeight.bold, color: ThixConstants.primary))])])),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _loading? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: ThixConstants.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: _loading? const CircularProgressIndicator(color: Colors.white) : const Text('Confirmer la recharge', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
          ]),
        ),
      ),
    );
  }
}

class _SuccessSheet extends StatelessWidget {
  final String refTransa; final int montant; final String devise; final String phone;
  const _SuccessSheet({required this.refTransa, required this.montant, required this.devise, required this.phone});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 60, height: 60, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 32)),
      const SizedBox(height: 16), const Text('Demande envoyée!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), Text('Validez le paiement de $montant $devise sur votre $phone', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 12), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Ref:'), Text(refTransa, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10))])),
      const SizedBox(height: 24), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.popUntil(context, (r) => r.isFirst), child: const Text('Terminé'))),
    ]));
  }
}
