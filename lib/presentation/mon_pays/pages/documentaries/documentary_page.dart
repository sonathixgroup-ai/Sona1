// lib/presentation/mon_pays/pages/documentaries/documentary_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../providers/documentaries_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

class DocumentaryPage extends ConsumerStatefulWidget {
  final String id;
  const DocumentaryPage({Key? key, required this.id}) : super(key: key);

  @override
  ConsumerState<DocumentaryPage> createState() => _DocumentaryPageState();
}

class _DocumentaryPageState extends ConsumerState<DocumentaryPage> {
  YoutubePlayerController? _youtubeController;
  VideoPlayerController? _localController;
  bool _isYoutube = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocumentary();
  }

  Future<void> _loadDocumentary() async {
    try {
      final documentary = await ref.read(documentaryProvider(widget.id).future);
      if (documentary.url != null && documentary.url!.contains('youtube.com')) {
        final youtubeId = YoutubePlayerController.getYoutubeVideoId(documentary.url!);
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
      } else if (documentary.url != null && documentary.url!.startsWith('http')) {
        _localController = VideoPlayerController.networkUrl(Uri.parse(documentary.url!));
        await _localController!.initialize();
        await _localController!.play();
        _isYoutube = false;
      } else {
        _isYoutube = false;
      }
    } catch (e) {
      _error = 'Erreur de chargement du documentaire';
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
          'Documentaire',
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
                      _loadDocumentary();
                    },
                  ),
                )
              : FutureBuilder(
                  future: ref.read(documentaryProvider(widget.id).future),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final documentary = snapshot.data!;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (documentary.url != null && documentary.url!.isNotEmpty) ...[
                            _isYoutube && _youtubeController != null
                                ? YoutubePlayer(
                                    controller: _youtubeController!,
                                    showVideoProgressIndicator: true,
                                  )
                                : _localController != null &&
                                        _localController!.value.isInitialized
                                    ? VideoPlayer(_localController!)
                                    : const SizedBox.shrink(),
                            const SizedBox(height: 16),
                          ],
                          if (documentary.url == null || documentary.url!.isEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                documentary.thumbnailUrl,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 200,
                                  color: MonPaysColors.backgroundLight,
                                  child: const Icon(
                                    Icons.movie,
                                    size: 50,
                                    color: MonPaysColors.textHint,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: MonPaysColors.primaryRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              documentary.category,
                              style: MonPaysTextStyles.caption.copyWith(
                                color: MonPaysColors.primaryRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            documentary.title,
                            style: MonPaysTextStyles.heading5.copyWith(
                              color: MonPaysColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.timer,
                                size: 16,
                                color: MonPaysColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Durée: ${documentary.duration}',
                                style: MonPaysTextStyles.caption.copyWith(
                                  color: MonPaysColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              if (documentary.year != null) ...[
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: MonPaysColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  documentary.year!,
                                  style: MonPaysTextStyles.caption.copyWith(
                                    color: MonPaysColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const Divider(height: 32),
                          if (documentary.description != null) ...[
                            Text(
                              'Résumé',
                              style: MonPaysTextStyles.heading6.copyWith(
                                color: MonPaysColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              documentary.description!,
                              style: MonPaysTextStyles.bodyMedium.copyWith(
                                height: 1.6,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => context.pop(),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Retour'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: MonPaysColors.primaryBlue),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
