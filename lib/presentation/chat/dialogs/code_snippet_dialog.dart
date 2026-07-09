// lib/presentation/chat/dialogs/code_snippet_dialog.dart
import 'package:flutter/material.dart';

class CodeSnippetDialog extends StatefulWidget {
  const CodeSnippetDialog({super.key});

  @override
  State<CodeSnippetDialog> createState() => _CodeSnippetDialogState();
}

class _CodeSnippetDialogState extends State<CodeSnippetDialog> {
  final TextEditingController _codeController = TextEditingController();
  String _selectedLanguage = 'dart';

  final List<Map<String, String>> _languages = [
    {'label': 'Dart', 'value': 'dart'},
    {'label': 'Python', 'value': 'python'},
    {'label': 'JavaScript', 'value': 'javascript'},
    {'label': 'TypeScript', 'value': 'typescript'},
    {'label': 'HTML', 'value': 'html'},
    {'label': 'CSS', 'value': 'css'},
    {'label': 'JSON', 'value': 'json'},
    {'label': 'YAML', 'value': 'yaml'},
    {'label': 'Java', 'value': 'java'},
    {'label': 'C++', 'value': 'cpp'},
    {'label': 'C#', 'value': 'csharp'},
    {'label': 'Go', 'value': 'go'},
    {'label': 'Rust', 'value': 'rust'},
    {'label': 'PHP', 'value': 'php'},
    {'label': 'Swift', 'value': 'swift'},
    {'label': 'Kotlin', 'value': 'kotlin'},
    {'label': 'Ruby', 'value': 'ruby'},
    {'label': 'Shell', 'value': 'shell'},
    {'label': 'SQL', 'value': 'sql'},
    {'label': 'Texte', 'value': 'text'},
  ];

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.code, color: Color(0xFFD4AF37)),
          SizedBox(width: 8),
          Text('Code snippet'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Langage',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _languages.map((lang) {
                return DropdownMenuItem(
                  value: lang['value'],
                  child: Text(lang['label']!),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedLanguage = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Collez votre code ici...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            final code = _codeController.text.trim();
            if (code.isNotEmpty) {
              Navigator.pop(context, {
                'code': code,
                'language': _selectedLanguage,
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Le code ne peut pas être vide'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
          icon: const Icon(Icons.send),
          label: const Text('Envoyer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

/// Fonction utilitaire pour afficher le dialogue et obtenir le résultat
Future<Map<String, String>?> showCodeSnippetDialog(BuildContext context) {
  return showDialog<Map<String, String>>(
    context: context,
    builder: (context) => const CodeSnippetDialog(),
  );
}
