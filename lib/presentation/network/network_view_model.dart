import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/post_model.dart';
import '../../data/models/story_model.dart';
import '../../data/models/metric_model.dart';
import '../../data/models/short_model.dart';

class NetworkViewModel extends ChangeNotifier {
  final SupabaseClient supabase;
  final String currentUserId;

  bool _isLoading = false;
  String? _error;
  List<Post> _posts = [];
  List<Story> _stories = [];
  List<Metric> _metrics = [];
  List<Short> _shorts = [];
  List<double> _chartData = [];

  NetworkViewModel({required this.supabase, required this.currentUserId});

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Post> get posts => _posts;
  List<Story> get stories => _stories;
  List<Metric> get metrics => _metrics;
  List<Short> get shorts => _shorts;
  List<double> get chartData => _chartData;

  // Chargement initial
  Future<void> loadInitialData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final postsFuture = _fetchPosts();
      final storiesFuture = _fetchStories();
      final metricsFuture = _fetchMetrics();
      final shortsFuture = _fetchShorts();
      final chartFuture = _fetchChartData();

      final results = await Future.wait([
        postsFuture,
        storiesFuture,
        metricsFuture,
        shortsFuture,
        chartFuture,
      ]);

      _posts = results[0];
      _stories = results[1];
      _metrics = results[2];
      _shorts = results[3];
      _chartData = results[4];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---- Requêtes Supabase ----

  Future<List<Post>> _fetchPosts() async {
    final response = await supabase
        .from('posts')
        .select('''
          id, user_id, content, media_urls, created_at, likes_count, comments_count, shares_count,
          users!inner(first_name, last_name, avatar_url, title)
        ''')
        .order('created_at', ascending: false)
        .limit(20);

    return response.map<Post>((json) {
      final user = json['users'] as Map<String, dynamic>;
      return Post(
        id: json['id'],
        userId: json['user_id'],
        userName: '${user['first_name']} ${user['last_name']}',
        userAvatarUrl: user['avatar_url'],
        userTitle: user['title'],
        content: json['content'],
        mediaUrls: json['media_urls'] != null ? List<String>.from(json['media_urls']) : null,
        createdAt: DateTime.parse(json['created_at']),
        likesCount: json['likes_count'] ?? 0,
        commentsCount: json['comments_count'] ?? 0,
        sharesCount: json['shares_count'] ?? 0,
      );
    }).toList();
  }

  Future<List<Story>> _fetchStories() async {
    final response = await supabase
        .from('stories')
        .select('''
          id, user_id, media_url, created_at, is_viewed,
          users!inner(first_name, last_name, avatar_url)
        ''')
        .order('created_at', ascending: false)
        .limit(10);

    return response.map<Story>((json) {
      final user = json['users'] as Map<String, dynamic>;
      return Story(
        id: json['id'],
        userId: json['user_id'],
        userName: '${user['first_name']} ${user['last_name']}',
        avatarUrl: user['avatar_url'],
        mediaUrl: json['media_url'],
        createdAt: DateTime.parse(json['created_at']),
        isViewed: json['is_viewed'] ?? false,
      );
    }).toList();
  }

  Future<List<Metric>> _fetchMetrics() async {
    // Simulé (à remplacer par une vraie requête SQL)
    return [
      Metric(label: 'Revenus', value: '24.8K €', change: '+12.5%', icon: Icons.attach_money, color: Colors.green),
      Metric(label: 'Utilisateurs', value: '2,540', change: '+18.2%', icon: Icons.people, color: Colors.blue),
      Metric(label: 'Tâches', value: '18', change: 'En cours', icon: Icons.task, color: Colors.orange),
      Metric(label: 'Activité', value: '55', change: '+42%', icon: Icons.trending_up, color: Colors.purple),
    ];
  }

  Future<List<Short>> _fetchShorts() async {
    final response = await supabase
        .from('shorts')
        .select('''
          id, user_id, video_url, thumbnail_url, description, hashtags, views, likes, comments, duration,
          users!inner(first_name, last_name, avatar_url, title)
        ''')
        .order('created_at', ascending: false)
        .limit(5);

    return response.map<Short>((json) {
      final user = json['users'] as Map<String, dynamic>;
      return Short(
        id: json['id'],
        userId: json['user_id'],
        userName: '${user['first_name']} ${user['last_name']}',
        userAvatarUrl: user['avatar_url'],
        userTitle: user['title'],
        videoUrl: json['video_url'],
        thumbnailUrl: json['thumbnail_url'],
        description: json['description'] ?? '',
        hashtags: json['hashtags'] != null ? List<String>.from(json['hashtags']) : [],
        views: json['views'] ?? 0,
        likes: json['likes'] ?? 0,
        comments: json['comments'] ?? 0,
        duration: Duration(seconds: json['duration'] ?? 0),
      );
    }).toList();
  }

  Future<List<double>> _fetchChartData() async {
    // Simulé
    return [3.5, 5.0, 4.2, 6.8, 7.5, 5.5, 4.0];
  }

  // ---- Actions utilisateur ----

  Future<void> toggleLike(String postId) async {
    try {
      // Vérifier si déjà liké
      final existing = await supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (existing != null) {
        await supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', currentUserId);
        await supabase.rpc('decrement_likes', params: {'post_id': postId});
      } else {
        await supabase
            .from('post_likes')
            .insert({'post_id': postId, 'user_id': currentUserId});
        await supabase.rpc('increment_likes', params: {'post_id': postId});
      }
      // Recharger les posts pour mettre à jour
      _posts = await _fetchPosts();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleSave(String postId) async {
    try {
      final existing = await supabase
          .from('saved_posts')
          .select()
          .eq('post_id', postId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (existing != null) {
        await supabase
            .from('saved_posts')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', currentUserId);
      } else {
        await supabase
            .from('saved_posts')
            .insert({'post_id': postId, 'user_id': currentUserId});
      }
      // Recharger
      _posts = await _fetchPosts();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> sharePost(String postId) async {
    // Logique de partage (ex: ouvrir un modal)
  }

  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    final response = await supabase
        .from('comments')
        .select('''
          id, content, created_at,
          users!inner(first_name, last_name, avatar_url)
        ''')
        .eq('post_id', postId)
        .order('created_at', ascending: false);
    return response.map((c) {
      final user = c['users'] as Map<String, dynamic>;
      return {
        'id': c['id'],
        'content': c['content'],
        'created_at': c['created_at'],
        'user_name': '${user['first_name']} ${user['last_name']}',
        'avatar_url': user['avatar_url'],
      };
    }).toList();
  }

  Future<void> addComment(String postId, String content) async {
    await supabase.from('comments').insert({
      'post_id': postId,
      'user_id': currentUserId,
      'content': content,
    });
    // Mise à jour du compteur
    await supabase.rpc('increment_comments', params: {'post_id': postId});
  }
}
