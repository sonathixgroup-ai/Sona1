// lib/providers/forum_provider.dart
import 'package:flutter/material.dart';
import '../services/education_service.dart';
import '../models/forum_topic.dart';
import '../models/forum_reply.dart';

class ForumProvider extends ChangeNotifier {
  final EducationService _service;

  List<ForumTopic> _topics = [];
  List<ForumReply> _replies = [];
  ForumTopic? _currentTopic;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ForumTopic> get topics => _topics;
  List<ForumReply> get replies => _replies;
  ForumTopic? get currentTopic => _currentTopic;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ForumProvider(this._service);

  // ─── SUJETS ──────────────────────────────────────────────────────

  Future<void> loadTopics(String formationId) async {
    _setLoading(true);
    try {
      _topics = await _service.getForumTopics(formationId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading forum topics: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadTopicReplies(String topicId) async {
    _setLoading(true);
    try {
      _replies = await _service.getTopicReplies(topicId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading topic replies: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<ForumTopic?> createTopic({
    required String formationId,
    required String userId,
    required String title,
    required String body,
  }) async {
    _setLoading(true);
    try {
      final topic = await _service.createForumTopic(
        formationId: formationId,
        userId: userId,
        title: title,
        body: body,
      );
      _topics.insert(0, topic);
      _error = null;
      return topic;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating forum topic: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> closeTopic(String topicId) async {
    _setLoading(true);
    try {
      await _service.closeForumTopic(topicId);
      final index = _topics.indexWhere((t) => t.id == topicId);
      if (index != -1) {
        _topics[index].status = 'closed';
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error closing forum topic: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ─── RÉPONSES ────────────────────────────────────────────────────

  Future<ForumReply?> createReply({
    required String topicId,
    required String userId,
    required String body,
  }) async {
    _setLoading(true);
    try {
      final reply = await _service.createForumReply(
        topicId: topicId,
        userId: userId,
        body: body,
      );
      _replies.add(reply);
      _error = null;
      return reply;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating forum reply: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ─── UTILITAIRES ──────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _topics = [];
    _replies = [];
    _currentTopic = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
