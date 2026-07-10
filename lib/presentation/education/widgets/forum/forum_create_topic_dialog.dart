// lib/presentation/education/widgets/forum/forum_create_topic_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/presentation/education/providers/forum_provider.dart';

class ForumCreateTopicDialog extends StatefulWidget {
  final String formationId;

  const ForumCreateTopicDialog({super.key, required this.formationId});

  @override
  State<ForumCreateTopicDialog> createState() => _ForumCreateTopicDialogState();
}

class _ForumCreateTopicDialogState extends State<ForumCreateTopicDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Créer un sujet',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1A1A2E),
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Titre',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Ex: Question sur le module 2',
                hintStyle: const TextStyle(color: Color(0xFF7386A8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2D6CDF), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Description',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _bodyController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Détaillez votre question...',
                hintStyle: const TextStyle(color: Color(0xFF7386A8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2D6CDF), width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Annuler',
            style: TextStyle(color: Color(0xFF7386A8)),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createTopic,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D6CDF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Publier'),
        ),
      ],
    );
  }

  Future<void> _createTopic() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs.'),
          backgroundColor: Color(0xFFFF5B3D),
        ),
      );
      return;
    }

    // ✅ Supabase maintenant disponible
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final provider = context.read<ForumProvider>();
      final topic = await provider.createTopic(
        formationId: widget.formationId,
        userId: userId,
        title: title,
        body: body,
      );
      if (topic != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sujet créé avec succès !'), backgroundColor: Color(0xFF2ECC71)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
