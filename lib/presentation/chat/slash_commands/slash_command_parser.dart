// lib/presentation/chat/slash_commands/slash_command_parser.dart
// Analyse les commandes slash et retourne une structure exploitable

class ParsedSlashCommand {
  final String command; // ex: "poll", "remind", "todo"
  final List<String> args; // arguments
  final String? rawText; // texte restant après la commande

  ParsedSlashCommand({
    required this.command,
    required this.args,
    this.rawText,
  });
}

class SlashCommandParser {
  // Liste des commandes disponibles
  static const List<String> supportedCommands = ['poll', 'remind', 'todo', 'me', 'giphy', 'code'];

  static ParsedSlashCommand? parse(String text) {
    if (!text.startsWith('/')) return null;
    final parts = text.split(' ');
    if (parts.isEmpty) return null;
    final command = parts[0].substring(1).toLowerCase();
    if (!supportedCommands.contains(command)) return null;
    final args = parts.skip(1).toList();
    final rawText = parts.length > 1 ? parts.skip(1).join(' ') : null;
    return ParsedSlashCommand(command: command, args: args, rawText: rawText);
  }

  static bool isSlashCommand(String text) {
    return text.startsWith('/') && supportedCommands.any((cmd) => text.substring(1).startsWith(cmd));
  }
}
