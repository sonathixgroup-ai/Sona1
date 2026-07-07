// lib/presentation/education/education_routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Apprenant
import 'package:thix_id/presentation/education/screens/education_home.dart';
import 'package:thix_id/presentation/education/screens/education_search_page.dart';
import 'package:thix_id/presentation/education/screens/education_all_formations.dart';
import 'package:thix_id/presentation/education/screens/education_my_learning.dart';
import 'package:thix_id/presentation/education/screens/education_certificates.dart';
import 'package:thix_id/presentation/education/screens/education_forum.dart';
import 'package:thix_id/presentation/education/pages/formation_detail_page.dart';
import 'package:thix_id/presentation/education/pages/certificate_detail_page.dart';
import 'package:thix_id/presentation/education/pages/forum_topic_detail_page.dart';
import 'package:thix_id/presentation/education/pages/recommendations_page.dart';
import 'package:thix_id/presentation/education/models/certificate.dart';

// Formateur – routes fonctionnelles
import 'package:thix_id/presentation/education/instructor/instructor_dashboard.dart';
import 'package:thix_id/presentation/education/instructor/courses/course_list_page.dart';
import 'package:thix_id/presentation/education/instructor/courses/course_create_page.dart';
import 'package:thix_id/presentation/education/instructor/content/module_management_page.dart';
import 'package:thix_id/presentation/education/instructor/content/lesson_management_page.dart';
import 'package:thix_id/presentation/education/instructor/evaluations/question_management_page.dart';
import 'package:thix_id/presentation/education/instructor/book_management_page.dart';
import 'package:thix_id/presentation/education/instructor/create_book_page.dart';
// import 'package:thix_id/presentation/education/instructor/promotion/banner_management_page.dart'; // à décommenter plus tard

// ❌ SUPPRIMER la définition de NoTransitionPage (déjà dans app_router.dart)

List<GoRoute> educationRoutes = [
  GoRoute(
    path: '/education',
    name: 'educationHome',
    pageBuilder: (context, state) => const NoTransitionPage(child: EducationHome()),
    routes: [
      GoRoute(path: 'search', name: 'educationSearch', pageBuilder: (_, __) => const NoTransitionPage(child: EducationSearchPage())),
      GoRoute(path: 'all', name: 'educationAll', pageBuilder: (_, __) => const NoTransitionPage(child: EducationAllFormations())),
      GoRoute(path: 'my-learning', name: 'educationMyLearning', pageBuilder: (_, __) => const NoTransitionPage(child: EducationMyLearning())),
      GoRoute(path: 'certificates', name: 'educationCertificates', pageBuilder: (_, __) => const NoTransitionPage(child: EducationCertificates())),
      GoRoute(path: 'formation/:formationId', name: 'educationFormationDetail', pageBuilder: (_, state) {
        final id = state.pathParameters['formationId']!;
        return NoTransitionPage(child: FormationDetailPage(formationId: id));
      }),
      GoRoute(path: 'certificate/:certificateId', name: 'educationCertificateDetail', pageBuilder: (_, state) {
        final id = state.pathParameters['certificateId']!;
        final cert = state.extra as Certificate?;
        return NoTransitionPage(child: CertificateDetailPage(certificate: cert ?? Certificate(id: id, enrollmentId: '', userId: '', formationId: '', issuedAt: DateTime.now(), certificateUrl: '', verificationHash: '')));
      }),
      GoRoute(path: 'forum/:formationId', name: 'educationForum', pageBuilder: (_, state) {
        final id = state.pathParameters['formationId']!;
        return NoTransitionPage(child: EducationForum(formationId: id));
      }),
      GoRoute(path: 'forum/topic/:topicId', name: 'educationForumTopic', pageBuilder: (_, state) {
        final id = state.pathParameters['topicId']!;
        return NoTransitionPage(child: ForumTopicDetailPage(topicId: id));
      }),
      GoRoute(path: 'recommendations', name: 'educationRecommendations', pageBuilder: (_, __) => const NoTransitionPage(child: RecommendationsPage())),
    ],
  ),
];

List<GoRoute> instructorRoutes = [
  GoRoute(path: '/instructor/dashboard', name: 'instructorDashboard', pageBuilder: (_, __) => const NoTransitionPage(child: InstructorDashboard())),
  GoRoute(path: '/instructor/courses', name: 'instructorCourses', pageBuilder: (_, __) => const NoTransitionPage(child: CourseListPage())),
  GoRoute(path: '/instructor/courses/create', name: 'instructorCreateCourse', pageBuilder: (_, __) => const NoTransitionPage(child: CourseCreatePage())),
  GoRoute(path: '/instructor/courses/edit/:courseId', name: 'instructorEditCourse', pageBuilder: (_, state) {
    final id = state.pathParameters['courseId']!;
    return NoTransitionPage(child: CourseCreatePage(courseId: id));
  }),
  GoRoute(path: '/instructor/content/modules/:courseId', name: 'instructorCourseModules', pageBuilder: (_, state) {
    final id = state.pathParameters['courseId']!;
    return NoTransitionPage(child: ModuleManagementPage(courseId: id));
  }),
  GoRoute(path: '/instructor/content/lessons/create', name: 'instructorCreateLesson', pageBuilder: (_, __) => const NoTransitionPage(child: LessonManagementPage())),
  GoRoute(path: '/instructor/evaluations/:evaluationId/questions', name: 'instructorEvaluationQuestions', pageBuilder: (_, state) {
    final id = state.pathParameters['evaluationId']!;
    return NoTransitionPage(child: QuestionManagementPage(evaluationId: id));
  }),
  GoRoute(path: '/instructor/books', name: 'instructorBooks', pageBuilder: (_, __) => const NoTransitionPage(child: BookManagementPage())),
  GoRoute(path: '/instructor/books/create', name: 'instructorCreateBook', pageBuilder: (_, __) => const NoTransitionPage(child: CreateBookPage())),
  GoRoute(path: '/instructor/books/edit/:bookId', name: 'instructorEditBook', pageBuilder: (_, state) {
    final id = state.pathParameters['bookId']!;
    return NoTransitionPage(child: CreateBookPage(bookId: id));
  }),
];
