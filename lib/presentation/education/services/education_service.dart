// lib/services/education_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/formation.dart';
import '../models/category.dart';
import '../models/module.dart';
import '../models/lesson.dart';
import '../models/video.dart';
import '../models/evaluation.dart';
import '../models/question.dart';
import '../models/enrollment.dart';
import '../models/certificate.dart';
import '../models/forum_topic.dart';
import '../models/forum_reply.dart';
import '../models/recommendation.dart';
import '../models/user_progress.dart';

class EducationService {
  final SupabaseClient _supabase;

  EducationService(this._supabase);

  // ─── FORMATIONS ────────────────────────────────────────────────

  /// Récupère toutes les formations avec pagination et filtres.
  /// [categoryId] : filtre par catégorie
  /// [level] : beginner, intermediate, advanced
  /// [status] : draft, published, archived
  /// [search] : recherche textuelle dans le titre ou la description
  /// [limit] et [offset] pour la pagination
  Future<List<Formation>> getFormations({
    String? categoryId,
    String? level,
    String? status,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = _supabase
        .from('formations')
        .select('*, categories!inner(*)') // jointure pour obtenir la catégorie
        .eq('status', status ?? 'published');

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (level != null) {
      query = query.eq('level', level);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or(
          'title.ilike.%$search%,description.ilike.%$search%');
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final List<dynamic> data = response;
    return data.map((json) {
      final formation = Formation.fromJson(json);
      // La catégorie est incluse dans le résultat de la jointure
      if (json['categories'] != null) {
        formation.category = Category.fromJson(json['categories']);
      }
      return formation;
    }).toList();
  }

  /// Récupère une formation avec ses modules, leçons, vidéos et évaluations.
  Future<Formation> getFormationDetails(String formationId) async {
    // 1. Récupérer la formation
    final formationJson = await _supabase
        .from('formations')
        .select('*, categories(*)')
        .eq('id', formationId)
        .single();

    final formation = Formation.fromJson(formationJson);
    if (formationJson['categories'] != null) {
      formation.category = Category.fromJson(formationJson['categories']);
    }

    // 2. Récupérer les modules de la formation
    final modulesJson = await _supabase
        .from('modules')
        .select('*')
        .eq('formation_id', formationId)
        .order('order', ascending: true);

    final List<Module> modules = [];
    for (var moduleJson in modulesJson) {
      final module = Module.fromJson(moduleJson);

      // 3. Récupérer les leçons de chaque module
      final lessonsJson = await _supabase
          .from('lessons')
          .select('*, videos(*), evaluations(*)')
          .eq('module_id', module.id)
          .order('order', ascending: true);

      final List<Lesson> lessons = [];
      for (var lessonJson in lessonsJson) {
        final lesson = Lesson.fromJson(lessonJson);

        // Vidéo associée
        if (lessonJson['videos'] != null) {
          lesson.video = Video.fromJson(lessonJson['videos']);
        }

        // Évaluation associée
        if (lessonJson['evaluations'] != null) {
          final evalJson = lessonJson['evaluations'];
          final evaluation = Evaluation.fromJson(evalJson);

          // Récupérer les questions de l'évaluation
          final questionsJson = await _supabase
              .from('questions')
              .select('*')
              .eq('evaluation_id', evaluation.id);

          evaluation.questions = questionsJson
              .map((qJson) => Question.fromJson(qJson))
              .toList();

          lesson.evaluation = evaluation;
        }

        lessons.add(lesson);
      }

      module.lessons = lessons;
      modules.add(module);
    }

    formation.modules = modules;
    return formation;
  }

  /// Récupère les formations auxquelles un utilisateur est inscrit.
  Future<List<Formation>> getMyFormations(String userId) async {
    // Récupère les inscriptions de l'utilisateur
    final enrollments = await _supabase
        .from('enrollments')
        .select('formation_id, formations(*)')
        .eq('user_id', userId);

    return enrollments.map((e) {
      final formation = Formation.fromJson(e['formations']);
      return formation;
    }).toList();
  }

  // ─── CATÉGORIES ──────────────────────────────────────────────────

  Future<List<Category>> getCategories() async {
    final response = await _supabase.from('categories').select('*');
    return response.map((json) => Category.fromJson(json)).toList();
  }

  // ─── INSCRIPTIONS (ENROLLMENTS) ────────────────────────────────

  /// Inscrit un utilisateur à une formation.
  Future<Enrollment> enrollUser(String userId, String formationId) async {
    final now = DateTime.now().toIso8601String();
    final response = await _supabase.from('enrollments').insert({
      'user_id': userId,
      'formation_id': formationId,
      'status': 'in_progress',
      'progress': 0.0,
      'started_at': now,
    }).select().single();

    return Enrollment.fromJson(response);
  }

  /// Récupère l'inscription d'un utilisateur à une formation donnée.
  Future<Enrollment?> getEnrollment(String userId, String formationId) async {
    final response = await _supabase
        .from('enrollments')
        .select('*')
        .eq('user_id', userId)
        .eq('formation_id', formationId)
        .maybeSingle();
    if (response == null) return null;
    return Enrollment.fromJson(response);
  }

  /// Met à jour la progression globale d'une formation.
  Future<void> updateEnrollmentProgress(String enrollmentId, double progress) async {
    await _supabase
        .from('enrollments')
        .update({
          'progress': progress,
          'status': progress >= 1.0 ? 'completed' : 'in_progress',
          'completed_at': progress >= 1.0 ? DateTime.now().toIso8601String() : null,
        })
        .eq('id', enrollmentId);
  }

  // ─── PROGRESSION PAR LEÇON (USER_PROGRESS) ──────────────────────

  /// Récupère la progression de toutes les leçons pour un utilisateur dans une formation.
  Future<List<UserProgress>> getUserProgressForFormation(String userId, String formationId) async {
    // Récupère les IDs des leçons de la formation
    final modules = await _supabase
        .from('modules')
        .select('id, lessons!inner(id)')
        .eq('formation_id', formationId);

    final lessonIds = modules.expand((m) {
      final lessons = m['lessons'] as List;
      return lessons.map((l) => l['id'] as String);
    }).toList();

    if (lessonIds.isEmpty) return [];

    final response = await _supabase
        .from('user_progress')
        .select('*')
        .eq('user_id', userId)
        .inFilter('lesson_id', lessonIds);

    return response.map((json) => UserProgress.fromJson(json)).toList();
  }

  /// Marque une leçon comme complétée pour un utilisateur.
  Future<void> completeLesson(String userId, String lessonId) async {
    final now = DateTime.now().toIso8601String();
    // On vérifie si une entrée existe déjà
    final existing = await _supabase
        .from('user_progress')
        .select('id, status')
        .eq('user_id', userId)
        .eq('lesson_id', lessonId)
        .maybeSingle();

    if (existing != null) {
      await _supabase
          .from('user_progress')
          .update({
            'status': 'completed',
            'progress': 1.0,
            'completed_at': now,
          })
          .eq('id', existing['id']);
    } else {
      await _supabase.from('user_progress').insert({
        'user_id': userId,
        'lesson_id': lessonId,
        'status': 'completed',
        'progress': 1.0,
        'last_accessed_at': now,
        'completed_at': now,
      });
    }
  }

  /// Met à jour le statut de progression d'une leçon (not_started, in_progress, completed).
  Future<void> updateLessonProgress(String userId, String lessonId, String status, double progress) async {
    final now = DateTime.now().toIso8601String();
    final existing = await _supabase
        .from('user_progress')
        .select('id')
        .eq('user_id', userId)
        .eq('lesson_id', lessonId)
        .maybeSingle();

    if (existing != null) {
      await _supabase
          .from('user_progress')
          .update({
            'status': status,
            'progress': progress,
            'last_accessed_at': now,
            'completed_at': status == 'completed' ? now : null,
          })
          .eq('id', existing['id']);
    } else {
      await _supabase.from('user_progress').insert({
        'user_id': userId,
        'lesson_id': lessonId,
        'status': status,
        'progress': progress,
        'last_accessed_at': now,
      });
    }
  }

  // ─── FORUM ──────────────────────────────────────────────────────

  Future<List<ForumTopic>> getForumTopics(String formationId) async {
    final response = await _supabase
        .from('forum_topics')
        .select('*, users(name)')
        .eq('formation_id', formationId)
        .order('created_at', ascending: false);

    return response.map((json) {
      final topic = ForumTopic.fromJson(json);
      topic.authorName = json['users']?['name'];
      return topic;
    }).toList();
  }

  Future<ForumTopic> createForumTopic({
    required String formationId,
    required String userId,
    required String title,
    required String body,
  }) async {
    final response = await _supabase.from('forum_topics').insert({
      'formation_id': formationId,
      'user_id': userId,
      'title': title,
      'body': body,
      'status': 'open',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).select().single();

    return ForumTopic.fromJson(response);
  }

  Future<List<ForumReply>> getTopicReplies(String topicId) async {
    final response = await _supabase
        .from('forum_replies')
        .select('*, users(name)')
        .eq('topic_id', topicId)
        .order('created_at', ascending: true);

    return response.map((json) {
      final reply = ForumReply.fromJson(json);
      reply.authorName = json['users']?['name'];
      return reply;
    }).toList();
  }

  Future<ForumReply> createForumReply({
    required String topicId,
    required String userId,
    required String body,
  }) async {
    final response = await _supabase.from('forum_replies').insert({
      'topic_id': topicId,
      'user_id': userId,
      'body': body,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).select().single();

    return ForumReply.fromJson(response);
  }

  Future<void> closeForumTopic(String topicId) async {
    await _supabase
        .from('forum_topics')
        .update({'status': 'closed', 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', topicId);
  }

  // ─── CERTIFICATS ─────────────────────────────────────────────────

  Future<Certificate?> getCertificate(String userId, String formationId) async {
    final response = await _supabase
        .from('certificates')
        .select('*')
        .eq('user_id', userId)
        .eq('formation_id', formationId)
        .maybeSingle();

    if (response == null) return null;
    return Certificate.fromJson(response);
  }

  Future<Certificate> generateCertificate(String userId, String formationId) async {
    final enrollment = await getEnrollment(userId, formationId);
    if (enrollment == null || enrollment.status != 'completed') {
      throw Exception('L\'utilisateur n\'a pas terminé la formation');
    }

    // Générer un certificat (ici on simule une URL)
    final certificateUrl =
        'https://thix.com/certificates/${userId}_${formationId}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    final response = await _supabase.from('certificates').insert({
      'enrollment_id': enrollment.id,
      'user_id': userId,
      'formation_id': formationId,
      'issued_at': DateTime.now().toIso8601String(),
      'certificate_url': certificateUrl,
    }).select().single();

    return Certificate.fromJson(response);
  }

  // ─── RECOMMANDATIONS ─────────────────────────────────────────────

  Future<List<Recommendation>> getRecommendations(String userId) async {
    final response = await _supabase
        .from('recommendations')
        .select('*, formations(*)')
        .eq('user_id', userId)
        .order('score', ascending: false);

    return response.map((json) {
      final rec = Recommendation.fromJson(json);
      if (json['formations'] != null) {
        rec.formation = Formation.fromJson(json['formations']);
      }
      return rec;
    }).toList();
  }

  // ─── ADMINISTRATION ──────────────────────────────────────────────

  // Ces méthodes sont réservées aux administrateurs / formateurs

  Future<Formation> createFormation(Formation formation) async {
    final response = await _supabase
        .from('formations')
        .insert(formation.toJson())
        .select()
        .single();
    return Formation.fromJson(response);
  }

  Future<void> updateFormation(Formation formation) async {
    await _supabase
        .from('formations')
        .update(formation.toJson())
        .eq('id', formation.id);
  }

  Future<void> deleteFormation(String formationId) async {
    await _supabase.from('formations').delete().eq('id', formationId);
  }

  Future<Module> createModule(Module module) async {
    final response = await _supabase
        .from('modules')
        .insert(module.toJson())
        .select()
        .single();
    return Module.fromJson(response);
  }

  Future<Lesson> createLesson(Lesson lesson) async {
    final response = await _supabase
        .from('lessons')
        .insert(lesson.toJson())
        .select()
        .single();
    return Lesson.fromJson(response);
  }

  Future<Video> createVideo(Video video) async {
    final response = await _supabase
        .from('videos')
        .insert(video.toJson())
        .select()
        .single();
    return Video.fromJson(response);
  }

  Future<Evaluation> createEvaluation(Evaluation evaluation) async {
    final response = await _supabase
        .from('evaluations')
        .insert(evaluation.toJson())
        .select()
        .single();
    return Evaluation.fromJson(response);
  }

  Future<Question> createQuestion(Question question) async {
    final response = await _supabase
        .from('questions')
        .insert(question.toJson())
        .select()
        .single();
    return Question.fromJson(response);
  }
}
