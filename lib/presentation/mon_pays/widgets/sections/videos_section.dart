// lib/presentation/mon_pays/widgets/sections/videos_section.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/video_model.dart';
import '../cards/video_card.dart';
import '../shared/section_title.dart';

class VideosSection extends StatelessWidget {
  final List<Video> videos;

  const VideosSection({Key? key, required this.videos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Vidéos Officielles',
          subtitle: 'Discours, conseils, projets',
          seeAllText: 'Voir tout',
          onSeeAll: null,
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: VideoCard(video: videos[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
