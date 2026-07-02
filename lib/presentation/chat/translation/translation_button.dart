// lib/presentation/chat/translation/translation_button.dart
// Bouton de traduction placé à côté d'un message (dans la bulle ou dans le menu)

import 'package:flutter/material.dart';

class TranslationButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isTranslating;

  const TranslationButton({
    Key? key,
    required this.onTap,
    this.isTranslating = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: isTranslating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.translate, size: 14),
                  SizedBox(width: 4),
                  Text('Traduire', style: TextStyle(fontSize: 11)),
                ],
              ),
      ),
    );
  }
}
