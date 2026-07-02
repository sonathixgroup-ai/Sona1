// lib/presentation/chat/slash_commands/slash_command_panel.dart
// Panneau flottant suggérant les commandes slash lors de la saisie de "/"

import 'package:flutter/material.dart';
import 'slash_command_parser.dart';
import 'built_in_commands.dart';

class SlashCommandPanel extends StatelessWidget {
  final String currentInput;
  final Function(String command, Map<String, dynamic>? data) onExecute;

  const SlashCommandPanel({
    Key? key,
    required this.currentInput,
    required this.onExecute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!currentInput.startsWith('/')) return const SizedBox.shrink();

    final matchingCommands = SlashCommandParser.supportedCommands
        .where((cmd) => '/$cmd'.startsWith(currentInput.toLowerCase()))
        .toList();

    if (matchingCommands.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: matchingCommands.map((cmd) {
          return ListTile(
            leading: const Icon(Icons.code, size: 18),
            title: Text('/$cmd'),
            subtitle: Text(_commandDescription(cmd)),
            onTap: () => _handleCommand(context, cmd),
          );
        }).toList(),
      ),
    );
  }

  String _commandDescription(String cmd) {
    switch (cmd) {
      case 'poll': return 'Créer un sondage';
      case 'remind': return 'Programmer un rappel';
      case 'todo': return 'Créer une tâche';
      case 'me': return 'Message d\'action (/me danse)';
      case 'giphy': return 'Chercher un GIF';
      case 'code': return 'Bloc de code formaté';
      default: return '';
    }
  }

  void _handleCommand(BuildContext context, String cmd) async {
    switch (cmd) {
      case 'poll':
        final pollData = await BuiltInCommands.showPollCreator(context);
        if (pollData != null) onExecute('poll', pollData);
        break;
      case 'remind':
        final remindData = await BuiltInCommands.showReminderCreator(context);
        if (remindData != null) onExecute('remind', remindData);
        break;
      case 'todo':
        final todoData = await BuiltInCommands.showTodoCreator(context);
        if (todoData != null) onExecute('todo', todoData);
        break;
      default:
        onExecute(cmd, {'text': currentInput});
    }
  }
}
