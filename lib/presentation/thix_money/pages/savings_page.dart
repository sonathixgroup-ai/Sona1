// lib/presentation/thix_money/pages/savings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/saving_provider.dart';
import '../utils/formatter.dart';

class SavingsPage extends ConsumerWidget {
  const SavingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savingProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Épargne • THIX MONEY')),
      body: state.isLoading && state.items.isEmpty? const Center(child: CircularProgressIndicator()) : ListView.builder(itemCount: state.items.length, itemBuilder: (_, i) {
        final s = state.items[i];
        return ListTile(title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: LinearProgressIndicator(value: s.progress), trailing: Text('${ThixFormatter.formatAmount(s.amount, s.devise)} / ${ThixFormatter.formatAmount(s.goal, s.devise)}'));
      }),
      floatingActionButton: FloatingActionButton(onPressed: () => ref.read(savingProvider.notifier).load(), child: const Icon(Icons.refresh)),
    );
  }
}
