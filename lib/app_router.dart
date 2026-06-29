import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/event_item.dart';
import 'package:thix_id/presentation/admin/admin_routes.dart';

// Pages
import 'presentation/home/home_page.dart';
import 'presentation/auth/login_page.dart';
import 'presentation/auth/personal_registration_page.dart';
import 'presentation/auth/enterprise_registration_page.dart';
import 'presentation/payment/payment_gateway_page.dart';
import 'presentation/payment/activation_receipt_page.dart';
import 'presentation/profile/public_profile_page.dart';
import 'presentation/dashboard/user_dashboard_page.dart';
import 'presentation/enterprise/enterprise_dashboard_page.dart';
import 'presentation/chat/thix_chat_page.dart';
import 'presentation/vault/document_vault_page.dart';
import 'presentation/settings/settings_page.dart';
import 'package:thix_id/presentation/network/network_pro_home.dart';
import 'presentation/jobs/jobs_page.dart';
import 'presentation/jobs/job_apply_page.dart';
import 'presentation/jobs/job_details_page.dart';
import 'presentation/jobs/job_dashboard_page.dart';
import 'presentation/recruiter/recruiter_portal_page.dart';
import 'presentation/opportunities/opportunities_page.dart';
import 'presentation/opportunities/opportunity_apply_page.dart';
import 'presentation/opportunities/opportunity_details_page.dart';
import 'presentation/events/events_page.dart';
import 'presentation/events/event_details_page.dart';
import 'presentation/events/event_register_page.dart';
import 'presentation/events/event_ticket_page.dart';
import 'presentation/events/user_event_dashboard_page.dart';
import 'presentation/education/education_page.dart';
import 'presentation/training/training_home_page.dart';
import 'presentation/training/training_details_page.dart';
import 'presentation/training/learning_dashboard_page.dart';
import 'presentation/training/lesson_player_page.dart';
import 'presentation/admin/admin_page.dart';
import 'presentation/thix_market/thix_market_page.dart';
import 'presentation/thix_reservation/thix_reservation_page.dart';
import 'presentation/thix_money/thix_money_page.dart';
import 'presentation/thix_media/thix_media_page.dart';
import 'package:thix_id/presentation/thix_info/thix_info_home_page.dart';
import 'presentation/admin/pages/admin_media_page.dart';

class NoTransitionPage<T> extends Page<T> {
  final Widget child;
  const NoTransitionPage({required this.child, super.key});

  @override
  Route<T> createRoute(BuildContext context) {
    // Navigator 2.0 / go_router friendly: avoid MaterialPageRoute here.
    return PageRouteBuilder<T>(
      settings: this,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
    );
  }
}

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String personalReg = '/personal-reg';
  static const String enterpriseReg = '/enterprise-reg';
  static const String userDashboard = '/user-dashboard';
  static const String enterpriseDashboard = '/enterprise-dashboard';
  static const String chat = '/chat';
  static const String vault = '/vault';
  static const String settings = '/settings';
  static const String network = '/network';
  static const String jobs = '/jobs';
  static const String opportunities = '/opportunities';
  static const String events = '/events';
  static const String education = '/education';
  static const String trainingHome = '/training';
  static const String admin = '/admin';
  static const String thixMarket = '/market';
  static const String reservation = '/reservation';
  static const String thixMoney = '/thix-money';
  static const String thixMedia = '/thix-media';
  static const String thixInfo = '/info';
}

class AppRouter {
  static GoRouter create(
    AuthController auth, {
    Listenable? extraRefreshListenable,
  }) {
    final refresh = extraRefreshListenable == null
        ? auth
        : Listenable.merge([auth, extraRefreshListenable]);
    return GoRouter(
      initialLocation: AppRoutes.home,
      // Keep behavior consistent with lib/nav.dart: always start from the homepage
      // instead of restoring the last browser URL (e.g. /login) on web reload.
      overridePlatformDefaultLocation: true,
      refreshListenable: refresh,
      redirect: (context, state) {
        final isLoggedIn = auth.isAuthenticated;
        final location = state.matchedLocation;

        final isAuthPage = location == AppRoutes.login ||
            location == AppRoutes.personalReg ||
            location == AppRoutes.enterpriseReg;

        // Allow public access to the homepage.
        if (!isLoggedIn && !isAuthPage && location != AppRoutes.home) return AppRoutes.login;
        if (isLoggedIn && isAuthPage) {
          return AppRoutes.userDashboard;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (context, state) => const NoTransitionPage(child: HomePagePremium()),
        ),
        GoRoute(
          path: AppRoutes.login,
          pageBuilder: (context, state) => const NoTransitionPage(child: LoginPage()),
        ),
        GoRoute(
          path: AppRoutes.personalReg,
          pageBuilder: (context, state) => const NoTransitionPage(child: PersonalRegistrationPage()),
        ),
        GoRoute(
          path: AppRoutes.enterpriseReg,
          pageBuilder: (context, state) => const NoTransitionPage(child: EnterpriseRegistrationPage()),
        ),
        GoRoute(
          path: AppRoutes.userDashboard,
          pageBuilder: (context, state) => const NoTransitionPage(child: UserDashboardPage()),
        ),
        GoRoute(
          path: AppRoutes.enterpriseDashboard,
          pageBuilder: (context, state) => const NoTransitionPage(child: EnterpriseDashboardPage()),
        ),
        GoRoute(
          path: AppRoutes.chat,
          pageBuilder: (context, state) => const NoTransitionPage(child: ThixChatPage()),
        ),
        GoRoute(
          path: AppRoutes.vault,
          pageBuilder: (context, state) => const NoTransitionPage(child: DocumentVaultPage()),
        ),
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (context, state) => const NoTransitionPage(child: SettingsPage()),
        ),
        GoRoute(
          path: AppRoutes.network,
          pageBuilder: (context, state) => const NoTransitionPage(child: NetworkProHome()),
        ),
        GoRoute(
          path: AppRoutes.jobs,
          pageBuilder: (context, state) => const NoTransitionPage(child: JobsPage()),
        ),
        GoRoute(
          path: AppRoutes.opportunities,
          pageBuilder: (context, state) => const NoTransitionPage(child: OpportunitiesPage()),
        ),
        GoRoute(
          path: AppRoutes.events,
          pageBuilder: (context, state) => const NoTransitionPage(child: EventsPage()),
        ),

        // ==================== EVENTS ROUTES ====================
        GoRoute(
          path: '/events/:eventId',
          pageBuilder: (context, state) {
            final eventId = state.pathParameters['eventId'] ?? '';
            return NoTransitionPage(child: EventDetailsPage(eventId: eventId));
          },
        ),
        GoRoute(
          path: '/events/:eventId/register',
          pageBuilder: (context, state) {
            final eventId = state.pathParameters['eventId'] ?? '';
            // Note: Tu peux passer l'event complet via extra si besoin
            return NoTransitionPage(child: EventRegisterPage(event: EventItem.placeholder(id: eventId))); // À adapter si nécessaire
          },
        ),
        GoRoute(
          path: '/events/:eventId/ticket/:registrationId',
          pageBuilder: (context, state) {
            final eventId = state.pathParameters['eventId'] ?? '';
            final registrationId = state.pathParameters['registrationId'] ?? '';
            return NoTransitionPage(
              child: EventTicketPage(eventId: eventId, registrationId: registrationId),
            );
          },
        ),
        GoRoute(
          path: '/events/me',
          pageBuilder: (context, state) => const NoTransitionPage(child: UserEventDashboardPage()),
        ),

        // Autres routes
        GoRoute(
          path: AppRoutes.education,
          pageBuilder: (context, state) => const NoTransitionPage(child: EducationPage()),
        ),
        GoRoute(
          path: AppRoutes.trainingHome,
          pageBuilder: (context, state) => const NoTransitionPage(child: TrainingHomePage()),
        ),
        GoRoute(
          path: AppRoutes.thixMarket,
          pageBuilder: (context, state) => const NoTransitionPage(child: ThixMarketPage()),
        ),
        GoRoute(
          path: AppRoutes.reservation,
          pageBuilder: (context, state) => const NoTransitionPage(child: ThixReservationPage()),
        ),
        GoRoute(
          path: AppRoutes.thixMoney,
          pageBuilder: (context, state) => const NoTransitionPage(child: ThixMoneyPage()),
        ),
        GoRoute(
          path: AppRoutes.thixMedia,
          pageBuilder: (context, state) => const NoTransitionPage(child: ThixMediaPage()),
        ),
        GoRoute(
          path: AppRoutes.thixInfo,
          pageBuilder: (context, state) => const NoTransitionPage(child: ThixInfoHomePage()),
        ),
        GoRoute(
          path: AppRoutes.admin,
          pageBuilder: (context, state) => const NoTransitionPage(child: AdminPage(module: AdminModule.overview)),
        ),
      ],
    );
  }
}
