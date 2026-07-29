import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ✅ CORRIGÉ : Import explicite depuis la racine du projet
import 'package:thix_id/presentation/education/providers/education_provider.dart'; 
import '../widgets/common/education_empty_state.dart';
import '../widgets/common/education_loading_shimmer.dart';
import '../widgets/common/formation_card.dart';

class EducationMyLearning extends ConsumerStatefulWidget {
  const EducationMyLearning({super.key});

  @override
  ConsumerState<EducationMyLearning> createState() => _EducationMyLearningState();
}

class _EducationMyLearningState extends ConsumerState<EducationMyLearning> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 300) {
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        ref.read(myEnrollmentsProvider(userId).notifier).loadMore();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7FAFF),
        appBar: AppBar(title: const Text('Mon apprentissage', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: Colors.white),
        body: const Center(child: Text('Non connecté')),
      );
    }

    final enrollmentsAsync = ref.watch(myEnrollmentsProvider(userId));

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        title: const Text('Mon apprentissage', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E)), onPressed: () => Navigator.pop(context)),
      ),
      body: enrollmentsAsync.when(
        loading: () => const EducationLoadingShimmer(),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (enrollments) {
          if (enrollments.isEmpty) {
            return EducationEmptyState(
              title: 'Aucune formation en cours',
              subtitle: 'Inscrivez-vous à une formation pour commencer à apprendre',
              icon: Icons.play_circle_outline_rounded,
              buttonText: 'Découvrir les formations',
              onButtonPressed: () => context.go('/education'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myEnrollmentsProvider(userId)),
            color: const Color(0xFF2D6CDF),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: enrollments.length + 1,
              itemBuilder: (context, index) {
                if (index == enrollments.length) {
                  final hasMore = ref.read(myEnrollmentsProvider(userId).notifier).hasMore;
                  return hasMore ? const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator(color: Color(0xFF2D6CDF)))) : const SizedBox(height: 32);
                }
                final enrollment = enrollments[index];
                final formation = enrollment.formation;
                if (formation == null) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FormationCard(
                    formation: formation,
                    onTap: () => context.push('/education/formation/${formation.id}'),
                    progress: enrollment.progress,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
