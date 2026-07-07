// lib/presentation/education/screens/education_forum.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/forum_provider.dart';
import '../../../providers/education_provider.dart';
import '../widgets/common/education_empty_state.dart';
import '../widgets/forum/forum_topic_card.dart';
import '../widgets/forum/forum_create_topic_dialog.dart';
import 'package:thix_id/presentation/education/providers/forum_provider.dart';
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
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<ForumProvider>();
    await provider.loadTopics(widget.formationId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ForumProvider>();
    final topics = provider.topics;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        title: const Text(
          'Forum de la formation',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFF1A1A2E)),
            onPressed: _showCreateTopicDialog,
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : topics.isEmpty
              ? EducationEmptyState(
                  title: 'Aucun sujet',
                  subtitle: 'Soyez le premier à poser une question',
                  icon: Icons.forum_rounded,
                  buttonText: 'Créer un sujet',
                  onButtonPressed: _showCreateTopicDialog,
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
                        onTap: () => context.push(
                          '/education/forum/topic/${topic.id}',
                          extra: topic,
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showCreateTopicDialog() {
    showDialog(
      context: context,
      builder: (context) => ForumCreateTopicDialog(
        formationId: widget.formationId,
      ),
    ).then((_) => _loadData());
  }
}
