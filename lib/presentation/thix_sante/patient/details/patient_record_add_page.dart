// presentation/thix_sante/patient/details/patient_record_add_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class PatientRecordAddPage extends StatefulWidget {
  const PatientRecordAddPage({super.key});

  @override
  State<PatientRecordAddPage> createState() => _PatientRecordAddPageState();
}

class _PatientRecordAddPageState extends State<PatientRecordAddPage> {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'Ordonnance';
  File? _selectedFile;
  String _fileName = '';
  bool _isUploading = false;
  bool _isSaving = false;

  final List<String> _recordTypes = [
    'Ordonnance',
    'Compte rendu',
    'Résultat d\'examen',
    'Imagerie médicale',
    'Certificat médical',
    'Autre',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      setState(() {
        _selectedFile = File(file.path!);
        _fileName = file.name;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection du fichier : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    setState(() {
      _isSaving = true;
    });

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      String? fileUrl;

      // Upload du fichier si sélectionné
      if (_selectedFile != null) {
        setState(() => _isUploading = true);

        final fileBytes = await _selectedFile!.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.path.split('/').last}';
        final storagePath = 'patient_records/${user.id}/$fileName';

        await _supabase.storage.from('health_files').uploadBinary(
              storagePath,
              fileBytes,
              fileOptions: const FileOptions(
                contentType: 'application/octet-stream',
              ),
            );

        fileUrl = _supabase.storage.from('health_files').getPublicUrl(storagePath);
        setState(() => _isUploading = false);
      }

      // Insérer l'enregistrement dans la base
      final payload = {
        'patient_id': user.id,
        'title': title,
        'record_type': _selectedType,
        'description': description.isNotEmpty ? description : null,
        'record_date': _selectedDate.toIso8601String(),
        'file_url': fileUrl,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('patient_records').insert(payload);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document ajouté au dossier médical.'),
          backgroundColor: Colors.green,
        ),
      );

      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter au dossier médical'),
        backgroundColor: const Color(0xFF2563FF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre du document *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer un titre.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Type de document
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: _recordTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
                decoration: const InputDecoration(
                  labelText: 'Type de document *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder),
                ),
              ),
              const SizedBox(height: 16),

              // Date
              Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 8),
                  const Text('Date du document : '),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setState(() => _selectedDate = date);
                    },
                    child: Text(
                      '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // Fichier
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedFile != null ? Icons.file_present : Icons.attach_file,
                      color: _selectedFile != null ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _fileName.isNotEmpty ? _fileName : 'Aucun fichier sélectionné',
                        style: TextStyle(
                          color: _fileName.isNotEmpty ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _pickFile,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2563FF),
                      ),
                      child: Text(_selectedFile != null ? 'Changer' : 'Choisir'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Indicateur d'upload
              if (_isUploading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Téléchargement du fichier...'),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Bouton d'enregistrement
              ElevatedButton(
                onPressed: (_isSaving || _isUploading) ? null : _saveRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563FF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Ajouter au dossier'),
              ),
              const SizedBox(height: 12),

              // Bouton Annuler
              OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
