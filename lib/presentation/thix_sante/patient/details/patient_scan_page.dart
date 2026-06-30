// presentation/thix_sante/patient/details/patient_scan_page.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class PatientScanPage extends StatefulWidget {
  const PatientScanPage({super.key});

  @override
  State<PatientScanPage> createState() => _PatientScanPageState();
}

class _PatientScanPageState extends State<PatientScanPage> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer =
      GoogleMlKit.vision.textRecognizer();

  bool _isScanning = false;
  XFile? _imageFile;
  String _recognizedText = '';
  List<_DetectedMedication> _detectedMedications = [];
  String? _error;

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickAndScan() async {
    // Vérifier les permissions
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _error = 'Permission caméra refusée.';
      });
      return;
    }

    setState(() {
      _isScanning = true;
      _error = null;
      _recognizedText = '';
      _detectedMedications = [];
    });

    try {
      // Prendre la photo
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (image == null) {
        setState(() => _isScanning = false);
        return;
      }

      setState(() => _imageFile = image);

      // Lire le fichier image
      final inputImage = InputImage.fromFilePath(image.path);

      // Reconnaître le texte
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final text = recognizedText.text;
      setState(() {
        _recognizedText = text;
        _detectedMedications = _extractMedications(text);
        _isScanning = false;
      });

      if (text.isEmpty) {
        setState(() {
          _error = 'Aucun texte reconnu. Veuillez réessayer.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du scan : $e';
        _isScanning = false;
      });
    }
  }

  List<_DetectedMedication> _extractMedications(String text) {
    // Logique simple d'extraction : chercher des motifs (nom, dosage, fréquence)
    // Dans une vraie app, on utiliserait une regex plus robuste ou une IA.
    final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final detected = <_DetectedMedication>[];

    // Exemple : on cherche des lignes qui contiennent "mg" ou "g" ou "ml"
    for (var line in lines) {
      if (line.contains('mg') || line.contains('g') || line.contains('ml')) {
        // Essayer d'extraire le nom
        final parts = line.split(RegExp(r'\d+'));
        final name = parts.isNotEmpty ? parts[0].trim() : line;
        // Essayer d'extraire le dosage
        final dosageMatch = RegExp(r'(\d+)\s*(mg|g|ml|µg)').firstMatch(line);
        final dosage = dosageMatch?.group(0) ?? '';
        // Fréquence par défaut
        final frequency = '1x/jour';
        detected.add(_DetectedMedication(
          name: name.isNotEmpty ? name : 'Médicament',
          dosage: dosage,
          frequency: frequency,
        ));
      }
    }

    // Si aucun médicament détecté, on propose un fallback
    if (detected.isEmpty && text.isNotEmpty) {
      // Prendre la première ligne comme nom
      final firstLine = lines.isNotEmpty ? lines.first : 'Médicament';
      detected.add(_DetectedMedication(
        name: firstLine,
        dosage: '',
        frequency: '1x/jour',
      ));
    }

    return detected;
  }

  void _addMedication(_DetectedMedication med) {
    // Naviguer vers la page d'ajout avec les données pré-remplies
    context.push(
      '/sante/patient/medication/new',
      extra: {
        'name': med.name,
        'dosage': med.dosage,
        'frequency': med.frequency,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner ordonnance'),
        backgroundColor: const Color(0xFF2563FF),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Zone d'image
              Expanded(
                flex: 2,
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(_imageFile!.path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_camera,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Prenez une photo de votre ordonnance',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 12),

              // Bouton scan
              ElevatedButton.icon(
                onPressed: _isScanning ? null : _pickAndScan,
                icon: _isScanning
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.camera_alt),
                label: Text(_isScanning ? 'Analyse en cours...' : 'Prendre une photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563FF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),

              const SizedBox(height: 12),

              // Erreur
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              // Texte reconnu
              if (_recognizedText.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Texte reconnu :',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _recognizedText,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Médicaments détectés
              if (_detectedMedications.isNotEmpty) ...[
                const Text(
                  'Médicaments détectés :',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  flex: 1,
                  child: ListView.builder(
                    itemCount: _detectedMedications.length,
                    itemBuilder: (context, index) {
                      final med = _detectedMedications[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.medication, color: Colors.blue),
                          title: Text(med.name),
                          subtitle: Text('${med.dosage} • ${med.frequency}'),
                          trailing: ElevatedButton(
                            onPressed: () => _addMedication(med),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            child: const Text('Ajouter'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else if (_recognizedText.isNotEmpty && _detectedMedications.isEmpty) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Aucun médicament détecté dans le texte.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetectedMedication {
  final String name;
  final String dosage;
  final String frequency;

  _DetectedMedication({
    required this.name,
    required this.dosage,
    required this.frequency,
  });
}
