// lib/services/market_payment_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarketPaymentService {
  final SupabaseClient _supabase;
  MarketPaymentService(this._supabase);

  Future<bool> processOrderPayment({
    required String orderId,
    required double amount,
    required String currency, // 'USD' ou 'FC'
    required String paymentMethod, // 'mobile_money', 'card', etc.
    String? phoneNumber,
    Map<String, String>? cardDetails,
  }) async {
    try {
      // Appel de la Supabase Edge Function sécurisée pour le Market
      final response = await _supabase.functions.invoke(
        'process-market-payment',
        body: {
          'order_id': orderId,
          'amount': amount,
          'currency': currency,
          'payment_method': paymentMethod,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (cardDetails != null) 'card_details': cardDetails,
        },
      );

      if (response.status == 200 && response.data != null && response.data['success'] == true) {
        return true;
      } else {
        final errorMessage = response.data?['error'] ?? 'Erreur inconnue lors du paiement de la commande';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ Erreur Edge Function Paiement Market : $e');
      rethrow;
    }
  }
}
