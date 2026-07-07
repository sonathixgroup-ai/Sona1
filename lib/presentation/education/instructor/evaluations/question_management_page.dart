// lib/presentation/education/instructor/evaluations/question_management_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuestionManagementPage extends StatefulWidget {
  final String evaluationId;
  const QuestionManagementPage({super.key, required this.evaluationId});

  @override
  State<QuestionManagementPage> createState() => _QuestionManagementPageState();
}

class _QuestionManagementPageState extends State<QuestionManagementPage> {
  final List<Map<String, dynamic>> _questions = [];
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  int? _correctIndex;
  String _questionType = 'qcm'; // qcm, vrai_faux, ouverte

  @override
  void dispose() {
    _questionController.dispose();
    for (var c in _optionControllers) c.dispose();
    super.dispose();
  }

  void _addQuestion() {
    if (_questionController.text.trim().isEmpty) return;
    if (_questionType == 'qcm') {
      final options = _optionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
      if (options.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajoutez au moins 2 options pour un QCM')),
        );
        return;
      }
      if (_correctIndex == null || _correctIndex! >= options.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sélectionnez la bonne réponse')),
        );
        return;
      }
      setState(() {
        _questions.add({
          'question': _questionController.text.trim(),
          'type': 'qcm',
          'options': options,
          'correctIndex': _correctIndex!,
        });
      });
    } else if (_questionType == 'vrai_faux') {
      if (_correctIndex == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choisissez Vrai ou Faux')),
        );
        return;
      }
      setState(() {
        _questions.add({
          'question': _questionController.text.trim(),
          'type': 'vrai_faux',
          'correctIndex': _correctIndex!, // 0 = Vrai, 1 = Faux
        });
      });
    } else {
      setState(() {
        _questions.add({
          'question': _questionController.text.trim(),
          'type': 'ouverte',
        });
      });
    }
    _questionController.clear();
    _optionControllers.clear();
    _correctIndex = null;
    setState(() {});
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  void _addOptionField() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Gérer les questions'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(_questions),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: () => Navigator.pop(context, _questions),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type de question
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
              const Text('Options (cliquez sur + pour en ajouter)', style: TextStyle(fontWeight: FontWeight.w700)),
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
                      onPressed: () {
                        setState(() {
                          _optionControllers.removeAt(index);
                          if (_correctIndex == index) _correctIndex = null;
                          else if (_correctIndex != null && _correctIndex! > index) _correctIndex = _correctIndex! - 1;
                        });
                      },
                    ),
                  ],
                );
              }).toList(),
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
            const Text('Questions ajoutées', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            Expanded(
              child: _questions.isEmpty
                  ? const Center(child: Text('Aucune question'))
                  : ListView.builder(
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        final q = _questions[index];
                        return Card(
                          child: ListTile(
                            title: Text(q['question']),
                            subtitle: q['type'] == 'qcm'
                                ? Text('QCM - ${(q['options'] as List).join(', ')} (réponse: ${q['correctIndex']})')
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
