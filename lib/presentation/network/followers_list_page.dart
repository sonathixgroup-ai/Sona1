import 'package:flutter/material.dart';

class FollowersListPage extends StatelessWidget {
  final String userId;
  const FollowersListPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Abonnés')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun abonné pour le moment'),
          ],
        ),
      ),
    );
  }
}
