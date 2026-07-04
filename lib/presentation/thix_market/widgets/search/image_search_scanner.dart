import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ImageSearchScanner extends StatefulWidget {
  final Function(Map<String, dynamic>? result) onResult;
  final Function(List<Map<String, dynamic>> results)? onMultipleResults;

  const ImageSearchScanner({
    super.key,
    required this.onResult,
    this.onMultipleResults,
  });

  @override
  State<ImageSearchScanner> createState() => _ImageSearchScannerState();
}

class _ImageSearchScannerState extends State<ImageSearchScanner> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _scanHistory = [];

  @override
  void initState() {
    super.initState();
    _loadScanHistory();
  }

  Future<void> _loadScanHistory() async {
    try {
      final response = await Supabase.instance.client
          .from('image_search_history')
          .select()
          .order('created_at', ascending: false)
          .limit(10);
      
      if (mounted) {
        setState(() {
          _scanHistory = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Error loading scan history: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la sélection de l\'image';
        _isProcessing = false;
      });
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Convertir l'image en base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Appeler l'Edge Function pour la recherche par image
      final response = await Supabase.instance.client
          .functions
          .invoke('image-search', body: {
            'image': base64Image,
            'return_similar': true,
            'limit': 10,
          });

      final result = response.data;
      
      if (result != null) {
        // Sauvegarder dans l'historique
        await Supabase.instance.client
            .from('image_search_history')
            .insert({
              'image_url': result['uploaded_image_url'],
              'result_count': result['matches']?.length ?? 0,
              'created_at': DateTime.now().toIso8601String(),
            });

        if (result['matches'] != null && result['matches'].isNotEmpty) {
          if (result['matches'].length == 1) {
            widget.onResult(result['matches'][0]);
          } else {
            widget.onMultipleResults?.call(List<Map<String, dynamic>>.from(result['matches']));
          }
        } else {
          widget.onResult(null);
        }
        
        await _loadScanHistory();
      }

      if (mounted) {
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
      setState(() {
        _errorMessage = 'Erreur lors de la recherche par image';
        _isProcessing = false;
      });
    }
  }

  void _showSourceSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choisir une image',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSourceButton(
                    icon: Icons.camera_alt,
                    label: 'Appareil photo',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceButton(
                    icon: Icons.photo_library,
                    label: 'Galerie',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE5592F).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 32, color: const Color(0xFFE5592F)),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bouton principal
          InkWell(
            onTap: _showSourceSelector,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE5592F),
                    const Color(0xFFE5592F).withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isProcessing)
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      const Icon(Icons.camera_alt, size: 32, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      _isProcessing ? 'Recherche en cours...' : 'Scanner par image',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!_isProcessing)
                      Text(
                        'Prenez une photo ou choisissez une image',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                  ],
                ),
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Historique des scans
          if (_scanHistory.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Recherches récentes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _scanHistory.length,
                itemBuilder: (context, index) {
                  final scan = _scanHistory[index];
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: scan['image_url'],
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              height: 60,
                              width: 60,
                              color: Colors.grey[200],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${scan['result_count']} résultats',
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          // Conseils
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.tips_and_updates, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Conseils pour un meilleur résultat',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '• Utilisez une image claire et bien éclairée\n• Cadrez bien le produit\n• Évitez les arrière-plans chargés',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget pour afficher les résultats multiples
class MultipleResultsDialog extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  final Function(Map<String, dynamic>) onSelect;

  const MultipleResultsDialog({
    super.key,
    required this.results,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plusieurs résultats trouvés',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez le produit correspondant',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final product = results[index];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: product['image_url'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(product['title']),
                    subtitle: Text('${product['price']} FCFA'),
                    trailing: Text(
                      '${product['similarity_score']?.toInt() ?? 0}%',
                      style: const TextStyle(
                        color: Color(0xFFE5592F),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onSelect(product);
                    },
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
