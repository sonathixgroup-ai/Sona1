// lib/presentation/network/widgets/story_highlights.dart
import 'package:flutter/material.dart';
import 'package:thix_id/theme.dart';

class Highlight {
  final String id;
  final String name;
  final String? coverImage;
  final List<String> storyIds;
  final DateTime createdAt;

  Highlight({
    required this.id,
    required this.name,
    this.coverImage,
    required this.storyIds,
    required this.createdAt,
  });
}

class StoryHighlights extends StatelessWidget {
  final List<Highlight> highlights;
  final VoidCallback? onAddHighlight;  // Type correct

  const StoryHighlights({
    super.key,
    required this.highlights,
    this.onAddHighlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('📌 En vedette', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThixHomeColors.darkNavy)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: highlights.length + (onAddHighlight != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (onAddHighlight != null && index == 0) {
                  return _buildAddHighlightButton();
                }
                final highlightIndex = onAddHighlight != null ? index - 1 : index;
                final highlight = highlights[highlightIndex];
                return _buildHighlightItem(highlight);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddHighlightButton() {
    return GestureDetector(
      onTap: onAddHighlight,
      child: Container(
        width: 56,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ThixHomeColors.primaryBlue, width: 2),
              ),
              child: const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                child: Icon(Icons.add, size: 22, color: ThixHomeColors.primaryBlue),
              ),
            ),
            const SizedBox(height: 4),
            const Text('Nouveau', style: TextStyle(fontSize: 9, color: ThixHomeColors.darkNavy)),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightItem(Highlight highlight) {
    return GestureDetector(
      onTap: () => _viewHighlight(highlight),
      child: Container(
        width: 56,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [ThixHomeColors.primaryBlue, ThixHomeColors.darkNavy]),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundImage: highlight.coverImage != null
                        ? NetworkImage(highlight.coverImage!)
                        : null,
                    child: highlight.coverImage == null
                        ? const Icon(Icons.star, size: 22, color: Colors.white)
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: ThixHomeColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_clock, size: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              highlight.name,
              style: const TextStyle(fontSize: 9, color: ThixHomeColors.darkNavy),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _viewHighlight(Highlight highlight) {
    // TODO: Naviguer vers la highlight
  }
}
