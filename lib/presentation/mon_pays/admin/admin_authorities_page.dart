// lib/presentation/mon_pays/admin/admin_authorities_page.dart
// Administration des autorités : liste avec actions CRUD

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/authorities_provider.dart';
import '../models/authority.dart';
import 'admin_authority_form_page.dart';
import 'widgets/admin_confirmation_dialog.dart';

class AdminAuthoritiesPage extends ConsumerStatefulWidget {
  const AdminAuthoritiesPage({super.key});

  @override
  ConsumerState<AdminAuthoritiesPage> createState() => _AdminAuthoritiesPageState();
}

class _AdminAuthoritiesPageState extends ConsumerState<AdminAuthoritiesPage> {
  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminAuthoritiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration – Autorités'),
        backgroundColor: Colors.red.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(adminAuthoritiesProvider.notifier).loadAuthorities();
            },
            tooltip: 'Rafraîchir',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminAuthorityFormPage(),
                ),
              );
            },
            tooltip: 'Ajouter',
          ),
        ],
      ),
      body: adminState.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement des autorités...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Erreur: ${error.toString()}',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(adminAuthoritiesProvider.notifier).loadAuthorities();
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (authorities) {
          if (authorities.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune autorité enregistrée',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Appuyez sur le bouton + pour ajouter',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: authorities.length,
            itemBuilder: (context, index) {
              final authority = authorities[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: authority.imageUrl != null && authority.imageUrl!.isNotEmpty
                        ? NetworkImage(authority.imageUrl!)
                        : null,
                    backgroundColor: Colors.grey.shade300,
                    child: authority.imageUrl == null || authority.imageUrl!.isEmpty
                        ? Text(
                            authority.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A5276),
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    authority.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(authority.title),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminAuthorityFormPage(
                                authority: authority,
                              ),
                            ),
                          );
                        },
                        tooltip: 'Modifier',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteConfirmation(context, authority.id);
                        },
                        tooltip: 'Supprimer',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AdminConfirmationDialog(
        title: 'Confirmation de suppression',
        message: 'Voulez-vous vraiment supprimer cette autorité ?',
        confirmText: 'Supprimer',
        cancelText: 'Annuler',
        isDestructive: true,
        onConfirm: () {
          Navigator.pop(ctx);
          ref.read(adminAuthoritiesProvider.notifier).deleteAuthority(id);
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }
}
