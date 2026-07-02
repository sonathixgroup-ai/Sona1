// lib/presentation/chat/archive/export_encrypted.dart
// Export chiffré des conversations (AES) avec mot de passe

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:share_plus/share_plus.dart';
import '../core/chat_repository.dart';

class ExportEncryptedPage extends StatefulWidget {
  final String conversationId;
  final String conversationName;

  const ExportEncryptedPage({Key? key, required this.conversationId, required this.conversationName}) : super(key: key);

  @override
  State<ExportEncryptedPage> createState() => _ExportEncryptedPageState();
}

class _ExportEncryptedPageState extends State<ExportEncryptedPage> {
  final ChatRepository _repository = ChatRepository();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export chiffré')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.conversationName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          const Text('Protégez l\'export par un mot de passe (AES-256)'),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              hintText: 'Mot de passe',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _exportEncrypted,
            icon: _isLoading ? const CircularProgressIndicator(strokeWidth: 2) : const Icon(Icons.lock),
            label: const Text('Exporter et chiffrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportEncrypted() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrez un mot de passe')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final messages = await _repository.fetchMessages(widget.conversationId, limit: 1000);
      final jsonData = jsonEncode(messages.map((m) => {
        'sent_at': m.sentAt.toIso8601String(),
        'sender_id': m.senderId,
        'content': m.content,
        'type': m.type,
      }).toList());
      final key = encrypt.Key.fromUtf8(password.padRight(32, '0').substring(0, 32));
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final encrypted = encrypter.encrypt(jsonData, iv: iv);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/export_encrypted_${widget.conversationId}.thix');
      await file.writeAsString(jsonEncode({
        'iv': iv.base64,
        'data': encrypted.base64,
      }));
      await Share.shareXFiles([XFile(file.path)], text: 'Export chiffré - ${widget.conversationName}');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
