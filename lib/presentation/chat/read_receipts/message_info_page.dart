// lib/presentation/chat/read_receipts/message_info_page.dart
// Page d'information détaillée pour un message (statut, accusés, réactions)

import 'package:flutter/material.dart';
import 'read_receipts_view.dart';
import 'delivery_status.dart';

class MessageInfoPage extends StatelessWidget {
  final String messageId;
  final String content;
  final DateTime sentAt;
  final DeliveryStatus status;
  final List<ReadReceiptUser> readBy;
  final Map<String, int> reactions;
  final bool isEdited;

  const MessageInfoPage({
    Key? key,
    required this.messageId,
    required this.content,
    required this.sentAt,
    required this.status,
    required this.readBy,
    required this.reactions,
    this.isEdited = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informations du message')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Message', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(content),
                  const SizedBox(height: 8),
                  Text('Envoyé le : ${_formatDateTime(sentAt)}', style: const TextStyle(fontSize: 12)),
                  if (isEdited)
                    const Text('(Modifié)', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.done_all),
              title: const Text('Statut de livraison'),
              subtitle: Text(_statusString(status)),
              trailing: DeliveryStatusIcon(status: status, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: const Text('Accusés de lecture'),
                  subtitle: Text('${readBy.length} personne(s) ont lu'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReadReceiptsView(
                          readers: readBy,
                          totalParticipants: readBy.length, // À remplacer par le vrai total
                        ),
                      ),
                    );
                  },
                ),
                if (reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Réactions', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: reactions.entries.map((e) => Chip(
                            label: Text('${e.key} ${e.value}'),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} à ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _statusString(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.sending:
        return 'Envoi en cours...';
      case DeliveryStatus.sent:
        return 'Envoyé (serveur)';
      case DeliveryStatus.delivered:
        return 'Distribué (appareil)';
      case DeliveryStatus.read:
        return 'Lu';
      case DeliveryStatus.failed:
        return 'Échec d\'envoi';
    }
  }
}
