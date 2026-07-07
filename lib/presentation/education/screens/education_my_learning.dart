// lib/presentation/education/screens/education_my_learning.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../models/enrollment.dart';
import '../../../providers/education_provider.dart';
import '../../../providers/progress_provider.dart';
import '../widgets/common/education_empty_state.dart';
import '../widgets/common/education_loading_shimmer.dart';
import '../widgets/formation_card.dart';

class EducationMyLearning extends StatefulWidget {
  const EducationMyLearning({super.key});

  @override
  State<EducationMyLearning> createState() => _EducationMyLearningState();
}

class _EducationMyLearningState extends State<EducationMyLearning> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final provider = context.read<EducationProvider>();
    await provider.loadMyEnrollments(userId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EducationProvider>();
    final enrollments = provider.myEnrollments;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        title: const Text(
          'Mon apprentissage',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: provider.isLoading
          ? const EducationLoadingShimmer()
          : enrollments.isEmpty
              ? EducationEmptyState(
                  title: 'Aucune formation en cours',
                  subtitle: 'Inscrivez-vous à une formation pour commencer à apprendre',
                  icon: Icons.play_circle_outline_rounded,
                  buttonText: 'Découvrir les formations',
                  onButtonPressed: () => context.go('/education'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: enrollments.length,
                  itemBuilder: (context, index) {
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
  }
}
