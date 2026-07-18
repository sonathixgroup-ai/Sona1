import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

// ✅ CHEMINS CORRIGÉS POUR TON ARBORESCENCE
import '../../../models/media_content.dart';
import '../../../services/media_service.dart';
import 'media_form_sheet.dart';
import '../../../app_router.dart';

// CHARTE THIX
const kNavyDeep = Color(0xFF0A1F44);
const kNavy = Color(0xFF123B7A);
const kAccent = Color(0xFF2D6CDF);
const kGold = Color(0xFFE3B23C);
const kBg = Color(0xFFF7FAFF);
const kBorder = Color(0xFFE7EEFC);

class ThixMediaAdminPage extends StatefulWidget {
  const ThixMediaAdminPage({super.key});
  @override
  State<ThixMediaAdminPage> createState() => _ThixMediaAdminPageState();
}

class _ThixMediaAdminPageState extends State<ThixMediaAdminPage> {
  late MediaService _service;
  List<MediaContent> _all = [];
  bool _loading = true;
  String _filter = 'Tous';

  @override
  void initState() {
    super.initState();
    _service = MediaService(client: Supabase.instance.client, bucket: 'media');
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.fetchAllMedia();
      if(mounted) setState(() { _all = data; _loading = false; });
    } catch(e){
      if(mounted) setState(()=> _loading = false);
    }
  }

  List<MediaContent> get _filtered {
    if (_filter == 'Tous') return _all;
    if (_filter == 'Publiés') return _all.where((e) => e.isPublished).toList();
    if (_filter == 'Brouillons') return _all.where((e) => !e.isPublished).toList();
    return _all.where((e) => e.type == _filter).toList();
  }

  void _openForm({MediaContent? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MediaFormSheet(existing: item, onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kNavyDeep,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18), onPressed: ()=> context.pop()),
        title: Row(children: [
          Container(padding: EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.play_circle_fill_rounded, size: 16, color: kGold)),
          SizedBox(width: 8),
          Text('ADMIN MEDIA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5, fontSize: 15)),
        ]),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _openForm(),
              icon: Icon(Icons.cloud_upload_rounded, size: 16),
              label: Text('Charger', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              style: ElevatedButton.styleFrom(backgroundColor: kGold, foregroundColor: kNavyDeep, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
            ),
          )
        ],
      ),
      body: _loading ? Center(child: CircularProgressIndicator(color: kAccent))
      : RefreshIndicator(onRefresh: _load, child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(children: [
          _buildStats(),
          _buildFilters(),
          _buildGrid(),
        ]),
      )),
    );
  }

  Widget _buildStats() => Container(
    margin: EdgeInsets.all(16),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder), boxShadow: [BoxShadow(color: kNavyDeep.withOpacity(0.04), blurRadius: 12)]),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _stat('${_all.length}', 'Total'),
      _stat('${_all.where((e)=>e.isPublished).length}', 'Publiés'),
      _stat('${_all.where((e)=>e.isNewRelease).length}', 'Nouveautés'),
      _stat('${(_all.fold<int>(0, (s,e)=>s+e.viewCount)/1000).toStringAsFixed(1)}k', 'Vues'),
    ]),
  );

  Widget _stat(String val, String label) => Column(children: [
    Text(val, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: kNavyDeep)),
    SizedBox(height: 2),
    Text(label, style: TextStyle(fontSize: 10.5, color: Color(0xFF7386A8), fontWeight: FontWeight.w600)),
  ]);

  Widget _buildFilters() => SizedBox(
    height: 38,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16),
      children: ['Tous','Publiés','Brouillons','Films','Séries','Vidéos','Musique'].map((f) =>
        Padding(padding: EdgeInsets.only(right: 8), child: ChoiceChip(
          label: Text(f, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          selected: _filter == f,
          selectedColor: kNavyDeep,
          backgroundColor: Colors.white,
          side: BorderSide(color: kBorder),
          labelStyle: TextStyle(color: _filter == f? Colors.white : kNavyDeep),
          onSelected: (_) => setState(()=>_filter=f),
        ))
      ).toList(),
    ),
  );

  Widget _buildGrid() => Padding(
    padding: EdgeInsets.all(16),
    child: _filtered.isEmpty ? Padding(padding: EdgeInsets.only(top: 40), child: Text('Aucun contenu dans $_filter', style: TextStyle(color: Color(0xFF7386A8)))) :
    GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.68, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: _filtered.length,
      itemBuilder: (c,i){
        final item = _filtered[i];
        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder), boxShadow: [BoxShadow(color: kNavyDeep.withOpacity(0.05), blurRadius: 10, offset: Offset(0,4))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              ClipRRect(borderRadius: BorderRadius.vertical(top: Radius.circular(18)), child: Image.network(item.coverUrl, height: 110, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___)=>Container(height:110,color: Color(0xFFEFF5FF), child: Icon(Icons.image_rounded, color: kBorder)))),
              Positioned(top:8, right:8, child: Container(padding: EdgeInsets.symmetric(horizontal:8, vertical:3), decoration: BoxDecoration(color: item.isPublished? Colors.green: Colors.orange, borderRadius: BorderRadius.circular(20)), child: Text(item.isPublished?'PUBLIÉ':'BROUILLON', style: TextStyle(color:Colors.white,fontSize:8.5,fontWeight: FontWeight.w900)))),
              if(item.rankPosition!=null) Positioned(top:8, left:8, child: Container(padding: EdgeInsets.symmetric(horizontal:7, vertical:3), decoration: BoxDecoration(color: kNavyDeep, borderRadius: BorderRadius.circular(20)), child: Text('#${item.rankPosition}', style: TextStyle(color:Colors.white,fontSize:9,fontWeight: FontWeight.w800)))),
            ]),
            Expanded(child: Padding(padding: EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, maxLines:1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize:12.5, color: kNavyDeep)),
              SizedBox(height: 2),
              Text('${item.type} • ${item.year?? ''} • ${item.viewCount} vues', maxLines:1, style: TextStyle(fontSize:9.5, color: Color(0xFF7386A8))),
              Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                InkWell(onTap: ()=>_openForm(item: item), child: Container(padding: EdgeInsets.all(6), decoration: BoxDecoration(color: Color(0xFFEFF5FF), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.edit_rounded, size:16, color: kAccent))),
                InkWell(onTap: () async {
                  final ok = await showDialog<bool>(context: context, builder: (_)=>AlertDialog(title: Text('Supprimer ${item.title} ?'), content: Text('Action irréversible.'), actions: [TextButton(onPressed: ()=>Navigator.pop(context,false), child: Text('Annuler')), TextButton(onPressed: ()=>Navigator.pop(context,true), child: Text('Supprimer', style: TextStyle(color: Colors.red)))]));
                  if(ok==true){ await _service.deleteMedia(item); _load(); }
                }, child: Container(padding: EdgeInsets.all(6), decoration: BoxDecoration(color: Color(0xFFFFEFF0), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.delete_rounded, size:16, color: Colors.redAccent))),
              ])
            ]))),
          ]),
        );
      },
    ),
  );
}
