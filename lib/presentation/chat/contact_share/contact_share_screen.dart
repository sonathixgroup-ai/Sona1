import 'package:flutter/material.dart';

class ContactShareScreen extends StatelessWidget {
  final String userId;

  const ContactShareScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partager un contact')),
      body: Center(
        child: Text('Partage du contact ID : $userId'),
      ),
    );
  }
}
