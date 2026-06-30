// Temporary fix: keep Dreamflow preview on a reliable landing page.
// This prevents nested redirects or stale web locations from landing on a blank screen.
// The full homepage remains available at AppRoutes.home.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';
export 'app_router.dart' show AppRoutes;
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
import 'presentation/education/education_page.dart';
import 'package:thix_id/presentation/training/training_home_page.dart';
import 'package:thix_id/presentation/training/training_details_page.dart';
import 'package:thix_id/presentation/training/learning_dashboard_page.dart';
import 'package:thix_id/presentation/training/lesson_player_page.dart';
import 'package:thix_id/presentation/admin/admin_page.dart';
import 'package:thix_id/presentation/admin/admin_routes.dart';
import 'package:thix_id/presentation/thix_market/thix_market_page.dart';
// Import du module Santé (unique point d'entrée)
import 'package:thix_id/presentation/thix_sante/thix_sante_page.dart';
import 'package:thix_id/presentation/thix_sante/thix_role.dart';
import 'package:thix_id/presentation/thix_sante/thix_sante_role_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/patient_dashboard_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/patient_health_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/patient_care_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/patient_life_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/patient_connect_page.dart';
// Patient detail pages
import 'package:thix_id/presentation/thix_sante/patient/details/patient_appointment_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_appointments_list_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_consultation_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_prescription_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_exam_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_scan_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_symptom_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_vital_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_medication_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_vaccine_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_pregnancy_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_family_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_sharing_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_ai_chat_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_alert_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_map_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_wellness_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_consent_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_notifications_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_profile_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_article_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_chat_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_chat_new_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_exams_list_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_prescriptions_list_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_teleexpertise_detail_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_teleexpertise_request_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_record_add_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_vital_chart_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_medication_reminders_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_medications_list_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_vaccination_calendar_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_pharmacy_detail_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/jitsi_teleconsultation_page.dart';

// Doctor pages
import 'package:thix_id/presentation/thix_sante/doctor/doctor_dashboard_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/doctor_care_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/doctor_consult_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/doctor_connect_page.dart';
// Doctor detail pages
import 'package:thix_id/presentation/thix_sante/doctor/details/doctor_patients_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/details/doctor_patient_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/details/doctor_prescription_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/details/doctor_teleconsult_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/details/doctor_teleexpertise_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/details/doctor_agenda_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/details/doctor_note_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/details/doctor_statistics_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/details/doctor_terrain_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/details/doctor_chat_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/details/doctor_alert_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/details/doctor_patient_add_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/details/doctor_slot_management_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/details/doctor_scan_bracelet_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/details/doctor_voice_dictation_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/details/doctor_offline_patients_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/details/doctor_photo_capture_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/details/doctor_new_message_page.dart';

// Pharmacy pages
import 'package:thix_id/presentation/thix_sante/pharmacy/pharmacy_dashboard_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/pharmacy_orders_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/pharmacy_inventory_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/pharmacy_connect_page.dart';
// Pharmacy detail pages
import 'package:thix_id/presentation/thix_sante/pharmacy/details/pharmacy_order_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/details/pharmacy_prescription_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/details/pharmacy_dispensing_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/details/pharmacy_delivery_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/details/pharmacy_inventory_item_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/details/pharmacy_stock_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/details/pharmacy_report_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/details/pharmacy_chat_page.dart';

import 'package:thix_id/presentation/thix_reservation/thix_reservation_page.dart';
import 'package:thix_id/presentation/thix_money/thix_money_page.dart';
import 'package:thix_id/presentation/thix_media/thix_media_page.dart';
import 'package:thix_id/presentation/thix_media/video_player_page.dart';
import 'package:thix_id/presentation/admin/pages/admin_media_page.dart';
import 'package:thix_id/presentation/splash/thix_id_start_page.dart';
import 'package:thix_id/presentation/thix_info/thix_info_article_page.dart';
import 'package:thix_id/presentation/thix_info/thix_info_home_page.dart';

// ==================== THIX ÉVÉNEMENT (IMPORTS) ====================
import 'package:thix_id/presentation/thix_event/thix_event_home.dart';
import 'package:thix_id/presentation/thix_event/event_detail_page.dart';
import 'package:thix_id/presentation/thix_event/event_search_page.dart';
import 'package:thix_id/presentation/thix_event/event_category_page.dart';
import 'package:thix_id/presentation/thix_event/event_reservation_page.dart';
import 'package:thix_id/presentation/thix_event/my_tickets_page.dart';
import 'package:thix_id/presentation/thix_event/favorite_events_page.dart';
import 'package:thix_id/presentation/thix_event/seat_selection_page.dart';
import 'package:thix_id/presentation/thix_event/waiting_queue_page.dart';

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
  static const String education = '/education';
  static const String trainingHome = '/training';
  static const String trainingDetailsBasePath = '/training-details';
  static const String learningDashboard = '/learn';
  static const String lessonPlayer = '/learn/player';
  static const String admin = '/admin';
  static const String thixMarket = '/market';
  // Routes THIX Santé
  static const String thixSante = '/sante';
  static const String thixSantePatient = '/sante/patient';
  static const String thixSanteDoctor = '/sante/medecin';
  static const String thixSantePharmacy = '/sante/pharmacie';
  static const String reservation = '/reservation';
  static const String thixMoney = '/thix-money';
  static const String thixMedia = '/thix-media';
  static const String thixMediaVideo = '/thix-media/video';
  static const String adminMedia = '/admin/media';
  static const String thixInfo = '/info';
  static const String thixInfoArticleBasePath = '/info/a';

  // ==================== THIX ÉVÉNEMENT (ROUTES) ====================
  static const String thixEvent = '/thix-event';
  static const String thixEventDetail = '/thix-event/event/:eventId';
  static const String thixEventSearch = '/thix-event/search';
  static const String thixEventCategory = '/thix-event/category/:category';
  static const String thixEventReservation = '/thix-event/reservation/:eventId';
  static const String thixEventMyTickets = '/thix-event/my-tickets';
  static const String thixEventFavorites = '/thix-event/favorites';
  static const String thixEventSeatSelection = '/thix-event/seat-selection/:eventId';
  static const String thixEventWaitingQueue = '/thix-event/waiting-queue/:eventId';

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
        final isAuthPage = location == AppRoutes.login ||
            location == AppRoutes.personalReg ||
            location == AppRoutes.enterpriseReg;
        final isAdmin = location == AppRoutes.admin ||
            location.startsWith('${AppRoutes.admin}/');
        final isEnterprisePortal = location.startsWith('${AppRoutes.enterprisePortalBasePath}/') ||
            location == AppRoutes.enterprisePortalBasePath;
        final isPublic = location == AppRoutes.start ||
            location == AppRoutes.home ||
            location == AppRoutes.publicProfile ||
            location == AppRoutes.jobs ||
            location == AppRoutes.opportunities ||
            location == AppRoutes.education ||
            location == AppRoutes.trainingHome ||
            location.startsWith('${AppRoutes.trainingDetailsBasePath}/');
        final isProtected = !isPublic && !isAuthPage;
        if (!isLoggedIn && isProtected) return AppRoutes.login;
        if (isAdmin && !isLoggedIn) return AppRoutes.login;
        if (isLoggedIn) {
          final t = auth.currentUser?.accountType;
          if (location == AppRoutes.userDashboard && t == AccountType.enterprise)
            return AppRoutes.enterpriseDashboard;
          if (location == AppRoutes.enterpriseDashboard && t == AccountType.personal)
            return AppRoutes.userDashboard;
        }
        if (isLoggedIn && isAuthPage) {
          final t = auth.currentUser?.accountType;
          return t == AccountType.enterprise
              ? AppRoutes.enterpriseDashboard
              : AppRoutes.userDashboard;
        }
        if (isEnterprisePortal) return null;
        return null;
      },
      routes: [
        // ---- Routes générales ----
        GoRoute(
          path: AppRoutes.start,
          name: 'start',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ThixIdStartPage()),
        ),
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomePagePremium()),
        ),
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: LoginPage()),
        ),
        GoRoute(
          path: AppRoutes.personalReg,
          name: 'personalReg',
          pageBuilder: (context, state) {
            final stepStr = state.uri.queryParameters['step'];
            final step = int.tryParse(stepStr ?? '') ?? 1;
            return NoTransitionPage(
                child: PersonalRegistrationPage(initialStep: step));
          },
        ),
        GoRoute(
          path: AppRoutes.enterpriseReg,
          name: 'enterpriseReg',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: EnterpriseRegistrationPage()),
        ),
        GoRoute(
          path: AppRoutes.payment,
          name: 'payment',
          pageBuilder: (context, state) {
            final returnTo = state.uri.queryParameters['returnTo'];
            return NoTransitionPage(
                child: PaymentGatewayPage(returnTo: returnTo));
          },
        ),
        GoRoute(
          path: AppRoutes.activationReceipt,
          name: 'activationReceipt',
          pageBuilder: (context, state) {
            final qp = state.uri.queryParameters;
            final paidAt = DateTime.tryParse((qp['paidAt'] ?? '').trim());
            return NoTransitionPage(
                child: ActivationReceiptPage(
              txRef: qp['txRef'],
              method: qp['method'],
              amount: qp['amount'],
              currency: qp['currency'],
              paidAt: paidAt,
            ));
          },
        ),
        GoRoute(
          path: AppRoutes.publicProfile,
          name: 'publicProfile',
          pageBuilder: (context, state) => NoTransitionPage(
              child: PublicProfilePage(
                  initialThixId: state.uri.queryParameters['thixId'])),
        ),
        GoRoute(
          path: AppRoutes.userDashboard,
          name: 'userDashboard',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: UserDashboardPage()),
        ),
        GoRoute(
          path: AppRoutes.enterpriseDashboard,
          name: 'enterpriseDashboard',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: EnterpriseDashboardPage()),
        ),
        GoRoute(
          path: AppRoutes.enterprise,
          name: 'enterpriseEntry',
          redirect: (context, state) {
            final isLoggedIn = auth.isAuthenticated;
            if (!isLoggedIn) return AppRoutes.login;
            final t = auth.currentUser?.accountType;
            if (t == AccountType.enterprise) return AppRoutes.enterpriseDashboard;
            return AppRoutes.enterpriseReg;
          },
        ),
        GoRoute(
          path: '/entreprise/:slug',
          name: 'enterprisePortalAliasFr',
          redirect: (context, state) {
            final slug = (state.pathParameters['slug'] ?? '').trim();
            return '${AppRoutes.enterprisePortalBase(slug)}/dashboard/overview';
          },
        ),
        GoRoute(
          path: '${AppRoutes.enterprisePortalBasePath}/:slug',
          name: 'enterprisePortal',
          pageBuilder: (context, state) {
            final slug = (state.pathParameters['slug'] ?? '').trim();
            return NoTransitionPage(child: EnterprisePortalPage(companySlug: slug));
          },
          routes: [
            GoRoute(
              path: 'dashboard/:section',
              name: 'enterprisePortalDashboard',
              pageBuilder: (context, state) {
                final slug = (state.pathParameters['slug'] ?? '').trim();
                final section = (state.pathParameters['section'] ?? 'overview').trim();
                return NoTransitionPage(
                    child: EnterpriseDashboardShellPage(
                        companySlug: slug, section: section));
              },
            ),
            GoRoute(
              path: 'dashboard',
              name: 'enterprisePortalDashboardRoot',
              redirect: (context, state) {
                final slug = (state.pathParameters['slug'] ?? '').trim();
                return '${AppRoutes.enterprisePortalBase(slug)}/dashboard/overview';
              },
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.chat,
          name: 'chat',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ThixChatPage()),
          routes: [
            GoRoute(
              path: ':chatId',
              name: 'chatConversation',
              pageBuilder: (context, state) {
                final chatId = Uri.decodeComponent(state.pathParameters['chatId'] ?? '');
                final extra = (state.extra is Map)
                    ? (state.extra as Map).cast<String, dynamic>()
                    : const <String, dynamic>{};
                final title = (extra['title'] as String?) ?? 'Discussion';
                final type = (extra['type'] as String?) ?? 'direct';
                return NoTransitionPage(
                    child: ChatConversationScreen(
                        chatId: chatId, title: title, type: type));
              },
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.vault,
          name: 'vault',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DocumentVaultPage()),
        ),
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsPage()),
        ),
        // ---- Réseau ----
        GoRoute(
          path: AppRoutes.network,
          name: 'network',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: NetworkProHome()),
        ),
        GoRoute(
          path: AppRoutes.networkSearch,
          name: 'networkSearch',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SearchNetworkPage()),
        ),
        GoRoute(
          path: AppRoutes.networkNotifications,
          name: 'networkNotifications',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: NotificationsPage()),
        ),
        GoRoute(
          path: AppRoutes.networkMessages,
          name: 'networkMessages',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ConversationsList()),
        ),
        GoRoute(
          path: '${AppRoutes.networkChatBasePath}/:userId',
          name: 'networkChat',
          pageBuilder: (context, state) {
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
            return NoTransitionPage(
                child: ChatScreen(
                    userId: userId,
                    userName: userName,
                    userAvatar: userAvatar));
          },
        ),
        GoRoute(
          path: AppRoutes.networkConnections,
          name: 'networkConnections',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ConnectionsListPage()),
        ),
        GoRoute(
          path: AppRoutes.networkProfileSettings,
          name: 'networkProfileSettings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ProfileSettingsPage()),
        ),
        GoRoute(
          path: AppRoutes.networkBlockedUsers,
          name: 'networkBlockedUsers',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: BlockedUsersPage()),
        ),
        GoRoute(
          path: '${AppRoutes.networkPostBasePath}/:postId',
          name: 'networkPostDetail',
          pageBuilder: (context, state) {
            final postId = (state.pathParameters['postId'] ?? '').trim();
            return NoTransitionPage(child: PostDetailPage(postId: postId));
          },
        ),
        GoRoute(
          path: '${AppRoutes.networkCommunityBasePath}/:communityId',
          name: 'networkCommunityDetail',
          pageBuilder: (context, state) {
            final communityId = (state.pathParameters['communityId'] ?? '').trim();
            return NoTransitionPage(
                child: CommunityDetailPage(communityId: communityId));
          },
        ),
        GoRoute(
          path: '${AppRoutes.networkProfileBasePath}/:userId',
          name: 'networkProfile',
          pageBuilder: (context, state) {
            final userId = (state.pathParameters['userId'] ?? '').trim();
            return NoTransitionPage(child: ProfilePage(userId: userId));
          },
        ),
        GoRoute(
          path: AppRoutes.profile,
          name: 'profile',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ProfilePage()),
        ),
        // ---- THIX Market ----
        GoRoute(
          path: AppRoutes.thixMarket,
          name: 'thixMarket',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ThixMarketPage()),
        ),
        // ---- THIX Santé ----
        // Point d'entrée principal
        GoRoute(
          path: AppRoutes.thixSante,
          name: 'thixSante',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ThixSantePage()),
        ),
        // Sélection de rôle (redirige vers les dashboards correspondants)
        GoRoute(
          path: AppRoutes.thixSantePatient,
          name: 'thixSantePatient',
          pageBuilder: (context, state) => NoTransitionPage(
              child: ThixSanteRolePage(role: ThixRole.patient)),
        ),
        GoRoute(
          path: AppRoutes.thixSanteDoctor,
          name: 'thixSanteDoctor',
          pageBuilder: (context, state) => NoTransitionPage(
              child: ThixSanteRolePage(role: ThixRole.doctor)),
        ),
        GoRoute(
          path: AppRoutes.thixSantePharmacy,
          name: 'thixSantePharmacy',
          pageBuilder: (context, state) => NoTransitionPage(
              child: ThixSanteRolePage(role: ThixRole.pharmacy)),
        ),

        // ----- Module Patient -----
        // Pages principales
        GoRoute(
          path: '/sante/patient/dashboard',
          name: 'patientDashboard',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientDashboardPage()),
        ),
        GoRoute(
          path: '/sante/patient/health',
          name: 'patientHealth',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientHealthPage()),
        ),
        GoRoute(
          path: '/sante/patient/care',
          name: 'patientCare',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientCarePage()),
        ),
        GoRoute(
          path: '/sante/patient/life',
          name: 'patientLife',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientLifePage()),
        ),
        GoRoute(
          path: '/sante/patient/connect',
          name: 'patientConnect',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientConnectPage()),
        ),

        // Détails Patient
        // Rendez-vous
        GoRoute(
          path: '/sante/patient/appointments',
          name: 'patientAppointmentsList',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientAppointmentsListPage()),
        ),
        GoRoute(
          path: '/sante/patient/appointment/:id',
          name: 'patientAppointmentDetail',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id'];
            final isEditing = state.uri.queryParameters['edit'] == 'true';
            return NoTransitionPage(
                child: PatientAppointmentPage(
                    appointmentId: id, isEditing: isEditing));
          },
        ),
        GoRoute(
          path: '/sante/patient/appointment/new',
          name: 'patientAppointmentNew',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientAppointmentPage()),
        ),
        // Consultation
        GoRoute(
          path: '/sante/patient/consultation/:id',
          name: 'patientConsultation',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(
                child: PatientConsultationPage(consultationId: id));
          },
        ),
        // Ordonnances
        GoRoute(
          path: '/sante/patient/prescriptions',
          name: 'patientPrescriptions',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientPrescriptionsListPage()),
        ),
        GoRoute(
          path: '/sante/patient/prescription/:id',
          name: 'patientPrescription',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(
                child: PatientPrescriptionPage(prescriptionId: id));
          },
        ),
        // Examens
        GoRoute(
          path: '/sante/patient/exams',
          name: 'patientExams',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientExamsListPage()),
        ),
        GoRoute(
          path: '/sante/patient/exam/:id',
          name: 'patientExam',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PatientExamPage(examId: id));
          },
        ),
        // Scan
        GoRoute(
          path: '/sante/patient/scan',
          name: 'patientScan',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientScanPage()),
        ),
        // Téléconsultation Jitsi
        GoRoute(
          path: '/sante/patient/teleconsultation/:id',
          name: 'patientTeleconsultation',
          pageBuilder: (context, state) {
            final link = state.extra as String? ?? 'https://meet.jit.si/default';
            return NoTransitionPage(
                child: JitsiTeleconsultationPage(link: link));
          },
        ),
        // Téléexpertise
        GoRoute(
          path: '/sante/patient/teleexpertise/:id',
          name: 'patientTeleexpertise',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(
                child: PatientTeleexpertiseDetailPage(
                    expertiseId: id));
          },
        ),
        GoRoute(
          path: '/sante/patient/teleexpertise/request',
          name: 'patientTeleexpertiseRequest',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientTeleexpertiseRequestPage()),
        ),
        // Symptômes
        GoRoute(
          path: '/sante/patient/symptom/:id',
          name: 'patientSymptom',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PatientSymptomPage(symptomId: id));
          },
        ),
        GoRoute(
          path: '/sante/patient/symptom/new',
          name: 'patientSymptomNew',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientSymptomPage()),
        ),
        // Constantes
        GoRoute(
          path: '/sante/patient/vital/:id',
          name: 'patientVital',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PatientVitalPage(vitalId: id));
          },
        ),
        GoRoute(
          path: '/sante/patient/vital/new',
          name: 'patientVitalNew',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientVitalPage()),
        ),
        GoRoute(
          path: '/sante/patient/vitals/chart',
          name: 'patientVitalChart',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientVitalChartPage()),
        ),
        GoRoute(
          path: '/sante/patient/record/add',
          name: 'patientRecordAdd',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientRecordAddPage()),
        ),
        // Médicaments
        GoRoute(
          path: '/sante/patient/medications',
          name: 'patientMedications',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientMedicationsListPage()),
        ),
        GoRoute(
          path: '/sante/patient/medication/:id',
          name: 'patientMedication',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(
                child: PatientMedicationPage(medicationId: id));
          },
        ),
        GoRoute(
          path: '/sante/patient/medication/new',
          name: 'patientMedicationNew',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientMedicationPage()),
        ),
        GoRoute(
          path: '/sante/patient/medication/:id/reminders',
          name: 'patientMedicationReminders',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(
                child: PatientMedicationRemindersPage(
                    medicationId: id));
          },
        ),
        // Vaccins
        GoRoute(
          path: '/sante/patient/vaccinations',
          name: 'patientVaccinations',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientVaccinationCalendarPage()),
        ),
        GoRoute(
          path: '/sante/patient/vaccine/:id',
          name: 'patientVaccine',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PatientVaccinePage(vaccineId: id));
          },
        ),
        GoRoute(
          path: '/sante/patient/vaccine/new',
          name: 'patientVaccineNew',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientVaccinePage()),
        ),
        // Grossesse
        GoRoute(
          path: '/sante/patient/pregnancy/:id',
          name: 'patientPregnancy',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(
                child: PatientPregnancyPage(pregnancyId: id));
          },
        ),
        GoRoute(
          path: '/sante/patient/pregnancy/new',
          name: 'patientPregnancyNew',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientPregnancyPage()),
        ),
        // Famille
        GoRoute(
          path: '/sante/patient/family/:id',
          name: 'patientFamily',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PatientFamilyPage(memberId: id));
          },
        ),
        GoRoute(
          path: '/sante/patient/family/new',
          name: 'patientFamilyNew',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientFamilyPage()),
        ),
        // Partage
        GoRoute(
          path: '/sante/patient/sharing/:id',
          name: 'patientSharing',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PatientSharingPage(shareId: id));
          },
        ),
        GoRoute(
          path: '/sante/patient/sharing/new',
          name: 'patientSharingNew',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientSharingPage()),
        ),
        // IA Chat
        GoRoute(
          path: '/sante/patient/ia',
          name: 'patientIA',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientAIChatPage()),
        ),
        GoRoute(
          path: '/sante/patient/ia/history/:id',
          name: 'patientIAHistory',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(
                child: PatientAIChatPage(conversationId: id));
          },
        ),
        // Alertes
        GoRoute(
          path: '/sante/patient/alerts',
          name: 'patientAlerts',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientAlertPage()),
        ),
        GoRoute(
          path: '/sante/patient/alert/:id',
          name: 'patientAlert',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PatientAlertPage(alertId: id));
          },
        ),
        // Map
        GoRoute(
          path: '/sante/patient/map/:type',
          name: 'patientMap',
          pageBuilder: (context, state) {
            final type = state.pathParameters['type']!;
            return NoTransitionPage(child: PatientMapPage(type: type));
          },
        ),
        GoRoute(
          path: '/sante/patient/map/pharmacy/:id',
          name: 'patientMapPharmacy',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(
                child: PatientPharmacyDetailPage(pharmacyId: id));
          },
        ),
        // Bien-être
        GoRoute(
          path: '/sante/patient/wellness/:id',
          name: 'patientWellness',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PatientWellnessPage(programId: id));
          },
        ),
        GoRoute(
          path: '/sante/patient/wellness/:id/track',
          name: 'patientWellnessTrack',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(
                child: PatientWellnessPage(programId: id, isTracking: true));
          },
        ),
        // Consentements
        GoRoute(
          path: '/sante/patient/consents',
          name: 'patientConsents',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientConsentPage()),
        ),
        GoRoute(
          path: '/sante/patient/consent/:id',
          name: 'patientConsent',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PatientConsentPage(consentId: id));
          },
        ),
        // Notifications
        GoRoute(
          path: '/sante/patient/notifications',
          name: 'patientNotifications',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientNotificationsPage()),
        ),
        // Profil
        GoRoute(
          path: '/sante/patient/profile',
          name: 'patientProfile',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientProfilePage()),
        ),
        // Article
        GoRoute(
          path: '/sante/patient/article/:id',
          name: 'patientArticle',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PatientArticlePage(articleId: id));
          },
        ),
        // Chat
        GoRoute(
          path: '/sante/patient/chat/:id',
          name: 'patientChat',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            final name = state.extra as String?;
            return NoTransitionPage(
                child: PatientChatPage(chatId: id, recipientName: name));
          },
        ),
        GoRoute(
          path: '/sante/patient/chat/new',
          name: 'patientChatNew',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientChatNewPage()),
        ),

        // ----- Module Médecin -----
        // Pages principales
        GoRoute(
          path: '/sante/doctor/dashboard',
          name: 'doctorDashboard',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DoctorDashboardPage()),
        ),
        GoRoute(
          path: '/sante/doctor/care',
          name: 'doctorCare',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DoctorCarePage()),
        ),
        GoRoute(
          path: '/sante/doctor/consult',
          name: 'doctorConsult',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DoctorConsultPage()),
        ),
        GoRoute(
          path: '/sante/doctor/connect',
          name: 'doctorConnect',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DoctorConnectPage()),
        ),
        // Détails Médecin
        // Patients
        GoRoute(
          path: '/sante/doctor/patients',
          name: 'doctorPatients',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DoctorPatientsPage()),
        ),
        GoRoute(
          path: '/sante/doctor/patient/:id',
          name: 'doctorPatient',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: DoctorPatientPage(patientId: id));
          },
        ),
        GoRoute(
          path: '/sante/doctor/patient/new',
          name: 'doctorPatientNew',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DoctorPatientAddPage()),
        ),
        // Prescriptions
        GoRoute(
          path: '/sante/doctor/prescription/new',
          name: 'doctorPrescriptionNew',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DoctorPrescriptionPage()),
        ),
        GoRoute(
          path: '/sante/doctor/prescription/:id',
          name: 'doctorPrescription',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(
                child: DoctorPrescriptionPage(prescriptionId: id));
          },
        ),
        // Téléconsultation
        GoRoute(
          path: '/sante/doctor/teleconsult',
          name: 'doctorTeleconsult',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DoctorTeleconsultPage()),
        ),
        GoRoute(
          path: '/sante/doctor/teleconsultation/jitsi',
          name: 'doctorJitsi',
          pageBuilder: (context, state) {
            final link = state.extra as String? ?? 'https://meet.jit.si/default';
            return NoTransitionPage(
                child: JitsiTeleconsultationPage(link: link));
          },
        ),
        // Téléexpertise
        GoRoute(
          path: '/sante/doctor/teleexpertise/:id',
          name: 'doctorTeleexpertise',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(
                child: DoctorTeleexpertisePage(requestId: id));
          },
        ),
        GoRoute(
          path: '/sante/doctor/teleexpertise/new',
          name: 'doctorTeleexpertiseNew',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DoctorTeleexpertisePage()),
        ),
        // Agenda
        GoRoute(
          path: '/sante/doctor/agenda',
          name: 'doctorAgenda',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DoctorAgendaPage()),
        ),
        GoRoute(
          path: '/sante/doctor/agenda/slots',
          name: 'doctorAgendaSlots',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DoctorSlotManagementPage()),
        ),
        // Notes
        GoRoute(
          path: '/sante/doctor/note/:id',
          name: 'doctorNote',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: DoctorNotePage(noteId: id));
          },
        ),
        GoRoute(
          path: '/sante/doctor/note/new',
          name: 'doctorNoteNew',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DoctorNotePage()),
        ),
        // Statistiques
        GoRoute(
          path: '/sante/doctor/statistics',
          name: 'doctorStatistics',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DoctorStatisticsPage()),
        ),
        // Terrain
        GoRoute(
          path: '/sante/doctor/terrain/scan',
          name: 'doctorTerrainScan',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DoctorScanBraceletPage()),
        ),
        GoRoute(
          path: '/sante/doctor/terrain/dictation',
          name: 'doctorTerrainDictation',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DoctorVoiceDictationPage()),
        ),
        GoRoute(
          path: '/sante/doctor/terrain/offline',
          name: 'doctorTerrainOffline',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DoctorOfflinePatientsPage()),
        ),
        GoRoute(
          path: '/sante/doctor/terrain/photo',
          name: 'doctorTerrainPhoto',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DoctorPhotoCapturePage()),
        ),
        // Chat
        GoRoute(
          path: '/sante/doctor/messages/:id',
          name: 'doctorChat',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            final name = state.extra as String?;
            return NoTransitionPage(
                child: DoctorChatPage(conversationId: id, participantName: name));
          },
        ),
        GoRoute(
          path: '/sante/doctor/messages/new',
          name: 'doctorChatNew',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DoctorNewMessagePage()),
        ),
        // Alertes
        GoRoute(
          path: '/sante/doctor/alerts',
          name: 'doctorAlerts',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DoctorAlertPage()),
        ),
        GoRoute(
          path: '/sante/doctor/alert/:patientName',
          name: 'doctorAlertPatient',
          pageBuilder: (context, state) {
            final name = state.pathParameters['patientName']!;
            return NoTransitionPage(child: DoctorAlertPage(patientName: name));
          },
        ),

        // ----- Module Pharmacie -----
        // Pages principales
        GoRoute(
          path: '/sante/pharmacy/dashboard',
          name: 'pharmacyDashboard',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PharmacyDashboardPage()),
        ),
        GoRoute(
          path: '/sante/pharmacy/orders',
          name: 'pharmacyOrders',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PharmacyOrdersPage()),
        ),
        GoRoute(
          path: '/sante/pharmacy/inventory',
          name: 'pharmacyInventory',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PharmacyInventoryPage()),
        ),
        GoRoute(
          path: '/sante/pharmacy/connect',
          name: 'pharmacyConnect',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PharmacyConnectPage()),
        ),
        // Détails Pharmacie
        // Commandes
        GoRoute(
          path: '/sante/pharmacy/order/:id',
          name: 'pharmacyOrder',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(
                child: PharmacyOrderPage(orderId: id));
          },
        ),
        GoRoute(
          path: '/sante/pharmacy/order/new',
          name: 'pharmacyOrderNew',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PharmacyOrderPage()),
        ),
        // Prescription validation
        GoRoute(
          path: '/sante/pharmacy/prescription/:id',
          name: 'pharmacyPrescription',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(
                child: PharmacyPrescriptionPage(prescriptionId: id));
          },
        ),
        // Dispensation
        GoRoute(
          path: '/sante/pharmacy/dispensing',
          name: 'pharmacyDispensing',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PharmacyDispensingPage()),
        ),
        // Livraisons
        GoRoute(
          path: '/sante/pharmacy/delivery',
          name: 'pharmacyDelivery',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PharmacyDeliveryPage()),
        ),
        // Inventaire
        GoRoute(
          path: '/sante/pharmacy/inventory/item/:id',
          name: 'pharmacyInventoryItem',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(
                child: PharmacyInventoryItemPage(itemId: id));
          },
        ),
        GoRoute(
          path: '/sante/pharmacy/inventory/item/new',
          name: 'pharmacyInventoryItemNew',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PharmacyInventoryItemPage()),
        ),
        // Stock
        GoRoute(
          path: '/sante/pharmacy/stock',
          name: 'pharmacyStock',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PharmacyStockPage()),
        ),
        // Rapports
        GoRoute(
          path: '/sante/pharmacy/report',
          name: 'pharmacyReport',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PharmacyReportPage()),
        ),
        // Chat
        GoRoute(
          path: '/sante/pharmacy/chat/:id',
          name: 'pharmacyChat',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            final name = state.extra as String?;
            return NoTransitionPage(
                child: PharmacyChatPage(conversationId: id, participantName: name));
          },
        ),
        GoRoute(
          path: '/sante/pharmacy/chat/new',
          name: 'pharmacyChatNew',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PharmacyChatPage()),
        ),

        // ---- Autres modules THIX ----
        GoRoute(
          path: AppRoutes.thixMoney,
          name: 'thixMoney',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ThixMoneyPage()),
        ),
        GoRoute(
          path: AppRoutes.thixMedia,
          name: 'thixMedia',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ThixMediaPage()),
        ),
        GoRoute(
          path: AppRoutes.thixMediaVideo,
          name: 'thixMediaVideo',
          pageBuilder: (context, state) {
            final title = (state.uri.queryParameters['title'] ?? '').trim();
            final url = (state.uri.queryParameters['url'] ?? '').trim();
            return NoTransitionPage(
              child: VideoPlayerPage(
                title: title.isEmpty ? 'Lecture vidéo' : title,
                videoUrl: url,
              ),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.thixInfo,
          name: 'thixInfo',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ThixInfoHomePage()),
        ),
        GoRoute(
          path: '${AppRoutes.thixInfoArticleBasePath}/:id',
          name: 'thixInfoArticle',
          pageBuilder: (context, state) {
            final id = (state.pathParameters['id'] ?? '').trim();
            return NoTransitionPage(child: ThixInfoArticlePage(id: id));
          },
        ),
        GoRoute(
          path: AppRoutes.reservation,
          name: 'reservation',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ThixReservationPage()),
        ),

        // ==================== THIX ÉVÉNEMENT ====================
        GoRoute(
          path: AppRoutes.thixEvent,
          name: 'thixEvent',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ThixEventHome()),
        ),
        GoRoute(
          path: AppRoutes.thixEventDetail,
          name: 'thixEventDetail',
          pageBuilder: (context, state) {
            final eventId = state.pathParameters['eventId']!;
            return NoTransitionPage(child: EventDetailPage(eventId: eventId));
          },
        ),
        GoRoute(
          path: AppRoutes.thixEventSearch,
          name: 'thixEventSearch',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: EventSearchPage()),
        ),
        GoRoute(
          path: AppRoutes.thixEventCategory,
          name: 'thixEventCategory',
          pageBuilder: (context, state) {
            final category = state.pathParameters['category']!;
            return NoTransitionPage(child: EventCategoryPage(category: category));
          },
        ),
        GoRoute(
          path: AppRoutes.thixEventReservation,
          name: 'thixEventReservation',
          pageBuilder: (context, state) {
            final eventId = state.pathParameters['eventId']!;
            final quantity = int.tryParse(state.uri.queryParameters['quantity'] ?? '1') ?? 1;
            return NoTransitionPage(child: EventReservationPage(eventId: eventId, quantity: quantity));
          },
        ),
        GoRoute(
          path: AppRoutes.thixEventMyTickets,
          name: 'thixEventMyTickets',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MyTicketsPage()),
        ),
        GoRoute(
          path: AppRoutes.thixEventFavorites,
          name: 'thixEventFavorites',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: FavoriteEventsPage()),
        ),
        GoRoute(
          path: AppRoutes.thixEventSeatSelection,
          name: 'thixEventSeatSelection',
          pageBuilder: (context, state) {
            final eventId = state.pathParameters['eventId']!;
            return NoTransitionPage(child: SeatSelectionPage(eventId: eventId));
          },
        ),
        GoRoute(
          path: AppRoutes.thixEventWaitingQueue,
          name: 'thixEventWaitingQueue',
          pageBuilder: (context, state) {
            final eventId = state.pathParameters['eventId']!;
            final quantity = int.tryParse(state.uri.queryParameters['quantity'] ?? '1') ?? 1;
            return NoTransitionPage(child: WaitingQueuePage(eventId: eventId, requestedQuantity: quantity));
          },
        ),

        // ---- Jobs ----
        GoRoute(
          path: AppRoutes.jobs,
          name: 'jobs',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: JobsPage()),
        ),
        GoRoute(
          path: AppRoutes.jobDashboard,
          name: 'jobDashboard',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: JobDashboardPage()),
        ),
        GoRoute(
          path: AppRoutes.recruiter,
          name: 'recruiter',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: RecruiterPortalPage()),
        ),
        // Opportunités
        GoRoute(
          path: AppRoutes.opportunities,
          name: 'opportunities',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: OpportunitiesPage()),
        ),
        GoRoute(
          path: '/opportunities/:opportunityId',
          name: 'opportunityDetails',
          pageBuilder: (context, state) {
            final opportunityId = state.pathParameters['opportunityId'] ?? '';
            final applied = (state.uri.queryParameters['applied'] ?? '').trim() == '1';
            return NoTransitionPage(
                child: OpportunityDetailsPage(
                    opportunityId: opportunityId, applied: applied));
          },
        ),
        GoRoute(
          path: '/opportunities/:opportunityId/apply',
          name: 'opportunityApply',
          pageBuilder: (context, state) {
            final opportunityId = state.pathParameters['opportunityId'] ?? '';
            return NoTransitionPage(
                child: OpportunityApplyPage(opportunityId: opportunityId));
          },
        ),
        // Jobs détail
        GoRoute(
          path: '/jobs/:jobId',
          name: 'jobDetails',
          pageBuilder: (context, state) {
            final jobId = state.pathParameters['jobId'] ?? '';
            final applied = (state.uri.queryParameters['applied'] ?? '').trim() == '1';
            return NoTransitionPage(
                child: JobDetailsPage(jobId: jobId, applied: applied));
          },
        ),
        GoRoute(
          path: '/jobs/:jobId/apply',
          name: 'jobApply',
          pageBuilder: (context, state) {
            final jobId = state.pathParameters['jobId'] ?? '';
            return NoTransitionPage(child: JobApplyPage(jobId: jobId));
          },
        ),
        // Education
        GoRoute(
          path: AppRoutes.education,
          name: 'education',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: EducationPage()),
        ),
        // Training
        GoRoute(
          path: AppRoutes.trainingHome,
          name: 'trainingHome',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: TrainingHomePage()),
        ),
        GoRoute(
          path: '${AppRoutes.trainingDetailsBasePath}/:trainingId',
          name: 'trainingDetails',
          pageBuilder: (context, state) {
            final id = state.pathParameters['trainingId'] ?? '';
            return NoTransitionPage(child: TrainingDetailsPage(trainingId: id));
          },
        ),
        GoRoute(
          path: AppRoutes.learningDashboard,
          name: 'learningDashboard',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: LearningDashboardPage()),
        ),
        GoRoute(
          path: '${AppRoutes.lessonPlayer}/:enrollmentId',
          name: 'lessonPlayer',
          pageBuilder: (context, state) {
            final id = state.pathParameters['enrollmentId'] ?? '';
            return NoTransitionPage(child: LessonPlayerPage(enrollmentId: id));
          },
        ),
        // Admin
        GoRoute(
          path: '${AppRoutes.admin}/:module',
          name: 'admin',
          pageBuilder: (context, state) {
            final module = AdminModuleX.fromSlug(state.pathParameters['module']);
            return NoTransitionPage(child: AdminPage(module: module));
          },
        ),
        GoRoute(
          path: AppRoutes.admin,
          name: 'adminRoot',
          redirect: (_, __) =>
              '${AppRoutes.admin}/${AdminModule.overview.slug}',
        ),
        GoRoute(
          path: AppRoutes.adminMedia,
          name: 'adminMedia',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: AdminMediaPage()),
        ),
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
