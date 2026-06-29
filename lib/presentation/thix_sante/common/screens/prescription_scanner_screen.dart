// 📁 lib/presentation/thix_sante/common/screens/prescription_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/loading_overlay.dart';

class PrescriptionScannerScreen extends ConsumerStatefulWidget {
  const PrescriptionScannerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PrescriptionScannerScreen> createState() => _PrescriptionScannerScreenState();
}

class _PrescriptionScannerScreenState extends ConsumerState<PrescriptionScannerScreen> {
  bool _isScanning = false;
  XFile? _image;
  List<Map<String, String>> _extractedDrugs = [];

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _image = image;
        _isScanning = true;
      });
      // Appel à l'Edge Function scan-prescription
      await Future.delayed(const Duration(seconds: 2)); // simulation
      setState(() {
        _isScanning = false;
        _extractedDrugs = [
          {'name': 'Amoxicilline', 'dosage': '500mg', 'frequency': '2x/jour'},
          {'name': 'Paracétamol', 'dosage': '1000mg', 'frequency': 'si besoin'},
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner une ordonnance'),
      ),
      body: LoadingOverlay(
        isLoading: _isScanning,
        message: 'Analyse en cours...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_image == null) ...[
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_camera, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        'Prenez une photo de l\'ordonnance',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        text: '📷 Appareil photo',
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: Icons.camera_alt,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        text: '🖼️ Galerie',
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: Icons.photo_library,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(_image!.path),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() => _image = null),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Reprendre', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_extractedDrugs.isNotEmpty) ...[
                  const Text(
                    '💊 Médicaments détectés',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ..._extractedDrugs.map((drug) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.medication, color: Colors.green, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(drug['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              Text('${drug['dosage']} • ${drug['frequency']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        GradientButton(
                          text: 'Ajouter',
                          onPressed: () {},
                          width: 80,
                          height: 32,
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                  GradientButton(
                    text: 'Créer les rappels',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Rappels créés avec succès'), backgroundColor: Colors.green),
                      );
                      Navigator.pop(context);
                    },
                    icon: Icons.notifications_active,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
