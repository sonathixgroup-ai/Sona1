// lib/presentation/thix_info/admin/admin_article_form_page.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/news_provider.dart';
import '../../models/news_article.dart';

class AdminArticleFormPage extends HookConsumerWidget {
  final String? articleId;
  const AdminArticleFormPage({super.key, this.articleId});

  static const Color _kGold = Color(0xFFFFB800);
  static const Color _kDark = Color(0xFF101840);
  static const Color _kBorder = Color(0xFFECEEF4);
  static const Color _kBg = Color(0xFFF7F8FB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ─── 1. CONTRÔLEURS ET ÉTATS LOCAUX (HOOKS) ───────────────────
    final formKey = useMemoized(() => GlobalKey<FormState>());
    
    final titleCtrl = useTextEditingController();
    final summaryCtrl = useTextEditingController();
    final contentCtrl = useTextEditingController();
    final videoUrlCtrl = useTextEditingController();

    final categoryState = useState<String>('politique');
    final isFeaturedState = useState<bool>(false);
    final isBreakingState = useState<bool>(false);
    
    final imageUrlState = useState<String?>(null);
    final videoUrlState = useState<String?>(null);
    final pickedImageState = useState<XFile?>(null);
    final pickedVideoState = useState<XFile?>(null);
    final imgBytesState = useState<Uint8List?>(null);
    final vidBytesState = useState<Uint8List?>(null);
    
    final loadingState = useState<bool>(false);
    final editArticleState = useState<NewsArticle?>(null);

    final cats = ['politique', 'economie', 'societe', 'tech', 'sport', 'culture', 'international'];

    // ─── 2. CHARGEMENT INITIAL (SI ÉDITION) ──────────────────────
    useEffect(() {
      if (articleId != null) {
        Future.microtask(() async {
          loadingState.value = true;
          final a = await ref.read(newsProvider.notifier).fetchArticleById(articleId!);
          if (a != null && context.mounted) {
            editArticleState.value = a;
            titleCtrl.text = a.title;
            summaryCtrl.text = a.summary ?? '';
            contentCtrl.text = a.content;
            categoryState.value = a.category;
            isFeaturedState.value = a.isFeatured;
            isBreakingState.value = a.isBreaking;
            imageUrlState.value = a.imageUrl;
            videoUrlState.value = a.videoUrl;
            videoUrlCtrl.text = a.videoUrl ?? '';
          }
          loadingState.value = false;
        });
      }
      return null;
    }, [articleId]);

    // ─── 3. SÉLECTION MÉDIA ───────────────────────────────────────
    Future<void> pickImage() async {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75);
      if (f != null) {
        final bytes = await f.readAsBytes();
        pickedImageState.value = f;
        imgBytesState.value = bytes;
      }
    }

    Future<void> pickVideo() async {
      final f = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (f != null) {
        final bytes = await f.readAsBytes();
        pickedVideoState.value = f;
        vidBytesState.value = bytes;
      }
    }

    // ─── 4. SAUVEGARDE / PUBLICATION ─────────────────────────────
    Future<void> save() async {
      if (!formKey.currentState!.validate()) return;
      loadingState.value = true;
      
      final prov = ref.read(newsProvider.notifier);
      
      try {
        String? finalImg = imageUrlState.value;
        String? finalVideo = videoUrlCtrl.text.trim().isNotEmpty ? videoUrlCtrl.text.trim() : videoUrlState.value;

        // Upload web-safe en bytes
        if (imgBytesState.value != null && pickedImageState.value != null) {
          finalImg = await prov.uploadImageBytes(imgBytesState.value!, pickedImageState.value!.name);
        }
        if (vidBytesState.value != null && pickedVideoState.value != null) {
          finalVideo = await prov.uploadVideoBytes(vidBytesState.value!, pickedVideoState.value!.name);
        }

        if (finalImg == null && pickedImageState.value != null) {
          throw Exception('Upload image échoué - vérifie bucket news public');
        }

        if (editArticleState.value == null) {
          await prov.createArticle(
            title: titleCtrl.text.trim(),
            summary: summaryCtrl.text.trim(),
            content: contentCtrl.text.trim(),
            category: categoryState.value,
            imageUrl: finalImg,
            videoUrl: finalVideo,
            isFeatured: isFeaturedState.value,
            isBreaking: isBreakingState.value,
          );
        } else {
          await prov.updateArticle(editArticleState.value!.id, {
            'title': titleCtrl.text.trim(),
            'summary': summaryCtrl.text.trim(),
            'content': contentCtrl.text.trim(),
            'category': categoryState.value,
            'image_url': finalImg,
            'video_url': finalVideo,
            'is_featured': isFeaturedState.value,
            'is_breaking': isBreakingState.value,
            'is_published': true,
          });
        }
        
        await prov.fetchArticles(category: 'all');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Publié avec succès')));
          context.go('/admin/articles');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
          );
        }
      } finally {
        loadingState.value = false;
      }
    }

    // Helper pour les inputs
    InputDecoration inputDecor(String label) => InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBorder)),
    );

    // ─── 5. UI PRINCIPALE ────────────────────────────────────────
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(editArticleState.value == null ? 'Nouvel Article' : 'Modifier', style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: _kDark,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            TextFormField(controller: titleCtrl, decoration: inputDecor('Titre *'), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: categoryState.value,
              items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => categoryState.value = v!,
              decoration: inputDecor('Catégorie'),
            ),
            const SizedBox(height: 10),
            TextFormField(controller: summaryCtrl, maxLines: 2, decoration: inputDecor('Résumé *'), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
            const SizedBox(height: 10),
            TextFormField(controller: contentCtrl, maxLines: 6, decoration: inputDecor('Contenu *'), validator: (v) => v == null || v.length < 20 ? 'Min 20' : null),

            const SizedBox(height: 16),
            const Text('PHOTO - PREVIEW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
            const SizedBox(height: 6),
            Container(
              height: 180,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
              clipBehavior: Clip.antiAlias,
              child: Stack(children: [
                Positioned.fill(
                  child: imgBytesState.value != null
                      ? Image.memory(imgBytesState.value!, fit: BoxFit.cover)
                      : imageUrlState.value != null && imageUrlState.value!.isNotEmpty
                          ? Image.network(imageUrlState.value!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)))
                          : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 28, color: Colors.grey), SizedBox(height: 6), Text('Aucune photo', style: TextStyle(fontSize: 12, color: Colors.grey))])),
                ),
                Positioned(
                  bottom: 8, right: 8,
                  child: ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.photo, size: 16),
                    label: Text(imgBytesState.value != null || imageUrlState.value != null ? 'Changer' : 'Choisir', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(backgroundColor: _kGold, foregroundColor: Colors.black, minimumSize: const Size(0, 32)),
                  ),
                ),
              ]),
            ),
            if (imgBytesState.value != null)
              Padding(padding: const EdgeInsets.only(top: 6), child: Text('Preview: ${pickedImageState.value?.name ?? ''} • ${(imgBytesState.value!.length / 1024).toStringAsFixed(0)} KB', style: const TextStyle(fontSize: 10, color: Colors.green))),

            const SizedBox(height: 16),
            const Text('VIDÉO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
            const SizedBox(height: 6),
            Container(
              height: 100,
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
              clipBehavior: Clip.antiAlias,
              child: Stack(alignment: Alignment.center, children: [
                Center(
                  child: vidBytesState.value != null
                      ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 28),
                          const SizedBox(height: 4),
                          Text('${pickedVideoState.value?.name}', style: const TextStyle(color: Colors.white, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${(vidBytesState.value!.length / 1024 / 1024).toStringAsFixed(1)} MB prêt', style: const TextStyle(color: Colors.white54, fontSize: 9)),
                        ])
                      : videoUrlState.value != null && videoUrlState.value!.isNotEmpty
                          ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.play_circle_fill, size: 36, color: Colors.white70), Text('Vidéo existante', style: TextStyle(color: Colors.white70, fontSize: 10))])
                          : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.videocam_off, size: 24, color: Colors.white38), Text('Aucune vidéo', style: TextStyle(color: Colors.white38, fontSize: 11))]),
                ),
                Positioned(
                  bottom: 8, left: 8, right: 8,
                  child: Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: pickVideo,
                        icon: const Icon(Icons.video_library, size: 16),
                        label: const Text('Choisir vidéo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _kDark, minimumSize: const Size(0, 34)),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            TextFormField(controller: videoUrlCtrl, decoration: inputDecor('Ou coller lien YouTube / MP4 (optionnel)'), style: const TextStyle(fontSize: 12)),

            const SizedBox(height: 14),
            SwitchListTile(
              value: isFeaturedState.value,
              onChanged: (v) => isFeaturedState.value = v,
              title: const Text('À la une', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              activeColor: _kGold, dense: true, contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: isBreakingState.value,
              onChanged: (v) => isBreakingState.value = v,
              title: const Text('Breaking News', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              activeColor: Colors.red, dense: true, contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: loadingState.value ? null : save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: loadingState.value
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text(editArticleState.value == null ? 'PUBLIER MAINTENANT' : 'METTRE À JOUR', style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
