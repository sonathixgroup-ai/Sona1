// lib/presentation/chat/archive/export_chat_page.dart
// Page pour exporter une conversation (PDF / JSON / texte)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../core/chat_repository.dart';

class ExportChatPage extends StatefulWidget {
  final String conversationId;
  final String conversationName;

  const ExportChatPage({Key? key, required this.conversationId, required this.conversationName}) : super(key: key);

  @override
  State<ExportChatPage> createState() => _ExportChatPageState();
}

class _ExportChatPageState extends State<ExportChatPage> {
  final ChatRepository _repository = ChatRepository();
  bool _isLoading = false;
  bool _includeMedia = false;
  String _format = 'txt'; // txt, json, pdf

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exporter la conversation')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.conversationName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Inclure les médias (liens)'),
            value: _includeMedia,
            onChanged: (val) => setState(() => _includeMedia = val),
          ),
          const SizedBox(height: 8),
          const Text('Format d\'export', style: TextStyle(fontWeight: FontWeight.w500)),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Texte (.txt)'),
                  value: 'txt',
                  groupValue: _format,
                  onChanged: (val) => setState(() => _format = val!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('JSON (.json)'),
                  value: 'json',
                  groupValue: _format,
                  onChanged: (val) => setState(() => _format = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _export,
            icon: _isLoading ? const CircularProgressIndicator(strokeWidth: 2) : const Icon(Icons.download),
            label: const Text('Exporter'),
          ),
        ],
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _isLoading = true);
    try {
      final messages = await _repository.fetchMessages(widget.conversationId, limit: 1000);
      String content;
      if (_format == 'json') {
        content = _toJson(messages);
      } else {
        content = _toText(messages);
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/export_${widget.conversationId}.$_format');
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)], text: 'Export de la conversation ${widget.conversationName}');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _toText(List<Message> messages) {
    final buffer = StringBuffer();
    buffer.writeln('Export de la conversation: ${widget.conversationName}');
    buffer.writeln('Date: ${DateTime.now()}\n');
    for (var m in messages.reversed) {
      buffer.writeln('[${_formatDateTime(m.sentAt)}] ${m.senderId}: ${m.content ?? '(média)'}');
    }
    return buffer.toString();
  }

  String _toJson(List<Message> messages) {
    final list = messages.map((m) => {
      'sent_at': m.sentAt.toIso8601String(),
      'sender_id': m.senderId,
      'content': m.content,
      'type': m.type,
    }).toList();
    return {'conversation': widget.conversationName, 'messages': list}.toString();
  }

  String _formatDateTime(DateTime dt) => '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute}';
}
