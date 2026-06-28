// Regroupe StoryCarousel, CreatePostBar, MetricsGrid, ActivityChart
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../data/models/story_model.dart';
import '../../data/models/metric_model.dart';

// ----- StoryCarousel -----
class StoryCarousel extends StatelessWidget {
  final List<Story> stories;
  const StoryCarousel({super.key, required this.stories});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAddStoryButton();
          }
          final story = stories[index - 1];
          return _buildStoryItem(story);
        },
      ),
    );
  }

  Widget _buildAddStoryButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.add, size: 30, color: Colors.white),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.live_tv, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Ma Story', style: TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStoryItem(Story story) {
    final isViewed = story.isViewed;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isViewed ? Colors.grey.shade400 : Colors.blue,
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  backgroundImage: story.avatarUrl != null
                      ? NetworkImage(story.avatarUrl!)
                      : null,
                  child: story.avatarUrl == null
                      ? Text(story.userName[0].toUpperCase())
                      : null,
                ),
              ),
              if (!isViewed)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.circle, size: 10, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(story.userName, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

// ----- CreatePostBar -----
class CreatePostBar extends StatelessWidget {
  const CreatePostBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Naviguer vers create_post_screen
              },
              child: Text(
                'Quoi de neuf dans votre monde pro ?',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.photo_camera_outlined, size: 20),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(Icons.video_camera_back_outlined, size: 20),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(Icons.poll_outlined, size: 20),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ----- MetricsGrid -----
class MetricsGrid extends StatelessWidget {
  final List<Metric> metrics;
  const MetricsGrid({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: metrics.map((m) => _buildCard(m)).toList(),
    );
  }

  Widget _buildCard(Metric m) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: m.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(m.icon, size: 18, color: m.color),
              ),
              const Spacer(),
              Text(
                m.change,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: m.change.contains('+') ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(m.value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(m.label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

// ----- ActivityChart -----
class ActivityChart extends StatelessWidget {
  final List<double> data;
  const ActivityChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final max = data.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
          const Text('Activité hebdomadaire', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(data.length, (i) {
                final h = (data[i] / max) * 80;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(width: 20, height: h, decoration: BoxDecoration(color: Colors.blue.withOpacity(0.7), borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 6),
                    Text(['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'][i], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
