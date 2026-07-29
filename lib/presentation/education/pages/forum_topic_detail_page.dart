// lib/presentation/education/pages/forum_topic_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ Modifié
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:thix_id/presentation/education/providers/forum_provider.dart';
import 'package:thix_id/presentation/education/models/forum_reply.dart';
import 'package:thix_id/presentation/education/widgets/common/education_loading_shimmer.dart';

// ✅ Modifié : ConsumerStatefulWidget au lieu de StatefulWidget
class ForumTopicDetailPage extends ConsumerStatefulWidget {
  final String topicId;

  const ForumTopicDetailPage({
    super.key,
    required this.topicId,
  });

  @override
  ConsumerState<ForumTopicDetailPage> createState() => _ForumTopicDetailPageState();
}

// ✅ Modifié : ConsumerState
class _ForumTopicDetailPageState extends ConsumerState<ForumTopicDetailPage> {
  final TextEditingController _replyController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReplies();
    });
  }

  Future<void> _loadReplies() async {
    // ✅ Modifié : Utilisation de ref.read() avec la variable de votre provider
    final provider = ref.read(forumProvider); 
    await provider.loadTopicReplies(widget.topicId);
  }

  Future<void> _sendReply() async {
    final content = _replyController.text.trim();

    if (content.isEmpty) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter.'),
        ),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      // ✅ Modifié : Utilisation de ref.read()
      final provider = ref.read(forumProvider);

      await provider.createReply(
        topicId: widget.topicId,
        userId: userId,
        body: content,
      );

      _replyController.clear();

      await _loadReplies();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réponse envoyée !'),
          backgroundColor: Color(0xFF2ECC71),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${e.toString()}'),
        ),
      );
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Modifié : Utilisation de ref.watch() au lieu de context.watch()
    final provider = ref.watch(forumProvider);
    final replies = provider.replies;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        title: const Text(
          'Sujet du forum',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF1A1A2E),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: provider.isLoading
          ? const EducationLoadingShimmer()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: replies.length,
                    itemBuilder: (context, index) {
                      final reply = replies[index];

                      return _ReplyCard(
                        reply: reply,
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: const Color(0xFFE7EEFC),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          decoration: const InputDecoration(
                            hintText: 'Votre réponse...',
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(
                                Radius.circular(30),
                              ),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Color(0xFFF7FAFF),
                            contentPadding:
                                EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed:
                            _sending ? null : _sendReply,
                        icon: Icon(
                          _sending
                              ? Icons.hourglass_empty_rounded
                              : Icons.send_rounded,
                          color: const Color(0xFF2D6CDF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ReplyCard extends StatelessWidget {
  final ForumReply reply;

  const _ReplyCard({
    required this.reply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE7EEFC),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1F44)
                .withOpacity(0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor:
                    Color(0xFFF0F7FF),
                child: Icon(
                  Icons.person,
                  size: 16,
                  color: Color(0xFF2D6CDF),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                reply.authorName ?? 'Utilisateur',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(reply.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF7386A8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reply.content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A1A2E),
              height: 1.4,
            ),
          ),
          if (reply.isSolution)
            Padding(
              padding:
                  const EdgeInsets.only(top: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71)
                      .withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Text(
                  '✅ Solution',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2ECC71),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return 'il y a ${diff.inDays}j';
    }

    if (diff.inHours > 0) {
      return 'il y a ${diff.inHours}h';
    }

    if (diff.inMinutes > 0) {
      return 'il y a ${diff.inMinutes}m';
    }

    return 'à l\'instant';
  }
}
