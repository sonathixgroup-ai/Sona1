// Temporary fix: keep Dreamflow preview on a reliable landing page.
// This prevents nested redirects or stale web locations from landing on a blank screen.
// The full homepage remains available at AppRoutes.home.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';

import 'presentation/home/home_page.dart';
import 'presentation/auth/login_page.dart';
import 'presentation/auth/personal_registration_page.dart';
import 'presentation/auth/enterprise_registration_page.dart';
import 'presentation/payment/payment_gateway_page.dart';
import 'presentation/payment/activation_receipt_page.dart';
import 'presentation/profile/public_profile_page.dart';
import 'presentation/dashboard/user_dashboard_page.dart';
import 'presentation/enterprise/enterprise_dashboard_page.dart';
import 'package:thix_id/presentation/enterprise/enterprise_portal_page.dart';
import 'package:thix_id/presentation/enterprise/enterprise_dashboard_shell_page.dart';
import 'presentation/chat/thix_chat_page.dart';
import 'package:thix_id/presentation/chat/screens/chat_conversation_screen.dart';
import 'presentation/vault/document_vault_page.dart';
import 'presentation/settings/settings_page.dart';
import 'package:thix_id/presentation/network/network_pro_home.dart';
import 'package:thix_id/presentation/network/search_network_page.dart';
import 'package:thix_id/presentation/network/notifications/notifications_page.dart';
import 'package:thix_id/presentation/network/messages/conversations_list.dart';
import 'package:thix_id/presentation/network/messages/chat_screen.dart';
import 'package:thix_id/presentation/network/connections_list_page.dart';
import 'package:thix_id/presentation/network/community_detail_page.dart';
import 'package:thix_id/presentation/network/post_detail_page.dart';
import 'package:thix_id/presentation/network/profile_page.dart';
import 'package:thix_id/presentation/network/profile_settings_page.dart';
import 'package:thix_id/presentation/network/blocked_users_page.dart';
import 'presentation/jobs/jobs_page.dart';
import 'package:thix_id/presentation/jobs/job_apply_page.dart';
import 'package:thix_id/presentation/jobs/job_details_page.dart';
import 'package:thix_id/presentation/jobs/job_dashboard_page.dart';
import 'package:thix_id/presentation/recruiter/recruiter_portal_page.dart';
import 'package:thix_id/presentation/opportunities/opportunities_page.dart';
import 'package:thix_id/presentation/opportunities/opportunity_apply_page.dart';
import 'package:thix_id/presentation/opportunities/opportunity_details_page.dart';
import 'presentation/events/events_page.dart';
import 'package:thix_id/presentation/events/event_details_page.dart';
import 'package:thix_id/presentation/events/event_register_page.dart';
import 'package:thix_id/presentation/events/event_ticket_page.dart';
import 'package:thix_id/presentation/events/user_event_dashboard_page.dart';
import 'presentation/education/education_page.dart';
import 'package:thix_id/presentation/training/training_home_page.dart';
import 'package:thix_id/presentation/training/training_details_page.dart';
import 'package:thix_id/presentation/training/learning_dashboard_page.dart';
import 'package:thix_id/presentation/training/lesson_player_page.dart';
import 'package:thix_id/presentation/admin/admin_page.dart';
import 'package:thix_id/presentation/admin/admin_routes.dart';
import 'package:thix_id/presentation/thix_market/thix_market_page.dart';
// Import du module Santé (unique point d'entrée)
import 'package:thix_id/presentation/thix_sante/thix_sante_page.dart'; // contient ThixSantePage, ThixSanteRolePage et importe thix_role.dart
import 'package:thix_id/presentation/thix_reservation/thix_reservation_page.dart';
import 'package:thix_id/presentation/thix_money/thix_money_page.dart';
import 'package:thix_id/presentation/thix_media/thix_media_page.dart';
import 'package:thix_id/presentation/admin/pages/admin_media_page.dart';
import 'package:thix_id/presentation/splash/thix_id_start_page.dart';
import 'package:thix_id/presentation/thix_info/thix_info_article_page.dart';
import 'package:thix_id/presentation/thix_info/thix_info_home_page.dart';

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

class AppRoutes {
  static const String start = '/start';
  static const String home = '/';
  static const String login = '/login';
  static const String personalReg = '/personal-reg';
  static const String enterpriseReg = '/enterprise-reg';
  static const String enterprise = '/enterprise';
  static const String payment = '/payment';
  static const String activationReceipt = '/activation-receipt';
  static const String publicProfile = '/public-profile';
  static const String userDashboard = '/user-dashboard';
  static const String enterpriseDashboard = '/enterprise-dashboard';
  static const String enterprisePortalBasePath = '/company';
  static const String chat = '/chat';
  static const String vault = '/vault';
  static const String settings = '/settings';
  static const String network = '/network';
  static const String networkSearch = '/network/search';
  static const String networkNotifications = '/network/notifications';
  static const String networkMessages = '/network/messages';
  static const String networkConnections = '/network/connections';
  static const String networkProfileSettings = '/network/profile-settings';
  static const String networkBlockedUsers = '/network/blocked';
  static const String networkChatBasePath = '/network/chat';
  static const String networkPostBasePath = '/network/post';
  static const String networkCommunityBasePath = '/network/community';
  static const String networkProfileBasePath = '/network/profile';
  static const String profile = '/profile';
  static const String jobs = '/jobs';
  static const String jobDashboard = '/jobs/dashboard';
  static const String recruiter = '/recruiter';
  static const String opportunities = '/opportunities';
  static const String events = '/events';
  static const String education = '/education';
  static const String trainingHome = '/training';
  static const String trainingDetailsBasePath = '/training-details';
  static const String learningDashboard = '/learn';
  static const String lessonPlayer = '/learn/player';
  static const String admin = '/admin';
  static const String thixMarket = '/market';
  // Routes THIX Santé (réintégrées)
  static const String thixSante = '/sante';
  static const String thixSantePatient = '/sante/patient';
  static const String thixSanteDoctor = '/sante/medecin';
  static const String thixSantePharmacy = '/sante/pharmacie';
  static const String reservation = '/reservation';
  static const String thixMoney = '/thix-money';
  static const String thixMedia = '/thix-media';
  static const String adminMedia = '/admin/media';
  static const String thixInfo = '/info';
  static const String thixInfoArticleBasePath = '/info/a';
  static String enterprisePortalBase(String slug) => '$enterprisePortalBasePath/$slug';
  static String enterprisePortalDashboard(String slug, String section) => '/company/$slug/dashboard/$section';
  static String thixInfoArticle(String id) => '$thixInfoArticleBasePath/$id';
  static String networkChat(String userId) => '$networkChatBasePath/$userId';
  static String networkPost(String postId) => '$networkPostBasePath/$postId';
  static String networkCommunity(String communityId) => '$networkCommunityBasePath/$communityId';
  static String networkProfile(String userId) => '$networkProfileBasePath/$userId';
}

class AppRouter {
  static GoRouter create(AuthController auth, {Listenable? extraRefreshListenable}) {
    final refresh = extraRefreshListenable ?? auth;
    return GoRouter(
      initialLocation: AppRoutes.home,
      overridePlatformDefaultLocation: true,
      refreshListenable: refresh,
      redirect: (context, state) {
        final location = state.matchedLocation;
        final isLoggedIn = auth.isAuthenticated;
        final isAuthPage = location == AppRoutes.login || location == AppRoutes.personalReg || location == AppRoutes.enterpriseReg;
        final isAdmin = location == AppRoutes.admin || location.startsWith('${AppRoutes.admin}/');
        final isEnterprisePortal = location.startsWith('${AppRoutes.enterprisePortalBasePath}/') || location == AppRoutes.enterprisePortalBasePath;
        final isPublic = location == AppRoutes.start || location == AppRoutes.home || location == AppRoutes.publicProfile || location == AppRoutes.jobs || location == AppRoutes.opportunities || location == AppRoutes.events || location == AppRoutes.education || location == AppRoutes.trainingHome || location.startsWith('${AppRoutes.trainingDetailsBasePath}/');
        final isProtected = !isPublic && !isAuthPage;
        if (!isLoggedIn && isProtected) return AppRoutes.login;
        if (isAdmin && !isLoggedIn) return AppRoutes.login;
        if (isLoggedIn) {
          final t = auth.currentUser?.accountType;
          if (location == AppRoutes.userDashboard && t == AccountType.enterprise) return AppRoutes.enterpriseDashboard;
          if (location == AppRoutes.enterpriseDashboard && t == AccountType.personal) return AppRoutes.userDashboard;
        }
        if (isLoggedIn && isAuthPage) {
          final t = auth.currentUser?.accountType;
          return t == AccountType.enterprise ? AppRoutes.enterpriseDashboard : AppRoutes.userDashboard;
        }
        if (isEnterprisePortal) return null;
        return null;
      },
      routes: [
        GoRoute(path: AppRoutes.start, name: 'start', pageBuilder: (context, state) => const NoTransitionPage(child: ThixIdStartPage())),
        GoRoute(path: AppRoutes.home, name: 'home', pageBuilder: (context, state) => const NoTransitionPage(child: HomePagePremium())),
        GoRoute(path: AppRoutes.login, name: 'login', pageBuilder: (context, state) => const NoTransitionPage(child: LoginPage())),
        GoRoute(path: AppRoutes.personalReg, name: 'personalReg', pageBuilder: (context, state) {
          final stepStr = state.uri.queryParameters['step'];
          final step = int.tryParse(stepStr ?? '') ?? 1;
          return NoTransitionPage(child: PersonalRegistrationPage(initialStep: step));
        }),
        GoRoute(path: AppRoutes.enterpriseReg, name: 'enterpriseReg', pageBuilder: (context, state) => const NoTransitionPage(child: EnterpriseRegistrationPage())),
        GoRoute(path: AppRoutes.payment, name: 'payment', pageBuilder: (context, state) {
          final returnTo = state.uri.queryParameters['returnTo'];
          return NoTransitionPage(child: PaymentGatewayPage(returnTo: returnTo));
        }),
        GoRoute(path: AppRoutes.activationReceipt, name: 'activationReceipt', pageBuilder: (context, state) {
          final qp = state.uri.queryParameters;
          final paidAt = DateTime.tryParse((qp['paidAt'] ?? '').trim());
          return NoTransitionPage(child: ActivationReceiptPage(txRef: qp['txRef'], method: qp['method'], amount: qp['amount'], currency: qp['currency'], paidAt: paidAt));
        }),
        GoRoute(path: AppRoutes.publicProfile, name: 'publicProfile', pageBuilder: (context, state) => NoTransitionPage(child: PublicProfilePage(initialThixId: state.uri.queryParameters['thixId']))),
        GoRoute(path: AppRoutes.userDashboard, name: 'userDashboard', pageBuilder: (context, state) => const NoTransitionPage(child: UserDashboardPage())),
        GoRoute(path: AppRoutes.enterpriseDashboard, name: 'enterpriseDashboard', pageBuilder: (context, state) => const NoTransitionPage(child: EnterpriseDashboardPage())),
        GoRoute(path: AppRoutes.enterprise, name: 'enterpriseEntry', redirect: (context, state) {
          final isLoggedIn = auth.isAuthenticated;
          if (!isLoggedIn) return AppRoutes.login;
          final t = auth.currentUser?.accountType;
          if (t == AccountType.enterprise) return AppRoutes.enterpriseDashboard;
          return AppRoutes.enterpriseReg;
        }),
        GoRoute(path: '/entreprise/:slug', name: 'enterprisePortalAliasFr', redirect: (context, state) {
          final slug = (state.pathParameters['slug'] ?? '').trim();
          return '${AppRoutes.enterprisePortalBase(slug)}/dashboard/overview';
        }),
        GoRoute(path: '${AppRoutes.enterprisePortalBasePath}/:slug', name: 'enterprisePortal', pageBuilder: (context, state) {
          final slug = (state.pathParameters['slug'] ?? '').trim();
          return NoTransitionPage(child: EnterprisePortalPage(companySlug: slug));
        }, routes: [GoRoute(path: 'dashboard/:section', name: 'enterprisePortalDashboard', pageBuilder: (context, state) {
          final slug = (state.pathParameters['slug'] ?? '').trim();
          final section = (state.pathParameters['section'] ?? 'overview').trim();
          return NoTransitionPage(child: EnterpriseDashboardShellPage(companySlug: slug, section: section));
        }), GoRoute(path: 'dashboard', name: 'enterprisePortalDashboardRoot', redirect: (context, state) {
          final slug = (state.pathParameters['slug'] ?? '').trim();
          return '${AppRoutes.enterprisePortalBase(slug)}/dashboard/overview';
        })]),
        GoRoute(path: AppRoutes.chat, name: 'chat', pageBuilder: (context, state) => const NoTransitionPage(child: ThixChatPage()), routes: [GoRoute(path: ':chatId', name: 'chatConversation', pageBuilder: (context, state) {
          final chatId = Uri.decodeComponent(state.pathParameters['chatId'] ?? '');
          final extra = (state.extra is Map) ? (state.extra as Map).cast<String, dynamic>() : const <String, dynamic>{};
          final title = (extra['title'] as String?) ?? 'Discussion';
          final type = (extra['type'] as String?) ?? 'direct';
          return NoTransitionPage(child: ChatConversationScreen(chatId: chatId, title: title, type: type));
        })]),
        GoRoute(path: AppRoutes.vault, name: 'vault', pageBuilder: (context, state) => const NoTransitionPage(child: DocumentVaultPage())),
        GoRoute(path: AppRoutes.settings, name: 'settings', pageBuilder: (context, state) => const NoTransitionPage(child: SettingsPage())),
        GoRoute(path: AppRoutes.network, name: 'network', pageBuilder: (context, state) => const NoTransitionPage(child: NetworkProHome())),
        GoRoute(path: AppRoutes.networkSearch, name: 'networkSearch', pageBuilder: (context, state) => const NoTransitionPage(child: SearchNetworkPage())),
        GoRoute(path: AppRoutes.networkNotifications, name: 'networkNotifications', pageBuilder: (context, state) => const NoTransitionPage(child: NotificationsPage())),
        GoRoute(path: AppRoutes.networkMessages, name: 'networkMessages', pageBuilder: (context, state) => const NoTransitionPage(child: ConversationsList())),
        GoRoute(path: '${AppRoutes.networkChatBasePath}/:userId', name: 'networkChat', pageBuilder: (context, state) {
          final userId = (state.pathParameters['userId'] ?? '').trim();
          final extra = state.extra;
          String userName = 'Discussion';
          String? userAvatar;
          if (extra is String && extra.trim().isNotEmpty) {
            userName = extra.trim();
          } else if (extra is Map) {
            final m = extra.cast<String, dynamic>();
            final n = (m['userName'] as String?)?.trim();
            if (n != null && n.isNotEmpty) userName = n;
            final a = (m['userAvatar'] as String?)?.trim();
            if (a != null && a.isNotEmpty) userAvatar = a;
          }
          return NoTransitionPage(child: ChatScreen(userId: userId, userName: userName, userAvatar: userAvatar));
        }),
        GoRoute(path: AppRoutes.networkConnections, name: 'networkConnections', pageBuilder: (context, state) => const NoTransitionPage(child: ConnectionsListPage())),
        GoRoute(path: AppRoutes.networkProfileSettings, name: 'networkProfileSettings', pageBuilder: (context, state) => const NoTransitionPage(child: ProfileSettingsPage())),
        GoRoute(path: AppRoutes.networkBlockedUsers, name: 'networkBlockedUsers', pageBuilder: (context, state) => const NoTransitionPage(child: BlockedUsersPage())),
        GoRoute(path: '${AppRoutes.networkPostBasePath}/:postId', name: 'networkPostDetail', pageBuilder: (context, state) {
          final postId = (state.pathParameters['postId'] ?? '').trim();
          return NoTransitionPage(child: PostDetailPage(postId: postId));
        }),
        GoRoute(path: '${AppRoutes.networkCommunityBasePath}/:communityId', name: 'networkCommunityDetail', pageBuilder: (context, state) {
          final communityId = (state.pathParameters['communityId'] ?? '').trim();
          return NoTransitionPage(child: CommunityDetailPage(communityId: communityId));
        }),
        GoRoute(path: '${AppRoutes.networkProfileBasePath}/:userId', name: 'networkProfile', pageBuilder: (context, state) {
          final userId = (state.pathParameters['userId'] ?? '').trim();
          return NoTransitionPage(child: ProfilePage(userId: userId));
        }),
        GoRoute(path: AppRoutes.profile, name: 'profile', pageBuilder: (context, state) => const NoTransitionPage(child: ProfilePage())),
        GoRoute(path: AppRoutes.thixMarket, name: 'thixMarket', pageBuilder: (context, state) => const NoTransitionPage(child: ThixMarketPage())),
        // Routes THIX Santé – sans const pour éviter l'erreur "Invalid constant value"
        GoRoute(
          path: AppRoutes.thixSante,
          name: 'thixSante',
          pageBuilder: (context, state) => const NoTransitionPage(child: ThixSantePage()),
        ),
        GoRoute(
          path: AppRoutes.thixSantePatient,
          name: 'thixSantePatient',
          pageBuilder: (context, state) => NoTransitionPage(
            child: ThixSanteRolePage(role: ThixRole.patient),
          ),
        ),
        GoRoute(
          path: AppRoutes.thixSanteDoctor,
          name: 'thixSanteDoctor',
          pageBuilder: (context, state) => NoTransitionPage(
            child: ThixSanteRolePage(role: ThixRole.doctor),
          ),
        ),
        GoRoute(
          path: AppRoutes.thixSantePharmacy,
          name: 'thixSantePharmacy',
          pageBuilder: (context, state) => NoTransitionPage(
            child: ThixSanteRolePage(role: ThixRole.pharmacy),
          ),
        ),
        GoRoute(path: AppRoutes.thixMoney, name: 'thixMoney', pageBuilder: (context, state) => const NoTransitionPage(child: ThixMoneyPage())),
        GoRoute(path: AppRoutes.thixMedia, name: 'thixMedia', pageBuilder: (context, state) => const NoTransitionPage(child: ThixMediaPage())),
        GoRoute(path: AppRoutes.thixInfo, name: 'thixInfo', pageBuilder: (context, state) => const NoTransitionPage(child: ThixInfoHomePage())),
        GoRoute(path: '${AppRoutes.thixInfoArticleBasePath}/:id', name: 'thixInfoArticle', pageBuilder: (context, state) {
          final id = (state.pathParameters['id'] ?? '').trim();
          return NoTransitionPage(child: ThixInfoArticlePage(id: id));
        }),
        GoRoute(path: AppRoutes.reservation, name: 'reservation', pageBuilder: (context, state) => const NoTransitionPage(child: ThixReservationPage())),
        GoRoute(path: AppRoutes.jobs, name: 'jobs', pageBuilder: (context, state) => const NoTransitionPage(child: JobsPage())),
        GoRoute(path: AppRoutes.jobDashboard, name: 'jobDashboard', pageBuilder: (context, state) => const NoTransitionPage(child: JobDashboardPage())),
        GoRoute(path: AppRoutes.recruiter, name: 'recruiter', pageBuilder: (context, state) => const NoTransitionPage(child: RecruiterPortalPage())),
        GoRoute(path: AppRoutes.opportunities, name: 'opportunities', pageBuilder: (context, state) => const NoTransitionPage(child: OpportunitiesPage())),
        GoRoute(path: '/opportunities/:opportunityId', name: 'opportunityDetails', pageBuilder: (context, state) {
          final opportunityId = state.pathParameters['opportunityId'] ?? '';
          final applied = (state.uri.queryParameters['applied'] ?? '').trim() == '1';
          return NoTransitionPage(child: OpportunityDetailsPage(opportunityId: opportunityId, applied: applied));
        }),
        GoRoute(path: '/opportunities/:opportunityId/apply', name: 'opportunityApply', pageBuilder: (context, state) {
          final opportunityId = state.pathParameters['opportunityId'] ?? '';
          return NoTransitionPage(child: OpportunityApplyPage(opportunityId: opportunityId));
        }),
        GoRoute(path: '/jobs/:jobId', name: 'jobDetails', pageBuilder: (context, state) {
          final jobId = state.pathParameters['jobId'] ?? '';
          final applied = (state.uri.queryParameters['applied'] ?? '').trim() == '1';
          return NoTransitionPage(child: JobDetailsPage(jobId: jobId, applied: applied));
        }),
        GoRoute(path: '/jobs/:jobId/apply', name: 'jobApply', pageBuilder: (context, state) {
          final jobId = state.pathParameters['jobId'] ?? '';
          return NoTransitionPage(child: JobApplyPage(jobId: jobId));
        }),
        GoRoute(path: AppRoutes.events, name: 'events', pageBuilder: (context, state) => const NoTransitionPage(child: EventsPage())),
        GoRoute(path: '/events/:eventId', name: 'eventDetails', pageBuilder: (context, state) {
          final eventId = state.pathParameters['eventId'] ?? '';
          return NoTransitionPage(child: EventDetailsPage(eventId: eventId));
        }),
        GoRoute(path: '/events/:eventId/register', name: 'eventRegister', pageBuilder: (context, state) {
          final eventId = state.pathParameters['eventId'] ?? '';
          return NoTransitionPage(child: EventDetailsPage(eventId: eventId));
        }),
        GoRoute(path: '/events/:eventId/ticket/:registrationId', name: 'eventTicket', pageBuilder: (context, state) {
          final eventId = state.pathParameters['eventId'] ?? '';
          final registrationId = state.pathParameters['registrationId'] ?? '';
          return NoTransitionPage(child: EventTicketPage(eventId: eventId, registrationId: registrationId));
        }),
        GoRoute(path: '/events/me', name: 'userEventsDashboard', pageBuilder: (context, state) => const NoTransitionPage(child: UserEventDashboardPage())),
        GoRoute(path: AppRoutes.education, name: 'education', pageBuilder: (context, state) => const NoTransitionPage(child: EducationPage())),
        GoRoute(path: AppRoutes.trainingHome, name: 'trainingHome', pageBuilder: (context, state) => const NoTransitionPage(child: TrainingHomePage())),
        GoRoute(path: '${AppRoutes.trainingDetailsBasePath}/:trainingId', name: 'trainingDetails', pageBuilder: (context, state) {
          final id = state.pathParameters['trainingId'] ?? '';
          return NoTransitionPage(child: TrainingDetailsPage(trainingId: id));
        }),
        GoRoute(path: AppRoutes.learningDashboard, name: 'learningDashboard', pageBuilder: (context, state) => const NoTransitionPage(child: LearningDashboardPage())),
        GoRoute(path: '${AppRoutes.lessonPlayer}/:enrollmentId', name: 'lessonPlayer', pageBuilder: (context, state) {
          final id = state.pathParameters['enrollmentId'] ?? '';
          return NoTransitionPage(child: LessonPlayerPage(enrollmentId: id));
        }),
        GoRoute(path: '${AppRoutes.admin}/:module', name: 'admin', pageBuilder: (context, state) {
          final module = AdminModuleX.fromSlug(state.pathParameters['module']);
          return NoTransitionPage(child: AdminPage(module: module));
        }),
        GoRoute(path: AppRoutes.admin, name: 'adminRoot', redirect: (_, __) => '${AppRoutes.admin}/${AdminModule.overview.slug}'),
        GoRoute(path: AppRoutes.adminMedia, name: 'adminMedia', pageBuilder: (context, state) => const NoTransitionPage(child: AdminMediaPage())),
      ],
    );
  }
}

extension GoRouterBackHelpers on BuildContext {
  void popOrGo(String fallbackLocation) {
    final router = GoRouter.of(this);
    if (router.canPop()) {
      pop();
      return;
    }
    go(fallbackLocation);
  }
}
