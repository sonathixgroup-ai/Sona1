import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'checkout_provider.dart';
import 'shipping_method_selector.dart';
import 'payment_method_selector.dart';
import 'order_summary_widget.dart';
import 'order_confirmation_page.dart';
import '../../cart/cart_provider.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
      ],
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Validation de commande'),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer<CheckoutProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            return _buildStepContent(provider, context);
          },
        ),
      ),
    );
  }

  Widget _buildStepContent(CheckoutProvider provider, BuildContext context) {
    switch (provider.currentStep) {
      case 'address':
        return _AddressStep(provider: provider);
      case 'shipping':
        return ShippingMethodSelector(provider: provider);
      case 'payment':
        return PaymentMethodSelector(provider: provider);
      case 'confirmation':
        return OrderSummaryWidget(provider: provider);
      default:
        return const SizedBox();
    }
  }
}

// Widget pour l'étape adresse (intégré dans la même page)
class _AddressStep extends StatelessWidget {
  final CheckoutProvider provider;

  const _AddressStep({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Adresse de livraison',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (provider.savedAddresses.isEmpty)
                _buildEmptyAddress(context)
              else
                ...provider.savedAddresses.map((addr) => _buildAddressCard(addr, provider)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => _showAddAddressDialog(context, provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFE5592F),
              side: const BorderSide(color: Color(0xFFE5592F)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('+ Ajouter une nouvelle adresse'),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address, CheckoutProvider provider) {
    final isSelected = provider.selectedAddress?['id'] == address['id'];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? const Color(0xFFE5592F) : Colors.grey[200]!, width: isSelected ? 2 : 1),
      ),
      child: RadioListTile<Map<String, dynamic>>(
        value: address,
        groupValue: provider.selectedAddress,
        onChanged: (value) => provider.selectAddress(value!),
        title: Text(address['full_name'] ?? 'Destinataire'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(address['address_line'] ?? ''),
            Text('${address['city']}, ${address['postal_code']}'),
            Text('Tél: ${address['phone']}'),
          ],
        ),
        activeColor: const Color(0xFFE5592F),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildEmptyAddress(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('Aucune adresse enregistrée', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _showAddAddressDialog(BuildContext context, CheckoutProvider provider) {
    final formKey = GlobalKey<FormState>();
    final fullNameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final postalCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nouvelle adresse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(controller: fullNameCtrl, decoration: const InputDecoration(labelText: 'Nom complet'), validator: (v) => v!.isEmpty ? 'Requis' : null),
              TextFormField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Adresse'), validator: (v) => v!.isEmpty ? 'Requis' : null),
              TextFormField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'Ville'), validator: (v) => v!.isEmpty ? 'Requis' : null),
              TextFormField(controller: postalCtrl, decoration: const InputDecoration(labelText: 'Code postal'), validator: (v) => v!.isEmpty ? 'Requis' : null),
              TextFormField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Téléphone'), validator: (v) => v!.isEmpty ? 'Requis' : null),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          provider.addAddress({
                            'full_name': fullNameCtrl.text,
                            'address_line': addressCtrl.text,
                            'city': cityCtrl.text,
                            'postal_code': postalCtrl.text,
                            'phone': phoneCtrl.text,
                          });
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5592F)),
                      child: const Text('Ajouter'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
