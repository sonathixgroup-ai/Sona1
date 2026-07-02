// lib/presentation/chat/polls/poll_results_widget.dart
// Affichage des résultats d'un sondage (barres de pourcentage)

import 'package:flutter/material.dart';

class PollResultsWidget extends StatelessWidget {
  final String question;
  final Map<String, int> votes; // option -> nombre de votes
  final int totalVotes;
  final bool isAnonymous;

  const PollResultsWidget({
    Key? key,
    required this.question,
    required this.votes,
    required this.totalVotes,
    this.isAnonymous = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            ...votes.entries.map((entry) {
              final percentage = totalVotes > 0 ? (entry.value / totalVotes) * 100 : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: const TextStyle(fontSize: 12)),
                        Text('${percentage.toStringAsFixed(1)}% (${entry.value})',
                            style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      color: Colors.blue,
                      minHeight: 6,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            if (isAnonymous)
              const Text('Votes anonymes', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
            Text('Total : $totalVotes vote(s)', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
