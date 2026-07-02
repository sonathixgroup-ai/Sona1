// lib/presentation/chat/widgets/reaction_picker.dart
import 'package:flutter/material.dart';
import '../core/chat_constants.dart';

class ReactionPicker extends StatelessWidget {
  final ValueChanged<String> onReactionSelected;

  const ReactionPicker({Key? key, required this.onReactionSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ChatConstants.defaultReactions.map((reaction) {
          return InkWell(
            onTap: () => onReactionSelected(reaction),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Text(reaction, style: const TextStyle(fontSize: 28)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
