import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ CORRIGÉ : Imports relatifs exacts
import '../providers/education_provider.dart' hide certificatesProvider;
import '../providers/certificate_provider.dart';

import '../widgets/common/education_category_chip.dart';
import '../widgets/common/formation_card.dart';
import '../widgets/common/edu_image.dart';
import '../models/category.dart';
import '../models/formation.dart';
import '../models/certificate.dart';

class _EduColors {
  static const navyDeep = Color(0xFF0A1F44); static const navy = Color(0xFF123B7A);
  static const primaryBlue = Color(0xFF2D6CDF); static const softBlue = Color(0xFFEFF5FF);
  static const background = Color(0xFFF7FAFF); static const pureWhite = Color(0xFFFFFFFF);
  static const darkText = Color(0xFF10192E); static const mutedText = Color(0xFF7386A8);
  static const border = Color(0xFFE7EEFC); static const gold = Color(0xFFE3B23C); static const green = Color(0xFF10B981);
}

class EducationHome extends ConsumerStatefulWidget {
  const EducationHome({super.key});
  @override
  ConsumerState<EducationHome> createState() => _EducationHomeState();
}

class _EducationHomeState extends ConsumerState<EducationHome> {
  int _selectedIndex = 0;
  final _pages = const [_HomePage(), _MyLearningPage(), _AllFormationsPage(), _CertificatesPage(), _LibraryPage(), _ProfilePage()];
  final _titles = ['Accueil','Mes cours','Apprendre','Certificats','Bibliothèque','Profil'];
  final _navIcons = [Icons.home_rounded, Icons.book_rounded, Icons.school_rounded, Icons.verified_rounded, Icons.library_books_rounded, Icons.person_rounded];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _EduColors.background,
      appBar: PreferredSize(preferredSize: const Size.fromHeight(72), child: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [_EduColors.navyDeep, _EduColors.navy, _EduColors.primaryBlue]), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(26), bottomRight: Radius.circular(26))),
        child: SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(10)), child: Icon(_navIcons[_selectedIndex], size: 16, color: _EduColors.gold)),
          const SizedBox(width: 9), Expanded(child: Text(_titles[_selectedIndex], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white))),
          if(_selectedIndex==0) InkWell(onTap: ()=>context.push('/education/search'), child: Container(width:34,height:34,margin:const EdgeInsets.symmetric(horizontal:2), decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.search_rounded, color: Colors.white, size: 17))),
        ]))),
      )),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(14,0,14,10),
        decoration: BoxDecoration(color: _EduColors.pureWhite, borderRadius: BorderRadius.circular(26), boxShadow: [BoxShadow(color: _EduColors.navyDeep.withOpacity(0.12), blurRadius: 22, offset: const Offset(0,9))]),
        child: SafeArea(top:false, child: Padding(padding: const EdgeInsets.symmetric(vertical:6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(_titles.length, (i) => InkWell(
          borderRadius: BorderRadius.circular(14), onTap: ()=>setState(()=>_selectedIndex=i),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal:5,vertical:3), child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: _selectedIndex==i? _EduColors.softBlue : Colors.transparent, borderRadius: BorderRadius.circular(12)), child: Icon(_navIcons[i], color: _selectedIndex==i? _EduColors.primaryBlue : _EduColors.mutedText, size:20)),
            const SizedBox(height:2), Text(_titles[i], style: TextStyle(fontSize:9, color: _selectedIndex==i? _EduColors.primaryBlue : _EduColors.mutedText, fontWeight: _selectedIndex==i? FontWeight.w800 : FontWeight.w500))
          ])),
        ))))),
      ),
    );
  }
}

class _HomePage extends ConsumerStatefulWidget { const _HomePage(); @override ConsumerState<_HomePage> createState() => _HomePageState(); }
class _HomePageState extends ConsumerState<_HomePage> {
  final _scrollController = ScrollController();
  @override
  void initState() { super.initState(); _scrollController.addListener((){ if(_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 300) { ref.read(formationsProvider.notifier).loadMore(); }}); }
  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final formationsAsync = ref.watch(formationsProvider);
    return formationsAsync.when(
      loading: ()=>const Center(child: CircularProgressIndicator(color: _EduColors.primaryBlue)),
      error: (e,_ )=>Center(child: Text('Erreur: $e')),
      data: (paginated){
        final formations = paginated.items;
        final featured = formations.isNotEmpty? formations.first : null;
        return RefreshIndicator(onRefresh: () async => ref.invalidate(formationsProvider), child: SingleChildScrollView(controller: _scrollController, padding: const EdgeInsets.fromLTRB(16,16,16,12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if(featured!=null) _FeaturedBanner(formation: featured),
          const SizedBox(height:22), const Text('Catégories', style: TextStyle(fontSize:16.5,fontWeight:FontWeight.w800,color:_EduColors.darkText)), const SizedBox(height:10),
          categoriesAsync.when(data: (cats)=>SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            EducationCategoryChip(label: 'Tous', isSelected: ref.read(formationsProvider.notifier).currentCategory==null, onTap: ()=>ref.read(formationsProvider.notifier).filterByCategory(null)),
           ...cats.map((cat)=>Padding(padding: const EdgeInsets.only(left:8), child: EducationCategoryChip(label: cat.name, isSelected: ref.read(formationsProvider.notifier).currentCategory==cat.id, onTap: ()=>ref.read(formationsProvider.notifier).filterByCategory(cat.id)))),
          ])), loading: ()=>const SizedBox(height:32), error: (_,__ )=>const SizedBox()),
          const SizedBox(height:22), const Text('Toutes les formations', style: TextStyle(fontSize:16.5,fontWeight:FontWeight.w800,color:_EduColors.darkText)), const SizedBox(height:10),
          GridView.builder(shrinkWrap:true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2, childAspectRatio:0.7, crossAxisSpacing:12, mainAxisSpacing:12), itemCount: formations.length + (paginated.hasMore? 2 : 0), itemBuilder: (c,i){
            if(i>=formations.length) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
            return FormationCard(formation: formations[i], onTap: ()=>context.push('/education/formation/${formations[i].id}'));
          }),
          if(paginated.isLoadingMore) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())), const SizedBox(height:32),
        ])));
      },
    );
  }
}

class _FeaturedBanner extends StatelessWidget {
  final Formation formation; const _FeaturedBanner({required this.formation});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: ()=>context.push('/education/formation/${formation.id}'), child: Container(height:148, decoration: BoxDecoration(gradient: const LinearGradient(colors: [_EduColors.navyDeep, _EduColors.navy, _EduColors.primaryBlue]), borderRadius: BorderRadius.circular(24)), padding: const EdgeInsets.all(20), child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal:10,vertical:4), decoration: BoxDecoration(color: _EduColors.gold, borderRadius: BorderRadius.circular(12)), child: const Text('À LA UNE', style: TextStyle(color:_EduColors.navyDeep,fontSize:10.5,fontWeight:FontWeight.w800))),
        const SizedBox(height:8), Text(formation.title, style: const TextStyle(color:Colors.white,fontSize:17,fontWeight:FontWeight.w800,height:1.2), maxLines:2, overflow:TextOverflow.ellipsis),
        const SizedBox(height:6), Row(children: [const Icon(Icons.star_rounded,color:Color(0xFFFBBF24),size:16), const SizedBox(width:4), Text(formation.rating.toStringAsFixed(1), style: const TextStyle(color:Colors.white,fontWeight:FontWeight.w700))]),
      ])), const SizedBox(width:10), EduImage(url: formation.imageUrl, width:84, height:84, radius: BorderRadius.circular(18)),
    ])));
  }
}

class _MyLearningPage extends ConsumerWidget {
  const _MyLearningPage();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    if(userId==null) return const Center(child: Text('Non connecté'));
    final enrollAsync = ref.watch(myEnrollmentsProvider(userId));
    return enrollAsync.when(loading: ()=>const Center(child: CircularProgressIndicator()), error: (e,_ )=>Center(child: Text('$e')), data: (list){
      if(list.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width:84,height:84,decoration: const BoxDecoration(color:_EduColors.softBlue,shape:BoxShape.circle), child: Icon(Icons.book_rounded,size:36,color:_EduColors.navy.withOpacity(0.5))), const SizedBox(height:16), const Text('Aucune formation en cours', style: TextStyle(fontWeight:FontWeight.w800))]));
      return ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length, itemBuilder: (c,i){
        final enrollment = list[i]; 
        final formation = enrollment.formation; 
        if(formation == null) return const SizedBox();
        return Padding(
          padding: const EdgeInsets.only(bottom:12), 
          child: FormationCard(
            formation: formation, 
            onTap: ()=>context.push('/education/formation/${formation.id}'), 
            progress: enrollment.progress?.toDouble(),
          )
        );
      });
    });
  }
}

class _AllFormationsPage extends ConsumerWidget {
  const _AllFormationsPage();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formationsAsync = ref.watch(formationsProvider);
    return formationsAsync.when(loading: ()=>const Center(child: CircularProgressIndicator()), error: (e,_ )=>Center(child: Text('$e')), data: (paginated)=>ListView.builder(padding: const EdgeInsets.all(16), itemCount: paginated.items.length, itemBuilder: (c,i)=>Padding(padding: const EdgeInsets.only(bottom:12), child: FormationCard(formation: paginated.items[i], onTap: ()=>context.push('/education/formation/${paginated.items[i].id}')))));
  }
}

class _CertificatesPage extends ConsumerWidget {
  const _CertificatesPage();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider); if(userId==null) return const Center(child: Text('Non connecté'));
    final certsAsync = ref.watch(certificatesProvider(userId));
    return certsAsync.when(loading: ()=>const Center(child: CircularProgressIndicator()), error: (e,_ )=>Center(child: Text('$e')), data: (certs){
      if(certs.isEmpty) return const Center(child: Text('Aucun certificat'));
      return ListView.builder(padding: const EdgeInsets.all(16), itemCount: certs.length, itemBuilder: (c,i){
        final cert = certs[i]; return Container(margin: const EdgeInsets.only(bottom:12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color:_EduColors.pureWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color:_EduColors.border)), child: Row(children: [Container(width:52,height:52,decoration: BoxDecoration(gradient: const LinearGradient(colors:[_EduColors.navyDeep,_EduColors.primaryBlue]), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.verified_rounded,color:Colors.white,size:28)), const SizedBox(width:14), Expanded(child: Text('Délivré le ${cert.issuedAt.day}/${cert.issuedAt.month}/${cert.issuedAt.year}')), IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: ()=>context.push('/education/certificate/${cert.id}', extra: cert))]));
      });
    });
  }
}

class _LibraryPage extends StatelessWidget { const _LibraryPage(); @override Widget build(BuildContext context) => const Center(child: Text('Bibliothèque - Bientôt')); }
class _ProfilePage extends ConsumerWidget {
  const _ProfilePage();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width:100,height:100,decoration: BoxDecoration(shape:BoxShape.circle, gradient: const LinearGradient(colors:[_EduColors.navyDeep,_EduColors.primaryBlue])), child: const Icon(Icons.person_rounded,size:48,color:Colors.white)),
      const SizedBox(height:18), Text(user?.email?? 'Utilisateur', style: const TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
      const SizedBox(height:26), SizedBox(width:double.infinity, child: ElevatedButton.icon(onPressed: ()=>context.push('/instructor/dashboard'), icon: const Icon(Icons.school_rounded), label: const Text('Passer en mode formateur'), style: ElevatedButton.styleFrom(backgroundColor:_EduColors.green,foregroundColor:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(30))))),
    ])));
  }
}
