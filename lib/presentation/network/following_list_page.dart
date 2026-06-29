import 'package:flutter/material.dart';

class FollowingListPage extends StatelessWidget {
  final String userId;
  const FollowingListPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Abonnements')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun abonnement pour le moment'),
          ],
        ),
      ),
    );
  }
}
