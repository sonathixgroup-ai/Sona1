// lib/presentation/thix_money/services/payment_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'wallet_service.dart';

class PaymentService {
  final _db = Supabase.instance.client;
  final _walletService = WalletService();

  Future<String> _getThixId() => _walletService.getVerifiedThixId();

  Future<String> send({required int montant, required String devise, required String destThixId, String phoneDest = ''}) async {
    final thixId = await _getThixId();
    if (thixId == destThixId) throw Exception('Impossible de vous envoyer à vous-même');
    final refTransa = 'THIX-${DateTime.now().millisecondsSinceEpoch}';
    // Vérif source de vérité profiles.thix_id
    final dest = await _db.from('profiles').select('thix_id').eq('thix_id', destThixId).maybeSingle();
    if (dest == null) throw Exception('Destinataire THIX ID introuvable');
    await _db.rpc('transfer_thix', params: {
      'p_from_thix_id': thixId,
      'p_to_thix_id': destThixId,
      'p_amount': montant,
      'p_devise': devise,
      'p_ref': refTransa,
    });
    return refTransa;
  }

  Future<String> recharge({required int montant, required String devise, required String phone}) async {
    final thixId = await _getThixId();
    if (montant < 1000) throw Exception('Montant minimum 1 000');
    final refTransa = 'RC-${DateTime.now().millisecondsSinceEpoch}';
    await _db.from('thix_transactions').insert({
      'thix_id': thixId,
      'type': 'RECHARGE',
      'montant': montant,
      'devise': devise,
      'statut': 'en_attente',
      'ref_transa': refTransa,
      'phone_dest': phone,
      'motif': 'Recharge $devise via $phone',
    });
    return refTransa;
  }

  Future<String> retrait({required int montant, required String devise, required String phone}) async {
    final thixId = await _getThixId();
    final wallet = await _walletService.getWallet();
    final solde = devise == 'CDF' ? wallet.soldeCdf : wallet.soldeUsd;
    if (solde < montant) throw Exception('Solde insuffisant. Dispo: $solde $devise');
    if (montant < 2000) throw Exception('Minimum retrait 2 000');
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

  Future<String> withdraw({required int montant, required String devise, required String phone}) => retrait(montant: montant, devise: devise, phone: phone);
  Future<String> topup({required int montant, required String devise, required String phone}) => recharge(montant: montant, devise: devise, phone: phone);
}
