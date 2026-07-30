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

class _C {
  static const bg = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const primary = Color(0xFF2D6CDF);
  static const green = Color(0xFF10B981);
  static const textMain = Color(0xFF1E293B);
  static const textMuted = Color(0xFF7386A8);
  static const border = Color(0xFFE2E8F0);
}

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

        final isEnrolled = enrollmentAsync?.value != null;

        return Scaffold(
          backgroundColor: _C.bg,
          // 🚀 UI ENTREPRISE : Utilisation de CustomScrollView et SliverAppBar pour l'image
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true,
                backgroundColor: _C.surface,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), 
                    onPressed: () => context.pop()
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.bookmark_border_rounded, color: Colors.white), 
                      onPressed: () {}
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Affichage de l'image de couverture
                      if (formation.imageUrl != null && formation.imageUrl!.isNotEmpty)
                        Image.network(
                          formation.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                        )
                      else
                        _buildPlaceholderImage(),
                      
                      // Dégradé sombre pour que le texte et les icônes ressortent
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black54, Colors.transparent, Colors.black87],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 20,
                        right: 20,
                        child: Text(
                          formation.title,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Contenu de la page
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAuthorAndMeta(formation),
                      const SizedBox(height: 24),
                      _buildEnrollmentSection(formation, isEnrolled, enrollmentAsync, userId),
                      const SizedBox(height: 24),
                      _buildInfoRow(formation),
                      const SizedBox(height: 24),
                      _buildDescription(formation),
                      const SizedBox(height: 32),
                      
                      const Text('Programme du cours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _C.textMain)),
                      const SizedBox(height: 16),
                      FormationModuleList(
                        formation: formation,
                        // Si l'utilisateur n'est pas inscrit, on peut bloquer l'accès aux leçons
                        onLessonTap: (lesson) {
                          if (isEnrolled) {
                            _openLesson(lesson, formation);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Veuillez vous inscrire pour accéder au contenu.'), behavior: SnackBarBehavior.floating),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: _C.primary.withOpacity(0.1),
      child: const Center(
        child: Icon(Icons.school_rounded, size: 64, color: _C.primary),
      ),
    );
  }

  Widget _buildAuthorAndMeta(Formation formation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (formation.instructorName != null && formation.instructorName!.isNotEmpty)
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _C.primary.withOpacity(0.2),
                child: const Icon(Icons.person, size: 16, color: _C.primary),
              ),
              const SizedBox(width: 10),
              Text(
                formation.instructorName!,
                style: const TextStyle(color: _C.textMain, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: _C.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(
                formation.category?.name ?? 'Non catégorisé',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _C.primary),
              ),
            ),
            const SizedBox(width: 10),
            if (formation.level.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: _C.border, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  formation.level == 'beginner' ? 'Débutant' : formation.level == 'intermediate' ? 'Intermédiaire' : 'Avancé',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _C.textMain),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // 🚀 UX DYNAMIQUE : Le bloc d'inscription s'adapte automatiquement
  Widget _buildEnrollmentSection(Formation formation, bool isEnrolled, AsyncValue? enrollmentAsync, String? userId) {
    if (isEnrolled) {
      final progress = ((enrollmentAsync?.value?['progress'] ?? 0) * 100).toInt();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Votre progression', style: TextStyle(fontWeight: FontWeight.w700, color: _C.textMain)),
              Text('$progress%', style: const TextStyle(fontWeight: FontWeight.w800, color: _C.primary)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: _C.border,
            color: _C.primary,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _startOrContinueLearning(formation),
              icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
              label: const Text('Continuer l\'apprentissage', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      );
    }

    // Vue si non inscrit
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.primary.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: _C.primary.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Prix du cours', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _C.textMuted)),
              if (formation.price > 0)
                Text('${formation.price.toInt()} ${formation.currency}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _C.textMain))
              else
                const Text('Gratuit', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _C.green)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isEnrolling ? null : () => _enrollUser(userId, formation),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isEnrolling
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Commencer ce cours', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // 🚀 REDIRECTION INTELLIGENTE APRÈS INSCRIPTION
  Future<void> _enrollUser(String? userId, Formation formation) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez vous connecter.')));
      return;
    }

    setState(() => _isEnrolling = true);

    try {
      bool success = false;
      try {
        success = await ref.read(enrollProvider.notifier).enroll(userId: userId, formationId: formation.id);
      } catch (_) {
        success = false;
      }

      if (!success) {
        await Supabase.instance.client.from('enrollments').insert({
          'uid': userId,
          'formation_id': formation.id,
          'status': 'active',
          'progress': 0.0,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        // 1. Rafraîchir les états pour que le cours apparaisse dans "Mes cours"
        ref.invalidate(enrollmentProvider((userId: userId, formationId: formation.id)));
        
        // 2. Lancer la première leçon immédiatement ou rediriger vers l'espace Apprendre
        _startOrContinueLearning(formation);
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('duplicate key') ? 'Vous êtes déjà inscrit.' : 'Erreur: $e';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: _C.red));
      }
    } finally {
      if (mounted) setState(() => _isEnrolling = false);
    }
  }

  void _startOrContinueLearning(Formation formation) {
    // Cherche la première leçon disponible dans les modules
    if (formation.modules != null && formation.modules!.isNotEmpty) {
      for (var module in formation.modules!) {
        if (module.lessons != null && module.lessons!.isNotEmpty) {
          final firstLesson = module.lessons!.first;
          _openLesson(firstLesson, formation);
          return; // On arrête dès qu'on a trouvé la leçon
        }
      }
    }
    
    // Si le cours est vide (aucune leçon), on redirige vers le tableau de bord Apprendre
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Le contenu arrive bientôt ! Redirection vers vos cours.'), backgroundColor: _C.green),
    );
    // ⚠️ Ajustez ce chemin '/apprendre' selon la configuration exacte de votre GoRouter pour l'onglet "Mes cours"
    context.go('/apprendre'); 
  }

  void _openLesson(Lesson lesson, Formation formation) {
    context.push(
      '/education/lesson/${lesson.id}',
      extra: {'formationId': formation.id, 'moduleId': lesson.moduleId, 'lesson': lesson},
    );
  }

  Widget _buildDescription(Formation formation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('À propos de ce cours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _C.textMain)),
        const SizedBox(height: 12),
        Text(formation.description, style: const TextStyle(fontSize: 14, height: 1.6, color: _C.textMuted)),
      ],
    );
  }

  Widget _buildInfoRow(Formation formation) {
    final totalLessons = formation.modules?.fold<int>(0, (sum, m) => sum + (m.lessons?.length ?? 0)) ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildInfoItem(Icons.people_rounded, '${formation.enrollments?.length ?? 0}', 'Élèves'),
        _buildInfoItem(Icons.video_library_rounded, '$totalLessons', 'Leçons'),
        _buildInfoItem(Icons.timer_rounded, '${formation.duration ~/ 60}h', 'Durée'),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _C.surface, shape: BoxShape.circle, border: Border.all(color: _C.border)),
          child: Icon(icon, color: _C.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _C.textMain)),
        Text(label, style: const TextStyle(fontSize: 12, color: _C.textMuted, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
