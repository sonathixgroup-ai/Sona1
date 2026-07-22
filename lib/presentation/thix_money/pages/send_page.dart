// lib/presentation/thix_money/pages/send_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/payment_service.dart';
import '../services/notification_service.dart';
import '../utils/validators.dart';
import '../utils/constants.dart';

class SendPage extends ConsumerStatefulWidget {
  const SendPage({super.key});
  @override
  ConsumerState<SendPage> createState() => _SendPageState();
}

class _SendPageState extends ConsumerState<SendPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneDestCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  String _devise = 'CDF';
  bool _loading = false;
  final _payment = PaymentService();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final montant = int.parse(_montantCtrl.text.replaceAll(' ', ''));
      final ref = await _payment.send(montant: montant, devise: _devise, phoneDest: _phoneDestCtrl.text);
      if (!mounted) return;
      NotificationService.showSnack(context, 'Envoi lancé. Ref: $ref');
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
      appBar: AppBar(title: const Text('Envoyer de l\'argent')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            DropdownButtonFormField<String>(value: _devise, decoration: const InputDecoration(labelText: 'Devise', border: OutlineInputBorder()), items: ThixConstants.supportedDevises.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), onChanged: (v) => setState(() => _devise = v!)),
            const SizedBox(height: 12),
            TextFormField(controller: _phoneDestCtrl, decoration: const InputDecoration(labelText: 'Numéro destinataire / THIX ID', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)), validator: ThixValidators.phone),
            const SizedBox(height: 12),
            TextFormField(controller: _montantCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Montant ($_devise)', border: const OutlineInputBorder()), validator: (v) => ThixValidators.montant(v, _devise)),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: _loading? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: ThixConstants.primary), child: _loading? const CircularProgressIndicator(color: Colors.white) : Text('Envoyer $_devise', style: const TextStyle(color: Colors.white)))),
          ]),
        ),
      ),
    );
  }
}
