// presentation/thix_sante/patient/details/patient_wellness_page.dart
// Version corrigée – lignes 532 et 542
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/supabase/supabase_config.dart';

// Modèle local pour un programme bien-être
class WellnessProgram {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String? imageUrl;
  final int totalSteps;
  final int completedSteps;
  final String category; // 'stress', 'nutrition', 'fitness', 'stop_smoking'
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;

  WellnessProgram({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    this.imageUrl,
    required this.totalSteps,
    required this.completedSteps,
    required this.category,
    required this.startDate,
    this.endDate,
    this.isActive = true,
  });

  factory WellnessProgram.fromJson(Map<String, dynamic> json) {
    return WellnessProgram(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String?,
      totalSteps: json['total_steps'] as int,
      completedSteps: json['completed_steps'] as int,
      category: json['category'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  double get progress => totalSteps > 0 ? completedSteps / totalSteps : 0;

  String get progressLabel => '${(progress * 100).toInt()}%';
}

class PatientWellnessPage extends StatefulWidget {
  final String? programId;
  final bool isTracking;

  const PatientWellnessPage({
    super.key,
    this.programId,
    this.isTracking = false,
  });

  @override
  State<PatientWellnessPage> createState() => _PatientWellnessPageState();
}

class _PatientWellnessPageState extends State<PatientWellnessPage> {
  final SupabaseClient _supabase = SupabaseConfig.client;
  List<WellnessProgram> _programs = [];
  WellnessProgram? _selectedProgram;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await _supabase
          .from('health_wellness_programs')
          .select('*')
          .eq('patient_id', user.id)
          .order('start_date', ascending: false);

      if (response is List) {
        _programs = response.map((data) => WellnessProgram.fromJson(data)).toList();
      }

      if (widget.programId != null) {
        final found = _programs.firstWhere(
          (p) => p.id == widget.programId,
          orElse: () => throw Exception('Programme introuvable'),
        );
        _selectedProgram = found;
      } else if (_programs.isNotEmpty) {
        _selectedProgram = _programs.first;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _completeStep() async {
    if (_selectedProgram == null) return;

    try {
      final updated = _selectedProgram!.completedSteps + 1;
      await _supabase
          .from('health_wellness_programs')
          .update({'completed_steps': updated})
          .eq('id', _selectedProgram!.id);

      setState(() {
        _selectedProgram = WellnessProgram(
          id: _selectedProgram!.id,
          title: _selectedProgram!.title,
          subtitle: _selectedProgram!.subtitle,
          description: _selectedProgram!.description,
          imageUrl: _selectedProgram!.imageUrl,
          totalSteps: _selectedProgram!.totalSteps,
          completedSteps: updated,
          category: _selectedProgram!.category,
          startDate: _selectedProgram!.startDate,
          endDate: _selectedProgram!.endDate,
          isActive: updated < _selectedProgram!.totalSteps,
        );
        final index = _programs.indexWhere((p) => p.id == _selectedProgram!.id);
        if (index != -1) {
          _programs[index] = _selectedProgram!;
        }
      });

      if (updated >= _selectedProgram!.totalSteps) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Félicitations ! Programme terminé !'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Étape validée ! Progression : ${_selectedProgram!.progressLabel}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isTracking && _selectedProgram != null) {
      return _buildTrackingView();
    }

    if (widget.programId != null && _selectedProgram != null) {
      return _buildDetailView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programmes bien-être'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Erreur : $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _programs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.self_improvement,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucun programme en cours.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Commencez un programme pour améliorer votre bien-être.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ajout de programme à implémenter'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Démarrer un programme'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563FF),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _programs.length,
                        itemBuilder: (context, index) {
                          final program = _programs[index];
                          return _ProgramCard(
                            program: program,
                            onTap: () {
                              context.push('/sante/patient/wellness/${program.id}');
                            },
                            onTrack: () {
                              context.push('/sante/patient/wellness/${program.id}/track');
                            },
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildDetailView() {
    final p = _selectedProgram!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Programme'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () {
              context.push('/sante/patient/wellness/${p.id}/track');
            },
            tooltip: 'Suivre le programme',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  p.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              p.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _categoryColor(p.category),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _categoryLabel(p.category),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              p.subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              p.description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progression',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          p.progressLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: p.progress,
                      backgroundColor: Colors.grey[200],
                      color: const Color(0xFF2563FF),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${p.completedSteps} étapes terminées',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'sur ${p.totalSteps}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/sante/patient/wellness/${p.id}/track');
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Suivre'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Retour'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingView() {
    final p = _selectedProgram!;
    final steps = _getStepsForProgram(p.category);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi du programme'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Progression : ${p.progressLabel}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: p.progress,
              backgroundColor: Colors.grey[200],
              color: const Color(0xFF2563FF),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Étapes du programme :',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final step = steps[index];
                  final isCompleted = index < p.completedSteps;
                  final isCurrent = index == p.completedSteps && !isCompleted;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCompleted
                          ? Colors.green
                          : isCurrent
                              ? const Color(0xFF2563FF)
                              : Colors.grey[300],
                      child: Icon(
                        isCompleted
                            ? Icons.check
                            : isCurrent
                                ? Icons.play_arrow
                                : Icons.circle_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    title: Text(
                      step['title'],
                      style: TextStyle(
                        fontWeight: isCompleted || isCurrent
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isCompleted || isCurrent
                            ? Colors.black
                            : Colors.grey[500],
                      ),
                    ),
                    subtitle: Text(step['description']),
                    trailing: isCompleted
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : isCurrent
                            ? ElevatedButton(
                                onPressed: _completeStep,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563FF),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text('Valider'),
                              )
                            : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, String>> _getStepsForProgram(String category) {
    switch (category) {
      case 'stress':
        return [
          {'title': 'Exercice de respiration', 'description': '5 minutes de respiration profonde'},
          {'title': 'Méditation guidée', 'description': '10 minutes de méditation'},
          {'title': 'Journal de gratitude', 'description': 'Écrire 3 choses positives'},
          {'title': 'Balade en nature', 'description': '30 minutes de marche en plein air'},
        ];
      case 'nutrition':
        return [
          {'title': 'Petit-déjeuner équilibré', 'description': 'Céréales complètes, fruits, protéines'},
          {'title': 'Hydratation', 'description': 'Boire 2 litres d\'eau'},
          {'title': 'Repas complet', 'description': 'Légumes, protéines, féculents'},
          {'title': 'Collation saine', 'description': 'Fruits, oléagineux, yaourt'},
        ];
      case 'fitness':
        return [
          {'title': 'Échauffement', 'description': '5 minutes de cardio léger'},
          {'title': 'Exercice principal', 'description': 'Séance de 20 minutes'},
          {'title': 'Étirements', 'description': '10 minutes de stretching'},
          {'title': 'Récupération', 'description': 'Repos et hydratation'},
        ];
      case 'stop_smoking':
        return [
          {'title': 'Jour 1 - Motivation', 'description': 'Identifier ses motivations'},
          {'title': 'Jour 2 - Substituts', 'description': 'Utiliser des substituts nicotiniques'},
          {'title': 'Jour 3 - Gestion des envies', 'description': 'Techniques de distraction'},
          {'title': 'Jour 7 - Bilan', 'description': 'Faire le point sur la progression'},
        ];
      default:
        return [
          {'title': 'Étape 1', 'description': 'Démarrer le programme'},
          {'title': 'Étape 2', 'description': 'Continuer'},
          {'title': 'Étape 3', 'description': 'Finaliser'},
        ];
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'stress':
        return Colors.blue;
      case 'nutrition':
        return Colors.orange;
      case 'fitness':
        return Colors.green;
      case 'stop_smoking':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'stress':
        return 'Gestion du stress';
      case 'nutrition':
        return 'Nutrition';
      case 'fitness':
        return 'Activité physique';
      case 'stop_smoking':
        return 'Arrêt du tabac';
      default:
        return category;
    }
  }
}

class _ProgramCard extends StatelessWidget {
  final WellnessProgram program;
  final VoidCallback onTap;
  final VoidCallback onTrack;

  const _ProgramCard({
    required this.program,
    required this.onTap,
    required this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _categoryColor(program.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _categoryIcon(program.category),
                      color: _categoryColor(program.category),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          program.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _categoryColor(program.category),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      program.progressLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: program.progress,
                backgroundColor: Colors.grey[200],
                color: const Color(0xFF2563FF),
                minHeight: 4,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onTrack,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2563FF),
                    ),
                    child: const Text('Suivre'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'stress':
        return Colors.blue;
      case 'nutrition':
        return Colors.orange;
      case 'fitness':
        return Colors.green;
      case 'stop_smoking':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'stress':
        return Icons.self_improvement;
      case 'nutrition':
        return Icons.restaurant;
      case 'fitness':
        return Icons.fitness_center;
      case 'stop_smoking':
        return Icons.smoke_free;
      default:
        return Icons.article;
    }
  }
}
