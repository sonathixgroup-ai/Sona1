// lib/presentation/thix_money/pages/recharge_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/payment_service.dart';
import '../services/notification_service.dart';
import '../utils/validators.dart';
import '../utils/constants.dart';

class RechargePage extends ConsumerStatefulWidget {
  const RechargePage({super.key});
  @override
  ConsumerState<RechargePage> createState() => _RechargePageState();
}

class _RechargePageState extends ConsumerState<RechargePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  String _devise = 'CDF';
  bool _loading = false;
  final _payment = PaymentService();

  @override
  void dispose() { _phoneCtrl.dispose(); _montantCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final montant = int.parse(_montantCtrl.text.replaceAll(' ', ''));
      final ref = await _payment.recharge(montant: montant, devise: _devise, phone: _phoneCtrl.text);
      if (!mounted) return;
      NotificationService.showSnack(context, 'Recharge lancée. Validez sur votre téléphone. Ref: $ref');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      NotificationService.showSnack(context, 'Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recharger • THIX MONEY'), backgroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            DropdownButtonFormField<String>(value: _devise, decoration: const InputDecoration(labelText: 'Devise', border: OutlineInputBorder()), items: ThixConstants.supportedDevises.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), onChanged: (v) => setState(() => _devise = v!)),
            const SizedBox(height: 12),
            TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Numéro Mobile Money (ex: 0991234567)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)), validator: ThixValidators.phone),
            const SizedBox(height: 12),
            TextFormField(controller: _montantCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Montant ($_devise)', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.money)), validator: (v) => ThixValidators.montant(v, _devise)),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: _loading? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: ThixConstants.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: _loading? const CircularProgressIndicator(color: Colors.white) : Text('Recharger en $_devise', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
          ]),
        ),
      ),
    );
  }
}
