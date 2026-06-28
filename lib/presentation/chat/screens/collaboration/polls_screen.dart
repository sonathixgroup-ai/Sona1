import 'package:flutter/material.dart';

class PollsScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String conversationName;

  const PollsScreen({
    Key? key,
    required this.conversationId,
    required this.conversationName,
  }) : super(key: key);

  @override
  ConsumerState<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends ConsumerState<PollsScreen> {
  final List<Poll> _polls = [
    Poll(
      id: '1',
      question: 'Quelle est votre langue préférée?',
      options: [
        PollOption(text: 'Français', votes: 5),
        PollOption(text: 'Anglais', votes: 3),
        PollOption(text: 'Espagnol', votes: 2),
      ],
      totalVotes: 10,
      isAnonymous: false,
      allowMultiple: false,
    ),
  ];

  void _createPoll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer un sondage'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Question',
                  hintText: 'Posez votre question',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Option 1',
                  hintText: 'Première option',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Option 2',
                  hintText: 'Deuxième option',
                ),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Sondages - ${widget.conversationName}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF5A67D8)),
            onPressed: _createPoll,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _polls.length,
        itemBuilder: (context, index) {
          final poll = _polls[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  poll.question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...poll.options.map((option) {
                  final percentage = (option.votes / poll.totalVotes * 100).toStringAsFixed(1);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(option.text),
                            Text(
                              '$percentage% (${option.votes})',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: option.votes / poll.totalVotes,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF5A67D8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 12),
                Text(
                  'Total: ${poll.totalVotes} votes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class Poll {
  final String id;
  final String question;
  final List<PollOption> options;
  final int totalVotes;
  final bool isAnonymous;
  final bool allowMultiple;

  Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.totalVotes,
    this.isAnonymous = false,
    this.allowMultiple = false,
  });
}

class PollOption {
  final String text;
  int votes;

  PollOption({
    required this.text,
    this.votes = 0,
  });
}
