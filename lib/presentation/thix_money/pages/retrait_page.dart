// lib/presentation/thix_money/pages/retrait_page.dart
import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import '../services/notification_service.dart';
import '../utils/validators.dart';
import '../utils/constants.dart';

class RetraitPage extends StatefulWidget {
  const RetraitPage({super.key});
  @override
  State<RetraitPage> createState() => _RetraitPageState();
}

class _RetraitPageState extends State<RetraitPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  String _devise = 'CDF';
  bool _loading = false;
  final _payment = PaymentService();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final ref = await _payment.retrait(montant: int.parse(_montantCtrl.text), devise: _devise, phone: _phoneCtrl.text);
      if (!mounted) return;
      NotificationService.showSnack(context, 'Retrait demandé. Ref: $ref');
      Navigator.pop(context);
    } catch (e) {
      NotificationService.showSnack(context, 'Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retrait THIX MONEY')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            DropdownButtonFormField<String>(value: _devise, decoration: const InputDecoration(labelText: 'Devise', border: OutlineInputBorder()), items: ThixConstants.supportedDevises.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), onChanged: (v) => setState(() => _devise = v!)),
            const SizedBox(height: 12),
            TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Numéro pour retrait', border: OutlineInputBorder()), validator: ThixValidators.phone),
            const SizedBox(height: 12),
            TextFormField(controller: _montantCtrl, decoration: InputDecoration(labelText: 'Montant $_devise', border: const OutlineInputBorder()), validator: (v) => ThixValidators.montant(v, _devise)),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: _loading? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: ThixConstants.primary), child: Text(_loading? '...' : 'Retirer', style: const TextStyle(color: Colors.white)))),
          ]),
        ),
      ),
    );
  }
}
