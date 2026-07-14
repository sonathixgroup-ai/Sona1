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
  @override
  State<ThixInfoHome> createState() => _ThixInfoHomeState();
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().fetchArticles(category: 'all');
      _startTimer();
    });
  }

  void _startTimer(){
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

  @override
  void dispose(){ _timer?.cancel(); _pageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context){
    final prov = context.watch<NewsProvider>();
    final featured = prov.articles.where((e)=>e.isFeatured).toList();
    final recents = prov.articles;
    final breaking = prov.articles.where((e)=>e.isBreaking).toList();
    final videos = prov.articles.where((e)=> e.videoUrl!=null && e.videoUrl!.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: _kBg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _topBar(),
          _searchBar(),
          _catRow(),
          if(breaking.isNotEmpty) _breaking(breaking),
          const SizedBox(height:10),
          featured.isNotEmpty? _featured(featured) : _loadingBox(),
          const SizedBox(height:10),
          _quick(),
          const SizedBox(height:14),
          _sectionTitle('Actualités récentes'),
          _recents(recents),
          const SizedBox(height:12),
          _sectionTitle('Vidéos à la une'),
          _videos(videos),
          const SizedBox(height:100),
        ],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _topBar(){
    return Container(
      color: _kWhite,
      padding: const EdgeInsets.fromLTRB(12,44,12,10),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.menu), onPressed: ()=>context.go('/')),
          Container(width:36,height:36,decoration: BoxDecoration(color:_kGold,borderRadius: BorderRadius.circular(10)),child: const Icon(Icons.newspaper,color:Colors.white,size:18)),
          const SizedBox(width:8),
          const Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('THIX INFO',style:TextStyle(fontWeight:FontWeight.w900,fontSize:14)),Text("L'info vraie, partout.",style:TextStyle(fontSize:10,color:_kMuted))])),
          GestureDetector(onTap: ()=>context.push('/admin'), child: Container(padding: const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration: BoxDecoration(color:_kGold,borderRadius: BorderRadius.circular(20)), child: const Text('ADMIN',style:TextStyle(fontSize:10,fontWeight:FontWeight.w900)))),
        ],
      ),
    );
  }

  Widget _searchBar(){
    return Container(
      color:_kWhite,
      padding: const EdgeInsets.fromLTRB(12,0,12,12),
      child: Container(height:38,decoration: BoxDecoration(color:_kBg,borderRadius: BorderRadius.circular(12),border: Border.all(color:_kBorder)),padding: const EdgeInsets.symmetric(horizontal:12),child: const Row(children:[Icon(Icons.search,size:18,color:_kMuted),SizedBox(width:8),Text('Rechercher...',style:TextStyle(fontSize:12,color:_kMuted))])),
    );
  }

  Widget _catRow(){
    return SizedBox(
      height:34,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal:12),
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (_,__)=> const SizedBox(width:6),
        itemBuilder: (_,i){
          final c = cats[i];
          final sel = _cat==c['slug'];
          return GestureDetector(
            onTap: (){
              setState(()=>_cat=c['slug']!);
              if(c['slug']=='featured'){ context.read<NewsProvider>().fetchArticles(category:'all'); }
              else { context.read<NewsProvider>().fetchArticles(category:c['slug']!); }
            },
            child: Container(padding: const EdgeInsets.symmetric(horizontal:14),alignment: Alignment.center,decoration: BoxDecoration(color: sel?_kGold:_kWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel?_kGold:_kBorder)), child: Text(c['name']!,style: const TextStyle(fontSize:12,fontWeight:FontWeight.w700))),
          );
        },
      ),
    );
  }

  Widget _breaking(List<NewsArticle> list){
    return Container(
      height:32,
      color: const Color(0xFFFFE9E9),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal:12),
        itemCount: list.length,
        itemBuilder: (_,i){
          return Row(children:[Container(padding: const EdgeInsets.symmetric(horizontal:6,vertical:2),decoration: BoxDecoration(color:Colors.red,borderRadius: BorderRadius.circular(4)), child: const Text('BREAKING',style:TextStyle(color:Colors.white,fontSize:8,fontWeight:FontWeight.w900))), const SizedBox(width:6), Text(list[i].title,style: const TextStyle(fontSize:11,fontWeight:FontWeight.w700)), const SizedBox(width:18)]);
        },
      ),
    );
  }

  Widget _featured(List<NewsArticle> list){
    return SizedBox(
      height:148,
      child: PageView.builder(
        controller: _pageCtrl,
        onPageChanged: (v)=>_page=v,
        itemCount: list.length,
        itemBuilder: (_,i){
          final a = list[i];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal:12),
            decoration: BoxDecoration(color:_kWhite,borderRadius: BorderRadius.circular(16),border: Border.all(color:_kBorder)),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal:6,vertical:2),decoration: BoxDecoration(color:_kGold.withOpacity(0.2),borderRadius: BorderRadius.circular(4)), child: const Text('À LA UNE',style:TextStyle(fontSize:8,fontWeight:FontWeight.w900))),
                        const SizedBox(height:6),
                        Text(a.title,maxLines:2,overflow: TextOverflow.ellipsis,style: const TextStyle(fontSize:13,fontWeight:FontWeight.w900)),
                        const SizedBox(height:4),
                        Text(a.summary??'',maxLines:2,overflow: TextOverflow.ellipsis,style: const TextStyle(fontSize:10,color:_kMuted)),
                        const Spacer(),
                        SizedBox(height:26,child: ElevatedButton(onPressed: ()=>context.push('/thix-info/article/${a.id}'), style: ElevatedButton.styleFrom(backgroundColor:_kGold,padding: const EdgeInsets.symmetric(horizontal:12)), child: const Text('Lire',style:TextStyle(fontSize:11,color:Colors.black,fontWeight:FontWeight.w800)))),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: a.imageUrl!=null? Image.network(a.imageUrl!,fit:BoxFit.cover,height:148,errorBuilder: (_,__,___)=>Container(color:_kBlue)) : Container(color:_kBlue),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _quick(){
    return Container(
      margin: const EdgeInsets.symmetric(horizontal:12),
      padding: const EdgeInsets.symmetric(vertical:10),
      decoration: BoxDecoration(color:_kWhite,borderRadius: BorderRadius.circular(14),border: Border.all(color:_kBorder)),
      child: const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children:[_QuickItem(icon:Icons.article,label:'Fil Info'),_QuickItem(icon:Icons.play_circle,label:'Vidéos'),_QuickItem(icon:Icons.headset,label:'Podcasts'),_QuickItem(icon:Icons.menu_book,label:'Magazines'),_QuickItem(icon:Icons.notifications,label:'Alertes')]),
    );
  }

  Widget _sectionTitle(String t){
    return Padding(padding: const EdgeInsets.symmetric(horizontal:12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text(t,style: const TextStyle(fontSize:14,fontWeight:FontWeight.w900)), const Text('Voir tout',style:TextStyle(fontSize:11,color:Color(0xFF9A7B11),fontWeight:FontWeight.w700))]));
  }

  Widget _recents(List<NewsArticle> list){
    if(list.isEmpty){ return const Padding(padding:EdgeInsets.all(24),child:Center(child:Text('Aucune actualité',style:TextStyle(color:_kMuted,fontSize:12)))); }
    return SizedBox(
      height:128,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal:12),
        scrollDirection: Axis.horizontal,
        itemCount: list.length>8?8:list.length,
        separatorBuilder: (_,__)=>const SizedBox(width:8),
        itemBuilder: (_,i){
          final a = list[i];
          return Container(
            width:138,
            decoration: BoxDecoration(color:_kWhite,borderRadius: BorderRadius.circular(12),border: Border.all(color:_kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(borderRadius: const BorderRadius.vertical(top:Radius.circular(12)), child: SizedBox(height:58,width:138,child: a.imageUrl!=null?Image.network(a.imageUrl!,fit:BoxFit.cover):Container(color:_kBg,child:const Icon(Icons.image,size:18)))),
                Padding(padding: const EdgeInsets.all(6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(a.title,maxLines:2,overflow: TextOverflow.ellipsis,style: const TextStyle(fontSize:11,fontWeight:FontWeight.w700)), const SizedBox(height:2), Text(a.category,style: const TextStyle(fontSize:9,color:_kMuted))])),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _videos(List<NewsArticle> list){
    if(list.isEmpty){ return const Padding(padding:EdgeInsets.all(20),child:Center(child:Text('Aucune vidéo',style:TextStyle(color:_kMuted,fontSize:12)))); }
    return SizedBox(
      height:140,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal:12),
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_,__)=>const SizedBox(width:8),
        itemBuilder: (_,i){
          final v = list[i];
          return GestureDetector(
            onTap: ()=>context.push('/thix-info/article/${v.id}'),
            child: SizedBox(
              width:156,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(children:[ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(height:88,width:156,child: v.imageUrl!=null?Image.network(v.imageUrl!,fit:BoxFit.cover):Container(color:Colors.black12))), const Positioned.fill(child: Center(child: Icon(Icons.play_circle_fill,color:Colors.white,size:32)))]),
                  const SizedBox(height:4),
                  Text(v.title,maxLines:2,overflow: TextOverflow.ellipsis,style: const TextStyle(fontSize:11,fontWeight:FontWeight.w700)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _loadingBox()=>Container(margin: const EdgeInsets.symmetric(horizontal:12),height:140,decoration: BoxDecoration(color:_kWhite,borderRadius: BorderRadius.circular(16)), child: const Center(child:CircularProgressIndicator()));
  Widget _bottomBar()=>Container(margin: const EdgeInsets.fromLTRB(12,0,12,10),padding: const EdgeInsets.symmetric(vertical:6),decoration: BoxDecoration(color:_kWhite,borderRadius: BorderRadius.circular(24),boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.06),blurRadius:12)]), child: const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children:[Icon(Icons.home,color:_kGold),Icon(Icons.grid_view,color:_kMuted),CircleAvatar(backgroundColor:_kGold,radius:20,child:Icon(Icons.newspaper,color:Colors.white,size:18)),Icon(Icons.bookmark_border,color:_kMuted),Icon(Icons.person_outline,color:_kMuted)]));
}

class _QuickItem extends StatelessWidget {
  final IconData icon; final String label;
  const _QuickItem({required this.icon, required this.label});
  @override Widget build(BuildContext context){ return Column(children:[Container(width:32,height:32,decoration: BoxDecoration(color:_kBg,borderRadius: BorderRadius.circular(8)), child: Icon(icon,size:18,color:_kDark)), const SizedBox(height:4), Text(label,style: const TextStyle(fontSize:9,fontWeight:FontWeight.w600))]); }
}
