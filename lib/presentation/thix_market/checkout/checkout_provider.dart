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
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Gestion explicite des erreurs pour éviter le blocage
          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(provider.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.loadCheckoutData(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          return _buildStepContent(provider);
        },
      ),
    );
  }

  Widget _buildStepContent(CheckoutProvider provider) {
    switch (provider.currentStep) {
      case 'address': return _AddressStep(provider: provider);
      case 'shipping': return ShippingMethodSelector(provider: provider);
      case 'payment': return PaymentMethodSelector(provider: provider);
      case 'confirmation': return OrderSummaryWidget(provider: provider);
      default: return const Center(child: Text("Erreur d'étape"));
    }
  }
}

class _AddressStep extends StatelessWidget {
  final CheckoutProvider provider;
  const _AddressStep({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: DeliveryAddressSelector(onAddressSelected: provider.selectAddress)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: provider.selectedAddress != null 
              ? () => provider.selectAddress(provider.selectedAddress!) 
              : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5592F),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Continuer'),
          ),
        ),
      ],
    );
  }
}
