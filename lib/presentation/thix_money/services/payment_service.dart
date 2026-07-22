// lib/presentation/thix_money/services/payment_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'wallet_service.dart';

class PaymentService {
  final _db = Supabase.instance.client;
  final _walletService = WalletService();

  Future<String> send({required int montant, required String devise, required String phoneDest, required String destThixId}) async {
    final thixId = await _walletService.getVerifiedThixId();
    final refTransa = 'THIX-${DateTime.now().millisecondsSinceEpoch}';
    final destExists = await _db.from('profiles').select('thix_id').eq('thix_id', destThixId).maybeSingle();
    if (destExists == null) throw Exception('Destinataire THIX ID introuvable dans profiles');
    await _db.rpc('transfer_thix', params: {
      'p_from_thix_id': thixId,
      'p_to_thix_id': destThixId,
      'p_amount': montant,
      'p_devise': devise,
      'p_ref': refTransa,
    });
    return refTransa;
  }
}
