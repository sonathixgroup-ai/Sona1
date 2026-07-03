// lib/presentation/chat/chat_spaces_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';

class ChatSpacesPage extends StatefulWidget {
  const ChatSpacesPage({super.key});

  @override
  State<ChatSpacesPage> createState() => _ChatSpacesPageState();
}

class _ChatSpacesPageState extends State<ChatSpacesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadSpaces();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final spaces = chatProvider.spaces;
    final isLoading = chatProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espaces'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateSpaceDialog(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : spaces.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: spaces.length,
                  itemBuilder: (context, index) {
                    final space = spaces[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFD4AF37),
                          child: Text(
                            space.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          space.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${space.members.length} membres',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Naviguer vers l'espace (à implémenter)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ouvrir l\'espace (à implémenter)'),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateSpaceDialog(),
        backgroundColor: const Color(0xFFD4AF37),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.space_dashboard,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun espace',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Créez votre premier espace de travail',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateSpaceDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Créer un espace'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: const Color(0xFF0B1B3D),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateSpaceDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer un espace'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Nom de l\'espace',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                // TODO: Appeler le provider pour créer l'espace
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Espace "$name" créé (simulation)')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
            ),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}
