import 'package:flutter/material.dart';

class EditAnnouncementPage extends StatelessWidget {
  final String announcementId;

  const EditAnnouncementPage({super.key, required this.announcementId});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Modifier une annonce')),
        body: Center(child: Text('Annonce #$announcementId')),
      );
}
