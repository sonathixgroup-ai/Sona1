import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/auto_reply_model.dart';
import '../../providers/automation_provider.dart';

class AutoRepliesScreen extends ConsumerStatefulWidget {
  const AutoRepliesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AutoRepliesScreen> createState() => _AutoRepliesScreenState();
}

class _AutoRepliesScreenState extends ConsumerState<AutoRepliesScreen> {
  @override
  Widget build(BuildContext context) {
    final autoReplies = ref.watch(autoRepliesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'R\u00e9ponses Automatiques',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF5A67D8)),
            onPressed: () => _showAutoReplyDialog(context, ref),
          ),
        ],
      ),
      body: autoReplies.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.reply_all, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune r\u00e9ponse automatique',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: autoReplies.length,
              itemBuilder: (context, index) {
                final reply = autoReplies[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Switch(
                      value: reply.isEnabled,
                      onChanged: (value) => ref
                          .read(autoRepliesProvider.notifier)
                          .toggleAutoReply(reply.id),
                      activeColor: const Color(0xFF5A67D8),
                    ),
                    title: Text(
                      reply.trigger,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'R\u00e9ponse: ${reply.response.length > 40 ? "${reply.response.substring(0, 40)}..." : reply.response}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Type: ${reply.triggerType.name} | Priorit\u00e9: ${reply.priority}/10',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text('Modifier'),
                          onTap: () => _showAutoReplyDialog(context, ref, reply),
                        ),
                        PopupMenuItem(
                          child: const Text('Supprimer'),
                          onTap: () => ref
                              .read(autoRepliesProvider.notifier)
                              .deleteAutoReply(reply.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAutoReplyDialog(BuildContext context, WidgetRef ref,
      [AutoReply? existingReply]) {
    final triggerController =
        TextEditingController(text: existingReply?.trigger ?? '');
    final responseController =
        TextEditingController(text: existingReply?.response ?? '');
    bool caseSensitive = existingReply?.caseSensitive ?? false;
    int priority = existingReply?.priority ?? 5;
    bool applyToGroups = existingReply?.applyToGroups ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existingReply != null
              ? 'Modifier la r\u00e9ponse'
              : 'Cr\u00e9er une r\u00e9ponse automatique'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: triggerController,
                  decoration: const InputDecoration(
                    labelText: 'Mot-cl\u00e9 ou motif',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: responseController,
                  decoration: const InputDecoration(
                    labelText: 'R\u00e9ponse',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: caseSensitive,
                  onChanged: (value) =>
                      setState(() => caseSensitive = value ?? false),
                  title: const Text('Sensible à la casse'),
                ),
                CheckboxListTile(
                  value: applyToGroups,
                  onChanged: (value) =>
                      setState(() => applyToGroups = value ?? true),
                  title: const Text('Appliquer aux groupes'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Priorit\u00e9:'),
                    Expanded(
                      child: Slider(
                        value: priority.toDouble(),
                        min: 1,
                        max: 10,
                        onChanged: (value) =>
                            setState(() => priority = value.toInt()),
                      ),
                    ),
                    Text('$priority/10'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                if (existingReply != null) {
                  ref.read(autoRepliesProvider.notifier).updateAutoReply(
                        existingReply.id,
                        existingReply.copyWith(
                          trigger: triggerController.text,
                          response: responseController.text,
                          caseSensitive: caseSensitive,
                          priority: priority,
                          applyToGroups: applyToGroups,
                        ),
                      );
                } else {
                  ref.read(autoRepliesProvider.notifier).addAutoReply(
                        AutoReply(
                          id: DateTime.now().toString(),
                          userId: '',
                          isEnabled: true,
                          trigger: triggerController.text,
                          response: responseController.text,
                          caseSensitive: caseSensitive,
                          priority: priority,
                          applyToGroups: applyToGroups,
                        ),
                      );
                }
                Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
