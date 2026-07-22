// lib/presentation/thix_money/services/payment_service.dart
import 'wonya_service.dart';

class PaymentService {
  final WonyaService _wonya = WonyaService();

  // RECHARGER - C2B - Client paye vers THIX MONEY
  Future<String> recharge({required int montant, required String devise, required String phone}) {
    return _wonya.initPayment(
      action: 'C2B',
      montant: montant,
      devise: devise,
      phone: phone,
      motif: 'Recharge THIX MONEY $devise',
    );
  }

  // ENVOYER - B2C - THIX MONEY vers un autre numéro
  Future<String> send({required int montant, required String devise, required String phoneDest, String? destThixId}) {
    return _wonya.initPayment(
      action: 'B2C',
      montant: montant,
      devise: devise,
      phone: phoneDest,
      phoneDest: phoneDest,
      motif: 'Envoi THIX vers $phoneDest ${destThixId ?? ''}',
    );
  }

  // RETRAIT - B2C - THIX MONEY vers son propre Mobile Money
  Future<String> retrait({required int montant, required String devise, required String phone}) {
    return _wonya.initPayment(
      action: 'B2C',
      montant: montant,
      devise: devise,
      phone: phone,
      motif: 'Retrait THIX MONEY',
    );
  }
}
