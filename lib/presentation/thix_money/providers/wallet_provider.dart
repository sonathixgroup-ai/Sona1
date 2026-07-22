// lib/presentation/thix_money/providers/wallet_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet_model.dart';
import '../services/wallet_service.dart';

final walletServiceProvider = Provider((ref) => WalletService());

// Récupère le thix_id vérifié depuis profiles - SOURCE DE VÉRITÉ
final currentThixIdProvider = FutureProvider<String>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser!.id;
  final res = await Supabase.instance.client.from('profiles').select('thix_id').eq('id', uid).single();
  final thixId = res['thix_id'] as String;
  if (thixId.isEmpty || thixId == 'THIX-PENDING') throw Exception('THIX ID invalide');
  return thixId;
});

// Stream wallet temps réel par thix_id - scalable
final walletStreamProvider = StreamProvider<WalletModel>((ref) {
  final service = ref.watch(walletServiceProvider);
  return service.streamWallet();
});

// Provider solde pour accès rapide
final walletBalanceProvider = Provider<AsyncValue<Map<String, int>>>((ref) {
  final wallet = ref.watch(walletStreamProvider);
  return wallet.whenData((w) => {'CDF': w.soldeCdf, 'USD': w.soldeUsd});
});
