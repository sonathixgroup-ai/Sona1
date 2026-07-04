import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'delivery_provider.dart';

class DeliveryAddressSelector extends StatelessWidget {
  final Function(Map<String, dynamic>)? onAddressSelected;

  const DeliveryAddressSelector({super.key, this.onAddressSelected});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeliveryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingAddresses) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.addresses.isEmpty) {
          return _buildEmptyState(context, provider);
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.addresses.length,
                itemBuilder: (context, index) {
                  final address = provider.addresses[index];
                  final isSelected = provider.selectedAddress?['id'] == address['id'];
                  return _buildAddressCard(address, isSelected, provider);
                },
              ),
            ),
            _buildAddAddressButton(context, provider),
          ],
        );
      },
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address, bool isSelected, DeliveryProvider provider) {
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
        onChanged: (value) {
          provider.selectAddress(value!);
          onAddressSelected?.call(value);
        },
        title: Row(
          children: [
            Expanded(child: Text(address['full_name'] ?? 'Destinataire')),
            if (address['is_default'] == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Par défaut', style: TextStyle(fontSize: 10, color: Colors.green)),
              ),
          ],
        ),
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
        secondary: IconButton(
          icon: const Icon(Icons.edit, size: 18),
          onPressed: () => _showEditAddressDialog(context, provider, address),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, DeliveryProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Aucune adresse enregistrée', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text('Ajoutez une adresse pour la livraison', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildAddAddressButton(BuildContext context, DeliveryProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () => _showAddAddressDialog(context, provider),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une adresse'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFE5592F),
          side: const BorderSide(color: Color(0xFFE5592F)),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showAddAddressDialog(BuildContext context, DeliveryProvider provider) {
    final formKey = GlobalKey<FormState>();
    final fullNameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final postalCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    bool isDefault = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
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
                TextFormField(controller: postalCtrl, decoration: const InputDecoration(labelText: 'Code postal')),
                TextFormField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Téléphone'), validator: (v) => v!.isEmpty ? 'Requis' : null),
                Row(
                  children: [
                    Checkbox(value: isDefault, onChanged: (val) => setState(() => isDefault = val ?? false)),
                    const Text('Définir comme adresse par défaut'),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      await provider.addAddress({
                        'full_name': fullNameCtrl.text,
                        'address_line': addressCtrl.text,
                        'city': cityCtrl.text,
                        'postal_code': postalCtrl.text,
                        'phone': phoneCtrl.text,
                        'is_default': isDefault,
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5592F), minimumSize: const Size(double.infinity, 48)),
                  child: const Text('Ajouter'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditAddressDialog(BuildContext context, DeliveryProvider provider, Map<String, dynamic> address) {
    final formKey = GlobalKey<FormState>();
    final fullNameCtrl = TextEditingController(text: address['full_name']);
    final addressCtrl = TextEditingController(text: address['address_line']);
    final cityCtrl = TextEditingController(text: address['city']);
    final postalCtrl = TextEditingController(text: address['postal_code'] ?? '');
    final phoneCtrl = TextEditingController(text: address['phone']);
    bool isDefault = address['is_default'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Modifier l\'adresse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(controller: fullNameCtrl, decoration: const InputDecoration(labelText: 'Nom complet'), validator: (v) => v!.isEmpty ? 'Requis' : null),
                TextFormField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Adresse'), validator: (v) => v!.isEmpty ? 'Requis' : null),
                TextFormField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'Ville'), validator: (v) => v!.isEmpty ? 'Requis' : null),
                TextFormField(controller: postalCtrl, decoration: const InputDecoration(labelText: 'Code postal')),
                TextFormField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Téléphone'), validator: (v) => v!.isEmpty ? 'Requis' : null),
                Row(
                  children: [
                    Checkbox(value: isDefault, onChanged: (val) => setState(() => isDefault = val ?? false)),
                    const Text('Définir comme adresse par défaut'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          provider.deleteAddress(address['id']);
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                        child: const Text('Supprimer'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            await provider.updateAddress(address['id'], {
                              'full_name': fullNameCtrl.text,
                              'address_line': addressCtrl.text,
                              'city': cityCtrl.text,
                              'postal_code': postalCtrl.text,
                              'phone': phoneCtrl.text,
                              'is_default': isDefault,
                            });
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5592F)),
                        child: const Text('Enregistrer'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
