// lib/presentation/education/education_routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ─── ROUTES APPRENANT ─────────────────────────────────────────────────
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

// ─── ROUTES FORMATEUR (Instructeur) ──────────────────────────────
// Dashboard
import 'package:thix_id/presentation/education/instructor/dashboard/instructor_dashboard.dart';

// Cours
import 'package:thix_id/presentation/education/instructor/courses/course_list_page.dart';
import 'package:thix_id/presentation/education/instructor/courses/course_create_page.dart';

// Contenu
import 'package:thix_id/presentation/education/instructor/content/module_management_page.dart';
import 'package:thix_id/presentation/education/instructor/content/lesson_management_page.dart';
import 'package:thix_id/presentation/education/instructor/content/resource_upload_page.dart';

// Évaluations
import 'package:thix_id/presentation/education/instructor/evaluations/evaluation_create_page.dart';
import 'package:thix_id/presentation/education/instructor/evaluations/question_management_page.dart';

// Étudiants
import 'package:thix_id/presentation/education/instructor/students/student_list_page.dart';
import 'package:thix_id/presentation/education/instructor/students/student_progress_page.dart';

// Performance
import 'package:thix_id/presentation/education/instructor/performance/performance_dashboard.dart';

// Communication
import 'package:thix_id/presentation/education/instructor/communication/announcements_page.dart';
import 'package:thix_id/presentation/education/instructor/communication/forum_management_page.dart';

// Devoirs
import 'package:thix_id/presentation/education/instructor/assignments/assignment_correction_page.dart';

// Certificats
import 'package:thix_id/presentation/education/instructor/certificates/certificate_settings_page.dart';

// Calendrier
import 'package:thix_id/presentation/education/instructor/calendar/instructor_calendar_page.dart';

// Classe virtuelle
import 'package:thix_id/presentation/education/instructor/virtual_class/virtual_class_page.dart';

// Bibliothèque (gestion des livres)
import 'package:thix_id/presentation/education/instructor/book_management_page.dart';
import 'package:thix_id/presentation/education/instructor/create_book_page.dart';

// ─── HELPER ──────────────────────────────────────────────────────────
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

// ============================================================================
// ROUTES APPRENANT (Éducation)
// ============================================================================
List<GoRoute> educationRoutes = [
  GoRoute(
    path: '/education',
    name: 'educationHome',
    pageBuilder: (context, state) => const NoTransitionPage(child: EducationHome()),
    routes: [
      GoRoute(
        path: 'search',
        name: 'educationSearch',
        pageBuilder: (context, state) => const NoTransitionPage(child: EducationSearchPage()),
      ),
      GoRoute(
        path: 'all',
        name: 'educationAll',
        pageBuilder: (context, state) => const NoTransitionPage(child: EducationAllFormations()),
      ),
      GoRoute(
        path: 'my-learning',
        name: 'educationMyLearning',
        pageBuilder: (context, state) => const NoTransitionPage(child: EducationMyLearning()),
      ),
      GoRoute(
        path: 'certificates',
        name: 'educationCertificates',
        pageBuilder: (context, state) => const NoTransitionPage(child: EducationCertificates()),
      ),
      GoRoute(
        path: 'formation/:formationId',
        name: 'educationFormationDetail',
        pageBuilder: (context, state) {
          final formationId = state.pathParameters['formationId']!;
          return NoTransitionPage(child: FormationDetailPage(formationId: formationId));
        },
      ),
      GoRoute(
        path: 'certificate/:certificateId',
        name: 'educationCertificateDetail',
        pageBuilder: (context, state) {
          final certificateId = state.pathParameters['certificateId']!;
          final certificate = state.extra as Certificate?;
          return NoTransitionPage(
            child: CertificateDetailPage(
              certificate: certificate ??
                  Certificate(
                    id: certificateId,
                    enrollmentId: '',
                    userId: '',
                    formationId: '',
                    issuedAt: DateTime.now(),
                    certificateUrl: '',
                    verificationHash: '',
                  ),
            ),
          );
        },
      ),
      GoRoute(
        path: 'forum/:formationId',
        name: 'educationForum',
        pageBuilder: (context, state) {
          final formationId = state.pathParameters['formationId']!;
          return NoTransitionPage(child: EducationForum(formationId: formationId));
        },
      ),
      GoRoute(
        path: 'forum/topic/:topicId',
        name: 'educationForumTopic',
        pageBuilder: (context, state) {
          final topicId = state.pathParameters['topicId']!;
          return NoTransitionPage(child: ForumTopicDetailPage(topicId: topicId));
        },
      ),
      GoRoute(
        path: 'recommendations',
        name: 'educationRecommendations',
        pageBuilder: (context, state) => const NoTransitionPage(child: RecommendationsPage()),
      ),
    ],
  ),
];

// ============================================================================
// ROUTES FORMATEUR (Instructeur)
// ============================================================================
List<GoRoute> instructorRoutes = [
  // Tableau de bord
  GoRoute(
    path: '/instructor/dashboard',
    name: 'instructorDashboard',
    pageBuilder: (context, state) => const NoTransitionPage(child: InstructorDashboard()),
  ),

  // Gestion des cours
  GoRoute(
    path: '/instructor/courses',
    name: 'instructorCourses',
    pageBuilder: (context, state) => const NoTransitionPage(child: CourseListPage()),
  ),
  GoRoute(
    path: '/instructor/courses/create',
    name: 'instructorCreateCourse',
    pageBuilder: (context, state) => const NoTransitionPage(child: CourseCreatePage()),
  ),
  GoRoute(
    path: '/instructor/courses/edit/:courseId',
    name: 'instructorEditCourse',
    pageBuilder: (context, state) {
      final courseId = state.pathParameters['courseId']!;
      return NoTransitionPage(child: CourseCreatePage(courseId: courseId));
    },
  ),

  // Contenu pédagogique
  GoRoute(
    path: '/instructor/content/modules/:courseId',
    name: 'instructorCourseModules',
    pageBuilder: (context, state) {
      final courseId = state.pathParameters['courseId']!;
      return NoTransitionPage(child: ModuleManagementPage(courseId: courseId));
    },
  ),
  GoRoute(
    path: '/instructor/content/lessons/create',
    name: 'instructorCreateLesson',
    pageBuilder: (context, state) => const NoTransitionPage(child: LessonManagementPage()),
  ),
  GoRoute(
    path: '/instructor/content/resources/upload',
    name: 'instructorUploadResource',
    pageBuilder: (context, state) => const NoTransitionPage(child: ResourceUploadPage()),
  ),

  // Évaluations
  GoRoute(
    path: '/instructor/evaluations/create',
    name: 'instructorCreateEvaluation',
    pageBuilder: (context, state) => const NoTransitionPage(child: EvaluationCreatePage()),
  ),
  GoRoute(
    path: '/instructor/evaluations/:evaluationId/questions',
    name: 'instructorEvaluationQuestions',
    pageBuilder: (context, state) {
      final evaluationId = state.pathParameters['evaluationId']!;
      return NoTransitionPage(child: QuestionManagementPage(evaluationId: evaluationId));
    },
  ),

  // Étudiants
  GoRoute(
    path: '/instructor/students',
    name: 'instructorStudents',
    pageBuilder: (context, state) => const NoTransitionPage(child: StudentListPage()),
  ),
  GoRoute(
    path: '/instructor/student/:studentId/progress',
    name: 'instructorStudentProgress',
    pageBuilder: (context, state) {
      final studentId = state.pathParameters['studentId']!;
      return NoTransitionPage(child: StudentProgressPage(studentId: studentId));
    },
  ),

  // Performance
  GoRoute(
    path: '/instructor/performance',
    name: 'instructorPerformance',
    pageBuilder: (context, state) => const NoTransitionPage(child: PerformanceDashboard()),
  ),

  // Communication
  GoRoute(
    path: '/instructor/announcements',
    name: 'instructorAnnouncements',
    pageBuilder: (context, state) => const NoTransitionPage(child: AnnouncementsPage()),
  ),
  GoRoute(
    path: '/instructor/forum',
    name: 'instructorForumManagement',
    pageBuilder: (context, state) => const NoTransitionPage(child: ForumManagementPage()),
  ),

  // Devoirs
  GoRoute(
    path: '/instructor/assignments',
    name: 'instructorAssignments',
    pageBuilder: (context, state) => const NoTransitionPage(child: AssignmentCorrectionPage()),
  ),

  // Certificats
  GoRoute(
    path: '/instructor/certificates/settings',
    name: 'instructorCertificateSettings',
    pageBuilder: (context, state) => const NoTransitionPage(child: CertificateSettingsPage()),
  ),

  // Calendrier
  GoRoute(
    path: '/instructor/calendar',
    name: 'instructorCalendar',
    pageBuilder: (context, state) => const NoTransitionPage(child: InstructorCalendarPage()),
  ),

  // Classe virtuelle
  GoRoute(
    path: '/instructor/virtual-class',
    name: 'instructorVirtualClass',
    pageBuilder: (context, state) => const NoTransitionPage(child: VirtualClassPage()),
  ),

  // Livres
  GoRoute(
    path: '/instructor/books',
    name: 'instructorBooks',
    pageBuilder: (context, state) => const NoTransitionPage(child: BookManagementPage()),
  ),
  GoRoute(
    path: '/instructor/books/create',
    name: 'instructorCreateBook',
    pageBuilder: (context, state) => const NoTransitionPage(child: CreateBookPage()),
  ),
  GoRoute(
    path: '/instructor/books/edit/:bookId',
    name: 'instructorEditBook',
    pageBuilder: (context, state) {
      final bookId = state.pathParameters['bookId']!;
      return NoTransitionPage(child: CreateBookPage(bookId: bookId));
    },
  ),
];
