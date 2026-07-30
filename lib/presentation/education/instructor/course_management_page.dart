// lib/presentation/education/instructor/course_management_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/presentation/education/models/formation.dart';
import 'package:thix_id/presentation/education/widgets/common/formation_card.dart';

class _C {
  static const bg = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const primary = Color(0xFF2D6CDF);
  static const textMain = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
}

class CourseManagementPage extends StatefulWidget {
  const CourseManagementPage({super.key});

  @override
  State<CourseManagementPage> createState() => _CourseManagementPageState();
}

class _CourseManagementPageState extends State<CourseManagementPage> {
  List<Formation> _courses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMyCourses();
  }

  // ✅ CORRIGÉ : Récupération ciblée uniquement des cours du formateur connecté
  Future<void> _loadMyCourses() async {
    setState(() => _loading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _loading = false);
        return;
      }

      // Requête directe filtrée par user_id ou instructor_id
      final response = await Supabase.instance.client
          .from('formations')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final loadedCourses = (response as List)
          .map((json) => Formation.fromJson(json))
          .toList();

      if (mounted) {
        setState(() {
          _courses = loadedCourses;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement de mes cours : $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: const Text('Mes cours', style: TextStyle(fontWeight: FontWeight.w800, color: _C.textMain, fontSize: 18)),
        backgroundColor: _C.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _C.textMain),
          onPressed: () => context.pop(),
        ),
        actions: [
          // ✅ CORRIGÉ : Au retour de la création (await push), on recharge la liste instantanément
          IconButton(
            icon: const Icon(Icons.add_rounded, color: _C.primary),
            onPressed: () async {
              await context.push('/instructor/courses/create');
              _loadMyCourses(); // Rafraîchit la liste des cours dès le retour
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.primary))
          : RefreshIndicator(
              color: _C.primary,
              onRefresh: _loadMyCourses,
              child: _courses.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 150),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.school_rounded, size: 64, color: _C.border),
                              SizedBox(height: 16),
                              Text(
                                'Aucun cours créé',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _C.textMain),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Créez votre premier cours en cliquant sur +',
                                style: TextStyle(color: _C.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _courses.length,
                      itemBuilder: (context, index) {
                        final course = _courses[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FormationCard(
                            formation: course,
                            onTap: () async {
                              await context.push('/instructor/courses/edit/${course.id}');
                              _loadMyCourses(); // Rafraîchit aussi au retour d'une modification
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
