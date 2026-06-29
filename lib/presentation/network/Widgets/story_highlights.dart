// lib/presentation/network/widgets/story_highlights.dart
import 'package:flutter/material.dart';

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
            child: Text('📌 En vedette', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
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
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              ),
              child: const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.add, size: 30, color: Color(0xFFD4AF37)),
              ),
            ),
            const SizedBox(height: 4),
            const Text('Nouveau', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightItem(Highlight highlight) {
    return GestureDetector(
      onTap: () => _viewHighlight(highlight),
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFE5C55E)],
                    ),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: highlight.coverImage != null
                        ? NetworkImage(highlight.coverImage!)
                        : null,
                    child: highlight.coverImage == null
                        ? Icon(Icons.star, size: 30, color: const Color(0xFFD4AF37))
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4AF37),
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
              style: const TextStyle(fontSize: 10),
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
