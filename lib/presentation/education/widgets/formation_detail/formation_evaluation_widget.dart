// lib/presentation/education/widgets/formation_detail/formation_evaluation_widget.dart
import 'package:flutter/material.dart';
import '../../../models/evaluation.dart';
import '../../../models/question.dart';

class FormationEvaluationWidget extends StatefulWidget {
  final Evaluation evaluation;
  final Function(int score, int total)? onComplete;

  const FormationEvaluationWidget({
    super.key,
    required this.evaluation,
    this.onComplete,
  });

  @override
  State<FormationEvaluationWidget> createState() => _FormationEvaluationWidgetState();
}

class _FormationEvaluationWidgetState extends State<FormationEvaluationWidget> {
  late List<Question> _questions;
  final Map<int, String> _answers = {};
  bool _isSubmitted = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _questions = widget.evaluation.questions ?? [];
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: Text(
            'Aucune question disponible pour cette évaluation.',
            style: TextStyle(color: Color(0xFF7386A8)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Évaluation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_questions.length} questions · Score minimum : ${widget.evaluation.passingScore}%',
          style: const TextStyle(
            color: Color(0xFF7386A8),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _questions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final question = _questions[index];
            final selected = _answers[index];
            return _buildQuestionCard(
              question,
              index,
              selected,
              _isSubmitted,
            );
          },
        ),
        const SizedBox(height: 24),
        if (!_isSubmitted)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitAnswers,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6CDF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Soumettre',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _score >= widget.evaluation.passingScore
                  ? const Color(0xFF2ECC71).withOpacity(0.1)
                  : const Color(0xFFFF5B3D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _score >= widget.evaluation.passingScore
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: _score >= widget.evaluation.passingScore
                          ? const Color(0xFF2ECC71)
                          : const Color(0xFFFF5B3D),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Score : $_score/${_questions.length} (${(_score / _questions.length * 100).toInt()}%)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _score >= widget.evaluation.passingScore
                      ? '✅ Félicitations ! Vous avez réussi l\'évaluation.'
                      : '❌ Vous devez obtenir au moins ${widget.evaluation.passingScore}% pour valider.',
                  style: TextStyle(
                    color: _score >= widget.evaluation.passingScore
                        ? const Color(0xFF2ECC71)
                        : const Color(0xFFFF5B3D),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionCard(
    Question question,
    int index,
    String? selected,
    bool submitted,
  ) {
    final isCorrect = submitted && selected != null && selected == question.correctAnswer;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: submitted
              ? (isCorrect ? const Color(0xFF2ECC71) : const Color(0xFFFF5B3D))
              : Colors.grey[200]!,
          width: submitted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Question ${index + 1}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7386A8),
                  ),
                ),
              ),
              if (submitted)
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: isCorrect ? const Color(0xFF2ECC71) : const Color(0xFFFF5B3D),
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          ..._buildOptions(question, index, selected, submitted),
          if (submitted && !isCorrect && question.correctAnswer != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '✅ Réponse correcte : ${question.correctAnswer}',
                style: const TextStyle(
                  color: Color(0xFF2D6CDF),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildOptions(
    Question question,
    int index,
    String? selected,
    bool submitted,
  ) {
    if (question.type == 'true_false') {
      return ['Vrai', 'Faux'].map((option) {
        final isSelected = selected == option;
        final isCorrect = option == question.correctAnswer;
        return RadioListTile<String>(
          value: option,
          groupValue: selected,
          onChanged: submitted ? null : (value) {
            setState(() {
              _answers[index] = value!;
            });
          },
          title: Text(option),
          activeColor: const Color(0xFF2D6CDF),
          contentPadding: EdgeInsets.zero,
          tileColor: submitted && isSelected
              ? (isCorrect ? const Color(0xFF2ECC71).withOpacity(0.1) : const Color(0xFFFF5B3D).withOpacity(0.1))
              : null,
        );
      }).toList();
    }

    return question.options.map((option) {
      final isSelected = selected == option;
      final isCorrect = option == question.correctAnswer;
      return RadioListTile<String>(
        value: option,
        groupValue: selected,
        onChanged: submitted ? null : (value) {
          setState(() {
            _answers[index] = value!;
          });
        },
        title: Text(option),
        activeColor: const Color(0xFF2D6CDF),
        contentPadding: EdgeInsets.zero,
        tileColor: submitted && isSelected
            ? (isCorrect ? const Color(0xFF2ECC71).withOpacity(0.1) : const Color(0xFFFF5B3D).withOpacity(0.1))
            : null,
      );
    }).toList();
  }

  void _submitAnswers() {
    if (_answers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez répondre à toutes les questions.'),
          backgroundColor: Color(0xFFFF5B3D),
        ),
      );
      return;
    }

    int correct = 0;
    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final answer = _answers[i];
      if (answer == question.correctAnswer) {
        correct++;
      }
    }

    setState(() {
      _isSubmitted = true;
      _score = correct;
    });

    widget.onComplete?.call(correct, _questions.length);
  }
}
