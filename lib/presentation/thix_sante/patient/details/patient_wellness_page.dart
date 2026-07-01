// presentation/thix_sante/patient/details/patient_wellness_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class WellnessProgram {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String? imageUrl;
  final int totalSteps;
  final int completedSteps;
  final String category;
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

  double get progress =>
      totalSteps > 0 ? completedSteps / totalSteps : 0;

  String get progressLabel =>
      '${(progress * 100).toInt()}%';
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
  State<PatientWellnessPage> createState() =>
      _PatientWellnessPageState();
}

class _PatientWellnessPageState
    extends State<PatientWellnessPage> {
  final SupabaseClient _supabase =
      SupabaseConfig.client;

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
        _programs = response
            .map(
              (data) =>
                  WellnessProgram.fromJson(data),
            )
            .toList();
      }

      if (widget.programId != null) {
        final found = _programs.firstWhere(
          (p) => p.id == widget.programId,
          orElse: () =>
              throw Exception('Programme introuvable'),
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
      final updated =
          _selectedProgram!.completedSteps + 1;

      await _supabase
          .from('health_wellness_programs')
          .update({
            'completed_steps': updated,
          })
          .eq('id', _selectedProgram!.id);

      setState(() {
        _selectedProgram = WellnessProgram(
          id: _selectedProgram!.id,
          title: _selectedProgram!.title,
          subtitle: _selectedProgram!.subtitle,
          description:
              _selectedProgram!.description,
          imageUrl: _selectedProgram!.imageUrl,
          totalSteps:
              _selectedProgram!.totalSteps,
          completedSteps: updated,
          category: _selectedProgram!.category,
          startDate:
              _selectedProgram!.startDate,
          endDate: _selectedProgram!.endDate,
          isActive:
              updated <
                  _selectedProgram!.totalSteps,
        );

        final index = _programs.indexWhere(
          (p) => p.id == _selectedProgram!.id,
        );

        if (index != -1) {
          _programs[index] =
              _selectedProgram!;
        }
      });

      if (updated >=
          _selectedProgram!.totalSteps) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              '🎉 Félicitations ! Programme terminé !',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Étape validée ! Progression : ${_selectedProgram!.progressLabel}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isTracking &&
        _selectedProgram != null) {
      return _buildTrackingView();
    }

    if (widget.programId != null &&
        _selectedProgram != null) {
      return _buildDetailView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Programmes bien-être',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 8),
                      Text('Erreur : $_error'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.all(16),
                    itemCount:
                        _programs.length,
                    itemBuilder:
                        (context, index) {
                      final program =
                          _programs[index];

                      return ListTile(
                        title:
                            Text(program.title),
                        subtitle: Text(
                          program.subtitle,
                        ),
                        trailing: Text(
                          program.progressLabel,
                        ),
                        onTap: () {
                          context.push(
                            '/sante/patient/wellness/${program.id}',
                          );
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              p.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(p.subtitle),
            const SizedBox(height: 16),
            Text(p.description),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingView() {
    final p = _selectedProgram!;
    final steps =
        _getStepsForProgram(p.category);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Suivi du programme',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: steps.length,
                itemBuilder:
                    (context, index) {
                  final step = steps[index];

                  final isCompleted =
                      index <
                          p.completedSteps;

                  final isCurrent =
                      index ==
                              p.completedSteps &&
                          !isCompleted;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          isCompleted
                              ? Colors.green
                              : (isCurrent
                                  ? const Color(
                                      0xFF2563FF,
                                    )
                                  : Colors
                                      .grey[300]),
                      child: Icon(
                        isCompleted
                            ? Icons.check
                            : (isCurrent
                                ? Icons
                                    .play_arrow
                                : Icons
                                    .circle_outlined),
                        color: Colors.white,
                        size: 16,
                      ),
                    ),

                    // ✅ CORRECTION ICI
                    title: Text(
                      step['title']!,
                      style: TextStyle(
                        fontWeight:
                            isCompleted ||
                                    isCurrent
                                ? FontWeight
                                    .w600
                                : FontWeight
                                    .normal,
                        color:
                            isCompleted ||
                                    isCurrent
                                ? Colors.black
                                : Colors
                                    .grey[500],
                      ),
                    ),

                    // ✅ CORRECTION ICI
                    subtitle: Text(
                      step['description']!,
                    ),

                    trailing: isCompleted
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          )
                        : isCurrent
                            ? ElevatedButton(
                                onPressed:
                                    _completeStep,
                                child:
                                    const Text(
                                  'Valider',
                                ),
                              )
                            : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, String>>
      _getStepsForProgram(
    String category,
  ) {
    switch (category) {
      case 'stress':
        return [
          {
            'title':
                'Exercice de respiration',
            'description':
                '5 minutes de respiration profonde',
          },
          {
            'title':
                'Méditation guidée',
            'description':
                '10 minutes de méditation',
          },
        ];

      case 'nutrition':
        return [
          {
            'title':
                'Petit-déjeuner équilibré',
            'description':
                'Repas sain',
          },
        ];

      default:
        return [
          {
            'title': 'Étape 1',
            'description':
                'Démarrer le programme',
          },
        ];
    }
  }
}
