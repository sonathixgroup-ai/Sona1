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
  bool loading=true; String? error;
  AccessRequestState? accessState;
  List<Map<String,dynamic>> remoteDocs=[];
  StreamSubscription? _profileSub, _accessSub, _docSub;

  Future<void> init(String thixId, String? viewerId) async {
    loading=true; notifyListeners();
    try{
      final p = await _profiles.fetchPublicProfileByThixId(thixId.toUpperCase());
      if(p==null){ error='THIX ID introuvable'; loading=false; notifyListeners(); return; }
      profile=p;

      // 1. BRANCHEMENT TEMPS REEL AU DASHBOARD - chaque SAUVEGARDER met à jour public view instantanément
      _profileSub?.cancel();
      _profileSub = _profiles.streamMyProfile(p.userId).listen((live){
        if(live!=null){ profile=live; notifyListeners(); }
      });

      // 2. Docs stream
      _docSub = _docs.streamDocuments(p.userId).listen((d){ remoteDocs=d; notifyListeners(); });

      // 3. Access request 10min
      if(viewerId!=null && viewerId!=p.userId){
        _accessSub = _access.streamState(requesterId: viewerId, targetUserId: p.userId).listen((s){ accessState=s; notifyListeners(); });
      }
    }catch(e){ error='Erreur réseau'; } finally{ loading=false; notifyListeners(); }
  }
  bool get canSeePrivate => accessState?.isActiveAt(DateTime.now().toUtc())??false;
  Future<void> requestAccess(String reqId) async => await _access.requestAccess(requesterId: reqId, targetUserId: profile!.userId, thixId: profile!.thixId);
  @override void dispose(){ _profileSub?.cancel(); _accessSub?.cancel(); _docSub?.cancel(); super.dispose(); }
}

class PublicProfilePage extends StatefulWidget {
  final String? initialThixId; const PublicProfilePage({super.key, this.initialThixId});
  @override State<PublicProfilePage> createState()=> _PState();
}
class _PState extends State<PublicProfilePage> {
  late final ctrl = PublicProfileCtrl();
  @override void initState(){ super.initState(); WidgetsBinding.instance.addPostFrameCallback((_){ ctrl.init(widget.initialThixId!, context.read<AuthController>().currentUser?.id); });}
  @override void dispose(){ ctrl.dispose(); super.dispose();}
  @override Widget build(BuildContext context){
    return ChangeNotifierProvider.value(value: ctrl, child: Scaffold(backgroundColor: const Color(0xFFF5F6FB), body: Consumer<PublicProfileCtrl>(builder:(_,c,__){
      if(c.loading) return const Center(child: CircularProgressIndicator(color:_blue));
      if(c.error!=null) return Center(child: Text(c.error!));
      final p=c.profile!; final meId=context.read<AuthController>().currentUser?.id;
      final isOwner=meId==p.userId; final canSee=isOwner||c.canSeePrivate;

      return CustomScrollView(slivers:[
        SliverToBoxAdapter(child: _RefHeader(p:p, onBack:()=>context.go(AppRoutes.home))),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: _RefStats(p:p))),
        const SliverToBoxAdapter(child: SizedBox(height:16)),
        if(!canSee) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: _GateCard(ctrl:c))),
        if(canSee)...[
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Column(children:[
            _Cadre(title:'Profil Professionnel', icon:Icons.badge_rounded, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              _Row(label:'Nom complet', value:p.fullName??p.displayName),
              _Row(label:'Bio', value:p.bio??'—'),
              _Row(label:'Compétence (résumé)', value:p.competence??'—'),
              _Row(label:'THIX CHAT', value:p.thixChat??'—'),
              _Row(label:'Origine / Pays', value:p.countryOrOrigin??'—'),
              _Row(label:'Profession', value:p.profession??p.occupation??'—'),
              const SizedBox(height:8),
              if(p.languagesDetailed.isNotEmpty) Wrap(spacing:6, runSpacing:6, children: p.languagesDetailed.map((l)=> Chip(label: Text('${l['name']} ${l['level']!=null?'• ${l['level']}':''}', style: const TextStyle(fontSize:11)), backgroundColor: const Color(0xFFEFF4FF))).toList())
              else if(p.languages.isNotEmpty) Wrap(spacing:6, children: p.languages.map((l)=> Chip(label: Text(l, style: const TextStyle(fontSize:11)))).toList()),
            ])),
            const SizedBox(height:16),
            _Cadre(title:'Identité civile', subtitle:'Informations sensibles (strictement protégées)', icon:Icons.account_circle_rounded, child: Column(children:[
              _Row(label:'Date de naissance', value:p.dateOfBirth??'—'),
              _Row(label:'Lieu de naissance', value:p.placeOfBirth??'—'),
              _Row(label:'Nationalité', value:p.nationality??'—'),
              _Row(label:'État civil', value:p.maritalStatus??'—'),
              _Row(label:'Genre', value:p.gender??'—'),
              _Row(label:'Adresse', value:p.address??'—'),
              _Row(label:'Père', value:p.fatherName??'—'),
              _Row(label:'Mère', value:p.motherName??'—'),
              _Row(label:'Contact', value:p.contactPhone??'—'),
            ])),
            const SizedBox(height:16),
            _Cadre(title:'Origine', icon:Icons.map_rounded, child: Column(children:[
              _Row(label:'Province origine', value:p.originProvince??'—'),
              _Row(label:'Territoire', value:p.originTerritory??'—'),
              _Row(label:'Secteur', value:p.originSector??'—'),
            ])),
            const SizedBox(height:16),
            _Cadre(title:'Résidence actuelle', icon:Icons.home_work_rounded, child: Column(children:[
              _Row(label:'Pays', value:p.residenceCountry??'—'),
              _Row(label:'Province', value:p.residenceProvince??'—'),
              _Row(label:'Territoire', value:p.residenceTerritory??'—'),
              _Row(label:'Ville', value:p.residenceCity??'—'),
              _Row(label:'Commune', value:p.residenceCommune??'—'),
              _Row(label:'Quartier', value:p.residenceQuarter??'—'),
              _Row(label:'Avenue', value:p.residenceAvenue??'—'),
              _Row(label:'Numéro', value:p.residenceNumber??'—'),
            ])),
            const SizedBox(height:16),
            _Cadre(title:'Contact d\'urgence', icon:Icons.contact_emergency_rounded, child: Column(children:[
              _Row(label:'Nom', value:p.emergencyContactName??'—'),
              _Row(label:'Téléphone', value:p.emergencyContactPhone??'—'),
              _Row(label:'Lien', value:p.emergencyContactRelation??'—'),
              if(p.emergencyContacts.isNotEmpty) ...p.emergencyContacts.map((e)=> ListTile(dense:true, contentPadding: EdgeInsets.zero, title: Text((e['name']??'—').toString(), subtitle: Text('${e['relation']??''} • ${e['phone']??''} • ${e['city']??''}'))),
            ])),
            const SizedBox(height:16),
            _Cadre(title:'Infos physiques', icon:Icons.monitor_weight_rounded, child: Column(children:[
              _Row(label:'Taille (cm)', value:p.height??'—'),
              _Row(label:'Poids (kg)', value:p.weight??'—'),
              _Row(label:'Groupe sanguin', value:p.bloodGroup??'—'),
              _Row(label:'Handicap physique', value: (p.hasPhysicalDisability??false) ? 'Oui - ${p.physicalDisabilityDescription??''}' : 'Non'),
            ])),
            const SizedBox(height:16),
            _Cadre(title:'Identité nationale', icon:Icons.verified_user_rounded, child: Column(children:[
              _Row(label:'Numéro identité', value:p.nationalIdNumber??'—'),
              _Row(label:'Type document', value:p.idDocumentType??'—'),
              _Row(label:'Date émission', value:p.idDocumentIssueDate??'—'),
              _Row(label:'Date expiration', value:p.idDocumentExpiryDate??'—'),
              _Row(label:'Lieu émission', value:p.idDocumentIssuePlace??'—'),
              _Row(label:'Statut', value:p.idVerificationStatus??'En attente'),
              _Row(label:'Pièces', value:'Recto: ${p.idDocumentFrontDocId??'—'} | Verso: ${p.idDocumentBackDocId??'—'} | Selfie: ${p.idDocumentSelfieDocId??'—'}'),
            ])),
            const SizedBox(height:16),
            _Cadre(title:'Formations • ${p.education.length}', icon:Icons.school_rounded, child: p.education.isEmpty? const Text('Aucune formation', style: TextStyle(color: Colors.black54, fontSize:12)) : Column(children: p.education.map((e)=> ListTile(dense:true, contentPadding: EdgeInsets.zero, title: Text((e['institution']??'—').toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize:13)), subtitle: Text('${e['degree']??''} • ${e['city']??''} • ${e['startYear']??e['period']??''}'))).toList())),
            const SizedBox(height:16),
            _Cadre(title:'Expériences • ${p.experience.length}', icon:Icons.work_rounded, child: p.experience.isEmpty? const Text('Aucune expérience', style: TextStyle(color: Colors.black54, fontSize:12)) : Column(children: p.experience.map((e)=> ListTile(dense:true, contentPadding: EdgeInsets.zero, title: Text((e['title']??'—').toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize:13)), subtitle: Text('${e['company']??e['org']??''} • ${e['city']??''}\n${e['tasks']??e['missions']??''}', style: const TextStyle(fontSize:11)))).toList())),
            const SizedBox(height:16),
            _Cadre(title:'Compétences • ${p.skills.length}', icon:Icons.psychology_rounded, child: p.skills.isEmpty? Text(p.competence??'—') : Column(children: p.skills.map((s)=> ListTile(dense:true, contentPadding: EdgeInsets.zero, title: Text((s['name']??'—').toString()), subtitle: Text('${s['level']??''} ${s['details']??''}'))).toList())),
            const SizedBox(height:16),
            _Cadre(title:'Documents • ${c.remoteDocs.length}', icon:Icons.folder_rounded, child: c.remoteDocs.isEmpty? const Text('Aucun document') : Column(children: c.remoteDocs.take(5).map((d)=> ListTile(dense:true, contentPadding: EdgeInsets.zero, title: Text((d['title']??d['file_name']??'Doc').toString(), style: const TextStyle(fontSize:13)), subtitle: Text((d['doc_type']??'').toString()))).toList())),
          ]))),
        ],
        const SliverToBoxAdapter(child: SizedBox(height:100)),
      ]);
    })));
  }
}

class _Cadre extends StatelessWidget {
  final String title; final String? subtitle; final IconData icon; final Widget child;
  const _Cadre({required this.title, this.subtitle, required this.icon, required this.child});
  @override Widget build(BuildContext context)=> Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Row(children:[Icon(icon, size:18, color:_blue), const SizedBox(width:8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), if(subtitle!=null) Text(subtitle!, style: const TextStyle(fontSize:10, color: Colors.black54))]))]), const Divider(height:20), child]));
}
class _Row extends StatelessWidget {
  final String label, value; const _Row({required this.label, required this.value});
  @override Widget build(BuildContext context)=> Padding(padding: const EdgeInsets.symmetric(vertical:5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children:[SizedBox(width:125, child: Text(label, style: const TextStyle(fontSize:11, color: Colors.black54, fontWeight: FontWeight.w700))), Expanded(child: Text(value.isEmpty? '—' : value, style: const TextStyle(fontSize:13, fontWeight: FontWeight.w600)))]));
}
class _RefHeader extends StatelessWidget { final ThixProfile p; final VoidCallback onBack; const _RefHeader({required this.p, required this.onBack}); @override Widget build(BuildContext context)=> Stack(clipBehavior: Clip.none, children:[Container(height:230, decoration: const BoxDecoration(gradient: LinearGradient(colors: [_blue,_blueDark]), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)))), SafeArea(child: Padding(padding: const EdgeInsets.all(12), child: Row(children:[InkWell(onTap:onBack, child: const Icon(Icons.arrow_back, color: Colors.white)), const Spacer(), const Text('THIX ID Public', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))]))), Positioned(top:110, left:16, right:16, child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: Row(children:[CircleAvatar(radius:38, backgroundImage: p.photoUrl!=null? NetworkImage(p.photoUrl!):null), const SizedBox(width:12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(p.displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize:18)), Text('THIX ID: ${p.thixId}', style: const TextStyle(fontSize:11, color: Colors.black54)), Text('@${p.thixChat??''}', style: const TextStyle(fontSize:11, color:_blue))]))])))]); }
class _RefStats extends StatelessWidget { final ThixProfile p; const _RefStats({required this.p}); @override Widget build(BuildContext context)=> Container(margin: const EdgeInsets.only(top:52), padding: const EdgeInsets.symmetric(vertical:14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Row(children:[_item('${p.education.length}','Diplômes',Icons.school), _item('${p.experience.length}','Expériences',Icons.work), _item('${p.skills.length}','Compétences',Icons.psychology)])); Widget _item(String v, String l, IconData ic)=> Expanded(child: Column(children:[Icon(ic, color:_blue, size:20), Text(v, style: const TextStyle(fontWeight: FontWeight.w900)), Text(l, style: const TextStyle(fontSize:10, color: Colors.black54))]));}
class _GateCard extends StatelessWidget { final PublicProfileCtrl ctrl; const _GateCard({required this.ctrl}); @override Widget build(BuildContext context){ final s=ctrl.accessState; String label='Demander l’accès'; if(s?.status==AccessRequestStatus.pending) label='En attente...'; return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(children:[const Icon(Icons.lock_rounded, color:_blue), const SizedBox(height:8), const Text('Profil privé - accès 10 min après approbation', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height:8), FilledButton(onPressed: s?.status==AccessRequestStatus.pending? null : () async { final me=context.read<AuthController>().currentUser; if(me==null) return; await ctrl.requestAccess(me.id); }, style: FilledButton.styleFrom(backgroundColor:_blue), child: Text(label))])) ; } }
