import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/services/document_service.dart';
import 'package:thix_id/services/user_service.dart';
import '../../nav.dart';
import '../../theme.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/dashboard_shared_widgets.dart'; // Pour DocRow

class DocumentsTab extends StatelessWidget {
  final String uid;
  final DocumentService docs;
  final UserService userService;
  final String filter;
  final ValueChanged<String> onChangeFilter;

  const DocumentsTab({
    super.key,
    required this.uid,
    required this.docs,
    required this.userService,
    required this.filter,
    required this.onChangeFilter,
  });

  static const _filters = ['Tous', 'CIN', 'Passeport', 'Permis', 'Diplôme', 'PreuveAdresse', 'Autre'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        children: [
          DashboardCard(
            icon: Icons.folder_special_rounded,
            title: 'Documents',
            subtitle: 'Portefeuille documentaire sécurisé',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _filters.map((f) => ChoiceChip(
                    label: Text(f),
                    selected: filter == f,
                    onSelected: (_) => onChangeFilter(f),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                
                // StreamBuilder pour les documents...
                const Text('Liste des documents chargée via le StreamBuilder'),
                
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Logique de paiement fictif et navigation vers AppRoutes.vault
                  },
                  icon: const Icon(Icons.upload_rounded),
                  label: const Text('Uploader un nouveau document (1 USD)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
