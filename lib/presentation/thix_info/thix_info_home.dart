import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/news_provider.dart';
import '../../models/news_article.dart';

const _kBlue = Color(0xFF0B3D91);
const _kGold = Color(0xFFFFB800);
const _kBg = Color(0xFFF7F8FB);
const _kWhite = Colors.white;
const _kDark = Color(0xFF101840);
const _kMuted = Color(0xFF8A8FA8);
const _kBorder = Color(0xFFECEEF4);

class ThixInfoHome extends StatefulWidget {
  const ThixInfoHome({super.key});
  @override State<ThixInfoHome> createState() => _ThixInfoHomeState();
}

class _ThixInfoHomeState extends State<ThixInfoHome> {
  String _cat = 'featured';
  int _nav = 0;
  final PageController _pageCtrl = PageController();
  Timer? _timer;
  int _currentPage = 0;

  final cats = [
    {'slug':'featured','name':'À la une'},
    {'slug':'politique','name':'Politique'},
    {'slug':'economie','name':'Économie'},
    {'slug':'societe','name':'Société'},
    {'slug':'tech','name':'Tech'},
    {'slug':'sport','name':'Sport'},
  ];

  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().fetchArticles(category: 'all');
      context.read<NewsProvider>().fetchVideos();
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final prov = context.read<NewsProvider>();
      final list = prov.articles.where((a)=>a.isFeatured).toList();
      if (list.isEmpty) return;
      _currentPage = (_currentPage + 1) % list.length;
      if (_pageCtrl.hasClients) _pageCtrl.animateToPage(_currentPage, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  @override void dispose() { _timer?.cancel(); _pageCtrl.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final prov = context.watch<NewsProvider>();
    final featured = prov.articles.where((a)=>a.isFeatured).toList();
    final recents = prov.articles; // PLUS DE FILTRE PAR CAT - fixe "Aucune actualité"
    final breaking = prov.articles.where((a)=>a.isBreaking).toList();
    final videos = prov.videos.isNotEmpty? prov.videos : prov.articles.where((a)=>a.videoUrl!=null && a.videoUrl!.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _topBar()),
        SliverToBoxAdapter(child: _search()),
        SliverToBoxAdapter(child: _catPills()),
        if (breaking.isNotEmpty) SliverToBoxAdapter(child: _breakingTicker(breaking)),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        SliverToBoxAdapter(child: featured.isNotEmpty? _featuredAutoScroll(featured) : _placeholder()),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        SliverToBoxAdapter(child: _quickActions()),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        SliverToBoxAdapter(child: _header('Actualités récentes','/thix-info/recent')),
        SliverToBoxAdapter(child: _recentCompact(recents)),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverToBoxAdapter(child: _alert()),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverToBoxAdapter(child: _header('Vidéos à la une','/thix-info/videos')),
        SliverToBoxAdapter(child: _videosSection(videos)),
        const SliverToBoxAdapter(child: SizedBox(height: 90)),
      ]),
      bottomNavigationBar: _bottom(),
    );
  }

  Widget _topBar() => Container(color:_kWhite, padding: const EdgeInsets.fromLTRB(12,44,12,8), child: Row(children:[
    IconButton(icon: const Icon(Icons.menu, size:22), onPressed:()=>context.go('/')),
    Container(width:36,height:36,decoration:BoxDecoration(color:_kGold,borderRadius:BorderRadius.circular(10)),child: const Icon(Icons.newspaper, size:18,color:Colors.white)),
    const SizedBox(width:8),
    const Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Text('THIX',style:TextStyle(fontWeight:FontWeight.w900,fontSize:15)),SizedBox(width:4),Text('INFO',style:TextStyle(fontWeight:FontWeight.w900,fontSize:15,color:_kGold))]),Text("L'info vraie, partout.",style:TextStyle(fontSize:10,color:_kMuted))])),
    InkWell(onTap:()=>context.push('/admin'), child: Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6), decoration:BoxDecoration(color:_kGold,borderRadius:BorderRadius.circular(16)), child: const Text('ADMIN',style:TextStyle(fontSize:10,fontWeight:FontWeight.w900)))),
    IconButton(icon: const Badge(label: Text('3'), child: Icon(Icons.notifications_none, size:22)), onPressed: (){}),
  ]));

  Widget _search()=>Container(color:_kWhite,padding:const EdgeInsets.fromLTRB(12,0,12,10),child:Container(height:38,decoration:BoxDecoration(color:_kBg,borderRadius:BorderRadius.circular(12),border:Border.all(color:_kBorder)),padding:const EdgeInsets.symmetric(horizontal:10),child: Row(children:[const Icon(Icons.search,size:18,color:_kMuted),const SizedBox(width:6),const Expanded(child:Text('Rechercher...',style:TextStyle(color:_kMuted,fontSize:12))),Container(width:1,height:18,color:_kBorder),const SizedBox(width:8),const Icon(Icons.tune,size:18)])));

  Widget _catPills()=>SizedBox(height:32,child:ListView.separated(padding:const EdgeInsets.symmetric(horizontal:12),scrollDirection:Axis.horizontal,itemCount:cats.length,separatorBuilder:(_,__)=>const SizedBox(width:6),itemBuilder:(_,i){final c=cats[i];final sel=_cat==c['slug'];return GestureDetector(onTap:(){setState(()=>_cat=c['slug']!); if(c['slug']=='featured'){context.read<NewsProvider>().fetchArticles(category:'all');}else{context.read<NewsProvider>().fetchArticles(category:c['slug']!);}},child:Container(padding:const EdgeInsets.symmetric(horizontal:14),alignment:Alignment.center,decoration:BoxDecoration(color:sel?_kGold:_kWhite,borderRadius:BorderRadius.circular(16),border:Border.all(color:sel?_kGold:_kBorder)),child:Text(c['name']!,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700))));}));

  Widget _breakingTicker(List<NewsArticle> list)=>Container(height:32,color:const Color(0xFFFFE9E9),child:ListView.builder(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:12),itemCount:list.length,itemBuilder:(_,i)=>Row(children:[Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:2),decoration:BoxDecoration(color:Colors.red,borderRadius:BorderRadius.circular(4)),child:const Text('BREAKING',style:TextStyle(color:Colors.white,fontSize:8,fontWeight:FontWeight.w900))),const SizedBox(width:6),Text(list[i].title,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700)),const SizedBox(width:20)])));

  Widget _featuredAutoScroll(List<NewsArticle> list)=>SizedBox(height:150,child:PageView.builder(controller:_pageCtrl,onPageChanged:(i)=>_currentPage=i,itemCount:list.length,itemBuilder:(_,i){final a=list[i];return Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Container(decoration:BoxDecoration(color:_kWhite,borderRadius:BorderRadius.circular(16),border:Border.all(color:_kBorder)),clipBehavior:Clip.antiAlias,child:Row(children:[Expanded(flex:5,child:Padding(padding:const EdgeInsets.all(10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:2),decoration:BoxDecoration(color:_kGold.withOpacity(0.2),borderRadius:BorderRadius.circular(4)),child:const Text('À LA UNE',style:TextStyle(fontSize:8,fontWeight:FontWeight.w900))),const SizedBox(height:6),Text(a.title,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w900,height:1.1)),const SizedBox(height:4),Text(a.summary??'',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10,color:_kMuted)),const Spacer(),SizedBox(height:26,child:ElevatedButton(onPressed:()=>context.push('/thix-info/article/${a.id}'),style:ElevatedButton.styleFrom(backgroundColor:_kGold,padding:const EdgeInsets.symmetric(horizontal:10),minimumSize:const Size(0,26)),child:const Text("Lire",style:TextStyle(fontSize:11,fontWeight:FontWeight.w800,color:Colors.black))))]))),Expanded(flex:5,child:Stack(children:[Positioned.fill(child:a.imageUrl!=null?Image.network(a.imageUrl!,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Container(color:_kBlue)):Container(color:_kBlue)),Positioned(bottom:6,left:0,right:0,child:Row(mainAxisAlignment:MainAxisAlignment.center,children:List.generate(list.length,(d)=>Container(margin:const EdgeInsets.symmetric(horizontal:2),width:d==_currentPage?14:6,height:5,decoration:BoxDecoration(color:d==_currentPage?_kGold:Colors.white70,borderRadius:BorderRadius.circular(4))))))]))])));})));

  Widget _quickActions(){final items=[{'l':'Fil Info','i':Icons.article},{'l':'Vidéos','i':Icons.play_circle},{'l':'Podcasts','i':Icons.headset},{'l':'Magazines','i':Icons.menu_book},{'l':'Communiqués','i':Icons.campaign},{'l':'Alertes','i':Icons.notifications}];return Container(margin:const EdgeInsets.symmetric(horizontal:12),padding:const EdgeInsets.symmetric(vertical:8,horizontal:4),decoration:BoxDecoration(color:_kWhite,borderRadius:BorderRadius.circular(14),border:Border.all(color:_kBorder)),child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:items.map((e)=>Column(children:[Container(width:34,height:34,decoration:BoxDecoration(color:_kBg,borderRadius:BorderRadius.circular(8)),child:Icon(e['i'] as IconData,size:18,color:_kDark)),const SizedBox(height:4),Text(e['l'] as String,style:const TextStyle(fontSize:9,fontWeight:FontWeight.w600))])).toList()));}

  Widget _header(String t,String r)=>Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(t,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w900)),GestureDetector(onTap:()=>context.push(r),child:const Row(children:[Text('Voir tout',style:TextStyle(fontSize:11,color:Color(0xFF9A7B11),fontWeight:FontWeight.w700)),Icon(Icons.chevron_right,size:14,color:Color(0xFF9A7B11))]))]));

  Widget _recentCompact(List<NewsArticle> list){if(list.isEmpty)return const Padding(padding:EdgeInsets.all(20),child:Center(child:Text('Aucune actualité',style:TextStyle(color:_kMuted,fontSize:12))));return SizedBox(height:130,child:ListView.builder(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:12),itemCount:list.length>10?10:list.length,itemBuilder:(_,i){final a=list[i];return Container(width:140,margin:EdgeInsets.only(right:i==list.length-1?0:8),decoration:BoxDecoration(color:_kWhite,borderRadius:BorderRadius.circular(12),border:Border.all(color:_kBorder)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[ClipRRect(borderRadius:const BorderRadius.vertical(top:Radius.circular(12)),child:SizedBox(height:60,width:140,child:a.imageUrl!=null?Image.network(a.imageUrl!,fit:BoxFit.cover):Container(color:_kBg,child:const Icon(Icons.image,size:20)))),Padding(padding:const EdgeInsets.all(6),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a.title,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700,height:1.2)),const SizedBox(height:2),Text('${a.category} • maintenant',style:const TextStyle(fontSize:9,color:_kMuted))]))]));}));}

  Widget _alert()=>Container(margin:const EdgeInsets.symmetric(horizontal:12),padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:const Color(0xFFFFFBEB),borderRadius:BorderRadius.circular(12),border:Border.all(color:const Color(0xFFFFE9A8))),child:Row(children:[Container(width:32,height:32,decoration:BoxDecoration(color:_kGold.withOpacity(0.2),shape:BoxShape.circle),child:const Icon(Icons.notifications,size:16,color:_kGold)),const SizedBox(width:8),const Expanded(child:Text('Restez informé en temps réel!',style:TextStyle(fontSize:11,fontWeight:FontWeight.w800)))]));

  Widget _videosSection(List<NewsArticle> vids){if(vids.isEmpty)return const Padding(padding:EdgeInsets.all(16),child:Center(child:Text('Aucune vidéo',style:TextStyle(fontSize:12,color:_kMuted))));return SizedBox(height:170,child:ListView.builder(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:12),itemCount:vids.length,itemBuilder:(_,i){final v=vids[i];final hasVideo=v.videoUrl!=null&&v.videoUrl!.isNotEmpty;return GestureDetector(onTap:()=>context.push('/thix-info/article/${v.id}'),child:Container(width:160,margin:EdgeInsets.only(right:i==vids.length-1?0:8),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Stack(children:[ClipRRect(borderRadius:BorderRadius.circular(10),child:SizedBox(height:90,width:160,child:v.imageUrl!=null?Image.network(v.imageUrl!,fit:BoxFit.cover):Container(color:Colors.black12))),Positioned.fill(child:Center(child:Container(padding:const EdgeInsets.all(5),decoration:BoxDecoration(color:Colors.white.withOpacity(0.9),shape:BoxShape.circle),child:Icon(hasVideo?Icons.play_arrow:Icons.article,size:18,color:_kGold)))),if(hasVideo)Positioned(bottom:4,right:4,child:Container(padding:const EdgeInsets.symmetric(horizontal:4,vertical:1),decoration:BoxDecoration(color:Colors.black87,borderRadius:BorderRadius.circular(4)),child:const Text('VIDEO',style:TextStyle(color:Colors.white,fontSize:7,fontWeight:FontWeight.w900))))]),const SizedBox(height:5),Text(v.title,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700,height:1.2)),Text('${v.viewsCount} vues',style:const TextStyle(fontSize:9,color:_kMuted)),if(hasVideo)Container(margin:const EdgeInsets.only(top:2),padding:const EdgeInsets.symmetric(horizontal:5,vertical:2),decoration:BoxDecoration(color:_kBg,borderRadius:BorderRadius.circular(4),border:Border.all(color:_kBorder)),child:Row(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.videocam,size:10,color:_kMuted),const SizedBox(width:3),Expanded(child:Text(v.videoUrl!,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:8,color:_kMuted)))]))])));}));}

  Widget _placeholder()=>Container(margin:const EdgeInsets.symmetric(horizontal:12),height:130,decoration:BoxDecoration(color:_kWhite,borderRadius:BorderRadius.circular(16)),child:const Center(child:CircularProgressIndicator()));
  Widget _bottom()=>Container(margin:const EdgeInsets.fromLTRB(10,0,10,10),padding:const EdgeInsets.symmetric(vertical:4),decoration:BoxDecoration(color:_kWhite,borderRadius:BorderRadius.circular(24),boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.07),blurRadius:12)]),child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[_bNav(Icons.home,'Accueil',0,true),_bNav(Icons.grid_view,'Cat.',1,false),Container(width:48,height:48,decoration:const BoxDecoration(color:_kGold,shape:BoxShape.circle),child:const Icon(Icons.newspaper,color:Colors.white,size:20)),_bNav(Icons.bookmark_border,'Favoris',3,false),_bNav(Icons.person_outline,'Profil',4,false)]));
  Widget _bNav(IconData ic,String lb,int idx,bool act)=>InkWell(onTap:(){setState(()=>_nav=idx);},child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(ic,color:act?_kGold:_kMuted,size:20),Text(lb,style:TextStyle(fontSize:9,color:act?_kGold:_kMuted,fontWeight:act?FontWeight.w800:FontWeight.w400))]));
}
