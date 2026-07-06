// lib/presentation/thix_market/checkout/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'checkout_provider.dart';
import 'shipping_method_selector.dart';
import 'payment_method_selector.dart';
import 'order_summary_widget.dart';
import 'order_confirmation_page.dart';
import '../cart/cart_provider.dart';
import '../delivery/delivery_address_selector.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isDataLoaded = false; // ✅ indicateur local pour éviter les rechargements multiples

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Charger les données une seule fois
    if (!_isDataLoaded) {
      _isDataLoaded = true;
      final provider = context.read<CheckoutProvider>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.loadCheckoutData();
      });
    }
  }

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
            onPressed: () => context.pop(),
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

// Étape Adresse (utilise DeliveryAddressSelector réutilisable)
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
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Continuer'),
          ),
        ),
      ],
    );
  }
}
