// lib/presentation/thix_market/checkout/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'checkout_provider.dart';
import 'shipping_method_selector.dart';
import 'payment_method_selector.dart';
import 'order_summary_widget.dart';
import '../delivery/delivery_address_selector.dart';
import '../delivery/delivery_provider.dart'; // ✅ Import crucial du DeliveryProvider

// 1. Initialisation propre des Providers avant d'afficher la page
class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // On crée et on charge le CheckoutProvider
        ChangeNotifierProvider(
          create: (_) => CheckoutProvider()..loadCheckoutData(),
        ),
        // On crée et on charge le DeliveryProvider manquant !
        ChangeNotifierProvider(
          create: (_) => DeliveryProvider()..init(),
        ),
      ],
      child: const _CheckoutContent(),
    );
  }
}

// 2. Contenu principal de la page
class _CheckoutContent extends StatelessWidget {
  const _CheckoutContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Validation de commande',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<CheckoutProvider>(
        builder: (context, provider, _) {
          // A. Chargement
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5592F)),
            );
          }

          // B. Affichage d'une erreur de base de données (si existante)
          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(provider.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => provider.loadCheckoutData(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5592F),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // C. Affichage sécurisé de l'étape
          try {
            return _buildStepContent(provider);
          } catch (e) {
            return Center(
              child: Text(
                'Erreur interface: $e',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildStepContent(CheckoutProvider provider) {
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
        return const Center(child: Text("Étape inconnue"));
    }
  }
}

// 3. Widget pour l'étape Adresse
class _AddressStep extends StatelessWidget {
  final CheckoutProvider provider;

  const _AddressStep({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DeliveryAddressSelector(
              onAddressSelected: (address) {
                // Fait le lien entre DeliveryProvider et CheckoutProvider
                provider.selectAddress(address);
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: provider.selectedAddress != null
                ? () => provider.selectAddress(provider.selectedAddress!)
                : null, // Le bouton s'active si une adresse est sélectionnée
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5592F),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Continuer',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
