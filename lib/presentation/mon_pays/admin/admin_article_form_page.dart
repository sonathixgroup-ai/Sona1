// lib/presentation/mon_pays/admin/admin_article_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/article.dart';
import '../providers/articles_provider.dart';

class AdminArticleFormPage extends ConsumerStatefulWidget {
  final Article? article;

  const AdminArticleFormPage({super.key, this.article});

  @override
  ConsumerState<AdminArticleFormPage> createState() => _AdminArticleFormPageState();
}

class _AdminArticleFormPageState extends ConsumerState<AdminArticleFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _typeController;
  late TextEditingController _chapterController;
  late TextEditingController _articleNumberController;
  late TextEditingController _contentController;
  late TextEditingController _explanationController;
  late bool _isPublished;

  @override
  void initState() {
    super.initState();
    final a = widget.article;
    _titleController = TextEditingController(text: a?.title ?? '');
    _typeController = TextEditingController(text: a?.type.label ?? '');
    _chapterController = TextEditingController(text: a?.chapter ?? '');
    _articleNumberController = TextEditingController(text: a?.articleNumber ?? '');
    _contentController = TextEditingController(text: a?.content ?? '');
    _explanationController = TextEditingController(text: a?.explanation ?? '');
    _isPublished = a?.isPublished ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _typeController.dispose();
    _chapterController.dispose();
    _articleNumberController.dispose();
    _contentController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.article != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier l\'article' : 'Nouvel article'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Type
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Type *'),
                  value: _typeController.text.isNotEmpty
                      ? ArticleType.fromString(_typeController.text).toString().split('.').last
                      : null,
                  items: ArticleType.values.map((type) {
                    return DropdownMenuItem(
                      value: type.toString().split('.').last,
                      child: Text(type.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    _typeController.text = value!;
                  },
                  validator: (v) => v == null ? 'Champ requis' : null,
                ),
                // Titre
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Titre *'),
                  validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                // Chapitre
                TextFormField(
                  controller: _chapterController,
                  decoration: const InputDecoration(labelText: 'Chapitre (optionnel)'),
                ),
                // Numéro d'article
                TextFormField(
                  controller: _articleNumberController,
                  decoration: const InputDecoration(labelText: 'Numéro d\'article (ex: 3, 14-1)'),
                ),
                // Contenu
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(labelText: 'Contenu *'),
                  maxLines: 10,
                  validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                // Explication
                TextFormField(
                  controller: _explanationController,
                  decoration: const InputDecoration(labelText: 'Explication (optionnelle)'),
                  maxLines: 5,
                ),
                // Statut de publication
                SwitchListTile(
                  title: const Text('Publié'),
                  value: _isPublished,
                  onChanged: (value) => setState(() => _isPublished = value),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEditing ? 'Modifier' : 'Créer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final type = ArticleType.fromString(_typeController.text);
    
    // ✅ CORRECTION : Si création, ne pas envoyer d'ID
    final article = Article(
      id: widget.article?.id ?? '', // On garde pour l'édition, mais le service ignorera l'ID vide
      type: type,
      title: _titleController.text.trim(),
      chapter: _chapterController.text.trim().isEmpty ? null : _chapterController.text.trim(),
      articleNumber: _articleNumberController.text.trim().isEmpty ? null : _articleNumberController.text.trim(),
      content: _contentController.text.trim(),
      explanation: _explanationController.text.trim().isEmpty ? null : _explanationController.text.trim(),
      isPublished: _isPublished,
    );
    
    final notifier = ref.read(adminArticlesProvider.notifier);
    try {
      if (widget.article != null) {
        await notifier.updateArticle(article);
      } else {
        await notifier.createArticle(article);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
