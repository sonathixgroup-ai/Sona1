// lib/presentation/chat/polls/poll_vote_widget.dart
// Widget pour voter dans un sondage (affiche les options avec boutons)

import 'package:flutter/material.dart';
import 'poll_results_widget.dart';

class PollVoteWidget extends StatefulWidget {
  final String pollId;
  final String question;
  final List<String> options;
  final bool isMultipleChoice;
  final Function(String pollId, List<String> selectedOptions) onVote;

  const PollVoteWidget({
    Key? key,
    required this.pollId,
    required this.question,
    required this.options,
    required this.isMultipleChoice,
    required this.onVote,
  }) : super(key: key);

  @override
  State<PollVoteWidget> createState() => _PollVoteWidgetState();
}

class _PollVoteWidgetState extends State<PollVoteWidget> {
  final Set<String> _selectedOptions = {};

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            ...widget.options.map((option) {
              return CheckboxListTile(
                title: Text(option, style: const TextStyle(fontSize: 13)),
                value: _selectedOptions.contains(option),
                onChanged: widget.isMultipleChoice
                    ? (val) {
                        setState(() {
                          if (val == true) {
                            _selectedOptions.add(option);
                          } else {
                            _selectedOptions.remove(option);
                          }
                        });
                      }
                    : (val) {
                        setState(() {
                          _selectedOptions.clear();
                          if (val == true) _selectedOptions.add(option);
                        });
                      },
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _selectedOptions.isEmpty
                  ? null
                  : () => widget.onVote(widget.pollId, _selectedOptions.toList()),
              child: const Text('Voter'),
            ),
          ],
        ),
      ),
    );
  }
}
