// lib/presentation/mon_pays/pages/videos/videos_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../cards/video_card.dart';
import '../../providers/videos_provider.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

class VideosPage extends ConsumerWidget {
  const VideosPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(videosProvider);

    return Scaffold(
      appBar: MonPaysAppBar(
        title: 'Vidéos Officielles',
      ),
      body: videosAsync.when(
        data: (videos) {
          if (videos.isEmpty) {
            return Center(
              child: Text(
                'Aucune vidéo disponible',
                style: MonPaysTextStyles.bodyLarge.copyWith(
                  color: MonPaysColors.textSecondary,
                ),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return VideoCard(
                video: video,
                onTap: () {
                  context.push(
                    '${AppRoutes.monPaysVideoDetail}'.replaceFirst(':id', video.id),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: LoadingWidget(
            message: 'Chargement des vidéos...',
          ),
        ),
        error: (error, stack) => Center(
          child: MonPaysErrorWidget(
            message: 'Erreur de chargement : $error',
            onRetry: () => ref.refresh(videosProvider),
          ),
        ),
      ),
    );
  }
}
