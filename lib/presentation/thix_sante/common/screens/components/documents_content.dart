// 📁 lib/presentation/thix_sante/common/screens/_components/documents_content.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/patient_provider.dart';
import '../../widgets/gradient_button.dart';

class DocumentsContent extends ConsumerStatefulWidget {
  const DocumentsContent({Key? key}) : super(key: key);

  @override
  ConsumerState<DocumentsContent> createState() => _DocumentsContentState();
}

class _DocumentsContentState extends ConsumerState<DocumentsContent> {
  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(patientDocumentsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upload button
          GradientButton(
            text: '+ Ajouter un document',
            onPressed: () => _showUploadDialog(),
            icon: Icons.upload_file,
          ),
          const SizedBox(height: 20),
          const Text(
            '📄 Mes documents',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          documentsAsync.when(
            data: (documents) {
              if (documents.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.folder_open, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Aucun document', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                        const SizedBox(height: 8),
                        Text('Ajoutez vos analyses, ordonnances...', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: documents.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = documents[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getDocColor(doc.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_getDocIcon(doc.type), color: _getDocColor(doc.type), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doc.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              Text('${doc.date.day}/${doc.date.month}/${doc.date.year}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          onPressed: () => _viewDocument(doc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, size: 18),
                          onPressed: () => _shareDocument(doc),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e', style: const TextStyle(fontSize: 12))),
          ),
        ],
      ),
    );
  }

  IconData _getDocIcon(String type) {
    switch (type) {
      case 'prescription': return Icons.medication;
      case 'analysis': return Icons.science;
      case 'radio': return Icons.image;
      default: return Icons.description;
    }
  }

  Color _getDocColor(String type) {
    switch (type) {
      case 'prescription': return Colors.blue;
      case 'analysis': return Colors.green;
      case 'radio': return Colors.purple;
      default: return Colors.grey;
    }
  }

  void _showUploadDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ajouter un document', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            _buildUploadOption(Icons.camera_alt, 'Prendre une photo', () => Navigator.pop(context)),
            _buildUploadOption(Icons.folder, 'Choisir depuis la galerie', () => Navigator.pop(context)),
            _buildUploadOption(Icons.picture_as_pdf, 'Importer un PDF', () => Navigator.pop(context)),
            const SizedBox(height: 10),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOption(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 24),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      onTap: onTap,
    );
  }

  void _viewDocument(dynamic doc) {}
  void _shareDocument(dynamic doc) {}
}
