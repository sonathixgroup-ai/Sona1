import 'package:flutter/material.dart'; // 'import' avec un 'i' minuscule
import '../../../models/network_story.dart';

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
  
  @override 
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.black, 
      body: PageView.builder(
        controller: _controller, 
        itemCount: widget.stories.length,
        itemBuilder: (context, index){ 
          final s = widget.stories[index]; 
          
          // 1. On sécurise la valeur de l'URL (gère le null et le vide)
          final String safeUrl = s.imageUrl ?? '';

          return Stack(
            children: [
              Center(
                // 2. On vérifie si l'URL existe avant d'appeler Image.network
                child: safeUrl.isNotEmpty 
                  ? Image.network(
                      safeUrl,
                      // 3. On empêche un crash si le lien web est mort
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, color: Colors.white54, size: 50);
                      },
                    )
                  // 4. Ce qui s'affiche si la story n'a pas d'image
                  : const Text("Aucun média", style: TextStyle(color: Colors.white54)),
              ), 
              Positioned(
                top: 50, 
                left: 16, 
                child: SafeArea(
                  child: Text(
                    s.userName, 
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold, // Optionnel: pour mieux lire le nom sur les images
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 4) // Ajoute de la lisibilité
                      ]
                    )
                  )
                )
              )
            ]
          ); 
        },
      )
    );
  }
}
