// lib/presentation/thix_money/widgets/balance_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/wallet_provider.dart';
import '../utils/formatter.dart';
import '../utils/constants.dart';

class BalanceCard extends ConsumerStatefulWidget {
  const BalanceCard({super.key});
  @override
  ConsumerState<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends ConsumerState<BalanceCard> {
  bool _show = true;
  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletStreamProvider);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [ThixConstants.darkBlue, ThixConstants.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: ThixConstants.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: walletAsync.when(
        loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: Colors.white))),
        error: (e, _) => Text('Erreur: $e', style: const TextStyle(color: Colors.white)),
        data: (w) {
          final isCdf = w.devisePref == 'CDF' || w.soldeCdf >= 0;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                const Text('Solde disponible', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(width: 8),
                InkWell(onTap: () => setState(() => _show =!_show), child: Icon(_show? Icons.visibility : Icons.visibility_off, color: Colors.white70, size: 18)),
              ]),
              const Icon(Icons.nfc, color: Colors.white54, size: 22),
            ]),
            const SizedBox(height: 12),
            Text(_show? (isCdf? ThixFormatter.formatCdf(w.soldeCdf) : ThixFormatter.formatUsd(w.soldeUsd)) : '••••••••', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(_show? (isCdf? '≈ ${ThixFormatter.formatUsd(w.soldeUsd)}' : '≈ ${ThixFormatter.formatCdf(w.soldeCdf)}') : '≈ ••••', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              OutlinedButton.icon(
                onPressed: () => context.push('/thix-money/history'),
                icon: const Icon(Icons.history, size: 16, color: Colors.white),
                label: const Text('Historique', style: TextStyle(color: Colors.white, fontSize: 12)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8), border: Border.all(color: ThixConstants.gold)),
                child: Row(children: [
                  const Text('VISA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 14, color: Colors.white24),
                  const SizedBox(width: 8),
                  Text(w.thixId.length > 12? '${w.thixId.substring(0, 12)}...' : w.thixId, style: const TextStyle(color: ThixConstants.gold, fontWeight: FontWeight.bold, fontSize: 10)),
                ]),
              )
            ])
          ]);
        },
      ),
    );
  }
}
