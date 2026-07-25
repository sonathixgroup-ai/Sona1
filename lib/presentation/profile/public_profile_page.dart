import 'dart:async';
import 'package:flutter/material.dart';
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
const _red = Color(0xFFD32F2F);

// -----------------------------------------------------------------------------
// HELPER: TRADUCTION DYNAMIQUE DES STATUTS
// -----------------------------------------------------------------------------
String _translateStatus(String? status) {
  if (status == null || status.trim().isEmpty) return 'Non renseigné';
  switch (status.toLowerCase()) {
    case 'pending': return 'En cours de vérification';
    case 'verified': return 'Vérifié avec succès';
    case 'rejected': return 'Rejeté / Invalide';
    case 'active': return 'Actif';
    case 'inactive': return 'Inactif';
    default: return status;
  }
}

// -----------------------------------------------------------------------------
// CONTROLLER
// -----------------------------------------------------------------------------
class PublicProfileCtrl extends ChangeNotifier {
  final _profiles = ProfileService();
  final _docs = DocumentService();
  final _access = AccessRequestService();
  
  ThixProfile? profile;
  bool loading = true;
  bool isRequestingAccess = false; // Ajout d'un état de chargement pour le bouton
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
      error = 'Erreur réseau';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  bool get canSeePrivate => accessState?.isActiveAt(DateTime.now().toUtc()) ?? false;

  Future<void> requestAccess(String reqId) async {
    if (profile == null) return;
    isRequestingAccess = true;
    notifyListeners();
    try {
      await _access.requestAccess(requesterId: reqId, targetUserId: profile!.userId, thixId: profile!.thixId);
      // Mise à jour optimiste de l'interface en attendant le retour du stream
      accessState = AccessRequestState(
  requestId: reqId, 
  status: AccessStatus.pending, 
  approvedUntil: DateTime.now().add(const Duration(days: 1))
);

    } catch (e) {
      // Gérer l'erreur silencieusement ou via un toast
    } finally {
      isRequestingAccess = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _accessSub?.cancel();
    _docSub?.cancel();
    super.dispose();
  }
}

// -----------------------------------------------------------------------------
// PAGE PRINCIPALE
// -----------------------------------------------------------------------------
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
            
            // Bouton de demande d'accès
            if (!canSee) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _GateCard(ctrl: c))),
            
            if (canSee)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [

                    // 1. Identité Civile
                    _Cadre(
                      title: 'Identité civile',
                      icon: Icons.account_circle_rounded,
                      child: _MaskableContent(
                        canSee: canSee,
                        child: Column(children: [
                          _Row(label: 'Nom complet', value: p.fullName ?? p.displayName),
                          _Row(label: 'Date naissance', value: p.dateOfBirth ?? '—'),
                          _Row(label: 'Lieu naissance', value: p.placeOfBirth ?? '—'),
                          _Row(label: 'Nationalité', value: p.nationality ?? '—'),
                          _Row(label: 'État civil', value: p.maritalStatus ?? '—'),
                          _Row(label: 'Genre', value: p.gender ?? '—'),
                          _Row(label: 'Adresse', value: p.address ?? '—'),
                          _Row(label: 'Père', value: p.fatherName ?? '—'),
                          _Row(label: 'Mère', value: p.motherName ?? '—'),
                          _Row(label: 'Contact', value: p.contactPhone ?? '—'),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ... [Sections 2 à 7 restent identiques] ...
                    _Cadre(title: 'Origine', icon: Icons.map_rounded, child: _MaskableContent(canSee: canSee, child: Column(children: [_Row(label: 'Province origine', value: p.originProvince ?? '—'), _Row(label: 'Territoire', value: p.originTerritory ?? '—'), _Row(label: 'Secteur', value: p.originSector ?? '—')]))),
                    const SizedBox(height: 16),
                    _Cadre(title: 'Résidence actuelle', icon: Icons.home_work_rounded, child: _MaskableContent(canSee: canSee, child: Column(children: [_Row(label: 'Pays', value: p.residenceCountry ?? '—'), _Row(label: 'Province', value: p.residenceProvince ?? '—'), _Row(label: 'Territoire', value: p.residenceTerritory ?? '—'), _Row(label: 'Ville', value: p.residenceCity ?? '—'), _Row(label: 'Commune', value: p.residenceCommune ?? '—'), _Row(label: 'Quartier', value: p.residenceQuarter ?? '—'), _Row(label: 'Avenue', value: p.residenceAvenue ?? '—'), _Row(label: 'Numéro', value: p.residenceNumber ?? '—')]))),
                    const SizedBox(height: 16),
                    _Cadre(title: 'Biographie', icon: Icons.history_edu_rounded, child: _MaskableContent(canSee: canSee, child: _ExpandableTextBody(text: p.bio ?? 'Aucune biographie renseignée.'))),
                    const SizedBox(height: 16),
                    _Cadre(title: 'Profil Professionnel', icon: Icons.work_outline_rounded, child: _MaskableContent(canSee: canSee, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_Row(label: 'Profession', value: p.profession ?? p.occupation ?? '—'), _ExpandableRow(label: 'Compétence', value: p.competence ?? '—'), _Row(label: 'THIX CHAT', value: p.thixChat ?? '—'), const SizedBox(height: 8), Wrap(spacing: 6, runSpacing: 6, children: (p.languagesDetailed.isNotEmpty ? p.languagesDetailed : p.languages.map((e) => {'name': e}).toList()).map((l) { final name = (l['name'] ?? '').toString(); final level = l['level'] != null ? ' ${l['level']}' : ''; return Chip(label: Text('$name$level', style: const TextStyle(fontSize: 11, color: _blueDark, fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFFEFF4FF), side: BorderSide.none); }).toList())]))),
                    const SizedBox(height: 16),
                    _Cadre(title: 'Contact urgence', icon: Icons.contact_emergency_rounded, child: _MaskableContent(canSee: canSee, child: Column(children: [_Row(label: 'Nom', value: p.emergencyContactName ?? '—'), _Row(label: 'Téléphone', value: p.emergencyContactPhone ?? '—'), _Row(label: 'Lien', value: p.emergencyContactRelation ?? '—'), if (p.emergencyContacts.isNotEmpty) ...p.emergencyContacts.map((e) => ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text((e['name'] ?? '—').toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), subtitle: Text('${e['relation'] ?? ''} - ${e['phone'] ?? ''}', style: const TextStyle(fontSize: 12))))]))),
                    const SizedBox(height: 16),
                    _Cadre(title: 'Infos physiques', icon: Icons.monitor_weight_rounded, child: _MaskableContent(canSee: canSee, child: Column(children: [_Row(label: 'Taille cm', value: p.height ?? '—'), _Row(label: 'Poids kg', value: p.weight ?? '—'), _Row(label: 'Groupe sanguin', value: p.bloodGroup ?? '—'), _Row(label: 'Handicap', value: (p.hasPhysicalDisability ?? false) ? 'Oui : ${p.physicalDisabilityDescription ?? ''}' : 'Non')]))),
                    const SizedBox(height: 16),

                    // 8. Identité nationale (Avec visionneuse de documents)
                    _Cadre(
                      title: 'Identité nationale',
                      icon: Icons.verified_user_rounded,
                      child: _MaskableContent(
                        canSee: canSee,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Row(label: 'Numéro', value: p.nationalIdNumber ?? '—'),
                            _Row(label: 'Type', value: p.idDocumentType ?? '—'),
                            _Row(label: 'Date émission', value: p.idDocumentIssueDate ?? '—'),
                            _Row(label: 'Date expiration', value: p.idDocumentExpiryDate ?? '—'),
                            _Row(label: 'Lieu émission', value: p.idDocumentIssuePlace ?? '—'),
                            _Row(label: 'Statut', value: _translateStatus(p.idVerificationStatus)),
                            // Recherche d'une pièce jointe dans remoteDocs liée à l'identité
                            if (c.remoteDocs.any((d) => (d['doc_type'] ?? '').toString().toLowerCase().contains('id')))
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: _DocumentViewerButton(
                                  label: 'Voir la pièce d\'identité',
                                  // Prend le premier document d'identité trouvé
                                  documentUrl: c.remoteDocs.firstWhere((d) => (d['doc_type'] ?? '').toString().toLowerCase().contains('id'))['download_url'] ?? '',
                                ),
                              )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 9. Parcours scolaire (Détaillé)
                    _Cadre(
                      title: 'Parcours scolaire',
                      icon: Icons.account_balance_rounded,
                      child: _MaskableContent(
                        canSee: canSee,
                        child: p.education.isEmpty 
                          ? const Text('Aucun parcours scolaire enregistré', style: TextStyle(fontSize: 12, color: Colors.black54)) 
                          : Column(
                              children: p.education.map((e) => _DetailedListItem(
                                title: e['institution']?.toString() ?? '—',
                                subtitle: e['degree']?.toString() ?? '',
                                location: e['city']?.toString() ?? '',
                                period: e['period']?.toString() ?? e['startYear']?.toString() ?? '',
                                description: e['description']?.toString(), // Potentiel champ de description
                                documentUrl: e['proofUrl']?.toString() ?? e['document']?.toString(), // Si une preuve existe
                              )).toList(),
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 10. Formations & Certifications
                    _Cadre(title: 'Formations & Certifs', icon: Icons.school_rounded, child: _MaskableContent(canSee: canSee, child: p.trainings.isEmpty && p.certifications.isEmpty ? const Text('Aucune formation ou certification', style: TextStyle(fontSize: 12, color: Colors.black54)) : Column(children: [...p.trainings.map((e) => ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text((e['title'] ?? e['name'] ?? '—').toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), subtitle: Text('${e['organizer'] ?? e['provider'] ?? ''}'))), ...p.certifications.map((e) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.workspace_premium, color: Colors.amber, size: 20), title: Text((e['title'] ?? e['name'] ?? '—').toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), subtitle: Text('${e['issuer'] ?? e['org'] ?? ''}')))]))),
                    const SizedBox(height: 16),

                    // 11. Expériences (Détaillées avec missions et preuves)
                    _Cadre(
                      title: 'Expériences Pro',
                      icon: Icons.business_center_rounded,
                      child: _MaskableContent(
                        canSee: canSee,
                        child: p.experience.isEmpty 
                          ? const Text('Aucune expérience enregistrée', style: TextStyle(fontSize: 12, color: Colors.black54)) 
                          : Column(
                              children: p.experience.map((e) => _DetailedListItem(
                                title: e['title']?.toString() ?? '—',
                                subtitle: e['company']?.toString() ?? e['org']?.toString() ?? '',
                                location: [e['sector']?.toString(), e['city']?.toString()].where((s) => s != null && s.isNotEmpty).join(' • '),
                                period: e['period']?.toString() ?? '',
                                description: e['missions']?.toString() ?? e['description']?.toString(), // Les missions et réalisations
                                documentUrl: e['proofUrl']?.toString() ?? e['document']?.toString() ?? (e['documents'] is List && (e['documents'] as List).isNotEmpty ? (e['documents'] as List).first.toString() : null), // Gestion des preuves rattachées
                              )).toList(),
                            ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 12. THIX ID CARD GENERATED AUTOMATICALLY
                    _ThixIdCardWidget(profile: p),

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

// -----------------------------------------------------------------------------
// COMPOSANTS UI EXISTANTS
// -----------------------------------------------------------------------------

class _Cadre extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Cadre({required this.title, required this.icon, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 20, color: _blue), 
          const SizedBox(width: 8), 
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _blueDark))
        ]),
        const Divider(height: 24, color: Color(0xFFE0E0E0)),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value.isEmpty ? '—' : value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
      ]),
    );
  }
}

class _ExpandableTextBody extends StatefulWidget {
  final String text;
  const _ExpandableTextBody({required this.text});
  @override
  State<_ExpandableTextBody> createState() => _ExpandableTextBodyState();
}
class _ExpandableTextBodyState extends State<_ExpandableTextBody> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final rawText = widget.text.trim();
    if (rawText.isEmpty || rawText == 'Aucune biographie renseignée.') {
      return Text(rawText, style: const TextStyle(fontSize: 13, color: Colors.black54));
    }
    final isLong = rawText.length > 120;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(rawText, maxLines: _expanded ? null : 3, overflow: _expanded ? null : TextOverflow.fade, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.5, color: Colors.black87)),
        if (isLong)
          Align(alignment: Alignment.centerRight, child: InkWell(onTap: () => setState(() => _expanded = !_expanded), child: Padding(padding: const EdgeInsets.only(top: 8, bottom: 4), child: Text(_expanded ? 'Voir moins' : 'Voir plus', style: const TextStyle(color: _blue, fontSize: 12, fontWeight: FontWeight.w900))))),
      ],
    );
  }
}

class _ExpandableRow extends StatefulWidget {
  final String label;
  final String value;
  const _ExpandableRow({required this.label, required this.value});
  @override
  State<_ExpandableRow> createState() => _ExpandableRowState();
}
class _ExpandableRowState extends State<_ExpandableRow> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final text = widget.value.isEmpty ? '—' : widget.value;
    final isLong = text.length > 80;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 130, child: Text(widget.label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600))),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.4), maxLines: _expanded ? null : 3, overflow: _expanded ? null : TextOverflow.ellipsis),
              if (isLong) InkWell(onTap: () => setState(() => _expanded = !_expanded), child: Padding(padding: const EdgeInsets.only(top: 4), child: Text(_expanded ? 'Voir moins' : 'Voir plus', style: const TextStyle(color: _blue, fontSize: 12, fontWeight: FontWeight.w800))))
            ],
          ),
        ),
      ]),
    );
  }
}

class _MaskableContent extends StatelessWidget {
  final bool canSee;
  final Widget child;
  const _MaskableContent({required this.canSee, required this.child});
  @override
  Widget build(BuildContext context) {
    if (canSee) return child;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.lock_rounded, color: Colors.grey, size: 28),
          SizedBox(height: 8),
          Text("Informations masquées", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          SizedBox(height: 4),
          Text("Veuillez demander l'autorisation pour avoir accès à ces données.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
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
      SafeArea(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        InkWell(onTap: onBack, child: const Icon(Icons.arrow_back, color: Colors.white)), 
        const Spacer(), 
        const Text('THIX ID Public', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        const Spacer(),
        const SizedBox(width: 24),
      ]))),
      Positioned(
        top: 110,
        left: 16,
        right: 16,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)]),
          child: Row(children: [
            CircleAvatar(radius: 38, backgroundColor: const Color(0xFFEFF4FF), backgroundImage: p.photoUrl != null && p.photoUrl!.isNotEmpty ? NetworkImage(p.photoUrl!) : null),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.displayName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)), 
              const SizedBox(height: 4),
              Text('THIX ID: ${p.thixId}', style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
            ])),
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(children: [
        Expanded(child: Column(children: [const Icon(Icons.school, color: _blue, size: 24), const SizedBox(height: 6), Text('${p.education.length}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const Text('Diplômes', style: TextStyle(fontSize: 11, color: Colors.black54))])),
        Expanded(child: Column(children: [const Icon(Icons.business_center, color: _blue, size: 24), const SizedBox(height: 6), Text('${p.experience.length}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const Text('Expériences', style: TextStyle(fontSize: 11, color: Colors.black54))])),
        Expanded(child: Column(children: [const Icon(Icons.psychology, color: _blue, size: 24), const SizedBox(height: 6), Text('${p.skills.length}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const Text('Compétences', style: TextStyle(fontSize: 11, color: Colors.black54))])),
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
    final rawStatus = s?.status?.name;
    
    String label = "Demander l'accès";
    bool isPending = rawStatus == 'pending' || rawStatus == 'En attente';
    
    if (isPending) label = 'Demande envoyée (En attente)';
    if (rawStatus == 'rejected') label = 'Refusé - Redemander';
    
    final btnColor = isPending ? Colors.grey : _red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _blue.withOpacity(0.15))),
      child: Column(children: [
        const Icon(Icons.lock_rounded, color: _blue, size: 32),
        const SizedBox(height: 12),
        const Text('Profil privé - accès 10 min après approbation', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: (isPending || ctrl.isRequestingAccess) ? null : () async {
              final me = context.read<AuthController>().currentUser;
              if (me == null) {
                context.go(AppRoutes.login);
                return;
              }
              await ctrl.requestAccess(me.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: btnColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: ctrl.isRequestingAccess
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ]),
    );
  }
}

// -----------------------------------------------------------------------------
// NOUVEAUX COMPOSANTS : LISTES DÉTAILLÉES ET VISIONNEUSE
// -----------------------------------------------------------------------------

/// Élément de liste générique avec bouton "Voir plus" pour les descriptions longues
/// et un gestionnaire de documents/preuves rattachés.
class _DetailedListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String location;
  final String period;
  final String? description;
  final String? documentUrl;

  const _DetailedListItem({
    required this.title,
    required this.subtitle,
    required this.location,
    required this.period,
    this.description,
    this.documentUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _blueDark)),
          if (location.isNotEmpty || period.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                [if (period.isNotEmpty) period, if (location.isNotEmpty) location].join(' • '),
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ),
          if (description != null && description!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _ExpandableTextBody(text: description!),
            ),
          if (documentUrl != null && documentUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _DocumentViewerButton(label: 'Voir le document / la preuve', documentUrl: documentUrl!),
            ),
          const Divider(height: 20, color: Color(0xFFF0F0F0)),
        ],
      ),
    );
  }
}

/// Bouton cliquable permettant d'ouvrir une photo/pièce dans une popup plein écran.
class _DocumentViewerButton extends StatelessWidget {
  final String label;
  final String documentUrl;

  const _DocumentViewerButton({required this.label, required this.documentUrl});

  void _showDocument(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  documentUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: const Text('Erreur lors du chargement de l\'image.', textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDocument(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF4FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _blue.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_rounded, color: _blue, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: _blueDark, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 12. THIX ID CARD WIDGET
// -----------------------------------------------------------------------------
class _ThixIdCardWidget extends StatelessWidget {
  final ThixProfile profile;
  const _ThixIdCardWidget({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.58, // Format standard carte ID
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE5C158), Color(0xFFF9E8A2), Color(0xFFD4AF37), Color(0xFFF9E8A2), Color(0xFFB59325)],
                stops: [0.0, 0.3, 0.5, 0.8, 1.0],
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Stack(
              children: [
                // Filigrane fond (Empreinte simulée ou motif)
                Positioned.fill(
                  child: Center(
                    child: Icon(Icons.fingerprint, size: 180, color: Colors.white.withOpacity(0.25)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      // HEADER CARTE
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFF8B0000), borderRadius: BorderRadius.circular(6)),
                            child: const Text('THIX ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('DIGITAL IDENTITY CARD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5, shadows: [Shadow(color: Colors.black45, blurRadius: 2)])),
                              Text('ID NAT : ${profile.nationalIdNumber ?? 'NON RENSEIGNÉ'}', style: const TextStyle(color: Color(0xFF5A4000), fontWeight: FontWeight.bold, fontSize: 10)),
                              const Text('VILLE / PAYS D\'EMISSION : KINSHASA / RDC', style: TextStyle(color: Color(0xFF5A4000), fontWeight: FontWeight.bold, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      // BODY CARTE
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Photo Principale
                          Container(
                            width: 85,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white, width: 2),
                              image: profile.photoUrl != null && profile.photoUrl!.isNotEmpty
                                  ? DecorationImage(image: NetworkImage(profile.photoUrl!), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: profile.photoUrl == null || profile.photoUrl!.isEmpty
                                ? const Icon(Icons.person, color: Colors.grey, size: 50) : null,
                          ),
                          const SizedBox(width: 12),
                          // Informations textuelles
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _CardLabelValue('Name / Nom', profile.fullName ?? profile.displayName),
                                _CardLabelValue('Place / Lieu', profile.placeOfBirth ?? '—'),
                                _CardLabelValue('Address / Adresse', '${profile.residenceCity ?? ''} ${profile.residenceCommune ?? ''}'.trim()),
                                _CardLabelValue('Profession / Occupation', profile.profession ?? profile.occupation ?? '—'),
                              ],
                            ),
                          ),
                          // Section Droite (QR Code & Petite photo)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text('DIGITAL ID', style: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.w900, fontSize: 12)),
                              Text(profile.thixId, style: const TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold, fontSize: 10)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(2),
                                color: Colors.white,
                                child: const Icon(Icons.qr_code_2, size: 55, color: Color(0xFF8B0000)), // Faux QR pour le design
                              ),
                              const SizedBox(height: 4),
                              const Text('CONGOLAIS', style: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.w900, fontSize: 11)),
                              const Text('NATIONALITY / NATIONALITÉ', style: TextStyle(color: Color(0xFF5A4000), fontSize: 7, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(profile.dateOfBirth ?? '—', style: const TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.w900, fontSize: 12)),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Mention de non-responsabilité
        const Padding(
          padding: EdgeInsets.only(top: 12.0, left: 8, right: 8),
          child: Text(
            "Cette pièce n'est pas une pièce d'identité officielle d'un gouvernement. Elle est générée automatiquement par THIX ID à titre strictement informatif.",
            textAlign: TextAlign.center,
            style: TextStyle(color: _red, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _CardLabelValue extends StatelessWidget {
  final String label;
  final String value;
  const _CardLabelValue(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF5A4000), fontSize: 8, fontWeight: FontWeight.w700)),
          Text(value.isEmpty ? '—' : value.toUpperCase(), style: const TextStyle(color: Color(0xFF222222), fontSize: 11, fontWeight: FontWeight.w900, height: 1.1)),
        ],
      ),
    );
  }
}
