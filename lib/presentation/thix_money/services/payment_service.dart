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
  // Cherche dans payment_service.dart et REMPLACE toutes les occurrences de .eq('user_id', 
// par .eq('thix_id', await WalletService().getVerifiedThixId())

Future<String> send({required int montant, required String devise, required String phoneDest, required String destThixId}) async {
  final db = Supabase.instance.client;
  final thixId = await WalletService().getVerifiedThixId();
  final refTransa = 'THIX-${DateTime.now().millisecondsSinceEpoch}';
  // Vérifie que dest existe en base profiles.thix_id
  final destExists = await db.from('profiles').select('thix_id').eq('thix_id', destThixId).maybeSingle();
  if (destExists == null) throw Exception('Destinataire THIX ID introuvable');
  
  await db.rpc('transfer_thix', params: {
    'p_from_thix_id': thixId,
    'p_to_thix_id': destThixId,
    'p_amount': montant,
    'p_devise': devise,
    'p_ref': refTransa,
  });
  return refTransa;
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
