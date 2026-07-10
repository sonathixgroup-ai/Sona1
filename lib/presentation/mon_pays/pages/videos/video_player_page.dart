// lib/presentation/mon_pays/pages/videos/video_player_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../providers/videos_provider.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

class VideoPlayerPage extends ConsumerStatefulWidget {
  final String id;

  const VideoPlayerPage({Key? key, required this.id}) : super(key: key);

  @override
  ConsumerState<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends ConsumerState<VideoPlayerPage> {
  YoutubePlayerController? _youtubeController;
  VideoPlayerController? _localController;
  bool _isYoutube = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      final video = await ref.read(videoProvider(widget.id).future);
      if (video.url != null && video.url!.contains('youtube.com')) {
        // Vidéo YouTube
        final youtubeId = YoutubePlayerController.getYoutubeVideoId(video.url!);
        if (youtubeId != null) {
          _youtubeController = YoutubePlayerController(
            initialVideoId: youtubeId,
            flags: const YoutubePlayerFlags(
              autoPlay: true,
              mute: false,
              isLive: false,
            ),
          );
          _isYoutube = true;
        } else {
          _error = 'Lien YouTube invalide';
        }
      } else if (video.url != null && video.url!.startsWith('http')) {
        // Vidéo directe (MP4, etc.)
        _localController = VideoPlayerController.networkUrl(Uri.parse(video.url!));
        await _localController!.initialize();
        await _localController!.play();
        _isYoutube = false;
      } else {
        _error = 'Aucune source vidéo disponible';
      }
    } catch (e) {
      _error = 'Erreur de chargement de la vidéo';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _localController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lecture vidéo',
          style: MonPaysTextStyles.heading6.copyWith(color: Colors.white),
        ),
        backgroundColor: MonPaysColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : _error != null
              ? Center(
                  child: MonPaysErrorWidget(
                    message: _error!,
                    onRetry: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      _loadVideo();
                    },
                  ),
                )
              : Column(
                  children: [
                    // Lecteur vidéo
                    Expanded(
                      flex: 3,
                      child: _isYoutube
                          ? YoutubePlayer(
                              controller: _youtubeController!,
                              showVideoProgressIndicator: true,
                            )
                          : _localController != null && _localController!.value.isInitialized
                              ? VideoPlayer(_localController!)
                              : const Center(
                                  child: Text('Aucun lecteur disponible'),
                                ),
                    ),
                    // Informations
                    Expanded(
                      flex: 1,
                      child: FutureBuilder(
                        future: ref.read(videoProvider(widget.id).future),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final video = snapshot.data!;
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video.title,
                                  style: MonPaysTextStyles.heading6.copyWith(
                                    color: MonPaysColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                if (video.description != null)
                                  Text(
                                    video.description!,
                                    style: MonPaysTextStyles.bodyMedium.copyWith(
                                      color: MonPaysColors.textSecondary,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (video.duration != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.timer,
                                          size: 16,
                                          color: MonPaysColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Durée: ${video.duration}',
                                          style: MonPaysTextStyles.caption.copyWith(
                                            color: MonPaysColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
