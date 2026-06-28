import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Models
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final MessageStatus status;
  final List<String> reactions;
  final String? replyTo;
  final bool isPinned;
  final bool isEdited;
  final bool isSelfDestructing;
  final bool isEncrypted;
  final MediaAttachment? media;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    this.reactions = const [],
    this.replyTo,
    this.isPinned = false,
    this.isEdited = false,
    this.isSelfDestructing = false,
    this.isEncrypted = false,
    this.media,
  });

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    DateTime? timestamp,
    MessageType? type,
    MessageStatus? status,
    List<String>? reactions,
    String? replyTo,
    bool? isPinned,
    bool? isEdited,
    bool? isSelfDestructing,
    bool? isEncrypted,
    MediaAttachment? media,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      status: status ?? this.status,
      reactions: reactions ?? this.reactions,
      replyTo: replyTo ?? this.replyTo,
      isPinned: isPinned ?? this.isPinned,
      isEdited: isEdited ?? this.isEdited,
      isSelfDestructing: isSelfDestructing ?? this.isSelfDestructing,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      media: media ?? this.media,
    );
  }
}

enum MessageType { text, image, video, audio, file, gif, sticker, emoji }
enum MessageStatus { sending, sent, delivered, read, failed }

class MediaAttachment {
  final String url;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final Duration? duration;

  MediaAttachment({
    required this.url,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    this.duration,
  });
}

class ChatConversation {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final bool isGroup;
  final List<String> memberIds;
  final List<String> adminIds;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final List<ChatMessage> messages;
  final List<String> pinnedMessageIds;
  final bool isMuted;
  final bool isArchived;
  final bool isEncrypted;

  ChatConversation({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    this.isGroup = false,
    this.memberIds = const [],
    this.adminIds = const [],
    required this.createdAt,
    required this.lastMessageAt,
    this.messages = const [],
    this.pinnedMessageIds = const [],
    this.isMuted = false,
    this.isArchived = false,
    this.isEncrypted = false,
  });
}

// State Management
final chatMessagesProvider = StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
  return ChatMessagesNotifier();
});

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  ChatMessagesNotifier() : super([]);

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void updateMessage(String messageId, ChatMessage updatedMessage) {
    state = state.map((msg) => msg.id == messageId ? updatedMessage : msg).toList();
  }

  void deleteMessage(String messageId) {
    state = state.where((msg) => msg.id != messageId).toList();
  }

  void addReaction(String messageId, String emoji) {
    state = state.map((msg) {
      if (msg.id == messageId) {
        final reactions = List<String>.from(msg.reactions);
        if (reactions.contains(emoji)) {
          reactions.remove(emoji);
        } else {
          reactions.add(emoji);
        }
        return msg.copyWith(reactions: reactions);
      }
      return msg;
    }).toList();
  }

  void togglePin(String messageId) {
    state = state.map((msg) {
      if (msg.id == messageId) {
        return msg.copyWith(isPinned: !msg.isPinned);
      }
      return msg;
    }).toList();
  }
}

final conversationProvider = StateNotifierProvider<ConversationNotifier, ChatConversation?>((ref) {
  return ConversationNotifier();
});

class ConversationNotifier extends StateNotifier<ChatConversation?> {
  ConversationNotifier() : super(null);

  void setConversation(ChatConversation conversation) {
    state = conversation;
  }

  void updateTypingStatus(String userId, bool isTyping) {
    // Implement typing status update
  }
}

// UI Components
class ChatHomeScreen extends ConsumerWidget {
  const ChatHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'THIX CHAT',
              style: TextStyle(
                color: Color(0xFF5A67D8),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Connectez-vous. Échangez. Avancez.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.grey),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none, color: Colors.grey),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF5A67D8),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF5A67D8),
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Stats Cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStatCard(
                    icon: Icons.people,
                    label: 'En ligne',
                    value: '142',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    icon: Icons.mail,
                    label: 'Nouveaux\nmessages',
                    value: '38',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    icon: Icons.videocam,
                    label: 'Réunions\nactives',
                    value: '12',
                    color: Colors.purple,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    icon: Icons.security,
                    label: 'Alertes\nsécurité',
                    value: '7',
                    color: Colors.orange,
                  ),
                ],
              ),
            ),

            // Online Users Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'En ligne',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Voir tout',
                        style: TextStyle(
                          color: Color(0xFF5A67D8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildAddStoryCard(),
                        ..._buildOnlineUserCards(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tab Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabFilter('Tous', true),
                    const SizedBox(width: 8),
                    _buildTabFilter('Équipes', false),
                    const SizedBox(width: 8),
                    _buildTabFilter('Appels', false),
                    const SizedBox(width: 8),
                    _buildTabFilter('Favoris', false),
                    const SizedBox(width: 8),
                    _buildTabFilter('Rendez-vous', false),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Conversations List
            Column(
              children: [
                _buildConversationTile(
                  name: 'Aminata Diallo',
                  message: 'Peux-tu me partager le document du projet ?',
                  time: '09:31',
                  unreadCount: 2,
                  isPinned: true,
                  isGroup: false,
                ),
                _buildConversationTile(
                  name: 'Équipe Marketing',
                  message: 'David : Voici les visuels pour la campagne',
                  time: '09:12',
                  unreadCount: 5,
                  isGroup: true,
                ),
                _buildConversationTile(
                  name: 'Koffi Mensah',
                  message: 'Merci pour ton retour ! On avance bien 👍',
                  time: 'Hier',
                  unreadCount: 1,
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF5A67D8),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Spaces'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: 1,
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddStoryCard() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF5A67D8), width: 2),
              color: Colors.grey[200],
            ),
            child: const Icon(Icons.add, color: Colors.grey, size: 24),
          ),
          const SizedBox(height: 8),
          const Text('Nouvelle\nhistoire', textAlign: TextAlign.center, style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  List<Widget> _buildOnlineUserCards() {
    final users = ['Aminata', 'Nathan', 'Sarah', 'Koffi', 'David'];
    return users
        .map(
          (name) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF5A67D8), width: 2),
                    color: const Color(0xFF5A67D8),
                  ),
                  child: Center(
                    child: Text(
                      name[0],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(name, style: const TextStyle(fontSize: 10)),
              ],
            ),
          ),
        )
        .toList();
  }

  Widget _buildTabFilter(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isActive ? const Color(0xFF5A67D8) : Colors.grey[200],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isActive ? Colors.white : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildConversationTile({
    required String name,
    required String message,
    required String time,
    required int unreadCount,
    bool isPinned = false,
    bool isGroup = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (isPinned) ...[
            const Icon(Icons.star, color: Color(0xFF5A67D8), size: 16),
            const SizedBox(width: 8),
          ],
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: isGroup ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: isGroup ? BorderRadius.circular(8) : null,
              color: const Color(0xFF5A67D8),
            ),
            child: Center(
              child: Text(
                name[0],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 4),
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF5A67D8),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
