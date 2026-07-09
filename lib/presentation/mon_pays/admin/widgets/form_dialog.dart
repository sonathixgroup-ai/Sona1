// lib/presentation/mon_pays/admin/widgets/form_dialog.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

enum FormFieldType {
  text,
  email,
  number,
  date,
  dropdown,
  multiline,
}

class FormFieldConfig {
  final String key;
  final String label;
  final String? hint;
  final FormFieldType type;
  final String? defaultValue;
  final String? Function(String?)? validator;
  final List<String>? dropdownItems;
  final int? maxLines;

  FormFieldConfig({
    required this.key,
    required this.label,
    this.hint,
    this.type = FormFieldType.text,
    this.defaultValue,
    this.validator,
    this.dropdownItems,
    this.maxLines,
  });
}

class FormDialog extends StatefulWidget {
  final String title;
  final List<FormFieldConfig> fields;
  final Future<void> Function(Map<String, dynamic> values) onSubmit;
  final Map<String, dynamic>? initialValues;
  final String submitLabel;
  final String cancelLabel;
  final bool isEditing;

  const FormDialog({
    Key? key,
    required this.title,
    required this.fields,
    required this.onSubmit,
    this.initialValues,
    this.submitLabel = 'Enregistrer',
    this.cancelLabel = 'Annuler',
    this.isEditing = false,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required String title,
    required List<FormFieldConfig> fields,
    required Future<void> Function(Map<String, dynamic> values) onSubmit,
    Map<String, dynamic>? initialValues,
    String submitLabel = 'Enregistrer',
    String cancelLabel = 'Annuler',
    bool isEditing = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => FormDialog(
        title: title,
        fields: fields,
        onSubmit: onSubmit,
        initialValues: initialValues,
        submitLabel: submitLabel,
        cancelLabel: cancelLabel,
        isEditing: isEditing,
      ),
    );
  }

  @override
  State<FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<FormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (var field in widget.fields) {
      final controller = TextEditingController(
        text: widget.initialValues?[field.key]?.toString() ?? field.defaultValue ?? '',
      );
      _controllers[field.key] = controller;
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              Text(
                widget.title,
                style: AppTextStyles.heading5.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Champs de formulaire
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: widget.fields.map((field) {
                      return _buildField(field);
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.textSecondary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(widget.cancelLabel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              widget.submitLabel,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(FormFieldConfig field) {
    final controller = _controllers[field.key]!;

    switch (field.type) {
      case FormFieldType.text:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: field.label,
              hintText: field.hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.primaryWhite,
            ),
            validator: field.validator,
            maxLines: field.maxLines ?? 1,
          ),
        );
      case FormFieldType.email:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: field.label,
              hintText: field.hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.primaryWhite,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Champ requis';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Email invalide';
              }
              return null;
            },
            keyboardType: TextInputType.emailAddress,
          ),
        );
      case FormFieldType.number:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: field.label,
              hintText: field.hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.primaryWhite,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Champ requis';
              if (double.tryParse(value) == null) return 'Doit être un nombre';
              return null;
            },
            keyboardType: TextInputType.number,
          ),
        );
      case FormFieldType.date:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: field.label,
              hintText: field.hint ?? 'AAAA-MM-JJ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.primaryWhite,
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context, controller),
              ),
            ),
            validator: field.validator,
            readOnly: true,
            onTap: () => _selectDate(context, controller),
          ),
        );
      case FormFieldType.dropdown:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: field.label,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.primaryWhite,
            ),
            value: controller.text.isNotEmpty ? controller.text : null,
            items: field.dropdownItems?.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: (value) {
              controller.text = value ?? '';
            },
            validator: field.validator,
          ),
        );
      case FormFieldType.multiline:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: field.label,
              hintText: field.hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.primaryWhite,
            ),
            validator: field.validator,
            maxLines: 4,
          ),
        );
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      controller.text = date.toIso8601String().split('T').first;
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final values = <String, dynamic>{};
      for (var field in widget.fields) {
        values[field.key] = _controllers[field.key]!.text;
      }
      await widget.onSubmit(values);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
