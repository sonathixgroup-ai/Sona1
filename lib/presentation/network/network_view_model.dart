import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Modèles simplifiés (à externaliser plus tard)
class Post {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String? userTitle;
  final String content;
  final List<String>? mediaUrls;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  bool isLiked;
  bool isSaved;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    this.userTitle,
    required this.content,
    this.mediaUrls,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.isLiked = false,
    this.isSaved = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>?;
    return Post(
      id: json['id'],
      userId: json['user_id'],
      userName: user != null ? '${user['first_name']} ${user['last_name']}' : 'Utilisateur',
      userAvatarUrl: user != null ? user['avatar_url'] : null,
      userTitle: user != null ? user['title'] : null,
      content: json['content'] ?? '',
      mediaUrls: json['media_urls'] != null ? List<String>.from(json['media_urls']) : null,
      createdAt: DateTime.parse(json['created_at']),
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      sharesCount: json['shares_count'] ?? 0,
    );
  }
}

class Story {
  final String id;
  final String userId;
  final String userName;
  final String? avatarUrl;
  final String? mediaUrl;
  final DateTime createdAt;
  final bool isViewed;

  Story({
    required this.id,
    required this.userId,
    required this.userName,
    this.avatarUrl,
    this.mediaUrl,
    required this.createdAt,
    this.isViewed = false,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>?;
    return Story(
      id: json['id'],
      userId: json['user_id'],
      userName: user != null ? '${user['first_name']} ${user['last_name']}' : 'Utilisateur',
      avatarUrl: user != null ? user['avatar_url'] : null,
      mediaUrl: json['media_url'],
      createdAt: DateTime.parse(json['created_at']),
      isViewed: json['is_viewed'] ?? false,
    );
  }
}

class Metric {
  final String label;
  final String value;
  final String change;
  final IconData icon;
  final Color color;

  Metric({
    required this.label,
    required this.value,
    required this.change,
    required this.icon,
    this.color = Colors.blue,
  });
}

class Short {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String? userTitle;
  final String videoUrl;
  final String? thumbnailUrl;
  final String description;
  final List<String> hashtags;
  final int views;
  final int likes;
  final int comments;
  final Duration duration;

  Short({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    this.userTitle,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.description,
    this.hashtags = const [],
    this.views = 0,
    this.likes = 0,
    this.comments = 0,
    required this.duration,
  });

  factory Short.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>?;
    return Short(
      id: json['id'],
      userId: json['user_id'],
      userName: user != null ? '${user['first_name']} ${user['last_name']}' : 'Utilisateur',
      userAvatarUrl: user != null ? user['avatar_url'] : null,
      userTitle: user != null ? user['title'] : null,
      videoUrl: json['video_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      description: json['description'] ?? '',
      hashtags: json['hashtags'] != null ? List<String>.from(json['hashtags']) : [],
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      duration: Duration(seconds: json['duration'] ?? 0),
    );
  }
}

class Opportunity {
  final String title;
  final String subtitle;
  final String type; // 'job', 'funding', 'project'
  final String? imageUrl;

  Opportunity({
    required this.title,
    required this.subtitle,
    required this.type,
    this.imageUrl,
  });
}

// ViewModel principal
class NetworkViewModel extends ChangeNotifier {
  final SupabaseClient supabase;
  final String currentUserId;

  bool _isLoading = false;
  String? _error;
  List<Post> _posts = [];
  List<Story> _stories = [];
  List<Metric> _metrics = [];
  List<double> _chartData = [];
  List<Short> _shorts = [];
  List<Opportunity> _opportunities = [];

  NetworkViewModel({required this.supabase, required this.currentUserId});

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Post> get posts => _posts;
  List<Story> get stories => _stories;
  List<Metric> get metrics => _metrics;
  List<double> get chartData => _chartData;
  List<Short> get shorts => _shorts;
  List<Opportunity> get opportunities => _opportunities;

  // Chargement initial
  Future<void> loadInitialData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final postsFuture = _fetchPosts();
      final storiesFuture = _fetchStories();
      final metricsFuture = _fetchMetrics();
      final chartFuture = _fetchChartData();
      final shortsFuture = _fetchShorts();
      final opportunitiesFuture = _fetchOpportunities();

      final results = await Future.wait([
        postsFuture,
        storiesFuture,
        metricsFuture,
        chartFuture,
        shortsFuture,
        opportunitiesFuture,
      ]);

      _posts = results[0];
      _stories = results[1];
      _metrics = results[2];
      _chartData = results[3];
      _shorts = results[4];
      _opportunities = results[5];

      // Charger les états de like/save pour chaque post (optimisé plus tard)
      for (var post in _posts) {
        post.isLiked = await _isPostLikedByUser(post.id);
        post.isSaved = await _isPostSavedByUser(post.id);
      }

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

    return response.map<Post>((json) => Post.fromJson(json)).toList();
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

    return response.map<Story>((json) => Story.fromJson(json)).toList();
  }

  Future<List<Metric>> _fetchMetrics() async {
    // Pour l'exemple, on simule des métriques (car elles sont souvent calculées)
    // Vous pouvez les remplacer par des requêtes SQL (ex: SUM des revenus, COUNT des users, etc.)
    return [
      const Metric(label: 'Revenus', value: '24.8K €', change: '+12.5%', icon: Icons.attach_money, color: Colors.green),
      const Metric(label: 'Utilisateurs', value: '2,540', change: '+18.2%', icon: Icons.people, color: Colors.blue),
      const Metric(label: 'Tâches', value: '18', change: 'En cours', icon: Icons.task, color: Colors.orange),
      const Metric(label: 'Activité', value: '55', change: '+42%', icon: Icons.trending_up, color: Colors.purple),
    ];
  }

  Future<List<double>> _fetchChartData() async {
    // Simulé (vous pouvez interroger une table d'activité)
    return [3.5, 5.0, 4.2, 6.8, 7.5, 5.5, 4.0];
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

    return response.map<Short>((json) => Short.fromJson(json)).toList();
  }

  Future<List<Opportunity>> _fetchOpportunities() async {
    // Pour l'exemple, on utilise des données statiques
    // Vous pouvez remplacer par une table Supabase 'opportunities'
    return [
      const Opportunity(
        title: 'Offre d\'emploi',
        subtitle: 'UI/UX Designer - TechNova',
        type: 'job',
      ),
      const Opportunity(
        title: 'Financement',
        subtitle: 'Fonds Innovation Afrique 2024',
        type: 'funding',
      ),
      const Opportunity(
        title: 'Appel à projets',
        subtitle: 'Impact Startup Challenge',
        type: 'project',
      ),
    ];
  }

  // ---- Actions utilisateur ----

  Future<void> toggleLike(String postId) async {
    try {
      final existing = await supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (existing != null) {
        // Unlike
        await supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', currentUserId);
        await supabase.rpc('decrement_likes', params: {'post_id': postId});
        // Mise à jour locale
        final index = _posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          _posts[index].isLiked = false;
          _posts[index].likesCount--;
          notifyListeners();
        }
      } else {
        // Like
        await supabase
            .from('post_likes')
            .insert({'post_id': postId, 'user_id': currentUserId});
        await supabase.rpc('increment_likes', params: {'post_id': postId});
        final index = _posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          _posts[index].isLiked = true;
          _posts[index].likesCount++;
          notifyListeners();
        }
      }
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
        final index = _posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          _posts[index].isSaved = false;
          notifyListeners();
        }
      } else {
        await supabase
            .from('saved_posts')
            .insert({'post_id': postId, 'user_id': currentUserId});
        final index = _posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          _posts[index].isSaved = true;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> sharePost(String postId) async {
    // Logique de partage (ex: ouvrir un modal de partage)
    // Pour l'exemple, on affiche un snackbar
    // (à implémenter avec un overlay)
  }

  Future<bool> _isPostLikedByUser(String postId) async {
    final response = await supabase
        .from('post_likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', currentUserId)
        .maybeSingle();
    return response != null;
  }

  Future<bool> _isPostSavedByUser(String postId) async {
    final response = await supabase
        .from('saved_posts')
        .select()
        .eq('post_id', postId)
        .eq('user_id', currentUserId)
        .maybeSingle();
    return response != null;
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
    await supabase.rpc('increment_comments', params: {'post_id': postId});
    // Mise à jour locale du compteur
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      _posts[index].commentsCount++;
      notifyListeners();
    }
  }
}
