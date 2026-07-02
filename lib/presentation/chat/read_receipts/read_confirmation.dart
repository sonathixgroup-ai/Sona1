// lib/presentation/chat/read_receipts/read_confirmation.dart
// Boîte de dialogue demandant confirmation de lecture pour un message prioritaire

import 'package:flutter/material.dart';

class ReadConfirmationDialog extends StatelessWidget {
  final String messageContent;
  final VoidCallback onConfirm;

  const ReadConfirmationDialog({
    Key? key,
    required this.messageContent,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Accusé de lecture requis'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('L\'expéditeur a demandé un accusé de lecture pour ce message prioritaire :'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(messageContent),
          ),
          const SizedBox(height: 12),
          const Text('En ouvrant ce message, l\'expéditeur sera notifié que vous l\'avez lu.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Ignorer'),
        ),
        ElevatedButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: const Text('Accepter et lire'),
        ),
      ],
    );
  }
}
