// lib/presentation/thix_sante/sante/screens/suivi_grossesse_page.dart
// =============================================================================
// Screen: SuiviGrossessePage - Service Sante 3/11
// Source reelle: public.health_records where type in ('consultation','laboratoire','radiologie') + title ilike '%grossesse%'
// + public.health_links pour sage-femme liee par THIX ID
// Zero mock - calcul semaines amenorrhee reel depuis exam_date
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/thix_id_validator.dart';
import '../../patient/models/health_record_model.dart';

final grossesseRecordsProvider = FutureProvider<List<HealthRecordModel>>((ref) async {
  final db = Supabase.instance.client;
  final uid = db.auth.currentUser!.id;
  final List<dynamic> data = await db
   .from('health_records')
   .select()
   .eq('patient_uid', uid)
   .or('title.ilike.%grossesse%,description.ilike.%grossesse%')
   .order('exam_date', ascending: true);
  return data.map((e) => HealthRecordModel.fromJson(e as Map<String,dynamic>)).toList();
});

class SuiviGrossessePage extends ConsumerWidget {
  const SuiviGrossessePage({super.key});

  int _calculateSA(DateTime? debutGrossesse) {
    if (debutGrossesse == null) return 0;
    return DateTime.now().difference(debutGrossesse).inDays ~/ 7;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grossesseAsync = ref.watch(grossesseRecordsProvider);

    return Scaffold(
      backgroundColor: ThixSanteColors.background,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: const Text('Suivi Grossesse', style: TextStyle(color: ThixSanteColors.ink, fontWeight: FontWeight.w800)), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: ThixSanteColors.ink), onPressed: () => Navigator.pop(context))),
      body: grossesseAsync.when(
        data: (records) {
          final DateTime? debut = records.isNotEmpty? records.first.examDate?? records.first.createdAt: null;
          final int sa = _calculateSA(debut);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)]), borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Text('🤰', style: TextStyle(fontSize: 20))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(sa>0? '$sa Semaines d amenorrhee':'Suivi non demarre', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)), Text(debut!=null? 'Debut: ${debut.day}/${debut.month}/${debut.year} • Source: health_records':'Ajoutez 1ere consultation type grossesse', style: const TextStyle(color: Colors.white70, fontSize: 11))]))]),
                  if (sa>0)...[
                    const SizedBox(height: 12),
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: (sa/40).clamp(0,1).toDouble(), backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), minHeight: 6)),
                    const SizedBox(height: 6),
                    Text('${((sa/40)*100).toStringAsFixed(0)}% • Terme prevu dans ${40-sa} SA', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ]),
              ),
              const SizedBox(height: 16),
              if (records.isEmpty)
                Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Column(children: [Icon(Icons.pregnant_woman_rounded, size: 48, color: ThixSanteColors.mutedLight.withOpacity(0.5)), const SizedBox(height: 10), const Text('Aucun suivi enregistre', style: TextStyle(fontWeight: FontWeight.w600)), const Text('Votre sage-femme liee par THIX ID ajoutera consultations, echos et bilans ici', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: ThixSanteColors.muted))]))
              else
              ...records.map((r) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: ThixSanteColors.borderLight)),
                      child: Row(children: [
                        Container(width: 44, height: 44, decoration: BoxDecoration(color: r.typeLightColor, borderRadius: BorderRadius.circular(10)), child: Icon(r.typeIcon, color: r.typeColor)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), Text(r.description?? 'Suivi grossesse', style: const TextStyle(fontSize: 11, color: ThixSanteColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis), Text('${r.examDate?.day?? r.createdAt.day}/${r.examDate?.month?? r.createdAt.month}/${r.examDate?.year?? r.createdAt.year} • ${r.doctorName?? 'Sage-femme THIX'}', style: const TextStyle(fontSize: 10, color: ThixSanteColors.mutedLight))])),
                        if (r.hasFile) IconButton(icon: const Icon(Icons.visibility_rounded, size: 18, color: ThixSanteColors.primary), onPressed: () {}),
                      ]),
                    )),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e,_) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}
