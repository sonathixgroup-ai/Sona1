import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/formation.dart';
import '../models/module.dart';
import '../models/lesson.dart';
import '../models/video.dart';
import '../models/evaluation.dart';
import '../models/question.dart';
import '../models/enrollment.dart';
import '../models/user_progress.dart';
import '../models/certificate.dart';
import '../models/forum_topic.dart';
import '../models/forum_reply.dart';
import '../models/announcement.dart';
import '../models/assignment.dart';
import '../models/submission.dart';
import '../models/virtual_class.dart';
import '../models/calendar_event.dart';
import '../models/book.dart';

class EducationService {
  final SupabaseClient _supabase;

  EducationService(this._supabase);

  // ─── FORMATIONS ────────────────────────────────────────────────
  Future<List<Formation>> getFormations({
    String? categoryId,
    String? level,
    String? status,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = _supabase.from('formations').select('*, categories!inner(*)');
    if (status != null) query = query.eq('status', status);
    if (categoryId != null) query = query.eq('category_id', categoryId);
    if (level != null) query = query.eq('level', level);
    if (search != null && search.isNotEmpty) {
      query = query.or('title.ilike.%$search%,description.ilike.%$search%');
    }
    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return response.map((json) => Formation.fromJson(json)).toList();
  }

  Future<Formation> getFormationDetails(String formationId) async {
    final json = await _supabase
        .from('formations')
        .select('*, categories(*)')
        .eq('id', formationId)
        .single();
    final formation = Formation.fromJson(json);
    // Charger modules, lessons, videos, evaluations, questions
    final modulesJson = await _supabase
        .from('modules')
        .select('*')
        .eq('formation_id', formationId)
        .order('order', ascending: true);
    final modules = <Module>[];
    for (var mJson in modulesJson) {
      final module = Module.fromJson(mJson);
      final lessonsJson = await _supabase
          .from('lessons')
          .select('*, videos(*), evaluations(*)')
          .eq('module_id', module.id)
          .order('order', ascending: true);
      final lessons = <Lesson>[];
      for (var lJson in lessonsJson) {
        final lesson = Lesson.fromJson(lJson);
        if (lJson['videos'] != null) lesson.video = Video.fromJson(lJson['videos']);
        if (lJson['evaluations'] != null) {
          final evalJson = lJson['evaluations'];
          final evaluation = Evaluation.fromJson(evalJson);
          final questionsJson = await _supabase
              .from('questions')
              .select('*')
              .eq('evaluation_id', evaluation.id);
          evaluation.questions = questionsJson.map((q) => Question.fromJson(q)).toList();
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

  Future<List<Formation>> getMyFormations(String userId) async {
    final enrollments = await _supabase
        .from('enrollments')
        .select('formation_id, formations(*)')
        .eq('user_id', userId);
    return enrollments.map((e) => Formation.fromJson(e['formations'])).toList();
  }

  Future<Formation> createFormation(Formation formation) async {
    final json = await _supabase.from('formations').insert(formation.toJson()).select().single();
    return Formation.fromJson(json);
  }

  Future<void> updateFormation(String id, Map<String, dynamic> data) async {
    await _supabase.from('formations').update(data).eq('id', id);
  }

  Future<void> deleteFormation(String id) async {
    await _supabase.from('formations').delete().eq('id', id);
  }

  // ─── MODULES ────────────────────────────────────────────────────
  Future<Module> createModule(Module module) async {
    final json = await _supabase.from('modules').insert(module.toJson()).select().single();
    return Module.fromJson(json);
  }

  Future<void> updateModule(String id, Map<String, dynamic> data) async {
    await _supabase.from('modules').update(data).eq('id', id);
  }

  Future<void> deleteModule(String id) async {
    await _supabase.from('modules').delete().eq('id', id);
  }

  // ─── LEÇONS ─────────────────────────────────────────────────────
  Future<Lesson> createLesson(Lesson lesson) async {
    final json = await _supabase.from('lessons').insert(lesson.toJson()).select().single();
    return Lesson.fromJson(json);
  }

  Future<void> updateLesson(String id, Map<String, dynamic> data) async {
    await _supabase.from('lessons').update(data).eq('id', id);
  }

  Future<void> deleteLesson(String id) async {
    await _supabase.from('lessons').delete().eq('id', id);
  }

  // ─── VIDÉOS ────────────────────────────────────────────────────
  Future<Video> createVideo(Video video) async {
    final json = await _supabase.from('videos').insert(video.toJson()).select().single();
    return Video.fromJson(json);
  }

  // ─── ÉVALUATIONS & QUESTIONS ──────────────────────────────────
  Future<Evaluation> createEvaluation(Evaluation evaluation) async {
    final json = await _supabase.from('evaluations').insert(evaluation.toJson()).select().single();
    return Evaluation.fromJson(json);
  }

  Future<Question> createQuestion(Question question) async {
    final json = await _supabase.from('questions').insert(question.toJson()).select().single();
    return Question.fromJson(json);
  }

  // ─── INSCRIPTIONS ──────────────────────────────────────────────
  Future<Enrollment> enrollUser(String userId, String formationId) async {
    final json = await _supabase.from('enrollments').insert({
      'user_id': userId,
      'formation_id': formationId,
      'status': 'active',
      'progress': 0.0,
    }).select().single();
    return Enrollment.fromJson(json);
  }

  Future<Enrollment?> getEnrollment(String userId, String formationId) async {
    final json = await _supabase
        .from('enrollments')
        .select('*, formations(*)')
        .eq('user_id', userId)
        .eq('formation_id', formationId)
        .maybeSingle();
    return json != null ? Enrollment.fromJson(json) : null;
  }

  Future<void> updateEnrollmentProgress(String enrollmentId, double progress) async {
    await _supabase.from('enrollments').update({
      'progress': progress,
      'status': progress >= 1.0 ? 'completed' : 'active',
      'completed_at': progress >= 1.0 ? DateTime.now().toIso8601String() : null,
    }).eq('id', enrollmentId);
  }

  // ─── PROGRESSION PAR LEÇON ────────────────────────────────────
  Future<List<UserProgress>> getUserProgress(String userId, String formationId) async {
    // Récupérer tous les IDs de leçons de la formation
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

  Future<void> completeLesson(String userId, String lessonId) async {
    final now = DateTime.now().toIso8601String();
    final existing = await _supabase
        .from('user_progress')
        .select('id')
        .eq('user_id', userId)
        .eq('lesson_id', lessonId)
        .maybeSingle();
    if (existing != null) {
      await _supabase.from('user_progress').update({
        'status': 'completed',
        'progress': 1.0,
        'completed_at': now,
      }).eq('id', existing['id']);
    } else {
      await _supabase.from('user_progress').insert({
        'user_id': userId,
        'lesson_id': lessonId,
        'status': 'completed',
        'progress': 1.0,
        'completed_at': now,
        'last_accessed_at': now,
      });
    }
  }

  // ─── CERTIFICATS ───────────────────────────────────────────────
  Future<Certificate?> getCertificate(String userId, String formationId) async {
    final json = await _supabase
        .from('certificates')
        .select('*')
        .eq('user_id', userId)
        .eq('formation_id', formationId)
        .maybeSingle();
    return json != null ? Certificate.fromJson(json) : null;
  }

  Future<Certificate> generateCertificate(String userId, String formationId) async {
    final enrollment = await getEnrollment(userId, formationId);
    if (enrollment == null || enrollment.status != 'completed') {
      throw Exception('Formation non terminée');
    }
    final hash = '${userId}_${formationId}_${DateTime.now().millisecondsSinceEpoch}';
    final json = await _supabase.from('certificates').insert({
      'enrollment_id': enrollment.id,
      'user_id': userId,
      'formation_id': formationId,
      'issued_at': DateTime.now().toIso8601String(),
      'certificate_url': 'https://thix.com/cert/$hash.pdf',
      'verification_hash': hash,
    }).select().single();
    return Certificate.fromJson(json);
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

  Future<ForumTopic> createForumTopic(String formationId, String userId, String title, String content) async {
    final json = await _supabase.from('forum_topics').insert({
      'formation_id': formationId,
      'user_id': userId,
      'title': title,
      'content': content,
      'status': 'open',
    }).select().single();
    return ForumTopic.fromJson(json);
  }

  Future<void> closeForumTopic(String topicId) async {
    await _supabase.from('forum_topics').update({'status': 'closed'}).eq('id', topicId);
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

  Future<ForumReply> createForumReply(String topicId, String userId, String content) async {
    final json = await _supabase.from('forum_replies').insert({
      'topic_id': topicId,
      'user_id': userId,
      'content': content,
    }).select().single();
    return ForumReply.fromJson(json);
  }

  // ─── LIVRES ─────────────────────────────────────────────────────
  Future<List<Book>> getBooks({String? category}) async {
    var query = _supabase.from('books').select('*');
    if (category != null) query = query.eq('category', category);
    final response = await query.order('created_at', ascending: false);
    return response.map((json) => Book.fromJson(json)).toList();
  }

  Future<Book> createBook(Book book) async {
    final json = await _supabase.from('books').insert(book.toJson()).select().single();
    return Book.fromJson(json);
  }

  Future<void> updateBook(String id, Map<String, dynamic> data) async {
    await _supabase.from('books').update(data).eq('id', id);
  }

  Future<void> deleteBook(String id) async {
    await _supabase.from('books').delete().eq('id', id);
  }
}
