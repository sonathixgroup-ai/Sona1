import 'package:flutter/material.dart';

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Reels', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.slow_motion_video, size: 80, color: Colors.white54),
            SizedBox(height: 16),
            Text('Bientôt disponible', style: TextStyle(color: Colors.white54)),
            Text('Partagez vos vidéos courtes', style: TextStyle(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}
