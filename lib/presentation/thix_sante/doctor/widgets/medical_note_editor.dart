// 📁 lib/presentation/thix_sante/doctor/widgets/medical_note_editor.dart

import 'package:flutter/material.dart';
import '../../../common/widgets/gradient_button.dart';

class MedicalNoteEditor extends StatefulWidget {
  final Function(String) onSave;
  final String? initialNote;

  const MedicalNoteEditor({Key? key, required this.onSave, this.initialNote}) : super(key: key);

  @override
  State<MedicalNoteEditor> createState() => _MedicalNoteEditorState();
}

class _MedicalNoteEditorState extends State<MedicalNoteEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes médicales',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Ajoutez vos observations...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: GradientButton(
            text: 'Enregistrer',
            onPressed: () => widget.onSave(_controller.text),
            width: 120,
            height: 38,
          ),
        ),
      ],
    );
  }
}
