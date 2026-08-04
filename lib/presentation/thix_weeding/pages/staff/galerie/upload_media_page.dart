// lib/presentation/thix_weeding/pages/staff/galerie/upload_media_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class UploadMediaPage extends StatefulWidget {
  final String weddingId;
  const UploadMediaPage({super.key, required this.weddingId});
  @override State<UploadMediaPage> createState()=> _UploadMediaPageState();
}

class _UploadMediaPageState extends State<UploadMediaPage> {
  List<XFile> _picked = [];
  final _caption = TextEditingController();
  bool _loading = false;
  final _picker = ImagePicker();

  Future<void> _pick() async {
    final files = await _picker.pickMultiImage(imageQuality: 80);
    if(files.isNotEmpty) setState(()=> _picked.addAll(files));
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if(file!=null) setState(()=> _picked.add(file));
  }

  Future<void> _uploadAll() async {
    if(_picked.isEmpty) return;
    setState(()=> _loading=true);
    try{
      final supa = Supabase.instance.client;
      for(var xfile in _picked){
        final file = File(xfile.path);
        final ext = xfile.path.split('.').last;
        final fileName = '${widget.weddingId}/${DateTime.now().millisecondsSinceEpoch}_${xfile.name}';
        final isVideo = ['mp4','mov','avi'].contains(ext.toLowerCase());
        await supa.storage.from('thix-weeding-gallery').upload(fileName, file);
        final publicUrl = supa.storage.from('thix-weeding-gallery').getPublicUrl(fileName);
        await supa.from('thix_weeding_gallery').insert({
          'wedding_id': widget.weddingId,
          'media_url': publicUrl,
          'media_type': isVideo? 'video':'image',
          'caption': _caption.text.trim(),
        });
      }
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_picked.length} médias uploadés')));
        context.pop();
      }
    }catch(e){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur $e'))); }
    finally{ if(mounted) setState(()=> _loading=false); }
  }

  @override Widget build(BuildContext context)=> Scaffold(appBar: AppBar(title: const Text('Uploader médias')), body: ListView(padding: const EdgeInsets.all(16), children: [
    Row(children: [
      Expanded(child: OutlinedButton.icon(onPressed: _pick, icon: const Icon(Icons.photo_library), label: const Text('Photos'))),
      const SizedBox(width:12),
      Expanded(child: OutlinedButton.icon(onPressed: _pickVideo, icon: const Icon(Icons.videocam), label: const Text('Vidéo'))),
    ]),
    const SizedBox(height:12),
    TextField(controller: _caption, decoration: const InputDecoration(labelText:'Légende (optionnelle)')),
    const SizedBox(height:12),
    if(_picked.isNotEmpty) GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3, crossAxisSpacing:8, mainAxisSpacing:8), itemCount: _picked.length, itemBuilder: (_,i)=> Stack(children: [
      ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_picked[i].path), fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
      Positioned(top:2, right:2, child: GestureDetector(onTap: ()=> setState(()=> _picked.removeAt(i)), child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size:16, color: Colors.white)))),
    ])),
    const SizedBox(height:24),
    FilledButton.icon(onPressed: _loading||_picked.isEmpty?null:_uploadAll, icon: _loading? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)): const Icon(Icons.cloud_upload), label: Text(_loading?'Upload en cours...':'Uploader ${_picked.length} médias')),
    const SizedBox(height:8),
    Text('Chaque média aura son ID uuid unique en DB après upload', style: TextStyle(fontSize:11, color: Colors.grey[600])),
  ]));
}
