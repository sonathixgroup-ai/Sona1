// ================================================================
// CHEMIN: lib/presentation/thix_reservation/delivery/pages/client/delivery_checkout_page.dart
// ROLE: FLOW CHECKOUT - 4 étapes fusionnées en 1 page à steps
// Destinataire + Adresse + Paiement + Success
// C'est après "Calculer le prix" sur Home
// ================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/delivery_client_provider.dart';
import '../../data/delivery_models.dart';

class DeliveryCheckoutPage extends StatefulWidget {
  const DeliveryCheckoutPage({super.key});

  @override
  State<DeliveryCheckoutPage> createState() => _DeliveryCheckoutPageState();
}

class _DeliveryCheckoutPageState extends State<DeliveryCheckoutPage> {
  int _step = 0; // 0=receiver, 1=payment, 2=success
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _senderAddrCtrl = TextEditingController();
  ParcelType _type = ParcelType.other;
  bool _isCreating = false;
  String? _trackingCode;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DeliveryClientProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Envoyer un colis"), backgroundColor: Colors.white),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () async {
          if (_step == 0) {
            // Validation simple
            if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Remplis tous les champs")));
              return;
            }
            setState(() => _step = 1);
          } else if (_step == 1) {
            // Création colis Supabase
            setState(() => _isCreating = true);
            try {
              final code = await prov.createShipment(
                receiverName: _nameCtrl.text,
                receiverPhone: _phoneCtrl.text,
                receiverAddress: _addressCtrl.text,
                senderAddress: _senderAddrCtrl.text,
              );
              setState(() {
                _trackingCode = code;
                _step = 2;
                _isCreating = false;
              });
            } catch (e) {
              setState(() => _isCreating = false);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
            }
          }
        },
        onStepCancel: () => setState(() => _step = _step > 0? _step - 1 : 0),
        steps: [
          // --- STEP 0: Infos destinataire ---
          Step(
            title: const Text("Destinataire"),
            content: Column(children: [
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Nom destinataire")),
              TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: "Téléphone"), keyboardType: TextInputType.phone),
              TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: "Adresse complète dest.")),
              TextField(controller: _senderAddrCtrl, decoration: const InputDecoration(labelText: "Ton adresse expéditeur")),
              const SizedBox(height: 10),
              DropdownButtonFormField<ParcelType>(value: _type, items: ParcelType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(), onChanged: (v) => setState(() => _type = v!)),
            ]),
          ),
          // --- STEP 1: Paiement ---
          Step(
            title: const Text("Paiement"),
            content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("${prov.fromCity} → ${prov.toCity}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("${prov.calculatedPrice} FCFA", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ]),
              ),
              const SizedBox(height: 10),
              const Text("Mode de paiement (Orange Money / Wave / Carte) - à intégrer"),
              if (_isCreating) const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
            ]),
          ),
          // --- STEP 2: Success ---
          Step(
            title: const Text("Succès"),
            content: Column(children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 10),
              const Text("Colis créé avec succès!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              SelectableText("Code tracking: $_trackingCode", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => Navigator.popUntil(context, (r) => r.isFirst), child: const Text("Retour Accueil")),
            ]),
          ),
        ],
      ),
    );
  }
}
