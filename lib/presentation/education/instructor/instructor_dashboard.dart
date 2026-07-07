// lib/presentation/education/instructor/instructor_dashboard.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/presentation/education/providers/education_provider.dart';

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  int _totalCourses = 0;
  int _totalStudents = 0;
  int _totalBooks = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final provider = context.read<EducationProvider>();
    await provider.loadFormations();
    // Pour l'instant on compte toutes les formations (à filtrer par instructorId)
    setState(() {
      _totalCourses = provider.formations.length;
      _totalStudents = 0; // à implémenter avec les inscriptions
      _totalBooks = 0; // à implémenter avec un service Book
      _loading = false;
    });
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
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistiques
                  Row(
                    children: [
                      _StatCard(
                        icon: Icons.school_rounded,
                        label: 'Cours',
                        value: '$_totalCourses',
                        color: const Color(0xFF2D6CDF),
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.people_rounded,
                        label: 'Étudiants',
                        value: '$_totalStudents',
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.library_books_rounded,
                        label: 'Livres',
                        value: '$_totalBooks',
                        color: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Actions rapides
                  const Text(
                    'Actions rapides',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _QuickAction(
                        icon: Icons.add_rounded,
                        label: 'Nouveau cours',
                        onTap: () => context.push('/instructor/courses/create'),
                        color: const Color(0xFF2D6CDF),
                      ),
                      _QuickAction(
                        icon: Icons.menu_book_rounded,
                        label: 'Mes cours',
                        onTap: () => context.push('/instructor/courses'),
                        color: const Color(0xFF10B981),
                      ),
                      _QuickAction(
                        icon: Icons.library_add_rounded,
                        label: 'Ajouter un livre',
                        onTap: () => context.push('/instructor/books/create'),
                        color: const Color(0xFFF59E0B),
                      ),
                      _QuickAction(
                        icon: Icons.library_books_rounded,
                        label: 'Mes livres',
                        onTap: () => context.push('/instructor/books'),
                        color: const Color(0xFF8B5CF6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A1F44).withOpacity(0.04),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF7386A8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
