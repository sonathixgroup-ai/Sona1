import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime timestamp;
  final String? imageUrl;
  final String? audioUrl;
  final String? status; // sent, delivered, read
  final VoidCallback? onImageTap;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
    this.imageUrl,
    this.audioUrl,
    this.status,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Material(
              elevation: 0,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              color: isMe ? const Color(0xFFE5592F) : Colors.grey[200],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image if present
                    if (imageUrl != null && imageUrl!.isNotEmpty)
                      GestureDetector(
                        onTap: onImageTap,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl!,
                            height: 150,
                            width: 200,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              height: 150,
                              width: 200,
                              color: Colors.grey[300],
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                          ),
                        ),
                      ),
                    
                    if (imageUrl != null && imageUrl!.isNotEmpty)
                      const SizedBox(height: 8),
                    
                    // Audio player if present
                    if (audioUrl != null && audioUrl!.isNotEmpty)
                      _buildAudioPlayer(),
                    
                    if (audioUrl != null && audioUrl!.isNotEmpty)
                      const SizedBox(height: 8),
                    
                    // Text message
                    if (message.isNotEmpty)
                      Text(
                        message,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(timestamp),
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
                if (isMe && status != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    status == 'sent' ? Icons.check : 
                    status == 'delivered' ? Icons.done_all : 
                    Icons.done_all,
                    size: 12,
                    color: status == 'read' ? const Color(0xFFE5592F) : Colors.grey[500],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      width: 200,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.play_arrow, size: 20, color: isMe ? Colors.white : Colors.black87),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: 0.3,
              backgroundColor: Colors.grey[400],
              color: isMe ? Colors.white : const Color(0xFFE5592F),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '0:30 / 1:00',
            style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey[700]),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
