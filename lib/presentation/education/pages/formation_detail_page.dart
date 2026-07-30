// lib/presentation/education/pages/formation_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:thix_id/presentation/education/models/formation.dart';
import 'package:thix_id/presentation/education/models/lesson.dart';
import 'package:thix_id/presentation/education/providers/education_provider.dart';
import 'package:thix_id/presentation/education/widgets/common/education_empty_state.dart';
import 'package:thix_id/presentation/education/widgets/common/education_loading_shimmer.dart';
import 'package:thix_id/presentation/education/widgets/formation_detail/formation_module_list.dart';

class FormationDetailPage extends ConsumerStatefulWidget {
  final String formationId;
  const FormationDetailPage({super.key, required this.formationId});

  @override
  ConsumerState<FormationDetailPage> createState() => _FormationDetailPageState();
}

class _FormationDetailPageState extends ConsumerState<FormationDetailPage> {
  bool _isEnrolling = false;

  @override
  Widget build(BuildContext context) {
    final formationAsync = ref.watch(formationDetailProvider(widget.formationId));
    final userId = Supabase.instance.client.auth.currentUser?.id;
    
    // Surveillance de l'état d'inscription
    final enrollmentAsync = userId == null 
        ? null 
        : ref.watch(enrollmentProvider((userId: userId, formationId: widget.formationId)));

    return formationAsync.when(
      loading: () => const Scaffold(body: EducationLoadingShimmer()),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Text('Erreur de chargement : $err', style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
        ),
      ),
      data: (formation) {
        if (formation == null) {
          return Scaffold(
            body: EducationEmptyState(
              title: 'Formation introuvable',
              subtitle: 'Cette formation n\'existe pas ou a été supprimée.',
              icon: Icons.school_rounded,
              buttonText: 'Retourner à la liste',
              onButtonPressed: () => context.pop(),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text(formation.title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 18)),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)), onPressed: () => context.pop()),
            actions: [
              IconButton(icon: const Icon(Icons.bookmark_border_rounded, color: Color(0xFF1E293B)), onPressed: () {}),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(formation),
                const SizedBox(height: 20),
                _buildDescription(formation),
                const SizedBox(height: 20),
                _buildInfoRow(formation),
                const SizedBox(height: 20),
                _buildEnrollButton(formation, enrollmentAsync, userId),
                const SizedBox(height: 24),
                FormationModuleList(
                  formation: formation,
                  onLessonTap: (lesson) => _openLesson(lesson),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Formation formation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formation.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          if (formation.instructorName != null && formation.instructorName!.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF7386A8)),
                const SizedBox(width: 6),
                Text(formation.instructorName!, style: const TextStyle(color: Color(0xFF7386A8), fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.school_rounded, size: 16, color: Color(0xFF7386A8)),
              const SizedBox(width: 6),
              Text(formation.category?.name ?? 'Non catégorisé', style: const TextStyle(color: Color(0xFF7386A8), fontSize: 13, fontWeight: FontWeight.w500)),
              const Spacer(),
              if (formation.level.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF2D6CDF).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    formation.level == 'beginner' ? 'Débutant' : formation.level == 'intermediate' ? 'Intermédiaire' : 'Avancé',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2D6CDF)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF7386A8)),
              const SizedBox(width: 6),
              Text('${formation.duration ~/ 60}h ${formation.duration % 60}min', style: const TextStyle(color: Color(0xFF7386A8), fontSize: 13, fontWeight: FontWeight.w500)),
              const Spacer(),
              if (formation.price > 0)
                Text('${formation.price.toInt()} ${formation.currency}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2D6CDF)))
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Gratuit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(Formation formation) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 10),
          Text(formation.description, style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF7386A8))),
        ],
      ),
    );
  }

  Widget _buildInfoRow(Formation formation) {
    final totalLessons = formation.modules?.fold<int>(0, (sum, m) => sum + (m.lessons?.length ?? 0)) ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(Icons.people_rounded, '${formation.enrollments?.length ?? 0}', 'Élèves'),
          _buildInfoItem(Icons.video_library_rounded, '$totalLessons', 'Leçons'),
          _buildInfoItem(Icons.star_rounded, '4.5', 'Note'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2D6CDF), size: 22),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF7386A8), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildEnrollButton(Formation formation, AsyncValue? enrollmentAsync, String? userId) {
    final isEnrolled = enrollmentAsync?.value != null;
    final progress = ((enrollmentAsync?.value?['progress'] ?? 0) * 100).toInt();

    if (isEnrolled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
            const SizedBox(width: 8),
            Text('Déjà inscrit · Progression : $progress%', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF10B981), fontSize: 15)),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isEnrolling ? null : () => _enrollUser(userId, formation.id),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D6CDF),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isEnrolling
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('S\'inscrire à cette formation', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }

  Future<void> _enrollUser(String? userId, String formationId) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter pour vous inscrire.'), backgroundColor: Color(0xFFEF4444)),
      );
      return;
    }

    setState(() => _isEnrolling = true);

    try {
      // ✅ 1. Tentative d'utilisation du provider d'inscription
      bool success = false;
      try {
        success = await ref.read(enrollProvider.notifier).enroll(userId: userId, formationId: formationId);
      } catch (e) {
        success = false;
      }

      // ✅ 2. SOLUTION DE SECOURS DIRECTE EN BASE SI LE PROVIDER ECHOUE
      if (!success) {
        await Supabase.instance.client.from('enrollments').insert({
          'user_id': userId,
          'formation_id': formationId,
          'status': 'active',
          'progress': 0.0,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inscription réussie ! Bon apprentissage.'), backgroundColor: Color(0xFF10B981)),
        );
        // On force le rafraîchissement pour afficher le bouton "Déjà inscrit"
        ref.invalidate(enrollmentProvider((userId: userId, formationId: formationId)));
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().contains('duplicate key') 
            ? 'Vous êtes déjà inscrit à cette formation.' 
            : 'Erreur lors de l\'inscription : $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _isEnrolling = false);
    }
  }

  void _openLesson(Lesson lesson) {
    context.push(
      '/education/lesson/${lesson.id}',
      extra: {'formationId': widget.formationId, 'moduleId': lesson.moduleId, 'lesson': lesson},
    );
  }
}
