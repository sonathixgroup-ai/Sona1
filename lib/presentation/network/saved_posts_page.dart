import 'package:flutter/material.dart';

class SavedPostsPage extends StatelessWidget {
  const SavedPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Posts sauvegardés')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun post sauvegardé'),
            SizedBox(height: 8),
            Text('Les posts que vous sauvegardez apparaîtront ici',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
