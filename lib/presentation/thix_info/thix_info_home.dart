import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/news_provider.dart';
import '../../models/news_article.dart';

const _kGold = Color(0xFFFFB800);
const _kBlue = Color(0xFF0B3D91);
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
  final PageController _pageCtrl = PageController();
  Timer? _timer;
  int _page = 0;

  final List<Map<String,String>> cats = const [
    {'slug':'featured','name':'À la une'},
    {'slug':'politique','name':'Politique'},
    {'slug':'economie','name':'Économie'},
    {'slug':'societe','name':'Société'},
    {'slug':'tech','name':'Tech'},
    {'slug':'sport','name':'Sport'},
  ];

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().fetchArticles(category:'all');
      _startAuto();
    });
  }

  void _startAuto(){
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds:4), (_){
      if(!mounted) return;
      final list = context.read<NewsProvider>().articles.where((e)=>e.isFeatured).toList();
      if(list.isEmpty) return;
      if(!_pageCtrl.hasClients) return;
      _page = (_page+1) % list.length;
      _pageCtrl.animateToPage(_page, duration: const Duration(milliseconds:350), curve: Curves.easeInOut);
    });
  }

  @override void dispose(){ _timer?.cancel(); _pageCtrl.dispose(); super.dispose(); }

  @override Widget build(BuildContext context){
    final prov = context.watch<NewsProvider>();
    // 3. INDEPENDANT DU FILTRAGE
    final featured = prov.articles.where((e)=>e.isFeatured).toList();
    final breaking = prov.articles.where((e)=>e.isBreaking).toList();
    final recents = prov.articles; // on n'utilise PAS le filtre cat ici pour fixer "Aucune actualité"
    final videos = prov.articles.where((e)=> e.videoUrl!=null && e.videoUrl!.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: _kBg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _top(),
          _search(),
          _cats(),
          if(breaking.isNotEmpty) _breakingBar(breaking),
          const SizedBox(height:8),
          // 4. AUTO-SCROLL + 5. TAILLE REDUITE (148px)
          featured.isNotEmpty? _featuredAuto(featured) : _loadBox(),
          const SizedBox(height:10),
          _quick(),
          const SizedBox(height:14),
          _titleRow('Actualités récentes'),
          _recentCompact(recents),
          const SizedBox(height:10),
          _titleRow('Vidéos à la une'),
          // 1. + 2. VIDEO + INFOS
          _videoWithInfos(videos),
          const SizedBox(height:90),
        ],
      ),
      bottomNavigationBar: _bottom(),
    );
  }

  Widget _top(){
    return Container(
      color:_kWhite,
      padding: const EdgeInsets.fromLTRB(12,44,12,10),
      child: Row(children:[
        IconButton(icon: const Icon(Icons.menu,size:20),onPressed: ()=>context.go('/')),
        Container(width:34,height:34,decoration: BoxDecoration(color:_kGold,borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.newspaper,size:16,color:Colors.white)),
        const SizedBox(width:8),
        const Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('THIX INFO',style:TextStyle(fontWeight:FontWeight.w900,fontSize:13)),Text("L'info vraie, partout.",style:TextStyle(fontSize:9,color:_kMuted))])),
        GestureDetector(onTap: ()=>context.push('/admin'), child: Container(padding: const EdgeInsets.symmetric(horizontal:10,vertical:5),decoration: BoxDecoration(color:_kGold,borderRadius: BorderRadius.circular(20)), child: const Text('ADMIN',style:TextStyle(fontSize:9,fontWeight:FontWeight.w900)))),
      ]),
    );
  }

  Widget _search(){
    return Container(color:_kWhite,padding: const EdgeInsets.fromLTRB(12,0,12,10), child: Container(height:36,decoration: BoxDecoration(color:_kBg,borderRadius: BorderRadius.circular(11),border: Border.all(color:_kBorder)), padding: const EdgeInsets.symmetric(horizontal:10), child: const Row(children:[Icon(Icons.search,size:16,color:_kMuted),SizedBox(width:6),Text('Rechercher une actualité...',style:TextStyle(fontSize:11,color:_kMuted))])));
  }

  Widget _cats(){
    return SizedBox(height:30, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal:12), scrollDirection: Axis.horizontal, itemCount:cats.length, separatorBuilder:(_,__)=>(const SizedBox(width:6)), itemBuilder:(_,i){
      final c=cats[i]; final sel=_cat==c['slug'];
      return GestureDetector(onTap:(){setState(()=>_cat=c['slug']!); if(c['slug']=='featured'){context.read<NewsProvider>().fetchArticles(category:'all');}else{context.read<NewsProvider>().fetchArticles(category:c['slug']!);}}, child: Container(padding: const EdgeInsets.symmetric(horizontal:12),alignment:Alignment.center,decoration: BoxDecoration(color:sel?_kGold:_kWhite,borderRadius: BorderRadius.circular(16),border: Border.all(color:sel?_kGold:_kBorder)), child: Text(c['name']!,style: const TextStyle(fontSize:11,fontWeight:FontWeight.w700))));
    }));
  }

  Widget _breakingBar(List<NewsArticle> list){
    return Container(height:28,color: const Color(0xFFFFE9E9), child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal:10), itemCount:list.length, itemBuilder:(_,i){return Row(children:[Container(padding: const EdgeInsets.symmetric(horizontal:5,vertical:2),decoration: BoxDecoration(color:Colors.red,borderRadius: BorderRadius.circular(3)), child: const Text('BREAKING',style:TextStyle(color:Colors.white,fontSize:7,fontWeight:FontWeight.w900))),const SizedBox(width:6),Text(list[i].title,style: const TextStyle(fontSize:10,fontWeight:FontWeight.w700)),const SizedBox(width:16)]);}));
  }

  Widget _featuredAuto(List<NewsArticle> list){
    return SizedBox(height:144, child: PageView.builder(controller:_pageCtrl, onPageChanged:(v)=>_page=v, itemCount:list.length, itemBuilder:(_,i){
      final a=list[i];
      return Container(margin: const EdgeInsets.symmetric(horizontal:12), decoration: BoxDecoration(color:_kWhite,borderRadius: BorderRadius.circular(14),border: Border.all(color:_kBorder)), clipBehavior:Clip.antiAlias, child: Row(children:[
        Expanded(child: Padding(padding: const EdgeInsets.all(9), child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(padding: const EdgeInsets.symmetric(horizontal:5,vertical:2),decoration: BoxDecoration(color:_kGold.withOpacity(0.2),borderRadius: BorderRadius.circular(4)), child: const Text('À LA UNE',style:TextStyle(fontSize:7,fontWeight:FontWeight.w900))),const SizedBox(height:5),Text(a.title,maxLines:2,overflow:TextOverflow.ellipsis,style: const TextStyle(fontSize:12,fontWeight:FontWeight.w900,height:1.1)),const SizedBox(height:3),Text(a.summary??'',maxLines:2,overflow:TextOverflow.ellipsis,style: const TextStyle(fontSize:9,color:_kMuted)),const Spacer(),SizedBox(height:24,child: ElevatedButton(onPressed: ()=>context.push('/thix-info/article/${a.id}'), style: ElevatedButton.styleFrom(backgroundColor:_kGold,padding: const EdgeInsets.symmetric(horizontal:10)), child: const Text('Lire',style:TextStyle(fontSize:10,color:Colors.black,fontWeight:FontWeight.w800))))]))),
        Expanded(child: a.imageUrl!=null?Image.network(a.imageUrl!,fit:BoxFit.cover,height:144,errorBuilder:(_,__,___)=>Container(color:_kBlue)):Container(color:_kBlue)),
      ]));
    }));
  }

  Widget _quick(){
    return Container(margin: const EdgeInsets.symmetric(horizontal:12), padding: const EdgeInsets.symmetric(vertical:8), decoration: BoxDecoration(color:_kWhite,borderRadius: BorderRadius.circular(12),border: Border.all(color:_kBorder)), child: const Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[_QI(icon:Icons.article,label:'Fil Info'),_QI(icon:Icons.play_circle,label:'Vidéos'),_QI(icon:Icons.headset,label:'Podcasts'),_QI(icon:Icons.menu_book,label:'Magazines'),_QI(icon:Icons.notifications,label:'Alertes')]));
  }

  Widget _titleRow(String t){return Padding(padding: const EdgeInsets.symmetric(horizontal:12), child: Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(t,style: const TextStyle(fontSize:13,fontWeight:FontWeight.w900)),const Text('Voir tout',style:TextStyle(fontSize:10,color:Color(0xFF9A7B11),fontWeight:FontWeight.w700))]));}

  Widget _recentCompact(List<NewsArticle> list){
    if(list.isEmpty){return const Padding(padding:EdgeInsets.all(20),child:Center(child:Text('Aucune actualité',style:TextStyle(fontSize:11,color:_kMuted))));}
    return SizedBox(height:120, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal:12), scrollDirection:Axis.horizontal, itemCount:list.length>8?8:list.length, separatorBuilder:(_,__)=>(const SizedBox(width:7)), itemBuilder:(_,i){final a=list[i]; return Container(width:132,decoration: BoxDecoration(color:_kWhite,borderRadius: BorderRadius.circular(11),border: Border.all(color:_kBorder)), child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[ClipRRect(borderRadius: const BorderRadius.vertical(top:Radius.circular(11)), child: SizedBox(height:54,width:132,child: a.imageUrl!=null?Image.network(a.imageUrl!,fit:BoxFit.cover):Container(color:_kBg,child:const Icon(Icons.image,size:16)))),Padding(padding: const EdgeInsets.all(6),child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a.title,maxLines:2,overflow:TextOverflow.ellipsis,style: const TextStyle(fontSize:10,fontWeight:FontWeight.w700)),Text(a.category,style: const TextStyle(fontSize:8,color:_kMuted))]))]));}));
  }

  Widget _videoWithInfos(List<NewsArticle> list){
    if(list.isEmpty){return const Padding(padding:EdgeInsets.all(18),child:Center(child:Text('Aucune vidéo',style:TextStyle(fontSize:11,color:_kMuted))));}
    return SizedBox(height:168, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal:12), scrollDirection:Axis.horizontal, itemCount:list.length, separatorBuilder:(_,__)=>(const SizedBox(width:8)), itemBuilder:(_,i){
      final v=list[i];
      return Container(width:158,decoration: BoxDecoration(color:_kWhite,borderRadius: BorderRadius.circular(11),border: Border.all(color:_kBorder)), clipBehavior:Clip.antiAlias, child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Stack(children:[SizedBox(height:84,width:158,child: v.imageUrl!=null?Image.network(v.imageUrl!,fit:BoxFit.cover):Container(color:Colors.black12)), const Positioned.fill(child:Center(child:Icon(Icons.play_circle_fill,color:Colors.white,size:30))), Positioned(bottom:4,right:4,child: Container(padding: const EdgeInsets.symmetric(horizontal:4,vertical:1),decoration: BoxDecoration(color:Colors.black87,borderRadius: BorderRadius.circular(3)), child: const Text('VIDEO',style:TextStyle(color:Colors.white,fontSize:7,fontWeight:FontWeight.w900))))]),
        // 2. CLASSE TOUTES LES INFOS EN BAS DE VIDEO
        Padding(padding: const EdgeInsets.fromLTRB(7,6,7,4), child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(v.title,maxLines:2,overflow:TextOverflow.ellipsis,style: const TextStyle(fontSize:10,fontWeight:FontWeight.w800,height:1.1)),
          const SizedBox(height:2),
          Row(children:[const Icon(Icons.category,size:10,color:_kMuted),const SizedBox(width:3),Text(v.category,style: const TextStyle(fontSize:8,color:_kMuted)),const SizedBox(width:6),const Icon(Icons.visibility,size:10,color:_kMuted),const SizedBox(width:2),Text('${v.viewsCount} vues',style: const TextStyle(fontSize:8,color:_kMuted))]),
          const SizedBox(height:2),
          Container(padding: const EdgeInsets.symmetric(horizontal:5,vertical:2),decoration: BoxDecoration(color:_kBg,borderRadius: BorderRadius.circular(4),border: Border.all(color:_kBorder)), child: Row(children:[const Icon(Icons.link,size:9,color:_kMuted),const SizedBox(width:3),Expanded(child: Text(v.videoUrl??'',maxLines:1,overflow:TextOverflow.ellipsis,style: const TextStyle(fontSize:7,color:_kMuted)))])),
        ])),
      ]));
    }));
  }

  Widget _loadBox()=>Container(margin: const EdgeInsets.symmetric(horizontal:12),height:120,decoration: BoxDecoration(color:_kWhite,borderRadius: BorderRadius.circular(12)), child: const Center(child:CircularProgressIndicator(strokeWidth:2)));
  Widget _bottom()=>Container(margin: const EdgeInsets.fromLTRB(10,0,10,8),padding: const EdgeInsets.symmetric(vertical:5),decoration: BoxDecoration(color:_kWhite,borderRadius: BorderRadius.circular(22),boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.06),blurRadius:10)]), child: const Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[Icon(Icons.home,color:_kGold,size:20),Icon(Icons.grid_view,color:_kMuted,size:20),CircleAvatar(backgroundColor:_kGold,radius:18,child:Icon(Icons.newspaper,color:Colors.white,size:16)),Icon(Icons.bookmark_border,color:_kMuted,size:20),Icon(Icons.person_outline,color:_kMuted,size:20)]));
}

class _QI extends StatelessWidget {
  final IconData icon; final String label;
  const _QI({required this.icon, required this.label});
  @override Widget build(BuildContext context){return Column(children:[Container(width:30,height:30,decoration: BoxDecoration(color:_kBg,borderRadius: BorderRadius.circular(7)), child: Icon(icon,size:16,color:_kDark)), const SizedBox(height:3),Text(label,style: const TextStyle(fontSize:8,fontWeight:FontWeight.w600))]);}
}
