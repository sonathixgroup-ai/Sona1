// lib/presentation/education/widgets/formation_detail/formation_lesson_player.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/lesson.dart';
import '../../../providers/progress_provider.dart';
import 'formation_video_player.dart';
import 'formation_evaluation_widget.dart';

class FormationLessonPlayer extends StatefulWidget {
  final Lesson lesson;
  final String formationId;
  final String moduleId;
  final VoidCallback? onComplete;

  const FormationLessonPlayer({
    super.key,
    required this.lesson,
    required this.formationId,
    required this.moduleId,
    this.onComplete,
  });

  @override
  State<FormationLessonPlayer> createState() => _FormationLessonPlayerState();
}

class _FormationLessonPlayerState extends State<FormationLessonPlayer> {
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    // Vérifier si la leçon est déjà complétée
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final progressProvider = context.read<ProgressProvider>();
      final prog = progressProvider.getLessonProgress(widget.lesson.id);
      if (prog != null && prog.status == 'completed') {
        setState(() => _isCompleted = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          lesson.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              color: _isCompleted ? const Color(0xFF2ECC71) : const Color(0xFF7386A8),
            ),
            onPressed: () {
              // Marquer comme terminé manuellement
              _markAsCompleted();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description de la leçon
            if (lesson.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  lesson.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A2E),
                    height: 1.5,
                  ),
                ),
              ),
            // Contenu selon le type
            if (lesson.type == 'video' && lesson.video != null)
              FormationVideoPlayer(
                video: lesson.video!,
                onProgress: (progress) {
                  _updateProgress(progress);
                },
                onComplete: () {
                  _markAsCompleted();
                },
              )
            else if (lesson.type == 'quiz' && lesson.evaluation != null)
              FormationEvaluationWidget(
                evaluation: lesson.evaluation!,
                onComplete: (score, total) {
                  _markAsCompleted();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Quiz terminé ! Score : $score/$total'),
                      backgroundColor: const Color(0xFF2ECC71),
                    ),
                  );
                },
              )
            else if (lesson.type == 'text')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Contenu texte de la leçon (à intégrer depuis Supabase)',
                  style: const TextStyle(color: Color(0xFF1A1A2E)),
                ),
              ),
            const SizedBox(height: 16),
            // Bouton marquer comme terminé
            if (!_isCompleted && lesson.type != 'video' && lesson.type != 'quiz')
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _markAsCompleted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D6CDF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Marquer comme terminé',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            if (_isCompleted)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF2ECC71)),
                    SizedBox(width: 8),
                    Text(
                      'Leçon terminée ! 🎉',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2ECC71),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _updateProgress(double progress) {
    final progressProvider = context.read<ProgressProvider>();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final status = progress >= 1.0 ? 'completed' : 'in_progress';
    progressProvider.updateLessonProgress(
      userId,
      widget.lesson.id,
      status,
      progress,
    );
  }

  void _markAsCompleted() async {
    if (_isCompleted) return;

    final progressProvider = context.read<ProgressProvider>();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter')),
      );
      return;
    }

    setState(() => _isCompleted = true);
    await progressProvider.completeLesson(userId, widget.lesson.id);
    widget.onComplete?.call();
  }
}
