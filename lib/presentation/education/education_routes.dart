// lib/education/education_routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/education_home.dart';
import 'screens/education_search_page.dart';
import 'screens/education_all_formations.dart';
import 'screens/education_my_learning.dart';
import 'screens/education_certificates.dart';
import 'screens/education_forum.dart';
import '../presentation/education/pages/formation_detail_page.dart';
import '../presentation/education/pages/certificate_detail_page.dart';
import '../presentation/education/pages/forum_topic_detail_page.dart';
import '../presentation/education/pages/recommendations_page.dart'; // à créer si nécessaire
import '../models/certificate.dart'; // pour le type

// Helper pour les pages sans transition
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

// Liste des routes du module Education
List<GoRoute> educationRoutes = [
  GoRoute(
    path: '/education',
    name: 'educationHome',
    pageBuilder: (context, state) => const NoTransitionPage(child: EducationHome()),
    routes: [
      // Recherche
      GoRoute(
        path: 'search',
        name: 'educationSearch',
        pageBuilder: (context, state) => const NoTransitionPage(child: EducationSearchPage()),
      ),
      // Toutes les formations
      GoRoute(
        path: 'all',
        name: 'educationAll',
        pageBuilder: (context, state) => const NoTransitionPage(child: EducationAllFormations()),
      ),
      // Mon apprentissage (inscriptions)
      GoRoute(
        path: 'my-learning',
        name: 'educationMyLearning',
        pageBuilder: (context, state) => const NoTransitionPage(child: EducationMyLearning()),
      ),
      // Mes certificats
      GoRoute(
        path: 'certificates',
        name: 'educationCertificates',
        pageBuilder: (context, state) => const NoTransitionPage(child: EducationCertificates()),
      ),
      // Détail d'une formation
      GoRoute(
        path: 'formation/:formationId',
        name: 'educationFormationDetail',
        pageBuilder: (context, state) {
          final formationId = state.pathParameters['formationId']!;
          return NoTransitionPage(child: FormationDetailPage(formationId: formationId));
        },
      ),
      // Détail d'un certificat (avec passage du certificat via extra)
      GoRoute(
        path: 'certificate/:certificateId',
        name: 'educationCertificateDetail',
        pageBuilder: (context, state) {
          final certificateId = state.pathParameters['certificateId']!;
          // On tente de récupérer le certificat depuis extra (si passé)
          final certificate = state.extra as Certificate?;
          // Si non passé, on peut soit le charger depuis un provider, soit créer un placeholder
          // Mais on va passer par le provider dans la page
          return NoTransitionPage(
            child: CertificateDetailPage(
              certificate: certificate ?? Certificate(
                id: certificateId,
                enrollmentId: '',
                userId: '',
                formationId: '',
                issuedAt: DateTime.now(),
                certificateUrl: '',
              ),
            ),
          );
        },
      ),
      // Forum d'une formation
      GoRoute(
        path: 'forum/:formationId',
        name: 'educationForum',
        pageBuilder: (context, state) {
          final formationId = state.pathParameters['formationId']!;
          return NoTransitionPage(child: EducationForum(formationId: formationId));
        },
      ),
      // Détail d'un sujet du forum
      GoRoute(
        path: 'forum/topic/:topicId',
        name: 'educationForumTopic',
        pageBuilder: (context, state) {
          final topicId = state.pathParameters['topicId']!;
          return NoTransitionPage(child: ForumTopicDetailPage(topicId: topicId));
        },
      ),
      // Recommandations (optionnel)
      GoRoute(
        path: 'recommendations',
        name: 'educationRecommendations',
        pageBuilder: (context, state) => const NoTransitionPage(child: RecommendationsPage()),
      ),
    ],
  ),
];
