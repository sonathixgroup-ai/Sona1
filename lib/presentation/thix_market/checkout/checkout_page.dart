// lib/presentation/market/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'checkout_provider.dart';
import 'shipping_method_selector.dart';
import 'payment_method_selector.dart';
import 'order_summary_widget.dart';
import '../delivery/delivery_address_selector.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});
  @override ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checkoutProvider.notifier).loadCheckoutData();
    });
  }

  @override Widget build(BuildContext context) {
    final state = ref.watch(checkoutProvider);
    final notifier = ref.read(checkoutProvider.notifier);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0A1931)), onPressed: ()=> context.pop()),
        title: const Text('Validation de commande', style: TextStyle(color: Color(0xFF0A1931), fontWeight: FontWeight.w900, fontSize: 18)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(56), child: _stepper(state.currentStep)),
      ),
      body: _buildBody(state, notifier),
    );
  }

  Widget _stepper(String step){
    int idx = 0;
    if(step=='address') idx=0;
    if(step=='shipping') idx=1;
    if(step=='payment') idx=2;
    if(step=='confirmation') idx=3;
    final labels = ['Adresse','Livraison','Paiement','Résumé'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(children: List.generate(4, (i){
        bool active = i<=idx;
        bool current = i==idx;
        return Expanded(child: Row(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: active? const Color(0xFFE5592F) : Colors.grey.shade200, shape: BoxShape.circle, border: current? Border.all(color: const Color(0xFFE5592F), width: 2) : null), child: Center(child: i<idx? const Icon(Icons.check, size: 16, color: Colors.white) : Text('${i+1}', style: TextStyle(color: active? Colors.white : Colors.grey, fontWeight: FontWeight.w800, fontSize: 12)))),
          if(i<3) Expanded(child: Container(height: 3, margin: const EdgeInsets.symmetric(horizontal: 6), decoration: BoxDecoration(color: i<idx? const Color(0xFFE5592F) : Colors.grey.shade200, borderRadius: BorderRadius.circular(2)))),
        ]));
      })),
    );
  }

  Widget _buildBody(CheckoutState state, CheckoutNotifier notifier){
    if(state.isLoading){
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE5592F)));
    }
    if(state.error!=null){
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text(state.error!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        ElevatedButton.icon(onPressed: ()=> notifier.loadCheckoutData(), icon: const Icon(Icons.refresh), label: const Text('Réessayer'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5592F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      ])));
    }
    try{
      return AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: _buildStepContent(state, notifier));
    }catch(e){
      return Center(child: Text('Erreur interface: $e', style: const TextStyle(color: Colors.red)));
    }
  }

  Widget _buildStepContent(CheckoutState state, CheckoutNotifier notifier){
    switch(state.currentStep){
      case 'address': return _AddressStep(state: state, notifier: notifier);
      case 'shipping': return const ShippingMethodSelector();
      case 'payment': return const PaymentMethodSelector();
      case 'confirmation': return const OrderSummaryWidget();
      default: return Center(child: Text('Étape inconnue: ${state.currentStep}'));
    }
  }
}

class _AddressStep extends StatelessWidget {
  final CheckoutState state;
  final CheckoutNotifier notifier;
  const _AddressStep({required this.state, required this.notifier});
  @override Widget build(BuildContext context){
    return Column(children: [
      Expanded(child: Padding(padding: const EdgeInsets.all(16), child: DeliveryAddressSelector(onAddressSelected: (address){ notifier.selectAddress(address); }))),
      Container(
        padding: const EdgeInsets.fromLTRB(16,12,16,24),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0,-4))]),
        child: SafeArea(
          top: false,
          child: SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
            onPressed: state.selectedAddress!=null? (){
              notifier.selectAddress(state.selectedAddress!);
              notifier.nextStep(); // Passage validé vers l'étape suivante
            } : null,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5592F), foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey.shade200, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: const Text('Continuer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          )),
        ),
      ),
    ]);
  }
}
