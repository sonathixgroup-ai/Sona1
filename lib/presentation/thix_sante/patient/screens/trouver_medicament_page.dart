// lib/presentation/thix_sante/patient/screens/trouver_medicament_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/thix_sante_colors.dart';

final medicamentSearchProvider = StateProvider<String>((ref) => '');

final medicamentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final q = ref.watch(medicamentSearchProvider).trim();
  
  // La séparation stricte évite le conflit de type PostgrestTransformBuilder
  if (q.isNotEmpty) {
    final res = await Supabase.instance.client
        .from('pharmacy_stock')
        .select('*, pharmacies(nom,adresse)')
        .eq('is_available', true)
        .ilike('nom', '%$q%') // Le filtre est placé AVANT le limit()
        .limit(50);
    return List<Map<String, dynamic>>.from(res);
  } else {
    final res = await Supabase.instance.client
        .from('pharmacy_stock')
        .select('*, pharmacies(nom,adresse)')
        .eq('is_available', true)
        .limit(50);
    return List<Map<String, dynamic>>.from(res);
  }
});

class TrouverMedicamentPage extends ConsumerWidget {
  const TrouverMedicamentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: ref.watch(medicamentSearchProvider));
    final async = ref.watch(medicamentsProvider);

    return Scaffold(
      backgroundColor: ThixSanteColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ThixSanteColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Médicaments',
          style: TextStyle(
            color: ThixSanteColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: ctrl,
              onChanged: (v) => ref.read(medicamentSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Rechercher DCI, nom commercial...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: ThixSanteColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Erreur: $e')),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('Aucun stock trouvé'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final m = list[i];
                    final ph = m['pharmacies'] as Map?;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: ThixSanteColors.borderLight), 
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: ThixSanteColors.primarySurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.medication,
                              color: ThixSanteColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m['nom'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  '${ph?['nom'] ?? ''} • ${m['prix'] ?? ''} FC',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: ThixSanteColors.inkLight,
                                  ),
                                ),
                                Text(
                                  'Stock: ${m['quantite'] ?? 0}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
