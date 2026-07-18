import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/network_story.dart';
import '../../../services/network_service.dart'; // N'oublie pas cet import

class StoryViewer extends StatefulWidget {
  final List<NetworkStory> stories;
  final int initialIndex;
  
  const StoryViewer({
    super.key, 
    required this.stories, 
    required this.initialIndex
  });
  
  @override 
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  late PageController _controller;
  
  @override 
  void initState(){ 
    super.initState(); 
    _controller = PageController(initialPage: widget.initialIndex); 
  }

  // --- FONCTION POUR SUPPRIMER LA STORY ---
  Future<void> _deleteStory(BuildContext context, String storyId) async {
    // 1. Demander confirmation avant de supprimer
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la story ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // 2. Si confirmé, on supprime via le service
    if (confirm == true && mounted) {
      try {
        final networkService = Provider.of<NetworkService>(context, listen: false);
        await networkService.deleteStory(storyId);
        
        if (mounted) {
          Navigator.pop(context); // Ferme le StoryViewer
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Story supprimée'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
  
  @override 
  Widget build(BuildContext context){
    // Récupérer l'ID de l'utilisateur actuel pour vérifier la propriété de la story
    final currentUserId = Provider.of<NetworkService>(context, listen: false).currentUserId;

    return Scaffold(
      backgroundColor: Colors.black, 
      body: PageView.builder(
        controller: _controller, 
        itemCount: widget.stories.length,
        itemBuilder: (context, index){ 
          final s = widget.stories[index]; 
          
          final String safeUrl = s.imageUrl ?? '';
          final String storyText = s.textContent ?? ''; // Ou s.text selon ton modèle
          
          // Vérifier si la story appartient à l'utilisateur connecté
          final bool isMyStory = s.userId == currentUserId; 

          return Stack(
            children: [
              // 1. LE FOND (Image ou Dégradé pour le texte)
              Positioned.fill(
                child: safeUrl.isNotEmpty 
                  ? Image.network(
                      safeUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 50));
                      },
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1B3B7A), Color(0xFF0B1B3D)],
                        ),
                      ),
                    ),
              ), 

              // 2. LE TEXTE (S'il y en a et qu'il n'y a pas d'image)
              if (storyText.isNotEmpty && safeUrl.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      storyText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // 3. HEADER : NOM DE L'UTILISATEUR (En haut à gauche)
              Positioned(
                top: 50, 
                left: 16, 
                child: SafeArea(
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        s.userName, 
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          shadows: [Shadow(color: Colors.black87, blurRadius: 4)]
                        )
                      ),
                    ],
                  )
                )
              ),

              // 4. LE BOUTON POUBELLE 🗑️ (En haut à droite, uniquement si c'est MA story)
              if (isMyStory)
                Positioned(
                  top: 50,
                  right: 16,
                  child: SafeArea(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white),
                        onPressed: () => _deleteStory(context, s.id), // s.id doit exister dans ton modèle NetworkStory
                      ),
                    ),
                  ),
                ),
            ]
          ); 
        },
      )
    );
  }
}
