import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestionManagementPage extends StatefulWidget {
  final String evaluationId;
  const QuestionManagementPage({super.key, required this.evaluationId});

  @override
  State<QuestionManagementPage> createState() => _QuestionManagementPageState();
}

class _QuestionManagementPageState extends State<QuestionManagementPage> {
  // Liste des questions (stockées en local avant sauvegarde)
  final List<Map<String, dynamic>> _questions = [];

  // Contrôleurs pour le formulaire
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  int? _correctIndex;
  String _questionType = 'qcm'; // qcm, vrai_faux, ouverte

  bool _isLoading = false;
  bool _isInitLoading = true; // Pour le chargement initial

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

  // 1. CHARGEMENT DES QUESTIONS DEPUIS SUPABASE
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
      debugPrint('Erreur lors du chargement des questions : $e');
    } finally {
      if (mounted) setState(() => _isInitLoading = false);
    }
  }

  // Ajoute un champ option vide
  void _addOptionField() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  // Supprime un champ option
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

  // Ajoute la question courante à la liste locale
  void _addQuestion() {
    final questionText = _questionController.text.trim();
    if (questionText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir une question.')),
      );
      return;
    }

    if (_questionType == 'qcm') {
      final options = _optionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
      if (options.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajoutez au moins 2 options.')),
        );
        return;
      }
      if (_correctIndex == null || _correctIndex! >= options.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sélectionnez la bonne réponse.')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choisissez Vrai ou Faux.')),
        );
        return;
      }
      setState(() {
        _questions.add({
          'question': questionText,
          'type': 'vrai_faux',
          'options': ['Vrai', 'Faux'], // Optionnel, mais utile pour l'affichage
          'correctIndex': _correctIndex!, // 0 = Vrai, 1 = Faux
        });
      });
    } else {
      // Question ouverte
      setState(() {
        _questions.add({
          'question': questionText,
          'type': 'ouverte',
        });
      });
    }

    // Réinitialiser le formulaire
    _questionController.clear();
    for (var c in _optionControllers) {
      c.dispose();
    }
    _optionControllers.clear();
    _correctIndex = null;
    setState(() {});
  }

  // Supprime une question de la liste locale
  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  // 2. SAUVEGARDE SYNCHRONISÉE DANS SUPABASE
  Future<void> _saveQuestions() async {
    setState(() => _isLoading = true);
    try {
      // Étape A : Supprimer les anciennes questions de cette évaluation pour éviter les doublons
      await Supabase.instance.client
          .from('questions')
          .delete()
          .eq('evaluation_id', widget.evaluationId);

      // Étape B : Insérer la nouvelle liste complète
      if (_questions.isNotEmpty) {
        final payload = _questions.map((q) => {
          'evaluation_id': widget.evaluationId,
          'text': q['question'],
          'type': q['type'],
          'options': q['options'] ?? [],
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Questions sauvegardées avec succès !'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pop(context, _questions);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Gérer les questions', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                : const Icon(Icons.save_rounded, color: Color(0xFF2D6CDF)),
            onPressed: _isLoading ? null : _saveQuestions,
          ),
        ],
      ),
      body: _isInitLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D6CDF)))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sélecteur de type de question
                  DropdownButtonFormField<String>(
                    value: _questionType,
                    items: const [
                      DropdownMenuItem(value: 'qcm', child: Text('QCM (choix multiples)')),
                      DropdownMenuItem(value: 'vrai_faux', child: Text('Vrai / Faux')),
                      DropdownMenuItem(value: 'ouverte', child: Text('Question ouverte')),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _questionType = v!;
                        for (var c in _optionControllers) { c.dispose(); }
                        _optionControllers.clear();
                        _correctIndex = null;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Type de question'),
                  ),
                  const SizedBox(height: 12),

                  // Champ question
                  TextFormField(
                    controller: _questionController,
                    decoration: const InputDecoration(
                      labelText: 'Question',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),

                  // Options (pour QCM)
                  if (_questionType == 'qcm') ...[
                    const Text('Options (cliquez sur + pour ajouter)', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ..._optionControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;
                      return Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller,
                              decoration: InputDecoration(
                                hintText: 'Option ${index + 1}',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Radio<int>(
                            value: index,
                            groupValue: _correctIndex,
                            onChanged: (v) => setState(() => _correctIndex = v),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _removeOptionField(index),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _addOptionField,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Ajouter une option'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],

                  // Vrai / Faux
                  if (_questionType == 'vrai_faux') ...[
                    const Text('Choisissez la réponse correcte :', style: TextStyle(fontWeight: FontWeight.w700)),
                    Row(
                      children: [
                        Radio<int>(
                          value: 0,
                          groupValue: _correctIndex,
                          onChanged: (v) => setState(() => _correctIndex = v),
                        ),
                        const Text('Vrai'),
                        const SizedBox(width: 16),
                        Radio<int>(
                          value: 1,
                          groupValue: _correctIndex,
                          onChanged: (v) => setState(() => _correctIndex = v),
                        ),
                        const Text('Faux'),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Ajouter la question'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6CDF),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Liste des questions
                  const Text(
                    'Questions ajoutées',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _questions.isEmpty
                        ? const Center(child: Text('Aucune question ajoutée'))
                        : ListView.builder(
                            itemCount: _questions.length,
                            itemBuilder: (context, index) {
                              final q = _questions[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(q['question']),
                                  subtitle: q['type'] == 'qcm'
                                      ? Text('QCM - ${(q['options'] as List).join(', ')}')
                                      : q['type'] == 'vrai_faux'
                                          ? Text('Vrai/Faux - ${q['correctIndex'] == 0 ? 'Vrai' : 'Faux'}')
                                          : const Text('Question ouverte'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_rounded, color: Colors.red),
                                    onPressed: () => _removeQuestion(index),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
