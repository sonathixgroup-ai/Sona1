// lib/presentation/thix_weeding/thix_weeding_routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'pages/home/thix_weeding_home_page.dart';
import 'pages/guest/guest_home_page.dart';
import 'pages/guest/invitation_page.dart';
import 'pages/guest/programme_page.dart';
import 'pages/guest/lieu_acces_page.dart';
import 'pages/guest/rsvp_page.dart';
import 'pages/guest/cadeaux_page.dart';
import 'pages/guest/galerie_page.dart';
import 'pages/guest/livre_or_page.dart';
import 'pages/guest/infos_page.dart';

class ThixWeedingRoutes {
  static const String home = '/thix-weeding';
  static const String guestHome = 'guestHome';
  static const String invitation = 'invitation';
  static const String programme = 'programme';
  static const String lieu = 'lieu';
  static const String rsvp = 'rsvp';
  static const String cadeaux = 'cadeaux';
  static const String galerie = 'galerie';
  static const String livreOr = 'livre-or';
  static const String infos = 'infos';

  static List<RouteBase> get routes => [
        GoRoute(
          path: home,
          name: 'thixWeedingHome',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const ThixWeedingHomePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
          ),
          routes: [
            // /thix-weeding/guest/:weddingId
            GoRoute(
              path: 'guest/:weddingId',
              name: guestHome,
              redirect: (context, state) {
                final id = state.pathParameters['weddingId'] ?? '';
                if (id.trim().length < 4) return home; // Guard prod
                return null;
              },
              pageBuilder: (context, state) {
                final weddingId = state.pathParameters['weddingId']!;
                return CustomTransitionPage(
                  key: state.pageKey,
                  child: GuestHomePage(weddingId: weddingId),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(animation), child: child),
                );
              },
              routes: [
                GoRoute(path: 'invitation', name: invitation, builder: (context, state) => InvitationPage(weddingId: state.pathParameters['weddingId']!)),
                GoRoute(path: 'programme', name: programme, builder: (context, state) => ProgrammePage(weddingId: state.pathParameters['weddingId']!)),
                GoRoute(path: 'lieu', name: lieu, builder: (context, state) => LieuAccesPage(weddingId: state.pathParameters['weddingId']!)),
                GoRoute(path: 'rsvp', name: rsvp, builder: (context, state) => RsvpPage(weddingId: state.pathParameters['weddingId']!)),
                GoRoute(path: 'cadeaux', name: cadeaux, builder: (context, state) => CadeauxPage(weddingId: state.pathParameters['weddingId']!)),
                GoRoute(path: 'galerie', name: galerie, builder: (context, state) => GaleriePage(weddingId: state.pathParameters['weddingId']!)),
                GoRoute(path: 'livre-or', name: livreOr, builder: (context, state) => LivreOrPage(weddingId: state.pathParameters['weddingId']!)),
                GoRoute(path: 'infos', name: infos, builder: (context, state) => InfosPage(weddingId: state.pathParameters['weddingId']!)),
              ],
            ),
          ],
        ),
      ];
}

// Comment l'intégrer dans ton router principal Sona1:
// Dans lib/presentation/app_router.dart
// GoRouter(
//   routes: [
//     ...ThixWeedingRoutes.routes,
//     // tes autres routes...
//   ],
// )
