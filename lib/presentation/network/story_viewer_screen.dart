import 'package:flutter/material.dart';

class StoryViewerScreen extends StatelessWidget {
  final String storyId;

  const StoryViewerScreen({super.key, required this.storyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Story', style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
        child: Text(
          'Visualisation de la story',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
