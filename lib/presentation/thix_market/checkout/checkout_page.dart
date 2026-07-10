// lib/presentation/thix_market/checkout/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'checkout_provider.dart';
import 'shipping_method_selector.dart';
import 'payment_method_selector.dart';
import 'order_summary_widget.dart';
import '../delivery/delivery_provider.dart';
import '../delivery/delivery_address_selector.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isDataLoaded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialiser DeliveryProvider au chargement de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // 1. Charger les adresses via DeliveryProvider
      final deliveryProvider = Provider.of<DeliveryProvider>(context, listen: false);
      await deliveryProvider.loadAddresses();

      // 2. Si une adresse est sélectionnée, la synchroniser avec CheckoutProvider
      if (deliveryProvider.selectedAddress != null) {
        final checkoutProvider = Provider.of<CheckoutProvider>(context, listen: false);
        checkoutProvider.selectAddress(deliveryProvider.selectedAddress!);
      }

      // 3. Charger les données du checkout
      final checkoutProvider = Provider.of<CheckoutProvider>(context, listen: false);
      await checkoutProvider.loadCheckoutData();

      _isDataLoaded = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          if (provider.isLoading || _isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          try {
            return _buildStepContent(provider);
          } catch (e) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur : ${e.toString()}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadData(),
                    child: const Text('Réessayer'),
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
        return _AddressStep(
          onAddressSelected: (address) {
            provider.selectAddress(address);
          },
        );
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

// ─── ÉTAPE ADRESSE CORRIGÉE ───
class _AddressStep extends StatelessWidget {
  final Function(Map<String, dynamic>) onAddressSelected;

  const _AddressStep({required this.onAddressSelected});

  @override
  Widget build(BuildContext context) {
    final deliveryProvider = context.watch<DeliveryProvider>();
    final checkoutProvider = context.watch<CheckoutProvider>();

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DeliveryAddressSelector(
              onAddressSelected: (address) {
                // ✅ Sélectionner l'adresse dans DeliveryProvider ET CheckoutProvider
                deliveryProvider.selectAddress(address);
                onAddressSelected(address);
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: deliveryProvider.selectedAddress != null
                ? () {
                    // ✅ Synchroniser et passer à l'étape suivante
                    final address = deliveryProvider.selectedAddress!;
                    checkoutProvider.selectAddress(address);
                  }
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
