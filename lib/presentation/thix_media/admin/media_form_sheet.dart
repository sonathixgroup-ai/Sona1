import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/media_content.dart';
import '../../../services/media_service.dart';

const kNavyDeep = Color(0xFF0A1F44);
const kAccent = Color(0xFF2D6CDF);
const kGold = Color(0xFFE3B23C);

class MediaFormSheet extends StatefulWidget {
  final MediaContent? existing;
  final VoidCallback onSaved;
  const MediaFormSheet({super.key, this.existing, required this.onSaved});
  @override State<MediaFormSheet> createState() => _MediaFormSheetState();
}

class _MediaFormSheetState extends State<MediaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _title, _subtitle, _year;
  String _type = 'Films';
  bool _isPublished = true, _isNew = true, _isTrending = false;
  int? _rank;
  PlatformFile? _coverFile, _videoFile;
  bool _saving = false;

  @override
  void initState(){
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title?? '');
    _subtitle = TextEditingController(text: e?.subtitle?? '');
    _year = TextEditingController(text: e?.year?? DateTime.now().year.toString());
    _type = e?.type?? 'Films';
    _isPublished = e?.isPublished?? true;
    _isNew = e?.isNewRelease?? true;
    _isTrending = e?.rankPosition!= null;
    _rank = e?.rankPosition;
  }

  @override
  void dispose(){ _title.dispose(); _subtitle.dispose(); _year.dispose(); super.dispose(); }

  Future<void> _pickCover() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if(res!=null) setState(()=>_coverFile=res.files.first);
  }
  Future<void> _pickVideo() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
    if(res!=null) setState(()=>_videoFile=res.files.first);
  }

  Future<void> _save() async {
    if(!_formKey.currentState!.validate()) return;
    if(widget.existing==null && (_coverFile==null || _videoFile==null)){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cover + Vidéo obligatoires pour création')));
      return;
    }
    setState(()=>_saving=true);
    try{
      final service = MediaService(client: Supabase.instance.client, bucket: 'media');
      if(widget.existing==null){
        // UPLOAD D'ABORD PUIS INSERT
        final coverUp = await service.uploadFile(file: _coverFile!, path: 'thix_media/covers');
        final videoUp = await service.uploadFile(file: _videoFile!, path: 'thix_media/videos');
        final newItem = MediaContent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _title.text.trim(),
          subtitle: _subtitle.text.trim(),
          type: _type,
          year: _year.text.trim(),
          coverUrl: coverUp['url']!,
          videoUrl: videoUp['url']!,
          viewCount: 0,
          rankPosition: _isTrending? (_rank??1) : null,
          isTrending: _isTrending,
          isNewRelease: _isNew,
          isRecommended: true,
          isPublished: _isPublished,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await Supabase.instance.client.from('media_content').insert(newItem.toJson());
      } else {
        await service.updateWithFiles(widget.existing!.copyWith(
          title: _title.text.trim(),
          subtitle: _subtitle.text.trim(),
          type: _type,
          year: _year.text.trim(),
          rankPosition: _isTrending? (_rank??1) : null,
          isTrending: _isTrending,
          isNewRelease: _isNew,
          isPublished: _isPublished,
          updatedAt: DateTime.now(),
        ), newCoverFile: _coverFile, newVideoFile: _videoFile);
      }
      widget.onSaved();
      if(mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Contenu enregistré'), backgroundColor: Colors.green));
    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(()=>_saving=false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      padding: EdgeInsets.fromLTRB(18, 12, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Color(0xFFE7EEFC), borderRadius: BorderRadius.circular(10)))),
          SizedBox(height: 16),
          Text(widget.existing==null?'Charger une vidéo':'Modifier la vidéo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kNavyDeep)),
          SizedBox(height: 16),
          Row(children: [
            Expanded(child: InkWell(onTap: _pickCover, child: Container(height: 110, decoration: BoxDecoration(color: Color(0xFFF7FAFF), borderRadius: BorderRadius.circular(14), border: Border.all(color: Color(0xFFE7EEFC), style: BorderStyle.solid)), child: _coverFile!=null? Center(child: Text(_coverFile!.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center)) : widget.existing!=null? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(widget.existing!.coverUrl, fit: BoxFit.cover)) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.image_rounded, color: kAccent), SizedBox(height: 6), Text('Cover *', style: TextStyle(fontSize: 11, color: Color(0xFF7386A8))) ])))),
            SizedBox(width: 12),
            Expanded(child: InkWell(onTap: _pickVideo, child: Container(height: 110, decoration: BoxDecoration(color: Color(0xFFF7FAFF), borderRadius: BorderRadius.circular(14), border: Border.all(color: Color(0xFFE7EEFC))), child: _videoFile!=null? Center(child: Text('${_videoFile!.name}\n${(_videoFile!.size/1024/1024).toStringAsFixed(1)} Mo', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.video_library_rounded, color: kAccent), SizedBox(height: 6), Text('Vidéo MP4 *', style: TextStyle(fontSize: 11, color: Color(0xFF7386A8))) ])))),
          ]),
          SizedBox(height: 18),
          TextFormField(controller: _title, validator: (v)=>v!.isEmpty?'Requis':null, decoration: InputDecoration(labelText: 'Titre *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Color(0xFFF7FAFF))),
          SizedBox(height: 12),
          TextFormField(controller: _subtitle, decoration: InputDecoration(labelText: 'Sous-titre / description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Color(0xFFF7FAFF))),
          SizedBox(height: 12),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(value: _type, decoration: InputDecoration(labelText: 'Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Color(0xFFF7FAFF)), items: ['Films','Séries','Vidéos','Musique','Playlists','En direct'].map((e)=>DropdownMenuItem(value:e, child: Text(e))).toList(), onChanged: (v)=>setState(()=>_type=v!))),
            SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _year, decoration: InputDecoration(labelText: 'Année', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Color(0xFFF7FAFF)))),
          ]),
          SizedBox(height: 14),
          SwitchListTile(value: _isPublished, onChanged: (v)=>setState(()=>_isPublished=v), title: Text('Publié', style: TextStyle(fontWeight: FontWeight.w700)), activeColor: kAccent),
          SwitchListTile(value: _isNew, onChanged: (v)=>setState(()=>_isNew=v), title: Text('Nouveauté (banner)', style: TextStyle(fontWeight: FontWeight.w700)), activeColor: kAccent),
          SwitchListTile(value: _isTrending, onChanged: (v)=>setState(()=>_isTrending=v), title: Text('Tendance (avec rang)', style: TextStyle(fontWeight: FontWeight.w700)), activeColor: kAccent),
          if(_isTrending) TextFormField(initialValue: _rank?.toString()??'1', keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Position #1, #2...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: (v)=>_rank=int.tryParse(v)),
          SizedBox(height: 22),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
            onPressed: _saving? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: kNavyDeep, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            child: _saving? CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : Text(widget.existing==null?'Uploader et Publier':'Enregistrer les modifications', style: TextStyle(fontWeight: FontWeight.w800)),
          )),
        ])),
      ),
    );
  }
}
