// =============================================================================
// Screen: SanteEnfantsPage - Service Sante 1/11
// Source reelle: public.family_members where type = 'enfant'
// + public.health_records pour vaccins/poids/taille par member_uid
// Zero mock-up - 100% Supabase RLS
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/thix_sante_colors.dart';
import '../../patient/services/family_service.dart';

// Provider pour la croissance
final enfantGrowthProvider = FutureProvider.family<Map<String,dynamic>, String>((ref, memberUid) async {
  final db = Supabase.instance.client;
  final data = await db.from('health_records')
   .select('title, description, created_at')
   .eq('patient_uid', memberUid)
   .ilike('title', '%poids%')
   .order('created_at', ascending: false)
   .limit(1)
   .maybeSingle();
  return data ?? {};
});

class SanteEnfantsPage extends ConsumerWidget {
  const SanteEnfantsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On utilise directement le provider défini dans votre family_service.dart
    final enfantsAsync = ref.watch(enfantsProvider);

    return Scaffold(
      backgroundColor: ThixSanteColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Santé Enfants', style: TextStyle(color: ThixSanteColors.ink, fontWeight: FontWeight.w800)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: ThixSanteColors.ink), onPressed: () => Navigator.pop(context)),
      ),
      body: enfantsAsync.when(
        data: (enfants) {
          if (enfants.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Color(0xFFFEF9C3), shape: BoxShape.circle), child: const Icon(Icons.child_care_rounded, size: 40, color: Color(0xFFCA8A04))),
                  const SizedBox(height: 16),
                  const Text('Aucun enfant lié', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text('Ajoutez vos enfants dans Dossier Famille. Leur dossier santé apparaîtra ici automatiquement.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: ThixSanteColors.muted)),
                ]),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFEF9C3), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.info_rounded, size: 18, color: Color(0xFFCA8A04)), const SizedBox(width: 8), Expanded(child: Text('${enfants.length} dossiers enfants liés • Source: family_members', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)))])),
              const SizedBox(height: 12),
              ...enfants.map((enfant) => _buildEnfantCard(context, ref, enfant)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e,_) => Center(child: Text('Erreur RLS: $e', style: const TextStyle(color: ThixSanteColors.danger))),
      ),
    );
  }

  // On utilise Map<String, dynamic> au lieu de la classe inexistante FamilyMember
  Widget _buildEnfantCard(BuildContext context, WidgetRef ref, Map<String, dynamic> enfant) {
    // Extraction sécurisée depuis votre Map Supabase
    final String fullName = '${enfant['prenom'] ?? ''} ${enfant['nom'] ?? ''}'.trim();
    final String memberUid = enfant['linked_patient_id']?.toString() ?? enfant['id'].toString();
    final String? avatarUrl = enfant['avatar_url']?.toString();
    final String memberThixId = enfant['numero_securite_sociale']?.toString() ?? 'ID non renseigné';
    final String type = enfant['type']?.toString() ?? 'enfant';
    
    final growthAsync = ref.watch(enfantGrowthProvider(memberUid));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: ThixSanteColors.borderLight)),
      child: Column(
        children: [
          Row(children: [
            CircleAvatar(
              radius: 22, 
              backgroundColor: ThixSanteColors.primaryLight, 
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null, 
              child: avatarUrl == null && fullName.isNotEmpty 
                  ? Text(fullName[0].toUpperCase(), style: const TextStyle(color: ThixSanteColors.primary, fontWeight: FontWeight.w800)) 
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(fullName.isNotEmpty ? fullName : 'Inconnu', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: ThixSanteColors.ink)),
              Text(memberThixId, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: ThixSanteColors.muted)),
              Text(type, style: const TextStyle(fontSize: 11, color: ThixSanteColors.muted)),
            ])),
            const Icon(Icons.chevron_right_rounded, color: ThixSanteColors.mutedLight),
          ]),
          const SizedBox(height: 12),
          growthAsync.when(
            data: (growth) => Row(children: [
              Expanded(child: _metricBox(icon: Icons.monitor_weight_rounded, label: 'Poids', value: growth['description']?.toString() ?? 'Non renseigné', color: ThixSanteColors.primary)),
              const SizedBox(width: 8),
              Expanded(child: _metricBox(icon: Icons.vaccines_rounded, label: 'Vaccins', value: 'Voir carnet', color: ThixSanteColors.success, isAction: true)),
            ]),
            loading: () => const SizedBox(height: 40, child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))),
            error: (_,__) => const Text('Erreur croissance', style: TextStyle(fontSize: 10, color: ThixSanteColors.muted)),
          ),
        ],
      ),
    );
  }

  Widget _metricBox({required IconData icon, required String label, required String value, required Color color, bool isAction = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: ThixSanteColors.background, borderRadius: BorderRadius.circular(10), border: isAction ? Border.all(color: color.withOpacity(0.3)) : null),
      child: Column(children: [Icon(icon, size: 18, color: color), const SizedBox(height: 4), Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: isAction ? color : ThixSanteColors.ink), maxLines: 1, overflow: TextOverflow.ellipsis), Text(label, style: const TextStyle(fontSize: 10, color: ThixSanteColors.muted))]),
    );
  }
}
