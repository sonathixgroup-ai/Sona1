import 'package:flutter/material.dart';

class LikedPostsPage extends StatelessWidget {
  const LikedPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Posts aimés')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun post aimé'),
            SizedBox(height: 8),
            Text('Les posts que vous aimez apparaîtront ici',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
