// lib/presentation/thix_weeding/pages/staff/galerie/gallery_management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final galleryProvider = FutureProvider.family<List<Map<String,dynamic>>, String>((ref, weddingId) async {
  final res = await Supabase.instance.client.from('thix_weeding_gallery').select().eq('wedding_id', weddingId).order('created_at', ascending: false);
  return List<Map<String,dynamic>>.from(res);
});

class GalleryManagementPage extends ConsumerWidget {
  final String weddingId;
  const GalleryManagementPage({super.key, required this.weddingId});
  @override Widget build(BuildContext context, WidgetRef ref){
    final async = ref.watch(galleryProvider(weddingId));
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: async.when(data: (d)=> Text('Galerie - ${d.length}'), loading: ()=> const Text('Galerie'), error: (_,__)=> const Text('Galerie')), backgroundColor: Colors.white, actions: [
        IconButton(icon: const Icon(Icons.cloud_upload), onPressed: ()=> context.push('/thix-weeding/staff/$weddingId/galerie/upload')),
      ]),
      body: async.when(
        loading: ()=> const Center(child: CircularProgressIndicator()),
        error: (e,s)=> Center(child: Text('$e')),
        data: (medias){
          if(medias.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.photo_library_outlined, size:60, color: Colors.grey), const SizedBox(height:12), const Text('Aucune photo'), const SizedBox(height:12), FilledButton.icon(onPressed: ()=> context.push('/thix-weeding/staff/$weddingId/galerie/upload'), icon: const Icon(Icons.add_a_photo), label: const Text('Ajouter photos'))]));
          return RefreshIndicator(onRefresh: () async => ref.invalidate(galleryProvider(weddingId)), child: GridView.builder(padding: const EdgeInsets.all(8), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3, crossAxisSpacing:6, mainAxisSpacing:6), itemCount: medias.length, itemBuilder: (_,i){
            final m = medias[i];
            return GestureDetector(onTap: ()=> _openViewer(context, m), onLongPress: ()=> _confirmDelete(context, ref, m), child: Stack(fit: StackFit.expand, children: [
              ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(m['media_url'], fit: BoxFit.cover, errorBuilder: (_,__,___)=> Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)))),
              if(m['media_type']=='video') const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size:32)),
              Positioned(top:4, right:4, child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)), child: Text(m['id'].toString().substring(0,4), style: const TextStyle(color: Colors.white, fontSize:8)))),
            ]));
          }));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: ()=> context.push('/thix-weeding/staff/$weddingId/galerie/upload'), icon: const Icon(Icons.add_a_photo), label: const Text('Uploader')),
    );
  }

  void _openViewer(BuildContext context, Map<String,dynamic> m){
    showDialog(context: context, builder: (_)=> Dialog(backgroundColor: Colors.black, child: Stack(children: [
      Center(child: Image.network(m['media_url'])),
      Positioned(top:8, right:8, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: ()=> Navigator.pop(context))),
      Positioned(bottom:12, left:12, right:12, child: Text(m['caption']??'', style: const TextStyle(color: Colors.white))),
    ])));
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Map<String,dynamic> m){
    showDialog(context: context, builder: (_)=> AlertDialog(title: const Text('Supprimer?'), content: Text('Supprimer ce média ID ${m['id']}?'), actions: [
      TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Annuler')),
      FilledButton(onPressed: () async {
        await Supabase.instance.client.from('thix_weeding_gallery').delete().eq('id', m['id']);
        ref.invalidate(galleryProvider(m['wedding_id']));
        if(context.mounted) Navigator.pop(context);
      }, child: const Text('Supprimer')),
    ]));
  }
}
