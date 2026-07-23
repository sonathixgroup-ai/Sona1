// lib/presentation/thix_event/event_payment_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/event_payment_provider.dart';

class _ThixColors {
  static const Color primary = Color(0xFF6B3CE2);
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color darkText = Color(0xFF1E1B4B);
  static const Color mutedText = Color(0xFF8B8BA7);
}

class EventPaymentPage extends StatefulWidget {
  final String bookingId;
  final double amount;
  final String currency;

  const EventPaymentPage({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.currency,
  });

  @override
  State<EventPaymentPage> createState() => _EventPaymentPageState();
}

class _EventPaymentPageState extends State<EventPaymentPage> {
  String _selectedMethod = 'airtel'; // Par défaut sur un réseau de RDC
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvcController = TextEditingController();
  
  StreamSubscription? _paymentSubscription;

  final List<Map<String, dynamic>> _methods = [
    {'id': 'mpesa', 'name': 'M-Pesa', 'brand': 'Vodacom', 'color': const Color(0xFF00A651), 'requiresPhone': true, 'icon': Icons.phone_android_rounded},
    {'id': 'airtel', 'name': 'Airtel Money', 'brand': 'Airtel', 'color': const Color(0xFFFF0000), 'requiresPhone': true, 'icon': Icons.phone_android_rounded},
    {'id': 'orange', 'name': 'Orange Money', 'brand': 'Orange', 'color': const Color(0xFFFF6600), 'requiresPhone': true, 'icon': Icons.phone_android_rounded},
    {'id': 'visa_master', 'name': 'Visa & Mastercard', 'brand': 'Carte Bancaire', 'color': const Color(0xFF1A1F71), 'requiresPhone': false, 'icon': Icons.credit_card_rounded},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvcController.dispose();
    _paymentSubscription?.cancel(); // Arrêter l'écoute si on quitte la page
    super.dispose();
  }

  Future<void> _submitPayment(EventPaymentProvider provider) async {
    final selectedMethodObj = _methods.firstWhere((m) => m['id'] == _selectedMethod);
    final bool requiresPhone = selectedMethodObj['requiresPhone'] ?? false;

    if (requiresPhone && _phoneController.text.trim().length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Numéro invalide.'), backgroundColor: Colors.orange));
      return;
    }

    final success = await provider.makePayment(
      bookingId: widget.bookingId,
      amount: widget.amount,
      currency: widget.currency,
      paymentMethod: _selectedMethod,
      phoneNumber: requiresPhone ? _phoneController.text.trim() : null,
    );

    if (success && mounted) {
      _showWaitingForPinDialog();
    } else if (provider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : ${provider.errorMessage}'), backgroundColor: Colors.red));
    }
  }

  // 🟢 NOUVELLE FONCTION : Pop-up d'attente + Écoute Temps Réel Supabase
  void _showWaitingForPinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Empêche l'utilisateur de fermer le pop-up
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: _ThixColors.primary),
            const SizedBox(height: 24),
            const Text('Validation en cours...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ThixColors.darkText)),
            const SizedBox(height: 12),
            const Text(
              'Un message a été envoyé sur votre téléphone. Veuillez taper votre code PIN pour confirmer le paiement.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _ThixColors.mutedText, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    // Écoute de la ligne de cette réservation spécifique dans Supabase
    _paymentSubscription = Supabase.instance.client
        .from('event_bookings')
        .stream(primaryKey: ['id'])
        .eq('id', widget.bookingId)
        .listen((List<Map<String, dynamic>> data) {
      if (data.isNotEmpty) {
        final paymentStatus = data.first['payment_status'];

        if (paymentStatus == 'paid') {
          // Si l'argent est reçu, on ferme le pop-up et on donne le billet !
          _paymentSubscription?.cancel();
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Paiement confirmé !'), backgroundColor: Colors.green));
          context.pushReplacement('/thix-event/ticket/${widget.bookingId}');
        } 
        else if (paymentStatus == 'failed' || paymentStatus == 'cancelled') {
          // Si le client annule sur son téléphone
          _paymentSubscription?.cancel();
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Transaction échouée ou annulée.'), backgroundColor: Colors.red));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EventPaymentProvider(Supabase.instance.client),
      child: Consumer<EventPaymentProvider>(
        builder: (context, provider, child) {
          final selectedMethodObj = _methods.firstWhere((m) => m['id'] == _selectedMethod);
          final bool requiresPhone = selectedMethodObj['requiresPhone'] ?? false;

          return Scaffold(
            backgroundColor: _ThixColors.lightBg,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: const BoxDecoration(color: _ThixColors.lightBg, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: _ThixColors.darkText, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              title: const Text('Passerelle de Paiement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ThixColors.darkText)),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        const Text('Montant total à payer', style: TextStyle(fontSize: 14, color: _ThixColors.mutedText, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.amount.toStringAsFixed(0)} ${widget.currency}',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: _ThixColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Moyen de paiement', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ThixColors.darkText)),
                  const SizedBox(height: 16),
                  
                  ..._methods.map((method) => _buildPaymentOption(method)).toList(),
                  
                  const SizedBox(height: 20),

                  if (requiresPhone) ...[
                    const Text('Numéro de téléphone Mobile Money', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _ThixColors.darkText)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'Ex: +243...',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.phone_iphone_rounded, color: _ThixColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _ThixColors.primary, width: 1.5)),
                      ),
                    ),
                  ]
                ],
              ),
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: ElevatedButton(
                onPressed: provider.isProcessing ? null : () => _submitPayment(provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ThixColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: provider.isProcessing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('PAYER ${widget.amount.toStringAsFixed(0)} ${widget.currency}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentOption(Map<String, dynamic> method) {
    final isSelected = _selectedMethod == method['id'];
    final color = method['color'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = method['id']),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? _ThixColors.primary.withOpacity(0.05) : Colors.white,
            border: Border.all(color: isSelected ? _ThixColors.primary : const Color(0xFFEEE9FF), width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(method['icon'] as IconData, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(method['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ThixColors.darkText)),
                    const SizedBox(height: 2),
                    Text(method['brand'] as String, style: const TextStyle(fontSize: 11, color: _ThixColors.mutedText, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: isSelected ? _ThixColors.primary : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
