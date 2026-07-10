// lib/presentation/thix_market/checkout/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'checkout_provider.dart';
import 'shipping_method_selector.dart';
import 'payment_method_selector.dart';
import 'order_summary_widget.dart';
import '../cart/cart_provider.dart';
import '../delivery/delivery_address_selector.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isDataLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // On s'assure que le chargement ne se lance qu'une seule fois
    if (!_isDataLoaded) {
      _isDataLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<CheckoutProvider>().loadCheckoutData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Validation de commande'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<CheckoutProvider>(
        builder: (context, provider, _) {
          // 1. Affichage de l'état de chargement global
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Affichage des erreurs interceptées par le Provider (ex: RLS, réseau)
          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => provider.loadCheckoutData(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5592F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // 3. Affichage sécurisé de l'étape en cours
          try {
            return _buildStepContent(provider);
          } catch (e) {
            // Sécurité anti-écran blanc au cas où un widget enfant crashe
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text('Erreur d\'interface : ${e.toString()}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadCheckoutData(),
                    child: const Text('Recharger la page'),
                  ),
                ],
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

// Widget pour l'étape Adresse
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
                : null,
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
