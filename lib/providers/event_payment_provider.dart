// lib/providers/event_payment_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/event_payment_service.dart';

class EventPaymentProvider extends ChangeNotifier {
  final EventPaymentService _paymentService;

  EventPaymentProvider(SupabaseClient supabase)
      : _paymentService = EventPaymentService(supabase);

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> makePayment({
    required String bookingId,
    required double amount,
    required String currency,
    required String paymentMethod,
    String? phoneNumber,
    Map<String, String>? cardDetails,
  }) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _paymentService.processPayment(
        bookingId: bookingId,
        amount: amount,
        currency: currency,
        paymentMethod: paymentMethod,
        phoneNumber: phoneNumber,
        cardDetails: cardDetails,
      );
      _isProcessing = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isProcessing = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
