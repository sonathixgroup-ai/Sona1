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
import 'package:thix_id/services/notification_service.dart';
import 'package:thix_id/supabase/supabase_config.dart';
import 'package:url_launcher/url_launcher.dart';

const _blue = Color(0xFF0D2CC1);
const _blueDark = Color(0xFF0A1E8A);
const _pageSize = 20;

// --- SECURE LAUNCHER ---
Future<void> safeLaunch(BuildContext context, String url) async {
  try {
    final uri = Uri.parse(url.trim());
    if (!['https','http'].contains(uri.scheme)) throw Exception('blocked');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch(_) {
    if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ouverture impossible')));
  }
}

// --- CONTROLLER ULTRA SCALABLE ---
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
    loading = true; notifyListeners();
    try {
      profile = await _profiles.fetchPublicProfileByThixId(thixId.toUpperCase());
      if(profile == null) { error = 'THIX ID introuvable'; return; }
      // Chargement initial paginé en parallèle
      final res = await Future.wait([
        _profiles.fetchFormationsPaginated(profile!.userId, limit: _pageSize, offset: 0),
        _profiles.fetchExperiencesPaginated(profile!.userId, limit: _pageSize, offset: 0),
        _docs.fetchDocumentsPaginated(profile!.userId, limit: _pageSize, offset: 0),
      ]);
      formations = res[0] as List<Map<String,dynamic>>;
      experiences = res[1] as List<Map<String,dynamic>>;
      documents = res[2] as List<Map<String,dynamic>>;
      _docOffset = documents.length;
      hasMoreDocs = documents.length == _pageSize;
      if(viewerId!= null && viewerId!= profile!.userId) {
        _accessSub = _access.streamState(requesterId: viewerId, targetUserId: profile!.userId).listen((s){ accessState=s; notifyListeners(); });
      }
    } catch(e){ error = 'Erreur réseau. Réessayez.'; }
    finally{ loading=false; notifyListeners(); }
  }

  Future<void> loadMoreDocs() async {
    if(loadingMore ||!hasMoreDocs || profile==null) return;
    loadingMore=true; notifyListeners();
    try{
      final more = await _docs.fetchDocumentsPaginated(profile!.userId, limit: _pageSize, offset: _docOffset);
      documents.addAll(more); _docOffset+=more.length; hasMoreDocs = more.length==_pageSize;
    } finally{ loadingMore=false; notifyListeners(); }
  }

  bool get canSeePrivate => accessState?.isActiveAt(DateTime.now().toUtc())?? false;
  @override void dispose(){ _accessSub?.cancel(); super.dispose(); }
}

// --- PAGE ---
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
      if(c.error!=null) return Center(child: Text(c.error!));
      final p = c.profile!;
      return CustomScrollView(slivers: [
        // HEADER BLEU REF PHOTO
        SliverToBoxAdapter(child: _RefHeader(p: p, onBack: ()=>context.go(AppRoutes.home))),
        // STATS
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _RefStats(diplomes: p.education.length, certs: c.formations.length, exps: c.experiences.length))),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        // GATE seulement si privé
        if(!c.canSeePrivate) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _GateCard(ctrl: c))),
        // BADGE VERIFIE REF PHOTO
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: _VerifiedCard())),
        // BIO
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _WhiteCard(title: 'Biographie', child: Text(p.bio?.isEmpty??true? '—' : p.bio!, style: const TextStyle(height: 1.5))))),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ]);
    })));
  }
}

// --- WIDGETS REF DESIGN ---
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
        const Padding(padding: EdgeInsets.only(left:8), child: Text('Informations publiques vérifiées', style: TextStyle(color: Colors.white70, fontSize:13))),
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
        Row(children: [Flexible(child: Text('THIX ID: ${p.thixId}', style: const TextStyle(fontSize:11, color: Colors.black54, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)), const SizedBox(width:6), InkWell(onTap: (){Clipboard.setData(ClipboardData(text: p.thixId));}, child: const Icon(Icons.copy, size:14, color: Colors.black54))]),
        const SizedBox(height:6),
        Container(padding: const EdgeInsets.symmetric(horizontal:10,vertical:5), decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(20)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.verified, size:12,color:Colors.white), SizedBox(width:4), Text('Identité Vérifiée', style: TextStyle(color:Colors.white, fontSize:10, fontWeight: FontWeight.w700))])),
        const SizedBox(height:4),
        const Text('Membre depuis mars 2025', style: TextStyle(fontSize:11, color: Colors.grey)),
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
    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Identité Vérifiée', style: TextStyle(fontWeight: FontWeight.w800, fontSize:13)), Text('Ce profil a été vérifié par THIX ID. Les informations publiques ci-dessous ont été vérifiées et sont authentiques.', style: TextStyle(fontSize:11, color: Colors.black54, height:1.3))])),
    const Icon(Icons.shield_outlined, size:44, color: Color(0xFFB9C9F5)),
  ]));
}

class _WhiteCard extends StatelessWidget {
  final String title; final Widget child; const _WhiteCard({required this.title, required this.child});
  @override Widget build(BuildContext context)=> Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const Divider(height:20), child]));
}

class _GateCard extends StatelessWidget {
  final PublicProfileCtrl ctrl; const _GateCard({required this.ctrl});
  @override Widget build(BuildContext context)=> Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _blue.withOpacity(0.15))), child: Column(children: [
    const Text('Accès restreint', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height:8),
    FilledButton(style: FilledButton.styleFrom(backgroundColor: _blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), onPressed: () async {
      final me = context.read<AuthController>().currentUser; if(me==null||ctrl.profile==null) return;
      await ctrl._access.requestAccess(requesterId: me.id, targetUserId: ctrl.profile!.userId, thixId: ctrl.profile!.thixId);
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande envoyée')));
    }, child: const Text('Demander l’accès')),
  ]));
}
