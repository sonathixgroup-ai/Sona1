// lib/presentation/thix_money/services/payment_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'wallet_service.dart';

class PaymentService {
  final _db = Supabase.instance.client;
  final _walletService = WalletService();

  // SEND THIX_ID vers THIX_ID - vérifié en base profiles
  Future<String> send({required int montant, required String devise, required String phoneDest, required String destThixId}) async {
    final thixId = await _walletService.getVerifiedThixId();
    final refTransa = 'THIX-${DateTime.now().millisecondsSinceEpoch}';
    final destExists = await _db.from('profiles').select('thix_id').eq('thix_id', destThixId).maybeSingle();
    if (destExists == null) throw Exception('Destinataire THIX ID introuvable');
    await _db.rpc('transfer_thix', params: {
      'p_from_thix_id': thixId,
      'p_to_thix_id': destThixId,
      'p_amount': montant,
      'p_devise': devise,
      'p_ref': refTransa,
    });
    return refTransa;
  }

  // RECHARGE via Wonya / Mobile Money - lié à thix_id
  Future<String> recharge({required int montant, required String devise, required String phone}) async {
    final thixId = await _walletService.getVerifiedThixId();
    final refTransa = 'RC-${DateTime.now().millisecondsSinceEpoch}';
    await _db.from('thix_transactions').insert({
      'thix_id': thixId,
      'type': 'RECHARGE',
      'montant': montant,
      'devise': devise,
      'statut': 'en_attente',
      'ref_transa': refTransa,
      'phone_dest': phone,
      'motif': 'Recharge Wonya $devise',
    });
    // Ici appelle ton WonyaService.c2b si tu as
    return refTransa;
  }

  // RETRAIT vers Mobile Money - vérifie solde via thix_id
  Future<String> retrait({required int montant, required String devise, required String phone}) async {
    final thixId = await _walletService.getVerifiedThixId();
    final wallet = await _walletService.getWallet();
    final solde = devise == 'CDF' ? wallet.soldeCdf : wallet.soldeUsd;
    if (solde < montant) throw Exception('Solde insuffisant: $solde $devise');
    final refTransa = 'RT-${DateTime.now().millisecondsSinceEpoch}';
    await _db.from('thix_transactions').insert({
      'thix_id': thixId,
      'type': 'RETRAIT',
      'montant': montant,
      'devise': devise,
      'statut': 'en_attente',
      'ref_transa': refTransa,
      'phone_dest': phone,
      'motif': 'Retrait $devise vers $phone',
    });
    return refTransa;
  }

  // Pour compat avec anciens noms
  Future<String> withdraw({required int montant, required String devise, required String phone}) => retrait(montant: montant, devise: devise, phone: phone);
  Future<String> topup({required int montant, required String devise, required String phone}) => recharge(montant: montant, devise: devise, phone: phone);
}
