// lib/presentation/education/widgets/formation_detail/formation_module_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/formation.dart';
import '../../../models/module.dart';
import '../../../models/lesson.dart';
import '../../../providers/progress_provider.dart';

class FormationModuleList extends StatelessWidget {
  final Formation formation;
  final Function(Lesson) onLessonTap;

  const FormationModuleList({
    super.key,
    required this.formation,
    required this.onLessonTap,
  });

  @override
  Widget build(BuildContext context) {
    final progressProvider = context.watch<ProgressProvider>();
    final modules = formation.modules ?? [];

    if (modules.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Aucun module disponible pour le moment.',
            style: TextStyle(color: Color(0xFF7386A8)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contenu de la formation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: modules.length,
          itemBuilder: (context, index) {
            final module = modules[index];
            return _buildModuleTile(module, progressProvider);
          },
        ),
      ],
    );
  }

  Widget _buildModuleTile(Module module, ProgressProvider progressProvider) {
    final lessons = module.lessons ?? [];
    final totalLessons = lessons.length;
    final completedLessons = lessons.where((lesson) {
      final prog = progressProvider.getLessonProgress(lesson.id);
      return prog != null && prog.status == 'completed';
    }).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  module.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              if (totalLessons > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D6CDF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completedLessons/$totalLessons',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D6CDF),
                    ),
                  ),
                ),
            ],
          ),
          children: lessons.map((lesson) {
            final progress = progressProvider.getLessonProgress(lesson.id);
            final isCompleted = progress != null && progress.status == 'completed';
            final isInProgress = progress != null && progress.status == 'in_progress';

            return ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF2ECC71).withOpacity(0.1)
                      : isInProgress
                          ? const Color(0xFFFFA500).withOpacity(0.1)
                          : const Color(0xFFF0F7FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : isInProgress
                          ? Icons.hourglass_empty_rounded
                          : lesson.type == 'video'
                              ? Icons.play_arrow_rounded
                              : lesson.type == 'quiz'
                                  ? Icons.quiz_rounded
                                  : Icons.description_rounded,
                  color: isCompleted
                      ? const Color(0xFF2ECC71)
                      : isInProgress
                          ? const Color(0xFFFFA500)
                          : const Color(0xFF7386A8),
                  size: 16,
                ),
              ),
              title: Text(
                lesson.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
                  color: isCompleted ? const Color(0xFF1A1A2E) : const Color(0xFF1A1A2E),
                ),
              ),
              trailing: isCompleted
                  ? const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF2ECC71), size: 18)
                  : const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF7386A8), size: 18),
              onTap: () => onLessonTap(lesson),
            );
          }).toList(),
        ),
      ),
    );
  }
}
