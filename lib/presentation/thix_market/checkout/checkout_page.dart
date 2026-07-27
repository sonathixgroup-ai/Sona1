// lib/presentation/thix_market/checkout/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ Import de Riverpod
import 'package:go_router/go_router.dart';
import 'checkout_provider.dart';
import 'shipping_method_selector.dart';
import 'payment_method_selector.dart';
import 'order_summary_widget.dart';
import '../delivery/delivery_address_selector.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  @override
  void initState() {
    super.initState();
    // ✅ Initialisation de tes données au chargement de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checkoutProvider.notifier).loadCheckoutData();
      
      // Si DeliveryProvider est aussi géré via Riverpod, tu l'initialises comme ça :
      // ref.read(deliveryProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Écoute l'état (isLoading, currentStep, error...)
    final state = ref.watch(checkoutProvider);
    // ✅ Accède aux actions (loadCheckoutData, selectAddress...)
    final notifier = ref.read(checkoutProvider.notifier);

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
      body: _buildBody(state, notifier),
    );
  }

  Widget _buildBody(CheckoutState state, CheckoutNotifier notifier) {
    // A. Chargement
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE5592F)),
      );
    }

    // B. Affichage d'une erreur
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => notifier.loadCheckoutData(),
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

    // C. Affichage de l'étape
    try {
      return _buildStepContent(state, notifier);
    } catch (e) {
      return Center(
        child: Text(
          'Erreur interface: $e',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
  }

  Widget _buildStepContent(CheckoutState state, CheckoutNotifier notifier) {
    switch (state.currentStep) {
      case 'address':
        return _AddressStep(state: state, notifier: notifier);
      case 'shipping':
        // 🚨 IMPORTANT : Ne passe plus l'argument "provider: provider" ici
        return const ShippingMethodSelector(); 
      case 'payment':
        return const PaymentMethodSelector();
      case 'confirmation':
        return const OrderSummaryWidget();
      default:
        return const Center(child: Text("Étape inconnue"));
    }
  }
}

// 3. Widget pour l'étape Adresse
class _AddressStep extends StatelessWidget {
  final CheckoutState state;
  final CheckoutNotifier notifier;

  const _AddressStep({required this.state, required this.notifier});

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
                notifier.selectAddress(address);
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: state.selectedAddress != null
                ? () => notifier.selectAddress(state.selectedAddress!)
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
