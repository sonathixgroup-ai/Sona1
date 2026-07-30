// lib/presentation/education/instructor/question_management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// CONSTANTES UI
// ============================================================
class _C {
  static const bg = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const primary = Color(0xFF2D6CDF);
  static const green = Color(0xFF10B981);
  static const textMain = Color(0xFF1E293B);
  static const textMuted = Color(0xFF7386A8);
  static const border = Color(0xFFE2E8F0);
  static const red = Color(0xFFEF4444);
}

class QuestionManagementPage extends ConsumerStatefulWidget {
  final String evaluationId;
  const QuestionManagementPage({super.key, required this.evaluationId});

  @override
  ConsumerState<QuestionManagementPage> createState() => _QuestionManagementPageState();
}

class _QuestionManagementPageState extends ConsumerState<QuestionManagementPage> {
  final List<Map<String, dynamic>> _questions = [];

  // Contrôleurs pour le formulaire de création de question
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  int? _correctIndex;
  String _questionType = 'qcm'; // qcm, vrai_faux, ouverte

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingQuestions();
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExistingQuestions() async {
    try {
      final res = await Supabase.instance.client
          .from('questions')
          .select('*')
          .eq('evaluation_id', widget.evaluationId);

      if (mounted) {
        setState(() {
          _questions.addAll((res as List).map((q) => {
            'id': q['id'],
            'question': q['text'] ?? q['question'] ?? '',
            'type': q['type'] ?? 'qcm',
            'options': q['options'] != null ? List<String>.from(q['options']) : [],
            'correctIndex': q['correct_index'] ?? 0,
          }));
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement questions : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addOptionField() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOptionField(int index) {
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
      if (_correctIndex == index) {
        _correctIndex = null;
      } else if (_correctIndex != null && _correctIndex! > index) {
        _correctIndex = _correctIndex! - 1;
      }
    });
  }

  void _addQuestion() {
    final questionText = _questionController.text.trim();
    if (questionText.isEmpty) {
      _showSnackBar('Veuillez saisir une question.', isError: true);
      return;
    }

    if (_questionType == 'qcm') {
      final options = _optionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
      if (options.length < 2) {
        _showSnackBar('Ajoutez au moins 2 options.', isError: true);
        return;
      }
      if (_correctIndex == null || _correctIndex! >= options.length) {
        _showSnackBar('Sélectionnez la bonne réponse.', isError: true);
        return;
      }
      setState(() {
        _questions.add({
          'question': questionText,
          'type': 'qcm',
          'options': options,
          'correctIndex': _correctIndex!,
        });
      });
    } else if (_questionType == 'vrai_faux') {
      if (_correctIndex == null) {
        _showSnackBar('Choisissez Vrai ou Faux.', isError: true);
        return;
      }
      setState(() {
        _questions.add({
          'question': questionText,
          'type': 'vrai_faux',
          'options': ['Vrai', 'Faux'],
          'correctIndex': _correctIndex!, // 0 = Vrai, 1 = Faux
        });
      });
    } else {
      // Question ouverte
      setState(() {
        _questions.add({
          'question': questionText,
          'type': 'ouverte',
          'options': [],
          'correctIndex': 0,
        });
      });
    }

    // Réinitialiser le formulaire de saisie
    _questionController.clear();
    for (var c in _optionControllers) {
      c.dispose();
    }
    _optionControllers.clear();
    _correctIndex = null;
    setState(() {});
    
    _showSnackBar('Question ajoutée à la liste locale.', isError: false);
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _saveQuestions() async {
    setState(() => _isSaving = true);
    try {
      // Stratégie robuste : Remplacer ou synchroniser les questions dans Supabase
      // 1. Supprimer les anciennes questions de cette évaluation
      await Supabase.instance.client
          .from('questions')
          .delete()
          .eq('evaluation_id', widget.evaluationId);

      // 2. Insérer la nouvelle liste de questions actualisée
      if (_questions.isNotEmpty) {
        final payload = _questions.map((q) => {
          'evaluation_id': widget.evaluationId,
          'text': q['question'],
          'type': q['type'],
          'options': q['options'],
          'correct_index': q['correctIndex'],
          'correct_answer': q['type'] == 'qcm' && q['options'] != null && (q['options'] as List).isNotEmpty
              ? q['options'][q['correctIndex']]
              : q['type'] == 'vrai_faux'
                  ? (q['correctIndex'] == 0 ? 'Vrai' : 'Faux')
                  : null,
          'created_at': DateTime.now().toIso8601String(),
        }).toList();

        await Supabase.instance.client.from('questions').insert(payload);
      }

      if (!mounted) return;
      _showSnackBar('Questions sauvegardées avec succès !', isError: false);
      context.pop(_questions);
    } catch (e) {
      _showSnackBar('Erreur lors de la sauvegarde : $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? _C.red : _C.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: const Text('Gérer les questions', style: TextStyle(fontWeight: FontWeight.w800, color: _C.textMain, fontSize: 18)),
        backgroundColor: _C.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _C.textMain),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_rounded, color: _C.primary),
            onPressed: _isSaving ? null : _saveQuestions,
            tooltip: 'Enregistrer',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _C.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte formulaire d'ajout
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _C.border),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nouvelle question', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _C.textMain)),
                        const SizedBox(height: 16),

                        // Sélecteur de type
                        DropdownButtonFormField<String>(
                          value: _questionType,
                          dropdownColor: _C.surface,
                          style: const TextStyle(color: _C.textMain, fontWeight: FontWeight.w600),
                          items: const [
                            DropdownMenuItem(value: 'qcm', child: Text('QCM (Choix multiples)')),
                            DropdownMenuItem(value: 'vrai_faux', child: Text('Vrai / Faux')),
                            DropdownMenuItem(value: 'ouverte', child: Text('Question ouverte')),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _questionType = v!;
                              for (var c in _optionControllers) {
                                c.dispose();
                              }
                              _optionControllers.clear();
                              _correctIndex = null;
                            });
                          },
                          decoration: _inputDecoration('Type de question', Icons.category_outlined),
                        ),
                        const SizedBox(height: 16),

                        // Champ texte de la question
                        TextFormField(
                          controller: _questionController,
                          maxLines: 3,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          decoration: _inputDecoration('Intitulé de la question*', Icons.help_outline_rounded),
                        ),
                        const SizedBox(height: 16),

                        // Options QCM
                        if (_questionType == 'qcm') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Options de réponse', style: TextStyle(fontWeight: FontWeight.w800, color: _C.textMain)),
                              TextButton.icon(
                                onPressed: _addOptionField,
                                icon: const Icon(Icons.add_rounded, size: 18, color: _C.primary),
                                label: const Text('Ajouter une option', style: TextStyle(color: _C.primary, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._optionControllers.asMap().entries.map((entry) {
                            final index = entry.key;
                            final controller = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              key: ValueKey(index),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: controller,
                                      decoration: _inputDecoration('Option ${index + 1}', Icons.list_rounded),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Tooltip(
                                    message: 'Définir comme bonne réponse',
                                    child: Radio<int>(
                                      value: index,
                                      groupValue: _correctIndex,
                                      activeColor: _C.green,
                                      onChanged: (v) => setState(() => _correctIndex = v),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, color: _C.red),
                                    onPressed: () => _removeOptionField(index),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],

                        // Vrai / Faux
                        if (_questionType == 'vrai_faux') ...[
                          const Text('Réponse correcte :', style: TextStyle(fontWeight: FontWeight.w800, color: _C.textMain)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<int>(
                                  value: 0,
                                  groupValue: _correctIndex,
                                  activeColor: _C.green,
                                  title: const Text('Vrai', style: TextStyle(fontWeight: FontWeight.w600)),
                                  onChanged: (v) => setState(() => _correctIndex = v),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<int>(
                                  value: 1,
                                  groupValue: _correctIndex,
                                  activeColor: _C.green,
                                  title: const Text('Faux', style: TextStyle(fontWeight: FontWeight.w600)),
                                  onChanged: (v) => setState(() => _correctIndex = v),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _addQuestion,
                            icon: const Icon(Icons.add_rounded, color: Colors.white),
                            label: const Text('Ajouter à la liste', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _C.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Liste des questions ajoutées
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Questions configurées (${_questions.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _C.textMain)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _questions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.quiz_outlined, size: 48, color: _C.textMuted.withOpacity(0.4)),
                                const SizedBox(height: 12),
                                const Text('Aucune question ajoutée pour le moment.', style: TextStyle(color: _C.textMuted, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _questions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final q = _questions[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: _C.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _C.border),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: _C.primary.withOpacity(0.12),
                                  child: Text('${index + 1}', style: const TextStyle(color: _C.primary, fontWeight: FontWeight.w800)),
                                ),
                                title: Text(q['question'], style: const TextStyle(fontWeight: FontWeight.w700, color: _C.textMain)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    q['type'] == 'qcm'
                                        ? 'QCM • Options: ${(q['options'] as List).join(', ')}'
                                        : q['type'] == 'vrai_faux'
                                            ? 'Vrai / Faux • Réponse : ${q['correctIndex'] == 0 ? 'Vrai' : 'Faux'}'
                                            : 'Question ouverte',
                                    style: const TextStyle(color: _C.textMuted, fontSize: 12),
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_rounded, color: _C.red, size: 20),
                                  onPressed: () => _removeQuestion(index),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _C.textMuted, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: _C.textMuted, size: 20),
      filled: true,
      fillColor: _C.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.transparent)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.red, width: 1.0)),
    );
  }
}
