// lib/presentation/chat/polls/poll_list_widget.dart
// Liste des sondages d'une conversation (affichage compact)

import 'package:flutter/material.dart';
import 'poll_vote_widget.dart';
import 'poll_results_widget.dart';

class PollDataWithStatus {
  final String id;
  final String question;
  final List<String> options;
  final bool isMultipleChoice;
  final bool isAnonymous;
  final DateTime? expiresAt;
  final bool hasVoted;
  final Map<String, int>? results;
  final int totalVotes;

  PollDataWithStatus({
    required this.id,
    required this.question,
    required this.options,
    this.isMultipleChoice = false,
    this.isAnonymous = false,
    this.expiresAt,
    this.hasVoted = false,
    this.results,
    this.totalVotes = 0,
  });
}

class PollListWidget extends StatelessWidget {
  final List<PollDataWithStatus> polls;
  final Function(String pollId, List<String> selectedOptions) onVote;

  const PollListWidget({
    Key? key,
    required this.polls,
    required this.onVote,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (polls.isEmpty) {
      return const Center(child: Text('Aucun sondage dans cette conversation'));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: polls.length,
      itemBuilder: (context, index) {
        final poll = polls[index];
        final isExpired = poll.expiresAt != null && DateTime.now().isAfter(poll.expiresAt!);
        if (poll.hasVoted || isExpired) {
          if (poll.results != null) {
            return PollResultsWidget(
              question: poll.question,
              votes: poll.results!,
              totalVotes: poll.totalVotes,
              isAnonymous: poll.isAnonymous,
            );
          } else {
            return const SizedBox.shrink();
          }
        } else {
          return PollVoteWidget(
            pollId: poll.id,
            question: poll.question,
            options: poll.options,
            isMultipleChoice: poll.isMultipleChoice,
            onVote: onVote,
          );
        }
      },
    );
  }
}
