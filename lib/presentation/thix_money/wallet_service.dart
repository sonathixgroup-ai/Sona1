// lib/presentation/thix_money/services/wallet_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';

class WalletService {
  final _db = Supabase.instance.client;

  // Récupère le thix_id officiel depuis profiles - SÉCURITÉ
  Future<String> getCurrentThixId() async {
    final uid = _db.auth.currentUser!.id;
    final res = await _db.from('profiles').select('thix_id').eq('id', uid).single();
    final thixId = res['thix_id'] as String?;
    if (thixId == null || thixId.isEmpty || thixId == 'THIX-PENDING') {
      throw Exception('THIX ID non trouvé, finalisez votre inscription');
    }
    return thixId;
  }

  // STREAM wallet lié au thix_id - temps réel
  Stream<WalletModel> streamWallet() async* {
    final uid = _db.auth.currentUser!.id;
    final thixId = await getCurrentThixId();
    // Vérifie que wallet existe sinon crée
    await _db.from('thix_wallets').upsert({
      'id': uid,
      'user_id': uid,
      'thix_id': thixId,
    }, onConflict: 'id');

    yield* _db.from('thix_wallets')
        .stream(primaryKey: ['id'])
        .eq('thix_id', thixId)
        .map((rows) {
          if (rows.isEmpty) throw Exception('Wallet introuvable');
          return WalletModel.fromJson(rows.first);
        });
  }

  // GET one shot
  Future<WalletModel> getWallet() async {
    final thixId = await getCurrentThixId();
    final res = await _db.from('thix_wallets').select().eq('thix_id', thixId).single();
    return WalletModel.fromJson(res);
  }

  // PAGINATION SCALABLE pour millions de transactions
  Future<List<TransactionModel>> getTransactions({int page = 0, int limit = ThixConstants.pageSize}) async {
    final thixId = await getCurrentThixId();
    final from = page * limit;
    final to = from + limit - 1;
    final data = await _db.from('thix_transactions')
        .select()
        .eq('thix_id', thixId)
        .order('created_at', ascending: false)
        .range(from, to);
    return (data as List).map((e) => TransactionModel.fromJson(e)).toList();
  }

  // Solde par devise
  Future<Map<String, int>> getBalances() async {
    final wallet = await getWallet();
    return {'CDF': wallet.soldeCdf, 'USD': wallet.soldeUsd};
  }
}
