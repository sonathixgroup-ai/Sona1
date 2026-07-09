// lib/presentation/mon_pays/sections/videos_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routes/app_routes.dart';
import '../cards/video_card.dart';
import '../providers/videos_provider.dart';
import '../widgets/section_title.dart';

class VideosSection extends ConsumerWidget {
  const VideosSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(videosProvider);

    return videosAsync.when(
      data: (videos) {
        if (videos.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: 'Vidéos Officielles',
              subtitle: 'Discours, conseils, projets',
              seeAllText: 'Voir tout',
              onSeeAll: () {
                context.push(AppRoutes.monPaysVideos);
              },
            ),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final video = videos[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: VideoCard(
                      video: video,
                      onTap: () {
                        context.push(
                          '${AppRoutes.monPaysVideoDetail}'.replaceFirst(':id', video.id),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox(
        height: 180,
        child: Center(child: Text('Erreur de chargement')),
      ),
    );
  }
}
