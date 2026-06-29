// 📁 lib/presentation/thix_sante/doctor/widgets/prescription_form.dart

import 'package:flutter/material.dart';
import '../../../common/widgets/gradient_button.dart';

class PrescriptionForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const PrescriptionForm({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<PrescriptionForm> createState() => _PrescriptionFormState();
}

class _PrescriptionFormState extends State<PrescriptionForm> {
  final _formKey = GlobalKey<FormState>();
  final _drugCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();

  @override
  void dispose() {
    _drugCtrl.dispose();
    _dosageCtrl.dispose();
    _durationCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nouvelle prescription',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _drugCtrl,
                decoration: const InputDecoration(
                  labelText: 'Médicament',
                  hintText: 'Amoxicilline',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 13),
                validator: (v) => v?.isEmpty == true ? 'Champ requis' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _dosageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  hintText: '500 mg',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 13),
                validator: (v) => v?.isEmpty == true ? 'Champ requis' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _durationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Durée',
                  hintText: '7 jours',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _instructionsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  hintText: 'Prendre avec de la nourriture',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              GradientButton(
                text: 'Ajouter à l\'ordonnance',
                onPressed: _submit,
                icon: Icons.add,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit({
        'drug': _drugCtrl.text,
        'dosage': _dosageCtrl.text,
        'duration': _durationCtrl.text,
        'instructions': _instructionsCtrl.text,
      });
      _drugCtrl.clear();
      _dosageCtrl.clear();
      _durationCtrl.clear();
      _instructionsCtrl.clear();
    }
  }
}
