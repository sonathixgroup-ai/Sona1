import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/news_provider.dart';
import '../../models/news_article.dart';

class AdminArticleFormPage extends StatefulWidget {
  final String? articleId;
  const AdminArticleFormPage({super.key, this.articleId});
  @override State<AdminArticleFormPage> createState() => _AdminArticleFormPageState();
}

class _AdminArticleFormPageState extends State<AdminArticleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _summary = TextEditingController();
  final _content = TextEditingController();
  String _category = 'politique';
  bool _isFeatured = false, _isBreaking = false;
  String? _imageUrl;
  XFile? _picked;
  bool _loading = false;
  NewsArticle? _edit;

  final cats = ['politique','economie','societe','tech','sport','culture','international'];

  @override void initState() { super.initState(); if (widget.articleId != null) _load(); }

  Future<void> _load() async {
    final a = await context.read<NewsProvider>().fetchArticleById(widget.articleId!);
    if (a != null) setState(() {
      _edit = a; _title.text = a.title; _summary.text = a.summary ?? ''; _content.text = a.content;
      _category = a.category; _isFeatured = a.isFeatured; _isBreaking = a.isBreaking; _imageUrl = a.imageUrl;
    });
  }

  Future<void> _pick() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (f != null) setState(() => _picked = f);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final prov = context.read<NewsProvider>();
    String? finalImg = _imageUrl;
    if (_picked != null) { finalImg = await prov.uploadImage(_picked!.path); }
    try {
      if (_edit == null) {
        await prov.createArticle(title: _title.text.trim(), summary: _summary.text.trim(), content: _content.text.trim(), category: _category, imageUrl: finalImg, isFeatured: _isFeatured, isBreaking: _isBreaking);
      } else {
        await prov.updateArticle(_edit!.id, {'title': _title.text.trim(),'summary': _summary.text.trim(),'content': _content.text.trim(),'category': _category,'image_url': finalImg,'is_featured': _isFeatured,'is_breaking': _isBreaking,'is_published': true});
      }
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Publié avec succès'))); context.go('/admin/articles'); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_edit == null ? 'Nouvel Article' : 'Modifier'), backgroundColor: const Color(0xFF101840), foregroundColor: Colors.white),
      body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
        TextFormField(controller: _title, decoration: _d('Titre *'), validator: (v) => v!.isEmpty ? 'Requis' : null),
        const SizedBox(height: 12),
        DropdownButtonFormField(value: _category, items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => _category = v!), decoration: _d('Catégorie')),
        const SizedBox(height: 12),
        TextFormField(controller: _summary, maxLines: 3, decoration: _d('Résumé * (affiché dans À la une)'), validator: (v) => v!.isEmpty ? 'Requis' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _content, maxLines: 12, decoration: _d('Contenu complet *'), validator: (v) => v!.length < 20 ? 'Min 20 caractères' : null),
        const SizedBox(height: 12),
        InkWell(onTap: _pick, child: Container(height: 150, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFECEEF4))), child: _picked != null ? Center(child: Text(_picked!.name)) : _imageUrl != null ? Image.network(_imageUrl!, fit: BoxFit.cover) : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo), SizedBox(height: 6), Text('Ajouter une image')])))),
        const SizedBox(height: 12),
        SwitchListTile(value: _isFeatured, onChanged: (v) => setState(() => _isFeatured = v), title: const Text('Mettre À la une'), activeColor: const Color(0xFFFFB800)),
        SwitchListTile(value: _isBreaking, onChanged: (v) => setState(() => _isBreaking = v), title: const Text('Breaking News'), activeColor: Colors.red),
        const SizedBox(height: 20),
        SizedBox(height: 54, child: ElevatedButton(onPressed: _loading ? null : _save, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB800), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: _loading ? const CircularProgressIndicator() : Text(_edit == null ? 'PUBLIER' : 'METTRE À JOUR', style: const TextStyle(fontWeight: FontWeight.w900)))),
      ])),
    );
  }
  InputDecoration _d(String l) => InputDecoration(labelText: l, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)));
}
