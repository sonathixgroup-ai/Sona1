// lib/presentation/education/pages/formation_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:thix_id/presentation/education/providers/education_provider.dart';
import 'package:thix_id/presentation/education/providers/progress_provider.dart';
import 'package:thix_id/presentation/education/models/formation.dart';
import 'package:thix_id/presentation/education/models/module.dart';
import 'package:thix_id/presentation/education/models/lesson.dart';
import 'package:thix_id/presentation/education/widgets/common/education_loading_shimmer.dart';

class FormationDetailPage extends StatefulWidget {
  final String formationId;
  const FormationDetailPage({super.key, required this.formationId});

  @override
  State<FormationDetailPage> createState() => _FormationDetailPageState();
}

class _FormationDetailPageState extends State<FormationDetailPage> {
  bool _isEnrolled = false;
  bool _loadingEnrollment = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<EducationProvider>();
    await provider.loadFormationDetails(widget.formationId);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final isEnrolled = await provider.isUserEnrolled(userId, widget.formationId);
      setState(() {
        _isEnrolled = isEnrolled;
        _loadingEnrollment = false;
      });
    } else {
      setState(() => _loadingEnrollment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EducationProvider>();
    final formation = provider.currentFormation;

    // ✅ Déclaration extraite pour éviter l'erreur dans le Column
    final modules = formation?.modules ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        title: Text(
          formation?.title ?? 'Détail formation',
          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => context.pop(),
        ),
      ),
      body: provider.isLoading
          ? const EducationLoadingShimmer()
          : formation == null
              ? const Center(child: Text('Formation introuvable'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          formation.imageUrl ?? 'https://via.placeholder.com/800x200',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 180,
                            color: const Color(0xFFF0F7FF),
                            child: const Icon(Icons.image_rounded, size: 60, color: Color(0xFF7386A8)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Titre et infos
                      Text(
                        formation.title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF7386A8)),
                          const SizedBox(width: 6),
                          Text(
                            formation.instructor ?? 'Instructeur',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF7386A8)),
                          ),
                          const Spacer(),
                          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 4),
                          Text(
                            formation.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${formation.reviewsCount} avis)',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF7386A8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      if (formation.description.isNotEmpty) ...[
                        const Text(
                          'Description',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formation.description,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E), height: 1.5),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Prix / gratuit
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D6CDF).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.school_rounded, color: Color(0xFF2D6CDF)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                formation.price > 0
                                    ? '${formation.price.toInt()} FC'
                                    : 'Gratuit',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2D6CDF),
                                ),
                              ),
                            ),
                            if (!_loadingEnrollment)
                              ElevatedButton(
                                onPressed: _isEnrolled
                                    ? null
                                    : () async {
                                        final userId = Supabase.instance.client.auth.currentUser?.id;
                                        if (userId == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Veuillez vous connecter.')),
                                          );
                                          return;
                                        }
                                        final success = await context.read<EducationProvider>().enrollUser(userId, formation.id);
                                        if (!context.mounted) return;
                                        if (success != null) {
                                          setState(() => _isEnrolled = true);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Inscription réussie !'), backgroundColor: Color(0xFF2ECC71)),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Échec de l\'inscription.'), backgroundColor: Color(0xFFFF5B3D)),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isEnrolled ? const Color(0xFF7386A8) : const Color(0xFF2D6CDF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                child: Text(_isEnrolled ? 'Inscrit' : 'S\'inscrire'),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Modules (la variable `modules` est définie avant le retour)
                      if (modules.isNotEmpty) ...[
                        const Text(
                          'Contenu de la formation',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
                        ),
                        const SizedBox(height: 12),
                        ...modules.map((module) => _ModuleCard(module: module, isEnrolled: _isEnrolled)),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final Module module;
  final bool isEnrolled;

  const _ModuleCard({required this.module, required this.isEnrolled});

  @override
  Widget build(BuildContext context) {
    final lessons = module.lessons ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EEFC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            module.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 4),
          Text(
            '${lessons.length} leçons',
            style: const TextStyle(fontSize: 13, color: Color(0xFF7386A8)),
          ),
          const SizedBox(height: 8),
          ...lessons.map((lesson) => _LessonTile(lesson: lesson, isEnrolled: isEnrolled)),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final Lesson lesson;
  final bool isEnrolled;

  const _LessonTile({required this.lesson, required this.isEnrolled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F7FF))),
      ),
      child: Row(
        children: [
          Icon(
            lesson.type == 'video' ? Icons.play_circle_rounded :
            lesson.type == 'quiz' ? Icons.quiz_rounded :
            Icons.text_snippet_rounded,
            size: 20,
            color: const Color(0xFF2D6CDF),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
                ),
                if (lesson.durationMinutes > 0)
                  Text(
                    '${lesson.durationMinutes} min',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF7386A8)),
                  ),
              ],
            ),
          ),
          if (isEnrolled)
            IconButton(
              icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF2D6CDF)),
              onPressed: () {
                // Naviguer vers la leçon
              },
            ),
        ],
      ),
    );
  }
}
