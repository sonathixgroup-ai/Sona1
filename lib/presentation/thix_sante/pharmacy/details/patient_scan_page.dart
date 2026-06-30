// presentation/thix_sante/patient/details/patient_scan_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PatientScanPage extends StatefulWidget {
  const PatientScanPage({super.key});

  @override
  State<PatientScanPage> createState() => _PatientScanPageState();
}

class _PatientScanPageState extends State<PatientScanPage> {
  bool _isScanning = false;
  String _result = '';

  Future<void> _pickImageAndScan() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() {
      _isScanning = true;
      _result = 'Analyse en cours...';
    });

    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isScanning = false;
      _result = 'Ordonnance détectée :\nParacétamol 500 mg, 3x/jour\nAmoxicilline 250 mg, 2x/jour';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner une ordonnance')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_camera, size: 80, color: Colors.purple),
            const SizedBox(height: 16),
            const Text('Prenez une photo de votre ordonnance',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            const Text('L\'application reconnaîtra les médicaments.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _pickImageAndScan,
              icon: _isScanning
                  ? const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.camera_alt),
              label: Text(_isScanning ? 'Analyse...' : 'Prendre une photo'),
            ),
            const SizedBox(height: 30),
            if (_result.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_result),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
