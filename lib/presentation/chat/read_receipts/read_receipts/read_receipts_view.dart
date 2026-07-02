// lib/presentation/chat/read_receipts/read_receipts_view.dart
// Affiche la liste des participants ayant lu un message donné

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ReadReceiptsView extends StatelessWidget {
  final List<ReadReceiptUser> readers;
  final int totalParticipants;

  const ReadReceiptsView({
    Key? key,
    required this.readers,
    required this.totalParticipants,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vus par')),
      body: ListView.builder(
        itemCount: readers.length,
        itemBuilder: (context, index) {
          final user = readers[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: user.avatarUrl != null
                  ? CachedNetworkImageProvider(user.avatarUrl!)
                  : const AssetImage('assets/default_avatar.png') as ImageProvider,
            ),
            title: Text(user.displayName),
            subtitle: Text('Lu le ${_formatDateTime(user.readAt)}'),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          '${readers.length} sur $totalParticipants ont lu ce message',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class ReadReceiptUser {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final DateTime readAt;

  ReadReceiptUser({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.readAt,
  });
}
