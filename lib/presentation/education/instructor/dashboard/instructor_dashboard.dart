import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importez ici votre fichier contenant formationsProvider
// import 'package:thix_id/presentation/education/providers/votre_fichier_provider.dart';

class InstructorDashboard extends ConsumerStatefulWidget {
  const InstructorDashboard({super.key});

  @override
  ConsumerState<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends ConsumerState<InstructorDashboard> {
  int _totalCourses = 0;
  int _totalStudents = 0;
  int _totalAssignments = 0;
  double _averageProgress = 0.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // ✅ CORRIGÉ : On compte directement depuis Supabase pour le tableau de bord
    final res = await Supabase.instance.client
        .from('formations')
        .select('id')
        .eq('instructor_id', userId);

    if (mounted) {
      setState(() {
        _totalCourses = res.length;
        _totalStudents = 0; // à calculer plus tard
        _totalAssignments = 0;
        _averageProgress = 0.0;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Tableau de bord formateur'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            onPressed: () => context.push('/education'),
            tooltip: 'Retour à l\'espace apprenant',
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StatCard(icon: Icons.school_rounded, label: 'Cours', value: '$_totalCourses', color: const Color(0xFF2D6CDF)),
                      const SizedBox(width: 12),
                      _StatCard(icon: Icons.people_rounded, label: 'Étudiants', value: '$_totalStudents', color: const Color(0xFF10B981)),
                      const SizedBox(width: 12),
                      _StatCard(icon: Icons.assignment_rounded, label: 'Devoirs', value: '$_totalAssignments', color: const Color(0xFFF59E0B)),
                      const SizedBox(width: 12),
                      _StatCard(icon: Icons.trending_up_rounded, label: 'Progression', value: '${(_averageProgress * 100).toInt()}%', color: const Color(0xFF8B5CF6)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Actions rapides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _QuickAction(icon: Icons.add_rounded, label: 'Nouveau cours', onTap: () => context.push('/instructor/courses/create'), color: const Color(0xFF2D6CDF)),
                      _QuickAction(icon: Icons.menu_book_rounded, label: 'Mes cours', onTap: () => context.push('/instructor/courses'), color: const Color(0xFF10B981)),
                      _QuickAction(icon: Icons.people_rounded, label: 'Étudiants', onTap: () => context.push('/instructor/students'), color: const Color(0xFF8B5CF6)),
                      _QuickAction(icon: Icons.bar_chart_rounded, label: 'Performance', onTap: () => context.push('/instructor/performance'), color: const Color(0xFFF59E0B)),
                      _QuickAction(icon: Icons.announcement_rounded, label: 'Annonces', onTap: () => context.push('/instructor/announcements'), color: const Color(0xFFEF4444)),
                      _QuickAction(icon: Icons.calendar_today_rounded, label: 'Calendrier', onTap: () => context.push('/instructor/calendar'), color: const Color(0xFF0D9488)),
                      _QuickAction(icon: Icons.flag_rounded, label: 'Bannière À la une', onTap: () => context.push('/instructor/banner'), color: const Color(0xFFEF4444)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Activités récentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: const Color(0xFF0A1F44).withOpacity(0.04), blurRadius: 12)],
                    ),
                    child: Column(
                      children: [
                        _ActivityItem(icon: Icons.person_add_rounded, title: 'Nouvel étudiant inscrit', time: 'Il y a 2 heures', color: const Color(0xFF10B981)),
                        _ActivityItem(icon: Icons.assignment_rounded, title: 'Devoir rendu', time: 'Il y a 4 heures', color: const Color(0xFFF59E0B)),
                        _ActivityItem(icon: Icons.forum_rounded, title: 'Nouveau message dans le forum', time: 'Il y a 1 jour', color: const Color(0xFF2D6CDF)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon; final String label; final String value; final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});
  @override Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: const Color(0xFF0A1F44).withOpacity(0.04), blurRadius: 12)]),
        child: Column(children: [Icon(icon, color: color, size: 28), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))), Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF7386A8)))]),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap; final Color color;
  const _QuickAction({required this.icon, required this.label, required this.onTap, required this.color});
  @override Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color))]),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon; final String title; final String time; final Color color;
  const _ActivityItem({required this.icon, required this.title, required this.time, required this.color});
  @override Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))), Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF7386A8)))])),
      ]),
    );
  }
}
