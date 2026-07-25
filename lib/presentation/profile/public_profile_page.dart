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
import 'package:url_launcher/url_launcher.dart';

const _blue = Color(0xFF0D2CC1);
const _blueDark = Color(0xFF0A1E8A);
const _pageSize = 20;

Future<void> safeLaunch(BuildContext context, String url) async {
  try {
    final uri = Uri.parse(url.trim());
    if (!['https','http'].contains(uri.scheme)) throw Exception('blocked');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch(_) {
    if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ouverture impossible')));
  }
}

class PublicProfileCtrl extends ChangeNotifier {
  final _profiles = ProfileService();
  final _docs = DocumentService();
  final _access = AccessRequestService();
  ThixProfile? profile;
  bool loading = true;
  String? error;
  AccessRequestState? accessState;
  List<Map<String,dynamic>> formations = [];
  List<Map<String,dynamic>> experiences = [];
  List<Map<String,dynamic>> documents = [];
  bool hasMoreDocs = true;
  bool loadingMore = false;
  int _docOffset = 0;
  StreamSubscription? _accessSub;

  Future<void> init(String thixId, String? viewerId) async {
    loading = true; error=null; notifyListeners();
    try {
      profile = await _profiles.fetchPublicProfileByThixId(thixId.toUpperCase());
      if(profile == null) { error = 'THIX ID introuvable'; loading=false; notifyListeners(); return; }
      final res = await Future.wait([
        _profiles.fetchFormationsPaginated(profile!.userId, limit: _pageSize, offset: 0),
        _profiles.fetchExperiencesPaginated(profile!.userId, limit: _pageSize, offset: 0),
        _docs.fetchDocumentsPaginated(profile!.userId, limit: _pageSize, offset: 0),
      ]);
      formations = (res[0] as List).cast<Map<String,dynamic>>();
      experiences = (res[1] as List).cast<Map<String,dynamic>>();
      documents = (res[2] as List).cast<Map<String,dynamic>>();
      if(formations.isEmpty && profile!.education.isNotEmpty){
        formations = profile!.education.map((e)=> (e is Map? e.cast<String,dynamic>() : <String,dynamic>{'title': e.toString()})).toList();
      }
      if(experiences.isEmpty && profile!.experience.isNotEmpty){
        experiences = profile!.experience.map((e)=> (e is Map? e.cast<String,dynamic>() : <String,dynamic>{'title': e.toString()})).toList();
      }
      _docOffset = documents.length;
      hasMoreDocs = documents.length == _pageSize;
      _accessSub?.cancel();
      if(viewerId!= null && viewerId!= profile!.userId) {
        _accessSub = _access.streamState(requesterId: viewerId, targetUserId: profile!.userId).listen((s){ accessState=s; notifyListeners(); });
      }
    } catch(e){ debugPrint('PublicCtrl $e'); error = 'Erreur réseau. Réessayez.'; }
    finally{ loading=false; notifyListeners(); }
  }

  Future<void> requestAccess(String requesterId) async {
    if(profile==null) return;
    await _access.requestAccess(requesterId: requesterId, targetUserId: profile!.userId, thixId: profile!.thixId);
  }

  bool get canSeePrivate => accessState?.isActiveAt(DateTime.now().toUtc())?? false;
  @override void dispose(){ _accessSub?.cancel(); super.dispose(); }
}

class PublicProfilePage extends StatefulWidget {
  final String? initialThixId; const PublicProfilePage({super.key, this.initialThixId});
  @override State<PublicProfilePage> createState() => _PState();
}
class _PState extends State<PublicProfilePage> {
  late final ctrl = PublicProfileCtrl();
  @override void initState(){ super.initState(); WidgetsBinding.instance.addPostFrameCallback((_){
    final me = context.read<AuthController>().currentUser;
    if(widget.initialThixId!=null) ctrl.init(widget.initialThixId!, me?.id);
  });}
  @override void dispose(){ ctrl.dispose(); super.dispose();}
  @override Widget build(BuildContext context){
    return ChangeNotifierProvider.value(value: ctrl, child: Scaffold(backgroundColor: const Color(0xFFF5F6FB), body: Consumer<PublicProfileCtrl>(builder: (_,c,__){
      if(c.loading) return const Center(child: CircularProgressIndicator(color: _blue));
      if(c.error!=null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(c.error!), const SizedBox(height:12), FilledButton(onPressed: ()=> c.init(widget.initialThixId!, context.read<AuthController>().currentUser?.id), child: const Text('Réessayer'))]));
      final p = c.profile!;
      final meId = context.read<AuthController>().currentUser?.id;
      final isOwner = meId!=null && meId==p.userId;
      final canSee = isOwner || c.canSeePrivate;

      return CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _RefHeader(p: p, onBack: ()=>context.go(AppRoutes.home))),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _RefStats(
          diplomes: canSee? c.formations.length : 0,
          certs: canSee? c.formations.where((e)=> (e['type']??'').toString().toLowerCase().contains('cert')).length : 0,
          exps: canSee? c.experiences.length : 0
        ))),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        if(!canSee)...[
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _GateCard(ctrl: c))),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: const Column(children: [Icon(Icons.lock_rounded, size:48, color: _blue), SizedBox(height:12), Text('Profil privé', style: TextStyle(fontWeight: FontWeight.w800, fontSize:16)), SizedBox(height:6), Text('Ce profil est privé. Demandez l’accès pour voir les informations vérifiées.', textAlign: TextAlign.center, style: TextStyle(fontSize:13, color: Colors.black54))])))),
        ],
        if(canSee)...[
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: _VerifiedCard())),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _WhiteCard(title: 'Biographie', child: Text((p.bio?.trim().isEmpty??true)? 'Aucune biographie.' : p.bio!, style: const TextStyle(height: 1.5, fontSize:13))))),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _WhiteCard(title: 'Formations • ${c.formations.length}', child: c.formations.isEmpty? const Text('—') : Column(children: c.formations.map((f)=> ListTile(dense:true, contentPadding: EdgeInsets.zero, leading: Container(width:32,height:32,decoration: BoxDecoration(color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.school, size:18, color:_blue)), title: Text((f['degree']??f['title']??'Formation').toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize:13)), subtitle: Text((f['institution']??f['school']??'').toString(), style: const TextStyle(fontSize:11, color:Colors.black54)),)).toList())))),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _WhiteCard(title: 'Expériences • ${c.experiences.length}', child: c.experiences.isEmpty? const Text('—') : Column(children: c.experiences.map((e)=> ListTile(dense:true, contentPadding: EdgeInsets.zero, leading: Container(width:32,height:32,decoration: BoxDecoration(color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.work, size:18, color:_blue)), title: Text((e['title']??e['position']??'Expérience').toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize:13)), subtitle: Text((e['company']??'').toString(), style: const TextStyle(fontSize:11, color:Colors.black54)),)).toList())))),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _WhiteCard(title: 'Compétences', child: (p.skills.isEmpty && (p.competence?.isEmpty??true))? const Text('—') : Wrap(spacing:6, runSpacing:6, children: [...p.skills.map((s)=> Chip(label: Text((s['name']??s.toString()).toString(), style: const TextStyle(fontSize:11)), backgroundColor: const Color(0xFFEFF4FF), side: BorderSide.none)), if(p.competence?.isNotEmpty??false) Chip(label: Text(p.competence!, style: const TextStyle(fontSize:11)))])))),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ]);
    })));
  }
}

class _RefHeader extends StatelessWidget {
  final ThixProfile p; final VoidCallback onBack;
  const _RefHeader({required this.p, required this.onBack});
  @override Widget build(BuildContext context){
    return Stack(clipBehavior: Clip.none, children: [
      Container(height: 230, decoration: const BoxDecoration(color: _blue, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)), gradient: LinearGradient(colors: [_blue,_blueDark], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
      SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(12,10,12,0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          InkWell(onTap: onBack, child: Container(width:38,height:38,decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.arrow_back, color: Colors.white))),
          const Spacer(),
          const Icon(Icons.verified_user, color: Colors.amber), const SizedBox(width:6),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('THIX ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize:12)), Text('Identité Vérifiée', style: TextStyle(color: Colors.white70, fontSize:10))]),
          const Spacer(),
          Container(width:38,height:38,decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.grid_view, color: Colors.white)),
        ]),
        const SizedBox(height: 22),
        const Padding(padding: EdgeInsets.only(left:8), child: Text('Profil Public', style: TextStyle(color: Colors.white, fontSize:26, fontWeight: FontWeight.w800))),
        const Padding(padding: EdgeInsets.only(left:8), child: Text('Informations privées protégées', style: TextStyle(color: Colors.white70, fontSize:13))),
      ]))),
      Positioned(top: 135, left:16, right:16, child: _ProfileCard(p: p)),
    ]);
  }
}

class _ProfileCard extends StatelessWidget {
  final ThixProfile p; const _ProfileCard({required this.p});
  @override Widget build(BuildContext context){
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)]), child: Row(children: [
      Stack(children: [
        Container(padding: const EdgeInsets.all(2.5), decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle), child: CircleAvatar(radius: 38, backgroundImage: p.photoUrl==null||p.photoUrl!.isEmpty?null:NetworkImage(p.photoUrl!), backgroundColor: const Color(0xFFEAF0FF))),
        Positioned(bottom:2,right:2, child: Container(width:22,height:22,decoration: BoxDecoration(color:_blue, shape: BoxShape.circle, border: Border.all(color:Colors.white,width:2)), child: const Icon(Icons.check, size:12,color:Colors.white))),
      ]),
      const SizedBox(width:12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p.displayName, style: const TextStyle(fontSize:18,fontWeight: FontWeight.w800)),
        Row(children: [Flexible(child: Text('THIX ID: ${p.thixId}', style: const TextStyle(fontSize:11, color: Colors.black54, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)), const SizedBox(width:6), InkWell(onTap: (){Clipboard.setData(ClipboardData(text: p.thixId)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('THIX ID copié')));}, child: const Icon(Icons.copy, size:14, color: Colors.black54))]),
        const SizedBox(height:6),
        Container(padding: const EdgeInsets.symmetric(horizontal:10,vertical:5), decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(20)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.verified, size:12,color:Colors.white), SizedBox(width:4), Text('Identité Vérifiée', style: TextStyle(color:Colors.white, fontSize:10, fontWeight: FontWeight.w700))])),
        const SizedBox(height:4),
        const Text('Profil privé - accès sur demande', style: TextStyle(fontSize:11, color: Colors.grey)),
      ])),
    ]));
  }
}

class _RefStats extends StatelessWidget {
  final int diplomes, certs, exps; const _RefStats({required this.diplomes, required this.certs, required this.exps});
  @override Widget build(BuildContext context){
    Widget item(IconData ic, String v, String l)=> Expanded(child: Column(children: [Icon(ic, color: _blue, size:22), const SizedBox(height:4), Text(v, style: const TextStyle(fontWeight: FontWeight.w900, fontSize:16)), Text(l, style: const TextStyle(fontSize:10, color: Colors.black54))]));
    return Container(margin: const EdgeInsets.only(top:52), padding: const EdgeInsets.symmetric(vertical:14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius:12)]), child: Row(children: [
      item(Icons.school, '$diplomes', 'Diplômes'), Container(width:1,height:30,color:Colors.black12),
      item(Icons.workspace_premium, '$certs', 'Certifications'), Container(width:1,height:30,color:Colors.black12),
      item(Icons.work, '$exps', 'Expériences'), Container(width:1,height:30,color:Colors.black12),
      item(Icons.forum, '0', 'Consultations'),
    ]));
  }
}

class _VerifiedCard extends StatelessWidget {
  @override Widget build(BuildContext context)=> Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFD6E3FF))), child: Row(children: [
    Container(width:42,height:42,decoration: const BoxDecoration(color:_blue, shape: BoxShape.circle), child: const Icon(Icons.verified_user, color: Colors.white)), const SizedBox(width:10),
    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Identité Vérifiée', style: TextStyle(fontWeight: FontWeight.w800, fontSize:13)), Text('Ce profil est privé. Les informations ci-dessous sont visibles uniquement après approbation.', style: TextStyle(fontSize:11, color: Colors.black54, height:1.3))])),
    const Icon(Icons.shield_outlined, size:44, color: Color(0xFFB9C9F5)),
  ]));
}

class _WhiteCard extends StatelessWidget {
  final String title; final Widget child; const _WhiteCard({required this.title, required this.child});
  @override Widget build(BuildContext context)=> Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius:10)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const Divider(height:20), child]));
}

class _GateCard extends StatelessWidget {
  final PublicProfileCtrl ctrl; const _GateCard({required this.ctrl});
  @override Widget build(BuildContext context){
    final state = ctrl.accessState;
    final expired = state?.status==AccessRequestStatus.approved &&!(state?.isActiveAt(DateTime.now().toUtc())??false);
    String label = 'Demander l’accès';
    if(state?.status==AccessRequestStatus.pending) label='Demande en attente...';
    if(state?.status==AccessRequestStatus.rejected) label='Redemander l’accès';
    if(expired) label='Accès expiré - Redemander';
    final enabled = state?.status!=AccessRequestStatus.pending;
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _blue.withOpacity(0.15))), child: Column(children: [
      const Text('Accès restreint - Profil privé', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height:8),
      const Text('Le propriétaire doit approuver votre demande. Accès valable 10 minutes.', style: TextStyle(fontSize:11, color: Colors.black54), textAlign: TextAlign.center), const SizedBox(height:12),
      FilledButton(style: FilledButton.styleFrom(backgroundColor: _blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), minimumSize: const Size(double.infinity, 44)), onPressed:!enabled? null : () async {
        final me = context.read<AuthController>().currentUser;
        if(me==null){ context.go(AppRoutes.login); return; }
        if(ctrl.profile==null) return;
        await ctrl.requestAccess(me.id);
        if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande envoyée - 10 min après approbation')));
      }, child: Text(label)),
      if(state?.approvedUntil!=null &&!expired) Padding(padding: const EdgeInsets.only(top:8), child: Text('Expire à ${state!.approvedUntil!.toLocal().toString().split('.').first}', style: const TextStyle(fontSize:10, color:Colors.green, fontWeight: FontWeight.w700))),
    ]));
  }
}
