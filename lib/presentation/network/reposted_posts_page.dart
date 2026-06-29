import 'package:flutter/material.dart';

class RepostedPostsPage extends StatelessWidget {
  const RepostedPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Posts repostés')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.repeat, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun post reposté'),
            SizedBox(height: 8),
            Text('Les posts que vous repostez apparaîtront ici',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
