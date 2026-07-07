// lib/presentation/education/education_routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Routes apprenant
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

// Routes formateur (instructeur)
import 'package:thix_id/presentation/education/instructor/instructor_dashboard.dart';
import 'package:thix_id/presentation/education/instructor/course_management_page.dart';
import 'package:thix_id/presentation/education/instructor/create_course_page.dart';
import 'package:thix_id/presentation/education/instructor/module_management_page.dart';
import 'package:thix_id/presentation/education/instructor/lesson_management_page.dart';
import 'package:thix_id/presentation/education/instructor/book_management_page.dart';
import 'package:thix_id/presentation/education/instructor/create_book_page.dart';

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
  GoRoute(
    path: '/instructor/dashboard',
    name: 'instructorDashboard',
    pageBuilder: (context, state) => const NoTransitionPage(child: InstructorDashboard()),
  ),
  GoRoute(
    path: '/instructor/courses',
    name: 'instructorCourses',
    pageBuilder: (context, state) => const NoTransitionPage(child: CourseManagementPage()),
  ),
  GoRoute(
    path: '/instructor/courses/create',
    name: 'instructorCreateCourse',
    pageBuilder: (context, state) => const NoTransitionPage(child: CreateCoursePage()),
  ),
  GoRoute(
    path: '/instructor/courses/edit/:courseId',
    name: 'instructorEditCourse',
    pageBuilder: (context, state) {
      final courseId = state.pathParameters['courseId']!;
      return NoTransitionPage(child: CreateCoursePage(courseId: courseId));
    },
  ),
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
