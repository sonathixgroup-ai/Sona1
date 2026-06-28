import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/scheduled_message_model.dart';
import '../../providers/automation_provider.dart';

class ScheduledMessagesScreen extends ConsumerStatefulWidget {
  const ScheduledMessagesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ScheduledMessagesScreen> createState() => _ScheduledMessagesScreenState();
}

class _ScheduledMessagesScreenState extends ConsumerState<ScheduledMessagesScreen> {
  @override
  Widget build(BuildContext context) {
    final scheduledMessages = ref.watch(scheduledMessagesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Messages Program\u00e9s',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF5A67D8)),
            onPressed: () => _showScheduleDialog(context, ref),
          ),
        ],
      ),
      body: scheduledMessages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun message programm\u00e9',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: scheduledMessages.length,
              itemBuilder: (context, index) {
                final message = scheduledMessages[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.schedule,
                      color: message.isActive ? const Color(0xFF5A67D8) : Colors.grey,
                    ),
                    title: Text(
                      message.content.length > 50
                          ? '${message.content.substring(0, 50)}...'
                          : message.content,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${message.scheduledTime.day}/${message.scheduledTime.month}/${message.scheduledTime.year} \u00e0 ${message.scheduledTime.hour.toString().padLeft(2, '0')}:${message.scheduledTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        Text(
                          'R\u00e9p\u00e9tition: ${message.recurrence.name}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: Text(message.isActive ? 'D\u00e9sactiver' : 'Activer'),
                          onTap: () => ref
                              .read(scheduledMessagesProvider.notifier)
                              .toggleScheduledMessage(message.id),
                        ),
                        PopupMenuItem(
                          child: const Text('Modifier'),
                          onTap: () => _showScheduleDialog(context, ref, message),
                        ),
                        PopupMenuItem(
                          child: const Text('Supprimer'),
                          onTap: () => ref
                              .read(scheduledMessagesProvider.notifier)
                              .deleteScheduledMessage(message.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showScheduleDialog(BuildContext context, WidgetRef ref,
      [ScheduledMessage? existingMessage]) {
    final contentController =
        TextEditingController(text: existingMessage?.content ?? '');
    DateTime selectedDateTime = existingMessage?.scheduledTime ?? DateTime.now();
    MessageRecurrence selectedRecurrence =
        existingMessage?.recurrence ?? MessageRecurrence.none;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existingMessage != null
              ? 'Modifier le message'
              : 'Programmer un message'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Contenu du message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Date et heure'),
                  subtitle: Text(
                      '${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year} \u00e0 ${selectedDateTime.hour}:${selectedDateTime.minute.toString().padLeft(2, '0')}'),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDateTime,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                      );
                      if (time != null) {
                        setState(() {
                          selectedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('R\u00e9p\u00e9tition:', style: TextStyle(fontWeight: FontWeight.w600)),
                DropdownButton<MessageRecurrence>(
                  isExpanded: true,
                  value: selectedRecurrence,
                  items: MessageRecurrence.values
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedRecurrence = value);
                    }
                  },
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
                if (existingMessage != null) {
                  ref
                      .read(scheduledMessagesProvider.notifier)
                      .updateScheduledMessage(
                        existingMessage.id,
                        existingMessage.copyWith(
                          content: contentController.text,
                          scheduledTime: selectedDateTime,
                          recurrence: selectedRecurrence,
                        ),
                      );
                } else {
                  ref.read(scheduledMessagesProvider.notifier).addScheduledMessage(
                        ScheduledMessage(
                          id: DateTime.now().toString(),
                          conversationId: '',
                          content: contentController.text,
                          scheduledTime: selectedDateTime,
                          recurrence: selectedRecurrence,
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
