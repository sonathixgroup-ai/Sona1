// lib/presentation/network/widgets/short_video_card.dart
import 'package:flutter/material.dart';
import 'package:thix_id/presentation/network/models/short_model.dart';

class ShortVideoCard extends StatelessWidget {
  final ShortModel short;
  const ShortVideoCard({Key? key, required this.short}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(short.thumbnailUrl, fit: BoxFit.cover),
          Positioned(
            left: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(short.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                Text('${short.views} vues', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
