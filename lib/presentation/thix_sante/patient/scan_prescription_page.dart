// presentation/thix_sante/patient/scan_prescription_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Page de scan d'ordonnance avec OCR (simulation)
class ScanPrescriptionPage extends StatefulWidget {
  const ScanPrescriptionPage({super.key});

  @override
  State<ScanPrescriptionPage> createState() => _ScanPrescriptionPageState();
}

class _ScanPrescriptionPageState extends State<ScanPrescriptionPage> {
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

    // Simuler un traitement OCR (à remplacer par une vraie intégration)
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isScanning = false;
      _result = 'Ordonnance détectée :\nParacétamol 500 mg, 3x/jour\nAmoxicilline 250 mg, 2x/jour';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner une ordonnance'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_camera, size: 80, color: Colors.purple),
            const SizedBox(height: 16),
            const Text(
              'Prenez une photo de votre ordonnance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'L\'application reconnaîtra automatiquement les médicaments.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _pickImageAndScan,
              icon: _isScanning
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.camera_alt),
              label: Text(_isScanning ? 'Analyse...' : 'Prendre une photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            if (_result.isNotEmpty)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Résultat du scan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(_result),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
