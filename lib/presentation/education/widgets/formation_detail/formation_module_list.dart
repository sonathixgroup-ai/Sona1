// lib/presentation/education/widgets/formation_detail/formation_module_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/presentation/education/models/formation.dart';
import 'package:thix_id/presentation/education/models/module.dart';
import 'package:thix_id/presentation/education/models/lesson.dart';
import 'package:thix_id/presentation/education/providers/progress_provider.dart';

class FormationModuleList extends StatelessWidget {
  final Formation formation;
  final Function(Lesson lesson) onLessonTap;

  const FormationModuleList({
    super.key,
    required this.formation,
    required this.onLessonTap,
  });

  @override
  Widget build(BuildContext context) {
    final modules = formation.modules ?? [];
    final progressProvider = context.watch<ProgressProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Modules',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        ...modules.map((module) => _buildModuleTile(module, progressProvider, context)),
      ],
    );
  }

  Widget _buildModuleTile(Module module, ProgressProvider progressProvider, BuildContext context) {
    final lessons = module.lessons ?? [];
    final completedLessons = lessons.where((l) => progressProvider.isLessonCompleted(l.id)).length;
    final totalLessons = lessons.length;
    final progress = totalLessons > 0 ? completedLessons / totalLessons : 0.0;

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
          title: Text(
            module.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${module.lessons?.length ?? 0} leçons',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  color: Colors.blue,
                  minHeight: 4,
                ),
              ),
            ],
          ),
          children: [
            ...lessons.map((lesson) => ListTile(
                  title: Text(lesson.title),
                  subtitle: Text(lesson.type ?? 'Leçon'),
                  trailing: progressProvider.isLessonCompleted(lesson.id)
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.play_arrow, color: Colors.blue),
                  onTap: () => onLessonTap(lesson),
                )),
          ],
        ),
      ),
    );
  }
}
