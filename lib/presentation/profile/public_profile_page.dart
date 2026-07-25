import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/thix_profile.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/services/access_request_service.dart';
import 'package:thix_id/services/profile_service.dart';
import 'package:thix_id/services/document_service.dart';

const _blue = Color(0xFF0D2CC1);
const _blueDark = Color(0xFF0A1E8A);

class PublicProfileCtrl extends ChangeNotifier {
  final _profiles = ProfileService();
  final _docs = DocumentService();
  final _access = AccessRequestService();
  ThixProfile? profile;
  bool loading = true;
  String? error;
  AccessRequestState? accessState;
  List<Map<String, dynamic>> remoteDocs = [];
  StreamSubscription? _profileSub;
  StreamSubscription? _accessSub;
  StreamSubscription? _docSub;

  Future<void> init(String thixId, String? viewerId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final p = await _profiles.fetchPublicProfileByThixId(thixId.toUpperCase());
      if (p == null) {
        error = 'THIX ID introuvable';
        loading = false;
        notifyListeners();
        return;
      }
      profile = p;
      _profileSub?.cancel();
      _profileSub = _profiles.streamMyProfile(p.userId).listen((live) {
        if (live != null) {
          profile = live;
          notifyListeners();
        }
      });
      _docSub?.cancel();
      _docSub = _docs.streamDocuments(p.userId).listen((d) {
        remoteDocs = d;
        notifyListeners();
      });
      if (viewerId != null && viewerId != p.userId) {
        _accessSub?.cancel();
        _accessSub = _access.streamState(requesterId: viewerId, targetUserId: p.userId).listen((s) {
          accessState = s;
          notifyListeners();
        });
      }
    } catch (e) {
      error = 'Erreur reseau';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  bool get canSeePrivate => accessState?.isActiveAt(DateTime.now().toUtc()) ?? false;

  Future<void> requestAccess(String reqId) async {
    if (profile == null) return;
    await _access.requestAccess(requesterId: reqId, targetUserId: profile!.userId, thixId: profile!.thixId);
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _accessSub?.cancel();
    _docSub?.cancel();
    super.dispose();
  }
}

class PublicProfilePage extends StatefulWidget {
  final String? initialThixId;
  const PublicProfilePage({super.key, this.initialThixId});
  @override
  State<PublicProfilePage> createState() => _PState();
}

class _PState extends State<PublicProfilePage> {
  late final ctrl = PublicProfileCtrl();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final me = context.read<AuthController>().currentUser;
      if (widget.initialThixId != null) {
        ctrl.init(widget.initialThixId!, me?.id);
      }
    });
  }
  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: ctrl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FB),
        body: Consumer<PublicProfileCtrl>(builder: (_, c, __) {
          if (c.loading) return const Center(child: CircularProgressIndicator(color: _blue));
          if (c.error != null) return Center(child: Text(c.error!));
          final p = c.profile!;
          final meId = context.read<AuthController>().currentUser?.id;
          final isOwner = meId == p.userId;
          final canSee = isOwner || c.canSeePrivate;
          return CustomScrollView(slivers: [
            SliverToBoxAdapter(child: _RefHeader(p: p, onBack: () => context.go(AppRoutes.home))),
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _RefStats(p: p))),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            if (!canSee) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _GateCard(ctrl: c))),
            if (canSee)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _Cadre(title: 'Profil Professionnel', icon: Icons.badge_rounded, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _Row(label: 'Nom complet', value: p.fullName ?? p.displayName),
                      _Row(label: 'Bio', value: p.bio ?? '—'),
                      _Row(label: 'Competence', value: p.competence ?? '—'),
                      _Row(label: 'THIX CHAT', value: p.thixChat ?? '—'),
                      _Row(label: 'Origine', value: p.countryOrOrigin ?? '—'),
                      _Row(label: 'Profession', value: p.profession ?? p.occupation ?? '—'),
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 6, children: (p.languagesDetailed.isNotEmpty ? p.languagesDetailed : p.languages.map((e) => {'name': e}).toList()).map((l) {
                        final name = (l['name'] ?? '').toString();
                        final level = l['level'] != null ? ' ${l['level']}' : '';
                        return Chip(label: Text('$name$level', style: const TextStyle(fontSize: 11)), backgroundColor: const Color(0xFFEFF4FF));
                      }).toList()),
                    ])),
                    const SizedBox(height: 16),
                    _Cadre(title: 'Identite civile', icon: Icons.account_circle_rounded, child: Column(children: [
                      _Row(label: 'Date naissance', value: p.dateOfBirth ?? '—'),
                      _Row(label: 'Lieu naissance', value: p.placeOfBirth ?? '—'),
                      _Row(label: 'Nationalite', value: p.nationality ?? '—'),
                      _Row(label: 'Etat civil', value: p.maritalStatus ?? '—'),
                      _Row(label: 'Genre', value: p.gender ?? '—'),
                      _Row(label: 'Adresse', value: p.address ?? '—'),
                      _Row(label: 'Pere', value: p.fatherName ?? '—'),
                      _Row(label: 'Mere', value: p.motherName ?? '—'),
                      _Row(label: 'Contact', value: p.contactPhone ?? '—'),
                    ])),
                    const SizedBox(height: 16),
                    _Cadre(title: 'Origine', icon: Icons.map_rounded, child: Column(children: [
                      _Row(label: 'Province origine', value: p.originProvince ?? '—'),
                      _Row(label: 'Territoire', value: p.originTerritory ?? '—'),
                      _Row(label: 'Secteur', value: p.originSector ?? '—'),
                    ])),
                    const SizedBox(height: 16),
                    _Cadre(title: 'Residence actuelle', icon: Icons.home_work_rounded, child: Column(children: [
                      _Row(label: 'Pays', value: p.residenceCountry ?? '—'),
                      _Row(label: 'Province', value: p.residenceProvince ?? '—'),
                      _Row(label: 'Territoire', value: p.residenceTerritory ?? '—'),
                      _Row(label: 'Ville', value: p.residenceCity ?? '—'),
                      _Row(label: 'Commune', value: p.residenceCommune ?? '—'),
                      _Row(label: 'Quartier', value: p.residenceQuarter ?? '—'),
                      _Row(label: 'Avenue', value: p.residenceAvenue ?? '—'),
                      _Row(label: 'Numero', value: p.residenceNumber ?? '—'),
                    ])),
                    const SizedBox(height: 16),
                    _Cadre(title: 'Contact urgence', icon: Icons.contact_emergency_rounded, child: Column(children: [
                      _Row(label: 'Nom', value: p.emergencyContactName ?? '—'),
                      _Row(label: 'Telephone', value: p.emergencyContactPhone ?? '—'),
                      _Row(label: 'Lien', value: p.emergencyContactRelation ?? '—'),
                      if (p.emergencyContacts.isNotEmpty)
                        ...p.emergencyContacts.map((e) {
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text((e['name'] ?? '—').toString()),
                            subtitle: Text('${e['relation'] ?? ''} ${e['phone'] ?? ''}'),
                          );
                        }),
                    ])),
                    const SizedBox(height: 16),
                    _Cadre(title: 'Infos physiques', icon: Icons.monitor_weight_rounded, child: Column(children: [
                      _Row(label: 'Taille cm', value: p.height ?? '—'),
                      _Row(label: 'Poids kg', value: p.weight ?? '—'),
                      _Row(label: 'Groupe sanguin', value: p.bloodGroup ?? '—'),
                      _Row(label: 'Handicap', value: (p.hasPhysicalDisability ?? false) ? 'Oui ${p.physicalDisabilityDescription ?? ''}' : 'Non'),
                    ])),
                    const SizedBox(height: 16),
                    _Cadre(title: 'Identite nationale', icon: Icons.verified_user_rounded, child: Column(children: [
                      _Row(label: 'Numero', value: p.nationalIdNumber ?? '—'),
                      _Row(label: 'Type', value: p.idDocumentType ?? '—'),
                      _Row(label: 'Date emission', value: p.idDocumentIssueDate ?? '—'),
                      _Row(label: 'Date expiration', value: p.idDocumentExpiryDate ?? '—'),
                      _Row(label: 'Lieu emission', value: p.idDocumentIssuePlace ?? '—'),
                      _Row(label: 'Statut', value: p.idVerificationStatus ?? 'En attente'),
                    ])),
                    const SizedBox(height: 16),
                    _Cadre(title: 'Formations ${p.education.length}', icon: Icons.school_rounded, child: p.education.isEmpty ? const Text('Aucune formation', style: TextStyle(fontSize: 12, color: Colors.black54)) : Column(children: p.education.map((e) {
                      return ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text((e['institution'] ?? '—').toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), subtitle: Text('${e['degree'] ?? ''} ${e['city'] ?? ''} ${e['startYear'] ?? e['period'] ?? ''}'));
                    }).toList())),
                    const SizedBox(height: 16),
                    _Cadre(title: 'Experiences ${p.experience.length}', icon: Icons.work_rounded, child: p.experience.isEmpty ? const Text('Aucune experience', style: TextStyle(fontSize: 12, color: Colors.black54)) : Column(children: p.experience.map((e) {
                      return ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text((e['title'] ?? '—').toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), subtitle: Text('${e['company'] ?? e['org'] ?? ''} ${e['city'] ?? ''}'));
                    }).toList())),
                  ]),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ]);
        }),
      ),
    );
  }
}

class _Cadre extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Cadre({required this.title, required this.icon, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 18, color: _blue), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w800))]),
        const Divider(height: 20),
        child,
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 125, child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w700))),
        Expanded(child: Text(value.isEmpty ? '—' : value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

class _RefHeader extends StatelessWidget {
  final ThixProfile p;
  final VoidCallback onBack;
  const _RefHeader({required this.p, required this.onBack});
  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      Container(height: 230, decoration: const BoxDecoration(gradient: LinearGradient(colors: [_blue, _blueDark]), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)))),
      SafeArea(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [InkWell(onTap: onBack, child: const Icon(Icons.arrow_back, color: Colors.white)), const Spacer(), const Text('THIX ID Public', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))]))),
      Positioned(
        top: 110,
        left: 16,
        right: 16,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)]),
          child: Row(children: [
            CircleAvatar(radius: 38, backgroundImage: p.photoUrl != null && p.photoUrl!.isNotEmpty ? NetworkImage(p.photoUrl!) : null),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), Text('THIX ID: ${p.thixId}', style: const TextStyle(fontSize: 11, color: Colors.black54))])),
          ]),
        ),
      ),
    ]);
  }
}

class _RefStats extends StatelessWidget {
  final ThixProfile p;
  const _RefStats({required this.p});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 52),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        Expanded(child: Column(children: [const Icon(Icons.school, color: _blue, size: 20), Text('${p.education.length}', style: const TextStyle(fontWeight: FontWeight.w900)), const Text('Diplomes', style: TextStyle(fontSize: 10))])),
        Expanded(child: Column(children: [const Icon(Icons.work, color: _blue, size: 20), Text('${p.experience.length}', style: const TextStyle(fontWeight: FontWeight.w900)), const Text('Experiences', style: TextStyle(fontSize: 10))])),
        Expanded(child: Column(children: [const Icon(Icons.psychology, color: _blue, size: 20), Text('${p.skills.length}', style: const TextStyle(fontWeight: FontWeight.w900)), const Text('Competences', style: TextStyle(fontSize: 10))])),
      ]),
    );
  }
}

class _GateCard extends StatelessWidget {
  final PublicProfileCtrl ctrl;
  const _GateCard({required this.ctrl});
  @override
  Widget build(BuildContext context) {
    final s = ctrl.accessState;
    String label = 'Demander l acces';
    if (s?.status == AccessRequestStatus.pending) label = 'En attente...';
    if (s?.status == AccessRequestStatus.rejected) label = 'Redemander';
    final enabled = s?.status != AccessRequestStatus.pending;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _blue.withOpacity(0.15))),
      child: Column(children: [
        const Icon(Icons.lock_rounded, color: _blue),
        const SizedBox(height: 8),
        const Text('Profil prive - acces 10 min apres approbation', style: TextStyle(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: !enabled ? null : () async {
            final me = context.read<AuthController>().currentUser;
            if (me == null) {
              context.go(AppRoutes.login);
              return;
            }
            await ctrl.requestAccess(me.id);
          },
          style: FilledButton.styleFrom(backgroundColor: _blue),
          child: Text(label),
        ),
      ]),
    );
  }
}
