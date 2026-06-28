// Contient ShortCard, LivePlayer, LiveChat, LiveParticipants
import 'package:flutter/material.dart';
import '../../data/models/short_model.dart';

// ----- ShortCard -----
class ShortCard extends StatelessWidget {
  final Short short;
  const ShortCard({super.key, required this.short});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: short.userAvatarUrl != null ? NetworkImage(short.userAvatarUrl!) : null,
                  child: short.userAvatarUrl == null ? Text(short.userName[0].toUpperCase()) : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(short.userName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      if (short.userTitle != null) Text(short.userTitle!, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, size: 18, color: Colors.grey),
              ],
            ),
          ),
          Stack(
            children: [
              ClipRRect(
                child: Image.network(
                  short.thumbnailUrl ?? short.videoUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.video_library, size: 40, color: Colors.grey)),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(short.duration),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.play_arrow, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('${short.views}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(short.description, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: short.hashtags.map((tag) => Text(tag, style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w500))).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _actionIcon(Icons.favorite_border, short.likes),
                    const SizedBox(width: 16),
                    _actionIcon(Icons.comment_outlined, short.comments),
                    const SizedBox(width: 16),
                    _actionIcon(Icons.share_outlined, 0),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        if (count > 0) Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(count.toString(), style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}

// ----- LivePlayer (paramétrable) -----
class LivePlayer extends StatelessWidget {
  final bool isAudio;
  final String streamUrl;
  final String hostName;
  final int listeners;
  const LivePlayer({super.key, required this.isAudio, required this.streamUrl, required this.hostName, required this.listeners});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAudio ? [Colors.purple.shade900, Colors.deepPurple.shade300] : [Colors.red.shade900, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 28, child: Icon(Icons.person, color: Colors.white)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hostName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('🔴 En direct • $listeners auditeurs', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white30,
            ),
            child: Slider(value: 0.5, onChanged: (_) {}),
          ),
          Row(
            children: [
              const Text('0:00', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              IconButton(
                icon: Icon(isAudio ? Icons.play_circle_filled : Icons.play_arrow, color: Colors.white, size: 48),
                onPressed: () {},
              ),
              const Spacer(),
              const Text('0:00', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _liveButton(Icons.chat_bubble_outline, 'Chat'),
              _liveButton(Icons.emoji_emotions_outlined, 'Réagir'),
              _liveButton(Icons.mic_off_outlined, 'Mute'),
              _liveButton(Icons.share_outlined, 'Partager'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _liveButton(IconData icon, String label) {
    return InkWell(
      onTap: () {},
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

// LiveChat, LiveParticipants peuvent être des widgets séparés (simplifiés ici)
class LiveChat extends StatelessWidget {
  const LiveChat({super.key});
  @override
  Widget build(BuildContext context) => const Text('Chat en direct (simplifié)');
}

class LiveParticipants extends StatelessWidget {
  const LiveParticipants({super.key});
  @override
  Widget build(BuildContext context) => const Text('Participants (simplifié)');
}
