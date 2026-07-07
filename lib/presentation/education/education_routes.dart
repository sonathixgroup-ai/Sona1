// lib/presentation/education/education_routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
