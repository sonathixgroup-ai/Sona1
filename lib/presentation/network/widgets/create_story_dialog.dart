import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart'; // NOUVEAU PACKAGE À AJOUTER
import 'package:provider/provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:thix_id/services/network_service.dart';

class CreateStoryDialog extends StatefulWidget {
  const CreateStoryDialog({super.key});

  @override
  State<CreateStoryDialog> createState() => _CreateStoryDialogState();
}

class _CreateStoryDialogState extends State<CreateStoryDialog> {
  final TextEditingController _textController = TextEditingController();
  
  // Remplacement de "Image" par "Media" pour gérer à la fois photo et vidéo
  Uint8List? _selectedMediaBytes;
  String? _selectedMediaExtension;
  String? _selectedMediaType; // 'image' ou 'video'
  
  bool _isUploading = false;
  int _duration = 24;

  final Color _thixBlue = const Color(0xFF1B3B7A);
  final Color _thixLightBlue = const Color(0xFFF0F4FA);
  final Color _thixGold = const Color(0xFFE7BE59);

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  static Future<Uint8List> compressImageBytes(Uint8List bytes) async {
    return FlutterImageCompress.compressWithList(
      bytes,
      minHeight: 1080,
      minWidth: 1080,
      quality: 85,
      rotate: 0,
    );
  }

  // 1. CHOISIR UNE IMAGE (GALERIE)
  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null && file.bytes!.length <= 10 * 1024 * 1024) {
          setState(() {
            _selectedMediaBytes = file.bytes;
            _selectedMediaExtension = file.extension ?? 'jpg';
            _selectedMediaType = 'image';
          });
        } else {
          _showError('L\'image dépasse 10 Mo');
        }
      }
    } catch (e) {
      debugPrint('Erreur sélection image: $e');
    }
  }

  // 2. CHOISIR UNE VIDÉO (GALERIE)
  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        // On autorise jusqu'à 50 Mo pour une vidéo brute
        if (file.bytes != null && file.bytes!.length <= 50 * 1024 * 1024) {
          setState(() {
            _selectedMediaBytes = file.bytes;
            _selectedMediaExtension = file.extension ?? 'mp4';
            _selectedMediaType = 'video';
          });
        } else {
          _showError('La vidéo est trop lourde (max 50 Mo)');
        }
      }
    } catch (e) {
      debugPrint('Erreur sélection vidéo: $e');
    }
  }

  // 3. NOUVELLE VIDÉO COURTE (CAMÉRA - MAX 45 SEC)
  Future<void> _recordShortVideo() async {
    try {
      // Ouvre la caméra avec une limite stricte de 45 secondes
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 45), 
      );

      if (video != null) {
        final bytes = await video.readAsBytes();
        setState(() {
          _selectedMediaBytes = bytes;
          _selectedMediaExtension = 'mp4';
          _selectedMediaType = 'video';
        });
      }
    } catch (e) {
      debugPrint('Erreur enregistrement vidéo: $e');
      _showError('Impossible d\'ouvrir la caméra');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _createStory() async {
    final text = _textController.text.trim();
    
    if (text.isEmpty && _selectedMediaBytes == null) {
      _showError('Ajoutez du texte ou un média');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final networkService = Provider.of<NetworkService>(context, listen: false);
      String? mediaUrl;

      if (_selectedMediaBytes != null) {
        // Si c'est une image, on la compresse
        Uint8List uploadBytes = _selectedMediaBytes!;
        if (_selectedMediaType == 'image') {
          uploadBytes = await compute(compressImageBytes, _selectedMediaBytes!);
        } 
        // Note : Idéalement, il faudra ajouter un package comme 'video_compress' 
        // pour compresser les vidéos ici avant l'upload.

        mediaUrl = await networkService.uploadImageBytes(
          uploadBytes,
          fileExtension: _selectedMediaExtension!,
          bucket: 'stories', // Assure-toi que ton bucket accepte les vidéos !
        );
      }

            await networkService.createStory(
        mediaUrl, // C'est l'argument positionnel qui manquait !
        text: text,
        duration: _duration,
        mediaType: _selectedMediaType ?? 'text',
      );


      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Erreur lors de la publication');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: MediaQuery.of(context).size.width,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Créer une publication',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _thixBlue,
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(color: _thixLightBlue, shape: BoxShape.circle),
                  child: IconButton(
                    icon: Icon(Icons.close, color: _thixBlue, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- ZONE DE TEXTE ---
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _thixLightBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Quoi de neuf dans votre monde pro ?",
                    hintStyle: TextStyle(color: _thixBlue.withOpacity(0.5), fontSize: 15),
                  ),
                  style: TextStyle(color: _thixBlue, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // --- PRÉVISUALISATION MÉDIA ---
            if (_selectedMediaBytes != null)
              Stack(
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                      image: _selectedMediaType == 'image'
                          ? DecorationImage(
                              image: MemoryImage(_selectedMediaBytes!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    // Si c'est une vidéo, on affiche une icône Play au lieu de l'image
                    child: _selectedMediaType == 'video'
                        ? const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 36))
                        : null,
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.black87),
                      onPressed: () => setState(() {
                        _selectedMediaBytes = null;
                        _selectedMediaType = null;
                      }),
                    ),
                  ),
                ],
              ),

            // --- ICÔNES MÉDIAS & PUBLIER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildMediaIcon(Icons.image, Colors.green, _pickImage, "Photo"),
                    const SizedBox(width: 8),
                    _buildMediaIcon(Icons.folder_shared, Colors.orange, _pickVideo, "Vidéo"),
                    const SizedBox(width: 8),
                    _buildMediaIcon(Icons.videocam, Colors.red, _recordShortVideo, "Caméra"),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- BOUTON PUBLIER ---
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _createStory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _thixGold,
                  foregroundColor: _thixBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Color(0xFF1B3B7A))
                    : const Text('PUBLIER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaIcon(IconData icon, Color iconColor, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _thixLightBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
      ),
    );
  }
}
