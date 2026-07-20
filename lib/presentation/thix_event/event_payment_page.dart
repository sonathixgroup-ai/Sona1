// lib/presentation/thix_event/event_payment_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  String _selectedMethod = 'mpesa'; // Par défaut
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _methods = [
    {'id': 'mpesa', 'name': 'M-Pesa', 'icon': Icons.phone_android_rounded, 'color': Colors.green},
    {'id': 'airtel', 'name': 'Airtel Money', 'icon': Icons.phone_android_rounded, 'color': Colors.red},
    {'id': 'orange', 'name': 'Orange Money', 'icon': Icons.phone_android_rounded, 'color': Colors.orange},
    {'id': 'card', 'name': 'Carte Bancaire', 'icon': Icons.credit_card_rounded, 'color': Colors.blue},
  ];

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    // 💡 SIMULATION API : Ici, vous intégrerez votre API de paiement (MaxiCash, Stripe, FlexPay...)
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() => _isProcessing = false);
      
      // ✅ Redirection vers le Billet généré !
      context.pushReplacement('/thix-event/ticket/${widget.bookingId}');
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Paiement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ThixColors.darkText)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Text('Montant à payer', style: TextStyle(fontSize: 14, color: _ThixColors.mutedText, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.amount.toStringAsFixed(0)} ${widget.currency}',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: _ThixColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Moyen de paiement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ThixColors.darkText)),
            const SizedBox(height: 16),
            ..._methods.map((method) => _buildPaymentOption(method)).toList(),
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
          onPressed: _isProcessing ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: _ThixColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 0,
          ),
          child: _isProcessing
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('PAYER ${widget.amount.toStringAsFixed(0)} ${widget.currency}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(Map<String, dynamic> method) {
    final isSelected = _selectedMethod == method['id'];
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
                decoration: BoxDecoration(color: method['color'].withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(method['icon'], color: method['color'], size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(method['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ThixColors.darkText)),
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
