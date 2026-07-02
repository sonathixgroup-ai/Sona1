// lib/presentation/chat/polls/inline_poll_widget.dart
// Widget de sondage intégré dans le flux des messages (un seul sondage, style compact)

import 'package:flutter/material.dart';
import 'poll_vote_widget.dart';
import 'poll_results_widget.dart';

class InlinePollWidget extends StatelessWidget {
  final String pollId;
  final String question;
  final List<String> options;
  final bool isMultipleChoice;
  final bool isAnonymous;
  final DateTime? expiresAt;
  final bool hasVoted;
  final Map<String, int>? results;
  final int totalVotes;
  final Function(String pollId, List<String> selectedOptions) onVote;

  const InlinePollWidget({
    Key? key,
    required this.pollId,
    required this.question,
    required this.options,
    this.isMultipleChoice = false,
    this.isAnonymous = false,
    this.expiresAt,
    this.hasVoted = false,
    this.results,
    this.totalVotes = 0,
    required this.onVote,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isExpired = expiresAt != null && DateTime.now().isAfter(expiresAt!);
    if (hasVoted || isExpired) {
      if (results != null) {
        return PollResultsWidget(
          question: question,
          votes: results!,
          totalVotes: totalVotes,
          isAnonymous: isAnonymous,
        );
      } else {
        return const SizedBox.shrink();
      }
    } else {
      return PollVoteWidget(
        pollId: pollId,
        question: question,
        options: options,
        isMultipleChoice: isMultipleChoice,
        onVote: onVote,
      );
    }
  }
}
