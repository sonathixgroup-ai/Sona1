// lib/presentation/thix_sante/patient/screens/consulter_medecin_page.dart
// =============================================================================
// Screen: ConsulterMedecin - Service Rapide 1
// Role: Liste medecins lies par THIX ID UID + recherche nouveau medecin
// Fonctionnalites modernes: Recherche temps reel, filtre specialite, chat
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/thix_id_validator.dart';
import '../../core/thix_sante_colors.dart';
import '../providers/patient_dashboard_provider.dart';
import '../models/patient_link_model.dart';
import 'mon_medecin_traitant_page.dart';

class ConsulterMedecinPage extends ConsumerStatefulWidget {
  const ConsulterMedecinPage({super.key});
  @override
  ConsumerState<ConsulterMedecinPage> createState() => _ConsulterMedecinPageState();
}

class _ConsulterMedecinPageState extends ConsumerState<ConsulterMedecinPage> {
  String _searchQuery = '';
  String _selectedSpeciality = 'Tous';

  final List<String> _specialities = ['Tous','Generaliste','Cardiologue','Pediatre','Gynecologue','Dermatologue'];

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<PatientLinkModel>> doctorsAsync = ref.watch(activeDoctorsStreamProvider);

    return Scaffold(
      backgroundColor: ThixSanteColors.background,
      appBar: AppBar(
        backgroundColor: ThixSanteColors.surface,
        elevation: 0,
        title: const Text('Consulter Medecin', style: TextStyle(color: ThixSanteColors.ink, fontWeight: FontWeight.w800, fontSize: 18)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: ThixSanteColors.ink), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.person_add_alt_1_rounded, color: ThixSanteColors.primary), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MonMedecinTraitantPage())))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Rechercher medecin, specialite, THIX ID...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _specialities.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (c,i) {
                      final s = _specialities[i];
                      final selected = s == _selectedSpeciality;
                      return ChoiceChip(
                        label: Text(s, style: TextStyle(fontSize: 12, fontWeight: selected? FontWeight.w700: FontWeight.w500, color: selected? Colors.white: ThixSanteColors.ink)),
                        selected: selected,
                        selectedColor: ThixSanteColors.primary,
                        backgroundColor: Colors.white,
                        onSelected: (_) => setState(() => _selectedSpeciality = s),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: doctorsAsync.when(
              data: (doctors) {
                final filtered = doctors.where((l) {
                  final name = l.doctorProfile?.fullName.toLowerCase()?? '';
                  final spec = l.doctorProfile?.speciality?.toLowerCase()?? '';
                  final matchSearch = name.contains(_searchQuery) || spec.contains(_searchQuery) || l.doctorThixId.toLowerCase().contains(_searchQuery);
                  final matchSpec = _selectedSpeciality == 'Tous' || spec.contains(_selectedSpeciality.toLowerCase());
                  return matchSearch && matchSpec;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: ThixSanteColors.primaryLight, shape: BoxShape.circle), child: const Icon(Icons.medical_services_outlined, size: 40, color: ThixSanteColors.primary)),
                      const SizedBox(height: 16),
                      const Text('Aucun medecin trouve', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      const Text('Ajoutez votre medecin traitant par son THIX ID', style: TextStyle(fontSize: 12, color: ThixSanteColors.muted)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MonMedecinTraitantPage())), icon: const Icon(Icons.add_link_rounded), label: const Text('Lier par THIX ID'), style: ElevatedButton.styleFrom(backgroundColor: ThixSanteColors.primary, foregroundColor: Colors.white)),
                    ]),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (c,i) {
                    final link = filtered[i];
                    final doc = link.doctorProfile;
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: ThixSanteColors.borderLight)),
                      child: Row(
                        children: [
                          Stack(children: [
                            CircleAvatar(radius: 26, backgroundColor: ThixSanteColors.primaryLight, backgroundImage: doc?.hasAvatar==true? NetworkImage(doc!.avatarUrl!): null, child: doc?.hasAvatar!=true? Text(doc?.initials?? 'D', style: const TextStyle(color: ThixSanteColors.primary, fontWeight: FontWeight.w800)): null),
                            Positioned(bottom: 0, right: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: ThixSanteColors.success, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                          ]),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(doc?.fullName?? 'Dr Inconnu', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: ThixSanteColors.ink)),
                            Text(doc?.displaySpeciality?? 'Generaliste', style: const TextStyle(fontSize: 12, color: ThixSanteColors.muted)),
                            const SizedBox(height: 4),
                            Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: ThixSanteColors.successLight, borderRadius: BorderRadius.circular(20)), child: Row(children: [const Icon(Icons.star_rounded, size: 12, color: ThixSanteColors.warning), const SizedBox(width: 2), Text('${doc?.rating?? 4.8}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))])), const SizedBox(width: 6), Text(link.doctorThixId, style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: ThixSanteColors.mutedLight))]),
                          ])),
                          Column(children: [
                            IconButton.filled(onPressed: () {}, icon: const Icon(Icons.videocam_rounded, size: 18), style: IconButton.styleFrom(backgroundColor: ThixSanteColors.primary, foregroundColor: Colors.white, minimumSize: const Size(36,36))),
                            const SizedBox(height: 2),
                            InkWell(onTap: () {}, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: ThixSanteColors.borderLight, borderRadius: BorderRadius.circular(20)), child: const Text('Chat', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)))),
                          ]),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e,_) => Center(child: Text('Erreur: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

final activeDoctorsStreamProvider = StreamProvider<List<PatientLinkModel>>((ref) {
  return ref.read(patientLinkServiceProvider).watchMyDoctors().map((list) => list.where((e) => e.isActive).toList());
});
