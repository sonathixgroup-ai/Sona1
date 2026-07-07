// lib/presentation/education/screens/education_forum.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/education/providers/forum_provider.dart';
import 'package:thix_id/presentation/education/models/forum_topic.dart';
import 'package:thix_id/presentation/education/widgets/forum/forum_topic_card.dart';
import 'package:thix_id/presentation/education/widgets/forum/forum_create_topic_dialog.dart';
import 'package:thix_id/presentation/education/widgets/common/education_empty_state.dart';

class EducationForum extends StatefulWidget {
  final String formationId;
  const EducationForum({super.key, required this.formationId});

  @override
  State<EducationForum> createState() => _EducationForumState();
}

class _EducationForumState extends State<EducationForum> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ForumProvider>().loadTopics(widget.formationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ForumProvider>();
    final topics = provider.topics;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        title: const Text('Forum', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFF1A1A2E)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => ForumCreateTopicDialog(formationId: widget.formationId),
              ).then((_) => provider.loadTopics(widget.formationId));
            },
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => context.pop(),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : topics.isEmpty
              ? EducationEmptyState(
                  title: 'Aucun sujet',
                  subtitle: 'Soyez le premier à poser une question',
                  icon: Icons.forum_rounded,
                  buttonText: 'Créer un sujet',
                  onButtonPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => ForumCreateTopicDialog(formationId: widget.formationId),
                    ).then((_) => provider.loadTopics(widget.formationId));
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ForumTopicCard(
                        topic: topic,
                        onTap: () => context.push('/education/forum/topic/${topic.id}'),
                      ),
                    );
                  },
                ),
    );
  }
}
