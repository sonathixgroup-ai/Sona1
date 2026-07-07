import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Apprenant
import 'screens/education_home.dart';
import 'screens/education_search_page.dart';
import 'screens/education_all_formations.dart';
import 'screens/education_my_learning.dart';
import 'screens/education_certificates.dart';
import 'screens/education_forum.dart';
import 'pages/formation_detail_page.dart';
import 'pages/certificate_detail_page.dart';
import 'pages/forum_topic_detail_page.dart';
import 'pages/recommendations_page.dart';
import 'models/certificate.dart';

// Formateur (routes fonctionnelles uniquement)
import 'instructor/dashboard/instructor_dashboard.dart';
import 'instructor/courses/course_list_page.dart';
import 'instructor/courses/course_create_page.dart';
import 'instructor/content/module_management_page.dart';
import 'instructor/content/lesson_management_page.dart';
// Les pages suivantes sont manquantes, on les importe seulement si elles existent
// import 'instructor/content/resource_upload_page.dart';
// import 'instructor/evaluations/evaluation_create_page.dart';
import 'instructor/evaluations/question_management_page.dart';
// import 'instructor/students/student_list_page.dart';
// import 'instructor/students/student_progress_page.dart';
// import 'instructor/performance/performance_dashboard.dart';
// import 'instructor/communication/announcements_page.dart';
// import 'instructor/communication/forum_management_page.dart';
// import 'instructor/assignments/assignment_correction_page.dart';
// import 'instructor/certificates/certificate_settings_page.dart';
// import 'instructor/calendar/instructor_calendar_page.dart';
// import 'instructor/virtual_class/virtual_class_page.dart';
import 'instructor/book_management_page.dart';
import 'instructor/create_book_page.dart';
// Bannière "À la une"
// import 'instructor/promotion/banner_management_page.dart'; // à décommenter si le fichier existe

class NoTransitionPage<T> extends Page<T> {
  final Widget child;
  const NoTransitionPage({required this.child, super.key});
  @override
  Route<T> createRoute(BuildContext context) => PageRouteBuilder<T>(
        settings: this,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
      );
}

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

// Seules les routes formateur dont les widgets sont réellement implémentés sont conservées.
// Les autres (resource_upload, evaluation_create, students, performance, communication, assignments, certificates, calendar, virtual_class) seront ajoutées ultérieurement.
List<GoRoute> instructorRoutes = [
  // Dashboard
  GoRoute(
    path: '/instructor/dashboard',
    name: 'instructorDashboard',
    pageBuilder: (_, __) => const NoTransitionPage(child: InstructorDashboard()),
  ),
  // Gestion des cours
  GoRoute(
    path: '/instructor/courses',
    name: 'instructorCourses',
    pageBuilder: (_, __) => const NoTransitionPage(child: CourseListPage()),
  ),
  GoRoute(
    path: '/instructor/courses/create',
    name: 'instructorCreateCourse',
    pageBuilder: (_, __) => const NoTransitionPage(child: CourseCreatePage()),
  ),
  GoRoute(
    path: '/instructor/courses/edit/:courseId',
    name: 'instructorEditCourse',
    pageBuilder: (_, state) {
      final id = state.pathParameters['courseId']!;
      return NoTransitionPage(child: CourseCreatePage(courseId: id));
    },
  ),
  // Contenu (modules et leçons)
  GoRoute(
    path: '/instructor/content/modules/:courseId',
    name: 'instructorCourseModules',
    pageBuilder: (_, state) {
      final id = state.pathParameters['courseId']!;
      return NoTransitionPage(child: ModuleManagementPage(courseId: id));
    },
  ),
  GoRoute(
    path: '/instructor/content/lessons/create',
    name: 'instructorCreateLesson',
    pageBuilder: (_, __) => const NoTransitionPage(child: LessonManagementPage()),
  ),
  // Évaluations (questions uniquement, car evaluation_create est manquant)
  GoRoute(
    path: '/instructor/evaluations/:evaluationId/questions',
    name: 'instructorEvaluationQuestions',
    pageBuilder: (_, state) {
      final id = state.pathParameters['evaluationId']!;
      return NoTransitionPage(child: QuestionManagementPage(evaluationId: id));
    },
  ),
  // Livres
  GoRoute(
    path: '/instructor/books',
    name: 'instructorBooks',
    pageBuilder: (_, __) => const NoTransitionPage(child: BookManagementPage()),
  ),
  GoRoute(
    path: '/instructor/books/create',
    name: 'instructorCreateBook',
    pageBuilder: (_, __) => const NoTransitionPage(child: CreateBookPage()),
  ),
  GoRoute(
    path: '/instructor/books/edit/:bookId',
    name: 'instructorEditBook',
    pageBuilder: (_, state) {
      final id = state.pathParameters['bookId']!;
      return NoTransitionPage(child: CreateBookPage(bookId: id));
    },
  ),
  // Bannière "À la une" (si le fichier existe)
  // GoRoute(
  //   path: '/instructor/banner',
  //   name: 'instructorBanner',
  //   pageBuilder: (_, __) => const NoTransitionPage(child: BannerManagementPage()),
  // ),
];
