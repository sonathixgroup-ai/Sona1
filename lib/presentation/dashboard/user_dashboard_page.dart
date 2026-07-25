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
import 'package:thix_id/theme.dart';

const _blue = Color(0xFF0D2CC1);
const _blueDark = Color(0xFF0A1E8A);
const _pageSize = 20;

class PublicProfileCtrl extends ChangeNotifier {
  final _profiles = ProfileService();
  final _docs = DocumentService();
  final _access = AccessRequestService();
  ThixProfile? profile;
  bool loading=true; String? error;
  AccessRequestState? accessState;
  List<Map<String,dynamic>> formations=[], experiences=[], documents=[];
  StreamSubscription? _profileSub, _accessSub;

  Future<void> init(String thixId, String? viewerId) async {
    loading=true; error=null; notifyListeners();
    try{
      final p = await _profiles.fetchPublicProfileByThixId(thixId.toUpperCase());
      if(p==null){ error='THIX ID introuvable'; loading=false; notifyListeners(); return; }
      profile=p;
      // STREAM TEMPS REEL - branché au dashboard
      _profileSub?.cancel();
      _profileSub = _profiles.streamMyProfile(p.userId).listen((live){
        if(live!=null){ profile=live; if(formations.isEmpty && live.education.isNotEmpty) formations=live.education.cast<Map<String,dynamic>>(); if(experiences.isEmpty && live.experience.isNotEmpty) experiences=live.experience.cast<Map<String,dynamic>>(); notifyListeners(); }
      });
      final res = await Future.wait([
        _profiles.fetchFormationsPaginated(p.userId, limit:_pageSize, offset:0),
        _profiles.fetchExperiencesPaginated(p.userId, limit:_pageSize, offset:0),
        _docs.fetchDocumentsPaginated(p.userId, limit:_pageSize, offset:0),
      ]);
      formations=(res[0] as List).cast<Map<String,dynamic>>();
      experiences=(res[1] as List).cast<Map<String,dynamic>>();
      documents=(res[2] as List).cast<Map<String,dynamic>>();
      if(formations.isEmpty && p.education.isNotEmpty) formations=p.education.cast<Map<String,dynamic>>();
      if(experiences.isEmpty && p.experience.isNotEmpty) experiences=p.experience.cast<Map<String,dynamic>>();
      if(viewerId!=null && viewerId!=p.userId){
        _accessSub = _access.streamState(requesterId: viewerId, targetUserId: p.userId).listen((s){ accessState=s; notifyListeners(); });
      }
    }catch(e){ error='Erreur réseau'; } finally{ loading=false; notifyListeners(); }
  }
  bool get canSeePrivate => accessState?.isActiveAt(DateTime.now().toUtc())??false;
  Future<void> requestAccess(String reqId) async => await _access.requestAccess(requesterId: reqId, targetUserId: profile!.userId, thixId: profile!.thixId);
  @override void dispose(){ _profileSub?.cancel(); _accessSub?.cancel(); super.dispose(); }
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
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: _RefStats(d:c.formations.length, e:c.experiences.length))),
        const SliverToBoxAdapter(child: SizedBox(height:16)),
        if(!canSee) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: _GateCard(ctrl:c))),
        if(canSee)...[
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Column(children:[
            // BIO / COMPETENCE / LANGUES / THIX CHAT
            _Cadre(title:'Profil Professionnel', icon:Icons.badge_rounded, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              _RowInfo(label:'Nom complet', value:p.displayName),
              _RowInfo(label:'Compétences', value:p.competence??'—'),
              _RowInfo(label:'Bio', value:p.bio??'—'),
              _RowInfo(label:'THIX CHAT', value:p.thixChat??'—'),
              const SizedBox(height:8),
              Wrap(spacing:6, children: (p.languagesDetailed.isNotEmpty? p.languagesDetailed : p.languages.map((e)=>{'name':e}).toList()).map((l)=> Chip(label: Text('${l['name']}${l['level']!=null?' • ${l['level']}':''}', style: const TextStyle(fontSize:11)), backgroundColor: const Color(0xFFEFF4FF))).toList()),
            ])),
            const SizedBox(height:16),
            // IDENTITE CIVILE - comme ton screenshot 1
            _Cadre(title:'Identité civile', subtitle:'Informations sensibles (strictement protégées)', icon:Icons.account_circle_rounded, child: Column(children:[
              _RowInfo(label:'Date de naissance', value:p.dateOfBirth??'—'),
              _RowInfo(label:'Lieu de naissance', value:p.placeOfBirth??'—'),
              _RowInfo(label:'Nationalité', value:p.nationality??'—'),
              _RowInfo(label:'État civil', value:p.maritalStatus??'—'),
              _RowInfo(label:'Genre', value:p.gender??'—'),
              _RowInfo(label:'Profession', value:p.occupation??p.profession??'—'),
              _RowInfo(label:'Adresse', value:p.address??'—'),
              _RowInfo(label:'Origine / Pays', value:p.countryOrOrigin??'—'),
              _RowInfo(label:'Contact', value:p.contactPhone??'—'),
            ])),
            const SizedBox(height:16),
            // ORIGINE
            _Cadre(title:'Origine', icon:Icons.map_rounded, child: Column(children:[
              _RowInfo(label:'Province origine', value:p.originProvince??'—'),
              _RowInfo(label:'Territoire', value:p.originTerritory??'—'),
              _RowInfo(label:'Secteur', value:p.originSector??'—'),
            ])),
            const SizedBox(height:16),
            // RESIDENCE ACTUELLE
            _Cadre(title:'Résidence actuelle', icon:Icons.home_work_rounded, child: Column(children:[
              _RowInfo(label:'Pays', value:p.residenceCountry??'—'),
              _RowInfo(label:'Province', value:p.residenceProvince??'—'),
              _RowInfo(label:'Territoire', value:p.residenceTerritory??'—'),
              _RowInfo(label:'Ville', value:p.residenceCity??'—'),
              _RowInfo(label:'Commune', value:p.residenceCommune??'—'),
              _RowInfo(label:'Quartier', value:p.residenceQuarter??'—'),
              _RowInfo(label:'Avenue', value:p.residenceAvenue??'—'),
              _RowInfo(label:'Numéro', value:p.residenceNumber??'—'),
            ])),
            const SizedBox(height:16),
            // CONTACT URGENCE
            _Cadre(title:'Contact d\'urgence', icon:Icons.contact_emergency_rounded, child: Column(children:[
              _RowInfo(label:'Nom', value:p.emergencyContactName??'—'),
              _RowInfo(label:'Téléphone', value:p.emergencyContactPhone??'—'),
              _RowInfo(label:'Lien', value:p.emergencyContactRelation??'—'),
              if(p.emergencyContacts.isNotEmpty)...p.emergencyContacts.map((e)=> ListTile(dense:true, contentPadding: EdgeInsets.zero, title: Text((e['name']??'—').toString(), style: const TextStyle(fontSize:13, fontWeight: FontWeight.w700)), subtitle: Text('${e['relation']??''} • ${e['phone']??''}', style: const TextStyle(fontSize:11)))),
            ])),
            const SizedBox(height:16),
            // INFOS PHYSIQUES
            _Cadre(title:'Infos physiques', icon:Icons.monitor_weight_rounded, child: Column(children:[
              _RowInfo(label:'Taille (cm)', value:p.height??'—'),
              _RowInfo(label:'Poids (kg)', value:p.weight??'—'),
              _RowInfo(label:'Groupe sanguin', value:p.bloodGroup??'—'),
              _RowInfo(label:'Handicap physique', value: (p.hasPhysicalDisability??false)? 'Oui - ${p.physicalDisabilityDescription??''}' : 'Non'),
            ])),
            const SizedBox(height:16),
            // IDENTITE NATIONALE
            _Cadre(title:'Identité nationale', icon:Icons.verified_user_rounded, child: Column(children:[
              _RowInfo(label:'Numéro identité', value:p.nationalIdNumber??'—'),
              _RowInfo(label:'Type document', value:p.idDocumentType??'—'),
              _RowInfo(label:'Date émission', value:p.idDocumentIssueDate??'—'),
              _RowInfo(label:'Date expiration', value:p.idDocumentExpiryDate??'—'),
              _RowInfo(label:'Lieu émission', value:p.idDocumentIssuePlace??'—'),
              _RowInfo(label:'Statut vérification', value:p.idVerificationStatus??'En attente'),
            ])),
            const SizedBox(height:16),
            // FORMATIONS
            _Cadre(title:'Cursus scolaire • ${c.formations.length}', icon:Icons.school_rounded, child: c.formations.isEmpty? const Text('Aucune formation enregistrée.', style: TextStyle(fontSize:12, color: Colors.black54)) : Column(children: c.formations.map((e)=> ListTile(dense:true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.school, color:_blue, size:18), title: Text((e['institution']??e['school']??'—').toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize:13)), subtitle: Text('${e['degree']??''} • ${e['city']??''} • ${e['startYear']??e['period']??''}', style: const TextStyle(fontSize:11)))).toList())),
            const SizedBox(height:16),
            // EXPERIENCES
            _Cadre(title:'Expérience professionnelle • ${c.experiences.length}', icon:Icons.work_rounded, child: c.experiences.isEmpty? const Text('Aucune expérience enregistrée.', style: TextStyle(fontSize:12, color: Colors.black54)) : Column(children: c.experiences.map((e)=> ListTile(dense:true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.work, color:_blue, size:18), title: Text((e['title']??'—').toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize:13)), subtitle: Text('${e['company']??e['org']??''} • ${e['city']??''} • ${e['date']??e['period']??''}\n${e['tasks']??e['missions']??''}', style: const TextStyle(fontSize:11)))).toList())),
          ]))),
        ],
        const SliverToBoxAdapter(child: SizedBox(height:100)),
      ]);
    })));
  }
}

// WIDGETS UI
class _Cadre extends StatelessWidget {
  final String title; final String? subtitle; final IconData icon; final Widget child;
  const _Cadre({required this.title, this.subtitle, required this.icon, required this.child});
  @override Widget build(BuildContext context)=> Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius:10)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
    Row(children:[Container(width:36,height:36,decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color:_blue, size:18)), const SizedBox(width:10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize:14)), if(subtitle!=null) Text(subtitle!, style: const TextStyle(fontSize:11, color: Colors.black54))]))]),
    const Divider(height:20), child
  ]));
}
class _RowInfo extends StatelessWidget {
  final String label; final String value;
  const _RowInfo({required this.label, required this.value});
  @override Widget build(BuildContext context)=> Padding(padding: const EdgeInsets.symmetric(vertical:6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children:[SizedBox(width:130, child: Text(label, style: const TextStyle(fontSize:11, color: Colors.black54, fontWeight: FontWeight.w700))), const SizedBox(width:8), Expanded(child: Text(value.isEmpty? '—' : value, style: const TextStyle(fontSize:13, fontWeight: FontWeight.w600, height:1.3)))]));
}
class _RefHeader extends StatelessWidget { final ThixProfile p; final VoidCallback onBack; const _RefHeader({required this.p, required this.onBack}); @override Widget build(BuildContext context)=> Stack(clipBehavior: Clip.none, children:[Container(height:230, decoration: const BoxDecoration(color:_blue, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)), gradient: LinearGradient(colors: [_blue,_blueDark]))), SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(12,10,12,0), child: Row(children:[InkWell(onTap:onBack, child: Container(width:38,height:38,decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.arrow_back, color: Colors.white))), const Spacer(), const Text('Profil Public Vérifié', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))]))), Positioned(top:110, left:16, right:16, child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius:20)]), child: Row(children:[CircleAvatar(radius:38, backgroundImage: p.photoUrl?.isNotEmpty==true? NetworkImage(p.photoUrl!):null), const SizedBox(width:12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(p.displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize:18)), Text('THIX ID: ${p.thixId}', style: const TextStyle(fontSize:11, color: Colors.black54))]))])))]); }
class _RefStats extends StatelessWidget { final int d,e; const _RefStats({required this.d, required this.e}); @override Widget build(BuildContext context)=> Container(margin: const EdgeInsets.only(top:52), padding: const EdgeInsets.symmetric(vertical:14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Row(children:[Expanded(child: Column(children:[const Icon(Icons.school, color:_blue), Text('$d', style: const TextStyle(fontWeight: FontWeight.w900)), const Text('Diplômes', style: TextStyle(fontSize:10))])), Expanded(child: Column(children:[const Icon(Icons.work, color:_blue), Text('$e', style: const TextStyle(fontWeight: FontWeight.w900)), const Text('Expériences', style: TextStyle(fontSize:10))]))])); }
class _GateCard extends StatelessWidget { final PublicProfileCtrl ctrl; const _GateCard({required this.ctrl}); @override Widget build(BuildContext context){ final s=ctrl.accessState; String label='Demander l’accès'; if(s?.status==AccessRequestStatus.pending) label='En attente...'; return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _blue.withOpacity(0.15))), child: Column(children:[const Icon(Icons.lock_rounded, size:32, color:_blue), const SizedBox(height:8), const Text('Profil privé - toutes les informations sont protégées', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height:8), FilledButton(onPressed: s?.status==AccessRequestStatus.pending? null : () async { final me=context.read<AuthController>().currentUser; if(me==null){ context.go(AppRoutes.login); return; } await ctrl.requestAccess(me.id); }, style: FilledButton.styleFrom(backgroundColor:_blue), child: Text(label))])) ; } }
