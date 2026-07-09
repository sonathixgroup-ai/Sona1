// lib/app_router.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';

// ✅ Constantes depuis nav.dart (unique source)
import 'package:thix_id/nav.dart' show AppRoutes;

// ---- Pages générales ----
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

// ---- Réseau Pro ----
import 'package:thix_id/presentation/network/network_pro_home.dart';
import 'package:thix_id/presentation/network/search_network_page.dart';
import 'package:thix_id/presentation/network/notifications/notifications_page.dart';
import 'package:thix_id/presentation/network/messages/conversations_list.dart';
import 'package:thix_id/presentation/network/messages/chat_screen.dart';
import 'package:thix_id/presentation/network/connections_list_page.dart';
import 'package:thix_id/presentation/network/community_detail_page.dart';
import 'package:thix_id/presentation/network/communities_list_page.dart';
import 'package:thix_id/presentation/network/create_community_page.dart';
import 'package:thix_id/presentation/network/post_detail_page.dart';
import 'package:thix_id/presentation/network/profile_page.dart';
import 'package:thix_id/presentation/network/profile_settings_page.dart';
import 'package:thix_id/presentation/network/blocked_users_page.dart';
import 'package:thix_id/presentation/network/discover_tab.dart';
import 'package:thix_id/presentation/network/story_viewer_screen.dart';
import 'package:thix_id/presentation/network/comments_page.dart';
import 'package:thix_id/presentation/network/hashtag_page.dart';

// ---- Jobs, Opportunités ----
import 'presentation/jobs/jobs_page.dart';
import 'package:thix_id/presentation/jobs/job_apply_page.dart';
import 'package:thix_id/presentation/jobs/job_details_page.dart';
import 'package:thix_id/presentation/jobs/job_dashboard_page.dart';
import 'package:thix_id/presentation/recruiter/recruiter_portal_page.dart';
import 'package:thix_id/presentation/opportunities/opportunities_page.dart';
import 'package:thix_id/presentation/opportunities/opportunity_apply_page.dart';
import 'package:thix_id/presentation/opportunities/opportunity_details_page.dart';

// ---- Admin ----
import 'package:thix_id/presentation/admin/admin_page.dart';
import 'package:thix_id/presentation/admin/admin_routes.dart';

// ---- THIX Market ----
import 'package:thix_id/presentation/thix_market/pages/market_home_page.dart';
import 'package:thix_id/presentation/thix_market/pages/search_page.dart' as marketSearch;
import 'package:thix_id/presentation/thix_market/pages/shops_page.dart';
import 'package:thix_id/presentation/thix_market/pages/buy_page.dart';
import 'package:thix_id/presentation/thix_market/pages/sell_page.dart';
import 'package:thix_id/presentation/thix_market/pages/messages_page.dart';
import 'package:thix_id/presentation/thix_market/pages/live_page.dart';
import 'package:thix_id/presentation/thix_market/pages/my_activity_page.dart';
import 'package:thix_id/presentation/thix_market/pages/market_settings_page.dart';
import 'package:thix_id/presentation/thix_market/pages/help_support_page.dart';
import 'package:thix_id/presentation/thix_market/pages/product_detail_page.dart';
import 'package:thix_id/presentation/thix_market/pages/product_comparator_page.dart';
import 'package:thix_id/presentation/thix_market/pages/price_alerts_page.dart';
import 'package:thix_id/presentation/thix_market/cart/cart_page.dart';
import 'package:thix_id/presentation/thix_market/checkout/checkout_page.dart';
import 'package:thix_id/presentation/thix_market/pages/order_history_page.dart';
import 'package:thix_id/presentation/thix_market/pages/order_detail_page.dart';
import 'package:thix_id/presentation/thix_market/pages/create_shop_page.dart';
import 'package:thix_id/presentation/thix_market/pages/manage_shop_page.dart';
import 'package:thix_id/presentation/thix_market/pages/shop_statistics_page.dart';
import 'package:thix_id/presentation/thix_market/pages/publish_announcement_page.dart';
import 'package:thix_id/presentation/thix_market/pages/edit_announcement_page.dart';
import 'package:thix_id/presentation/thix_market/pages/live_stream_page.dart';
import 'package:thix_id/presentation/thix_market/pages/create_live_page.dart';
import 'package:thix_id/presentation/thix_market/pages/live_replay_page.dart';
import 'package:thix_id/presentation/thix_market/pages/auction_page.dart';
import 'package:thix_id/presentation/thix_market/pages/chat_page.dart';
import 'package:thix_id/presentation/thix_market/pages/dispute_detail_page.dart';
import 'package:thix_id/presentation/thix_market/pages/notification_page.dart';
import 'package:thix_id/presentation/thix_market/pages/shop_detail_page.dart';
import 'package:thix_id/presentation/thix_market/vendor/vendor_dashboard.dart';
import 'package:thix_id/presentation/thix_market/vendor/delivery_management_page.dart';

// ---- THIX Info ----
import 'package:thix_id/presentation/thix_info/thix_info_home.dart';
import 'package:thix_id/presentation/thix_info/article_detail_page.dart';
import 'package:thix_id/presentation/thix_info/search_page.dart' as infoSearch;
import 'package:thix_id/presentation/thix_info/category_articles_page.dart';
import 'package:thix_id/presentation/thix_info/saved_articles_page.dart';
import 'package:thix_id/presentation/thix_info/breaking_news_page.dart';
import 'package:thix_id/presentation/admin/pages/admin_news_dashboard.dart';
import 'package:thix_id/presentation/admin/pages/create_news_page.dart';

// ---- THIX Santé ----
import 'package:thix_id/presentation/thix_sante/thix_sante_page.dart';
import 'package:thix_id/presentation/thix_sante/thix_role.dart';
import 'package:thix_id/presentation/thix_sante/thix_sante_role_page.dart';

// Patient
import 'package:thix_id/presentation/thix_sante/patient/patient_dashboard_page.dart' as patientDash;
import 'package:thix_id/presentation/thix_sante/patient/patient_health_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/patient_care_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/patient_life_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/patient_connect_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_appointment_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_appointments_list_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_consultation_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_prescription_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_prescriptions_list_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_exam_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_exams_list_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_scan_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_symptom_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_vital_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_vital_chart_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_medication_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_medications_list_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_medication_reminders_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_vaccine_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_vaccination_calendar_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_pregnancy_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_family_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_sharing_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_ai_chat_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_alert_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_map_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_pharmacy_detail_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_wellness_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_consent_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_notifications_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_profile_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_article_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_chat_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_chat_new_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_teleexpertise_detail_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_teleexpertise_request_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_record_add_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_teleconsultation_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_teleconsultation_jitsi_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_health_score_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_insurance_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/details/patient_record_page.dart';

// Doctor
import 'package:thix_id/presentation/thix_sante/doctor/doctor_dashboard_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/doctor_care_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/doctor_consult_page.dart';
import 'package:thix_id/presentation/thix_sante/doctor/doctor_connect_page.dart';
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

// Pharmacy
import 'package:thix_id/presentation/thix_sante/pharmacy/pharmacy_dashboard_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/pharmacy_orders_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/pharmacy_inventory_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/pharmacy_connect_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/details/pharmacy_order_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/details/pharmacy_prescription_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/details/pharmacy_dispensing_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/details/pharmacy_delivery_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/details/pharmacy_inventory_item_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/details/pharmacy_stock_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/details/pharmacy_report_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/details/pharmacy_chat_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/details/pharmacy_products_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/details/pharmacy_product_detail_page.dart';
import 'package:thix_id/presentation/thix_sante/pharmacy/details/pharmacy_cart_page.dart';

// ---- THIX Événement ----
import 'package:thix_id/presentation/thix_event/thix_event_home.dart';
import 'package:thix_id/presentation/thix_event/event_detail_page.dart';
import 'package:thix_id/presentation/thix_event/event_search_page.dart';
import 'package:thix_id/presentation/thix_event/event_category_page.dart';
import 'package:thix_id/presentation/thix_event/event_reservation_page.dart';
import 'package:thix_id/presentation/thix_event/my_tickets_page.dart';
import 'package:thix_id/presentation/thix_event/favorite_events_page.dart';
import 'package:thix_id/presentation/thix_event/seat_selection_page.dart';
import 'package:thix_id/presentation/thix_event/waiting_queue_page.dart';

// ---- Modérateur ----
import 'package:thix_id/presentation/moderator/moderator_home.dart';
import 'package:thix_id/presentation/moderator/moderator_event_list.dart';
import 'package:thix_id/presentation/moderator/moderator_event_form.dart';
import 'package:thix_id/providers/auth_provider.dart';

// ---- Éducation (apprenant + instructeur) ----
import 'package:thix_id/presentation/education/education_routes.dart';

// ---- THIX Money, Media, Reservation ----
import 'package:thix_id/presentation/thix_money/thix_money_page.dart';
import 'package:thix_id/presentation/thix_media/thix_media_page.dart';
import 'package:thix_id/presentation/thix_media/video_player_page.dart';
import 'package:thix_id/presentation/thix_reservation/thix_reservation_page.dart';
import 'package:thix_id/presentation/admin/pages/admin_media_page.dart';
import 'package:thix_id/presentation/splash/thix_id_start_page.dart';

// ---- THIX Chat (nouvelle version) ----
import 'package:thix_id/presentation/chat/screens/chat_list_page.dart';
import 'package:thix_id/presentation/chat/screens/new_conversation_page.dart';
import 'package:thix_id/presentation/chat/screens/chat_conversation_screen.dart' as NewChat;
import 'package:thix_id/models/chat/chat_conversation.dart';

// ==================== CLASSE DE TRANSITION SANS ANIMATION ====================
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

// ==================== CONSTRUCTEUR DU ROUTEUR ====================
class AppRouter {
  static GoRouter create(AuthController auth, {Listenable? extraRefreshListenable}) {
    final refresh = extraRefreshListenable ?? auth;
    return GoRouter(
      initialLocation: AppRoutes.home,
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
          pageBuilder: (context, state) => NoTransitionPage(child: ThixIdStartPage()),
        ),
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          pageBuilder: (context, state) => NoTransitionPage(child: HomePagePremium()),
        ),
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          pageBuilder: (context, state) => NoTransitionPage(child: LoginPage()),
        ),
        GoRoute(
          path: AppRoutes.personalReg,
          name: 'personalReg',
          pageBuilder: (context, state) {
            final stepStr = state.uri.queryParameters['step'];
            final step = int.tryParse(stepStr ?? '') ?? 1;
            return NoTransitionPage(child: PersonalRegistrationPage(initialStep: step));
          },
        ),
        GoRoute(
          path: AppRoutes.enterpriseReg,
          name: 'enterpriseReg',
          pageBuilder: (context, state) => NoTransitionPage(child: EnterpriseRegistrationPage()),
        ),
        GoRoute(
          path: AppRoutes.payment,
          name: 'payment',
          pageBuilder: (context, state) {
            final returnTo = state.uri.queryParameters['returnTo'];
            return NoTransitionPage(child: PaymentGatewayPage(returnTo: returnTo));
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
              child: PublicProfilePage(initialThixId: state.uri.queryParameters['thixId'])),
        ),
        GoRoute(
          path: AppRoutes.userDashboard,
          name: 'userDashboard',
          pageBuilder: (context, state) => NoTransitionPage(child: UserDashboardPage()),
        ),
        GoRoute(
          path: AppRoutes.enterpriseDashboard,
          name: 'enterpriseDashboard',
          pageBuilder: (context, state) => NoTransitionPage(child: EnterpriseDashboardPage()),
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
                    child: EnterpriseDashboardShellPage(companySlug: slug, section: section));
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

        // ---- THIX Chat (principal) ---
GoRoute(
  path: AppRoutes.chat,
  name: 'chat',
  pageBuilder: (context, state) => NoTransitionPage(child: const ThixChatPage()),
  routes: [
    GoRoute(
      path: 'new',
      name: 'chatNew',
      pageBuilder: (context, state) => NoTransitionPage(child: const NewChatPage()),
    ),
    GoRoute(
      path: ':conversationId',
      name: 'chatConversation',
      pageBuilder: (context, state) {
        final conversationId = state.pathParameters['conversationId']!;
        final conversation = state.extra as ChatConversation?;
        return NoTransitionPage(
          child: ChatConversationScreen(
            conversationId: conversationId,
            conversation: conversation,
          ),
        );
      },
    ),
  
        // ---- Vault & Settings ----
        GoRoute(
          path: AppRoutes.vault,
          name: 'document-vault',
          pageBuilder: (context, state) => NoTransitionPage(child: DocumentVaultPage()),
        ),
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          pageBuilder: (context, state) => NoTransitionPage(child: SettingsPage()),
        ),

        // ---- Réseau Pro ----
        GoRoute(
          path: AppRoutes.network,
          name: 'network',
          pageBuilder: (context, state) => NoTransitionPage(child: NetworkProHome()),
        ),
        GoRoute(
          path: AppRoutes.networkSearch,
          name: 'networkSearch',
          pageBuilder: (context, state) => NoTransitionPage(child: SearchNetworkPage()),
        ),
        GoRoute(
          path: AppRoutes.networkNotifications,
          name: 'networkNotifications',
          pageBuilder: (context, state) => NoTransitionPage(child: NotificationsPage()),
        ),
        GoRoute(
          path: AppRoutes.networkMessages,
          name: 'networkMessages',
          pageBuilder: (context, state) => NoTransitionPage(child: ConversationsList()),
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
            return NoTransitionPage(child: ChatScreen(userId: userId, userName: userName, userAvatar: userAvatar));
          },
        ),
        GoRoute(
          path: AppRoutes.networkConnections,
          name: 'networkConnections',
          pageBuilder: (context, state) => NoTransitionPage(child: ConnectionsListPage()),
        ),
        GoRoute(
          path: AppRoutes.networkProfileSettings,
          name: 'networkProfileSettings',
          pageBuilder: (context, state) => NoTransitionPage(child: ProfileSettingsPage()),
        ),
        GoRoute(
          path: AppRoutes.networkBlockedUsers,
          name: 'networkBlockedUsers',
          pageBuilder: (context, state) => NoTransitionPage(child: BlockedUsersPage()),
        ),
        // Nouveautés réseau
        GoRoute(
          path: '/network/discover',
          name: 'networkDiscover',
          pageBuilder: (context, state) => NoTransitionPage(child: const DiscoverTab()),
        ),
        GoRoute(
          path: '/network/communities',
          name: 'networkCommunities',
          pageBuilder: (context, state) => NoTransitionPage(child: const CommunitiesListPage()),
        ),
        GoRoute(
          path: '/network/community/create',
          name: 'networkCommunityCreate',
          pageBuilder: (context, state) => NoTransitionPage(child: const CreateCommunityPage()),
        ),
        GoRoute(
          path: '${AppRoutes.networkCommunityBasePath}/:communityId',
          name: 'networkCommunityDetail',
          pageBuilder: (context, state) {
            final communityId = (state.pathParameters['communityId'] ?? '').trim();
            return NoTransitionPage(child: CommunityDetailPage(communityId: communityId));
          },
        ),
        GoRoute(
          path: '/network/story/:storyId',
          name: 'networkStoryViewer',
          pageBuilder: (context, state) {
            final storyId = state.pathParameters['storyId']!;
            return NoTransitionPage(child: StoryViewerScreen(storyId: storyId));
          },
        ),
        GoRoute(
          path: '/network/comments/:postId',
          name: 'networkComments',
          pageBuilder: (context, state) {
            final postId = state.pathParameters['postId']!;
            final currentProfileId = Supabase.instance.client.auth.currentUser?.id ?? '';
            return NoTransitionPage(child: CommentsPage(postId: postId, currentProfileId: currentProfileId));
          },
        ),
        GoRoute(
          path: '/network/hashtag/:tag',
          name: 'networkHashtag',
          pageBuilder: (context, state) {
            final tag = state.pathParameters['tag']!;
            return NoTransitionPage(child: HashtagPage(tag: tag));
          },
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
          path: '${AppRoutes.networkProfileBasePath}/:userId',
          name: 'networkProfile',
          pageBuilder: (context, state) {
            final userId = state.pathParameters['userId']!;
            final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
            return NoTransitionPage(child: ProfilePage(userId: userId, currentProfileId: currentUserId));
          },
        ),
        GoRoute(
          path: AppRoutes.profile,
          name: 'profile',
          pageBuilder: (context, state) => NoTransitionPage(child: ProfilePage()),
        ),

        // ---- THIX Market ----
        GoRoute(
          path: AppRoutes.thixMarket,
          name: 'thixMarket',
          pageBuilder: (context, state) => NoTransitionPage(child: const MarketHomePage()),
          routes: [
            GoRoute(
              path: 'home',
              name: 'marketHome',
              pageBuilder: (context, state) => NoTransitionPage(child: const MarketHomePage()),
            ),
            GoRoute(
              path: 'search',
              name: 'marketSearch',
              pageBuilder: (context, state) => NoTransitionPage(child: const marketSearch.SearchPage()),
            ),
            GoRoute(
              path: 'shops',
              name: 'marketShops',
              pageBuilder: (context, state) => NoTransitionPage(child: const ShopsPage()),
            ),
            GoRoute(
              path: 'buy',
              name: 'marketBuy',
              pageBuilder: (context, state) => NoTransitionPage(child: const BuyPage()),
            ),
            GoRoute(
              path: 'sell',
              name: 'marketSell',
              pageBuilder: (context, state) => NoTransitionPage(child: const SellPage()),
            ),
            GoRoute(
              path: 'messages',
              name: 'marketMessages',
              pageBuilder: (context, state) => NoTransitionPage(child: const MessagesPage()),
            ),
            GoRoute(
              path: 'live',
              name: 'marketLive',
              pageBuilder: (context, state) => NoTransitionPage(child: const LivePage()),
            ),
            GoRoute(
              path: 'activity',
              name: 'marketActivity',
              pageBuilder: (context, state) => NoTransitionPage(child: const MyActivityPage()),
            ),
            GoRoute(
              path: 'settings',
              name: 'marketSettings',
              pageBuilder: (context, state) => NoTransitionPage(child: const MarketSettingsPage()),
            ),
            GoRoute(
              path: 'help',
              name: 'marketHelp',
              pageBuilder: (context, state) => NoTransitionPage(child: const HelpSupportPage()),
            ),
            GoRoute(
              path: 'product/:productId',
              name: 'marketProductDetail',
              pageBuilder: (context, state) {
                final productId = state.pathParameters['productId']!;
                return NoTransitionPage(child: ProductDetailPage(productId: productId));
              },
            ),
            GoRoute(
              path: 'shop/:shopId',
              name: 'marketShopDetail',
              pageBuilder: (context, state) {
                final shopId = state.pathParameters['shopId']!;
                return NoTransitionPage(child: ShopDetailPage(shopId: shopId));
              },
            ),
            GoRoute(
              path: 'compare',
              name: 'marketProductComparator',
              pageBuilder: (context, state) => NoTransitionPage(child: const ProductComparatorPage()),
            ),
            GoRoute(
              path: 'price-alerts',
              name: 'marketPriceAlerts',
              pageBuilder: (context, state) => NoTransitionPage(child: const PriceAlertsPage()),
            ),
            GoRoute(
              path: 'cart',
              name: 'marketCart',
              pageBuilder: (context, state) => NoTransitionPage(child: const CartPage()),
            ),
            GoRoute(
              path: 'checkout',
              name: 'marketCheckout',
              pageBuilder: (context, state) => NoTransitionPage(child: const CheckoutPage()),
            ),
            GoRoute(
              path: 'orders',
              name: 'marketOrders',
              pageBuilder: (context, state) => NoTransitionPage(child: const OrderHistoryPage()),
            ),
            GoRoute(
              path: 'order/:orderId',
              name: 'marketOrderDetail',
              pageBuilder: (context, state) {
                final orderId = state.pathParameters['orderId']!;
                return NoTransitionPage(child: OrderDetailPage(orderId: orderId));
              },
            ),
            GoRoute(
              path: 'chat/:shopId',
              name: 'marketChatSeller',
              pageBuilder: (context, state) {
                final shopId = state.pathParameters['shopId']!;
                final extra = state.extra as Map<String, dynamic>?;
                return NoTransitionPage(
                  child: ChatPage(
                    conversationId: '',
                    shopId: shopId,
                    title: extra?['title'] ?? 'Vendeur',
                    avatar: extra?['userAvatar'],
                  ),
                );
              },
            ),
            GoRoute(
              path: 'shop/create',
              name: 'marketCreateShop',
              pageBuilder: (context, state) => NoTransitionPage(child: const CreateShopPage()),
            ),
            GoRoute(
              path: 'shop/:shopId/manage',
              name: 'marketManageShop',
              pageBuilder: (context, state) {
                final shopId = state.pathParameters['shopId']!;
                return NoTransitionPage(child: ManageShopPage(shopId: shopId));
              },
            ),
            GoRoute(
              path: 'shop/:shopId/stats',
              name: 'marketShopStats',
              pageBuilder: (context, state) {
                final shopId = state.pathParameters['shopId']!;
                return NoTransitionPage(child: ShopStatisticsPage(shopId: shopId));
              },
            ),
            GoRoute(
              path: 'announcement/publish',
              name: 'marketPublishAnnouncement',
              pageBuilder: (context, state) => NoTransitionPage(child: const PublishAnnouncementPage()),
            ),
            GoRoute(
              path: 'vendor/dashboard',
              name: 'vendorDashboard',
              pageBuilder: (context, state) => NoTransitionPage(child: const VendorDashboard()),
            ),
            GoRoute(
              path: 'deliveries',
              name: 'deliveryManagement',
              pageBuilder: (context, state) => NoTransitionPage(child: const DeliveryManagementPage()),
            ),
            GoRoute(
              path: 'announcement/:announcementId/edit',
              name: 'marketEditAnnouncement',
              pageBuilder: (context, state) {
                final announcementId = state.pathParameters['announcementId']!;
                return NoTransitionPage(child: EditAnnouncementPage(announcementId: announcementId));
              },
            ),
            GoRoute(
              path: 'live/:liveId',
              name: 'marketLiveStream',
              pageBuilder: (context, state) {
                final liveId = state.pathParameters['liveId']!;
                return NoTransitionPage(child: LiveStreamPage(liveId: liveId));
              },
            ),
            GoRoute(
              path: 'live/create',
              name: 'marketCreateLive',
              pageBuilder: (context, state) => NoTransitionPage(child: const CreateLivePage()),
            ),
            GoRoute(
              path: 'live/:liveId/replay',
              name: 'marketLiveReplay',
              pageBuilder: (context, state) {
                final liveId = state.pathParameters['liveId']!;
                return NoTransitionPage(child: LiveReplayPage(liveId: liveId));
              },
            ),
            GoRoute(
              path: 'auction/:auctionId',
              name: 'marketAuction',
              pageBuilder: (context, state) {
                final auctionId = state.pathParameters['auctionId']!;
                return NoTransitionPage(child: AuctionPage(auctionId: auctionId));
              },
            ),
            GoRoute(
              path: 'chat/:conversationId',
              name: 'marketChat',
              pageBuilder: (context, state) {
                final conversationId = state.pathParameters['conversationId']!;
                return NoTransitionPage(child: ChatPage(conversationId: conversationId));
              },
            ),
            GoRoute(
              path: 'dispute/:disputeId',
              name: 'marketDispute',
              pageBuilder: (context, state) {
                final disputeId = state.pathParameters['disputeId']!;
                return NoTransitionPage(child: DisputeDetailPage(disputeId: disputeId));
              },
            ),
            GoRoute(
              path: 'notifications',
              name: 'marketNotifications',
              pageBuilder: (context, state) => NoTransitionPage(child: const NotificationPage()),
            ),
          ],
        ),

        // ---- THIX Info ----
        GoRoute(
          path: AppRoutes.thixInfo,
          name: 'thixInfo',
          pageBuilder: (context, state) => NoTransitionPage(child: const ThixInfoHome()),
        ),
        GoRoute(
          path: AppRoutes.thixInfoArticle,
          name: 'thixInfoArticle',
          pageBuilder: (context, state) {
            final articleId = state.pathParameters['articleId']!;
            return NoTransitionPage(child: ArticleDetailPage(articleId: articleId));
          },
        ),
        GoRoute(
          path: AppRoutes.thixInfoSearch,
          name: 'thixInfoSearch',
          pageBuilder: (context, state) => NoTransitionPage(child: const infoSearch.SearchPage()),
        ),
        GoRoute(
          path: AppRoutes.thixInfoCategory,
          name: 'thixInfoCategory',
          pageBuilder: (context, state) {
            final category = state.pathParameters['category']!;
            return NoTransitionPage(child: CategoryArticlesPage(category: category));
          },
        ),
        GoRoute(
          path: AppRoutes.thixInfoSaved,
          name: 'thixInfoSaved',
          pageBuilder: (context, state) => NoTransitionPage(child: const SavedArticlesPage()),
        ),
        GoRoute(
          path: AppRoutes.thixInfoBreaking,
          name: 'thixInfoBreaking',
          pageBuilder: (context, state) => NoTransitionPage(child: const BreakingNewsPage()),
        ),
        GoRoute(
          path: AppRoutes.thixInfoAdmin,
          name: 'thixInfoAdmin',
          pageBuilder: (context, state) => NoTransitionPage(child: const AdminNewsDashboard()),
        ),
        GoRoute(
          path: AppRoutes.thixInfoCreate,
          name: 'thixInfoCreate',
          pageBuilder: (context, state) => NoTransitionPage(child: const CreateNewsPage()),
        ),

        // ---- THIX Santé ----
        GoRoute(
          path: AppRoutes.thixSante,
          name: 'thixSante',
          pageBuilder: (context, state) => NoTransitionPage(child: ThixSantePage()),
        ),
        GoRoute(
          path: AppRoutes.thixSantePatient,
          name: 'thixSantePatient',
          pageBuilder: (context, state) => NoTransitionPage(child: ThixSanteRolePage(role: ThixRole.patient)),
        ),
        GoRoute(
          path: AppRoutes.thixSanteDoctor,
          name: 'thixSanteDoctor',
          pageBuilder: (context, state) => NoTransitionPage(child: ThixSanteRolePage(role: ThixRole.doctor)),
        ),
        GoRoute(
          path: AppRoutes.thixSantePharmacy,
          name: 'thixSantePharmacy',
          pageBuilder: (context, state) => NoTransitionPage(child: ThixSanteRolePage(role: ThixRole.pharmacy)),
        ),

        // ---- Patient ----
        GoRoute(
          path: '/sante/patient/dashboard',
          name: 'patientDashboard',
          pageBuilder: (context, state) => NoTransitionPage(child: patientDash.PatientDashboardPage()),
        ),
        GoRoute(
          path: '/sante/patient/health',
          name: 'patientHealth',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientHealthPage()),
        ),
        GoRoute(
          path: '/sante/patient/care',
          name: 'patientCare',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientCarePage()),
        ),
        GoRoute(
          path: '/sante/patient/life',
          name: 'patientLife',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientLifePage()),
        ),
        GoRoute(
          path: '/sante/patient/connect',
          name: 'patientConnect',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientConnectPage()),
        ),
        GoRoute(
          path: '/sante/patient/appointments',
          name: 'patientAppointmentsList',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientAppointmentsListPage()),
        ),
        GoRoute(
          path: '/sante/patient/appointment/:id',
          name: 'patientAppointmentDetail',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id'];
            final isEditing = state.uri.queryParameters['edit'] == 'true';
            return NoTransitionPage(child: PatientAppointmentPage(appointmentId: id, isEditing: isEditing));
          },
        ),
        GoRoute(
          path: '/sante/patient/appointment/new',
          name: 'patientAppointmentNew',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientAppointmentPage()),
        ),
        GoRoute(
          path: '/sante/patient/consultation/:id',
          name: 'patientConsultation',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PatientConsultationPage(consultationId: id));
          },
        ),
        GoRoute(
          path: '/sante/patient/prescriptions',
          name: 'patientPrescriptions',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientPrescriptionsListPage()),
        ),
        GoRoute(
          path: '/sante/patient/prescription/:id',
          name: 'patientPrescription',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PatientPrescriptionPage(prescriptionId: id));
          },
        ),
        GoRoute(
          path: '/sante/patient/exams',
          name: 'patientExams',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientExamsListPage()),
        ),
        GoRoute(
          path: '/sante/patient/exam/:id',
          name: 'patientExam',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PatientExamPage(examId: id));
          },
        ),
        GoRoute(
          path: '/sante/patient/scan',
          name: 'patientScan',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientScanPage()),
        ),
        GoRoute(
          path: '/sante/patient/teleconsultation/:id',
          name: 'patientTeleconsultation',
          pageBuilder: (context, state) {
            final link = state.extra as String? ?? 'https://meet.jit.si/default';
            return NoTransitionPage(child: PatientTeleconsultationJitsiPage(link: link));
          },
        ),
        GoRoute(
          path: '/sante/patient/teleconsultation/new',
          name: 'patientTeleconsultationNew',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientTeleconsultationPage()),
        ),
        GoRoute(
          path: '/sante/patient/teleconsultation/:id',
          name: 'patientTeleconsultationDetail',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            final isEditing = state.uri.queryParameters['edit'] == 'true';
            return NoTransitionPage(
              child: PatientTeleconsultationPage(consultationId: id, isEditing: isEditing),
            );
          },
        ),
        GoRoute(
          path: '/sante/patient/teleconsultation/jitsi',
          name: 'patientTeleconsultationJitsi',
          pageBuilder: (context, state) {
            final link = state.extra as String? ?? 'https://meet.jit.si/default';
            return NoTransitionPage(child: PatientTeleconsultationJitsiPage(link: link));
          },
        ),
        GoRoute(
          path: '/sante/patient/health-score',
          name: 'patientHealthScore',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientHealthScorePage()),
        ),
        GoRoute(
          path: '/sante/patient/insurance',
          name: 'patientInsurance',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientInsurancePage()),
        ),
        GoRoute(
          path: '/sante/patient/record',
          name: 'patientRecord',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientRecordPage()),
        ),
        GoRoute(
          path: '/sante/patient/teleexpertise/:id',
          name: 'patientTeleexpertise',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PatientTeleexpertiseDetailPage(expertiseId: id));
          },
        ),
        GoRoute(
          path: '/sante/patient/teleexpertise/request',
          name: 'patientTeleexpertiseRequest',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientTeleexpertiseRequestPage()),
        ),
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
          pageBuilder: (context, state) => NoTransitionPage(child: PatientSymptomPage()),
        ),
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
          pageBuilder: (context, state) => NoTransitionPage(child: PatientVitalPage()),
        ),
        GoRoute(
          path: '/sante/patient/vitals/chart',
          name: 'patientVitalChart',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientVitalChartPage()),
        ),
        GoRoute(
          path: '/sante/patient/record/add',
          name: 'patientRecordAdd',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientRecordAddPage()),
        ),
        GoRoute(
          path: '/sante/patient/medications',
          name: 'patientMedications',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientMedicationsListPage()),
        ),
        GoRoute(
          path: '/sante/patient/medication/:id',
          name: 'patientMedication',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PatientMedicationPage(medicationId: id));
          },
        ),
        GoRoute(
          path: '/sante/patient/medication/new',
          name: 'patientMedicationNew',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientMedicationPage()),
        ),
        GoRoute(
          path: '/sante/patient/medication/:id/reminders',
          name: 'patientMedicationReminders',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PatientMedicationRemindersPage(medicationId: id));
          },
        ),
        GoRoute(
          path: '/sante/patient/vaccinations',
          name: 'patientVaccinations',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientVaccinationCalendarPage()),
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
          pageBuilder: (context, state) => NoTransitionPage(child: PatientVaccinePage()),
        ),
        GoRoute(
          path: '/sante/patient/pregnancy/:id',
          name: 'patientPregnancy',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PatientPregnancyPage(pregnancyId: id));
          },
        ),
        GoRoute(
          path: '/sante/patient/pregnancy/new',
          name: 'patientPregnancyNew',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientPregnancyPage()),
        ),
        GoRoute(
          path: '/sante/patient/pregnancy',
          name: 'patientPregnancyList',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientPregnancyPage()),
        ),
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
          pageBuilder: (context, state) => NoTransitionPage(child: PatientFamilyPage()),
        ),
        GoRoute(
          path: '/sante/patient/family',
          name: 'patientFamilyList',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientFamilyPage()),
        ),
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
          pageBuilder: (context, state) => NoTransitionPage(child: PatientSharingPage()),
        ),
        GoRoute(
          path: '/sante/patient/sharing',
          name: 'patientSharingList',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientSharingPage()),
        ),
        GoRoute(
          path: '/sante/patient/ia',
          name: 'patientIA',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientAIChatPage()),
        ),
        GoRoute(
          path: '/sante/patient/ia/history/:id',
          name: 'patientIAHistory',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PatientAIChatPage(conversationId: id));
          },
        ),
        GoRoute(
          path: '/sante/patient/alerts',
          name: 'patientAlerts',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientAlertPage()),
        ),
        GoRoute(
          path: '/sante/patient/alert/:id',
          name: 'patientAlert',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PatientAlertPage(alertId: id));
          },
        ),
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
            return NoTransitionPage(child: PatientPharmacyDetailPage(pharmacyId: id));
          },
        ),
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
            return NoTransitionPage(child: PatientWellnessPage(programId: id, isTracking: true));
          },
        ),
        GoRoute(
          path: '/sante/patient/consents',
          name: 'patientConsents',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientConsentPage()),
        ),
        GoRoute(
          path: '/sante/patient/consent/:id',
          name: 'patientConsent',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PatientConsentPage(consentId: id));
          },
        ),
        GoRoute(
          path: '/sante/patient/notifications',
          name: 'patientNotifications',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientNotificationsPage()),
        ),
        GoRoute(
          path: '/sante/patient/profile',
          name: 'patientProfile',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientProfilePage()),
        ),
        GoRoute(
          path: '/sante/patient/article/:id',
          name: 'patientArticle',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PatientArticlePage(articleId: id));
          },
        ),
        GoRoute(
          path: '/sante/patient/chat/:id',
          name: 'patientChat',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            final name = state.extra as String?;
            return NoTransitionPage(child: PatientChatPage(chatId: id, recipientName: name));
          },
        ),
        GoRoute(
          path: '/sante/patient/chat/new',
          name: 'patientChatNew',
          pageBuilder: (context, state) => NoTransitionPage(child: PatientChatNewPage()),
        ),

        // ---- Doctor ----
        GoRoute(
          path: '/sante/doctor/dashboard',
          name: 'doctorDashboard',
          pageBuilder: (context, state) => NoTransitionPage(child: DoctorDashboardPage()),
        ),
        GoRoute(
          path: '/sante/doctor/care',
          name: 'doctorCare',
          pageBuilder: (context, state) => NoTransitionPage(child: DoctorCarePage()),
        ),
        GoRoute(
          path: '/sante/doctor/consult',
          name: 'doctorConsult',
          pageBuilder: (context, state) => NoTransitionPage(child: DoctorConsultPage()),
        ),
        GoRoute(
          path: '/sante/doctor/connect',
          name: 'doctorConnect',
          pageBuilder: (context, state) => NoTransitionPage(child: DoctorConnectPage()),
        ),
        GoRoute(
          path: '/sante/doctor/patients',
          name: 'doctorPatients',
          pageBuilder: (context, state) => NoTransitionPage(child: DoctorPatientsPage()),
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
          pageBuilder: (context, state) => NoTransitionPage(child: DoctorPatientAddPage()),
        ),
        GoRoute(
          path: '/sante/doctor/prescription/new',
          name: 'doctorPrescriptionNew',
          pageBuilder: (context, state) => NoTransitionPage(child: DoctorPrescriptionPage()),
        ),
        GoRoute(
          path: '/sante/doctor/prescription/:id',
          name: 'doctorPrescription',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: DoctorPrescriptionPage(prescriptionId: id));
          },
        ),
        GoRoute(
          path: '/sante/doctor/teleconsult',
          name: 'doctorTeleconsult',
          pageBuilder: (context, state) => NoTransitionPage(child: DoctorTeleconsultPage()),
        ),
        GoRoute(
          path: '/sante/doctor/teleconsultation/jitsi',
          name: 'doctorJitsi',
          pageBuilder: (context, state) {
            final link = state.extra as String? ?? 'https://meet.jit.si/default';
            return NoTransitionPage(child: PatientTeleconsultationJitsiPage(link: link));
          },
        ),
        GoRoute(
          path: '/sante/doctor/teleexpertise/:id',
          name: 'doctorTeleexpertise',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: DoctorTeleexpertisePage(requestId: id));
          },
        ),
        GoRoute(
          path: '/sante/doctor/teleexpertise/new',
          name: 'doctorTeleexpertiseNew',
          pageBuilder: (context, state) => NoTransitionPage(child: DoctorTeleexpertisePage()),
        ),
        GoRoute(
          path: '/sante/doctor/agenda',
          name: 'doctorAgenda',
          pageBuilder: (context, state) => NoTransitionPage(child: DoctorAgendaPage()),
        ),
        GoRoute(
          path: '/sante/doctor/agenda/slots',
          name: 'doctorAgendaSlots',
          pageBuilder: (context, state) => NoTransitionPage(child: DoctorSlotManagementPage()),
        ),
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
          pageBuilder: (context, state) => NoTransitionPage(child: DoctorNotePage()),
        ),
        GoRoute(
          path: '/sante/doctor/statistics',
          name: 'doctorStatistics',
          pageBuilder: (context, state) => NoTransitionPage(child: DoctorStatisticsPage()),
        ),
        GoRoute(
          path: '/sante/doctor/terrain/scan',
          name: 'doctorTerrainScan',
          pageBuilder: (context, state) => NoTransitionPage(child: DoctorScanBraceletPage()),
        ),
        GoRoute(
          path: '/sante/doctor/terrain/dictation',
          name: 'doctorTerrainDictation',
          pageBuilder: (context, state) => NoTransitionPage(child: DoctorVoiceDictationPage()),
        ),
        GoRoute(
          path: '/sante/doctor/terrain/offline',
          name: 'doctorTerrainOffline',
          pageBuilder: (context, state) => NoTransitionPage(child: DoctorOfflinePatientsPage()),
        ),
        GoRoute(
          path: '/sante/doctor/terrain/photo',
          name: 'doctorTerrainPhoto',
          pageBuilder: (context, state) => NoTransitionPage(child: DoctorPhotoCapturePage()),
        ),
        GoRoute(
          path: '/sante/doctor/messages/:id',
          name: 'doctorChat',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            final name = state.extra as String?;
            return NoTransitionPage(child: DoctorChatPage(chatId: id, participantName: name));
          },
        ),
        GoRoute(
          path: '/sante/doctor/messages/new',
          name: 'doctorChatNew',
          pageBuilder: (context, state) => NoTransitionPage(child: DoctorChatPage(chatId: '')),
        ),
        GoRoute(
          path: '/sante/doctor/alerts',
          name: 'doctorAlerts',
          pageBuilder: (context, state) => NoTransitionPage(child: DoctorAlertPage()),
        ),
        GoRoute(
          path: '/sante/doctor/alert/:patientName',
          name: 'doctorAlertPatient',
          pageBuilder: (context, state) {
            final name = state.pathParameters['patientName']!;
            return NoTransitionPage(child: DoctorAlertPage(patientName: name));
          },
        ),

        // ---- Pharmacy ----
        GoRoute(
          path: '/sante/pharmacy/dashboard',
          name: 'pharmacyDashboard',
          pageBuilder: (context, state) => NoTransitionPage(child: PharmacyDashboardPage()),
        ),
        GoRoute(
          path: '/sante/pharmacy/orders',
          name: 'pharmacyOrders',
          pageBuilder: (context, state) => NoTransitionPage(child: PharmacyOrdersPage()),
        ),
        GoRoute(
          path: '/sante/pharmacy/inventory',
          name: 'pharmacyInventory',
          pageBuilder: (context, state) => NoTransitionPage(child: PharmacyInventoryPage()),
        ),
        GoRoute(
          path: '/sante/pharmacy/connect',
          name: 'pharmacyConnect',
          pageBuilder: (context, state) => NoTransitionPage(child: PharmacyConnectPage()),
        ),
        GoRoute(
          path: '/sante/pharmacy/order/:id',
          name: 'pharmacyOrder',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PharmacyOrderPage(orderId: id));
          },
        ),
        GoRoute(
          path: '/sante/pharmacy/order/new',
          name: 'pharmacyOrderNew',
          pageBuilder: (context, state) => NoTransitionPage(child: PharmacyOrderPage(orderId: '')),
        ),
        GoRoute(
          path: '/sante/pharmacy/prescription/:id',
          name: 'pharmacyPrescription',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PharmacyPrescriptionPage(prescriptionId: id));
          },
        ),
        GoRoute(
          path: '/sante/pharmacy/dispensing',
          name: 'pharmacyDispensing',
          pageBuilder: (context, state) => NoTransitionPage(child: PharmacyDispensingPage()),
        ),
        GoRoute(
          path: '/sante/pharmacy/delivery',
          name: 'pharmacyDelivery',
          pageBuilder: (context, state) => NoTransitionPage(child: PharmacyDeliveryPage()),
        ),
        GoRoute(
          path: '/sante/pharmacy/inventory/item/:id',
          name: 'pharmacyInventoryItem',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PharmacyInventoryItemPage(itemId: id));
          },
        ),
        GoRoute(
          path: '/sante/pharmacy/inventory/item/new',
          name: 'pharmacyInventoryItemNew',
          pageBuilder: (context, state) => NoTransitionPage(child: PharmacyInventoryItemPage()),
        ),
        GoRoute(
          path: '/sante/pharmacy/stock',
          name: 'pharmacyStock',
          pageBuilder: (context, state) => NoTransitionPage(child: PharmacyStockPage()),
        ),
        GoRoute(
          path: '/sante/pharmacy/report',
          name: 'pharmacyReport',
          pageBuilder: (context, state) => NoTransitionPage(child: PharmacyReportPage()),
        ),
        GoRoute(
          path: '/sante/pharmacy/chat/:id',
          name: 'pharmacyChat',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            final name = state.extra as String?;
            return NoTransitionPage(child: PharmacyChatPage(chatId: id, participantName: name));
          },
        ),
        GoRoute(
          path: '/sante/pharmacy/chat/new',
          name: 'pharmacyChatNew',
          pageBuilder: (context, state) => NoTransitionPage(child: PharmacyChatPage(chatId: '')),
        ),
        GoRoute(
          path: '/sante/pharmacy/products',
          name: 'pharmacyProducts',
          pageBuilder: (context, state) => NoTransitionPage(child: PharmacyProductsPage()),
        ),
        GoRoute(
          path: '/sante/pharmacy/product/:id',
          name: 'pharmacyProductDetail',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PharmacyProductDetailPage(productId: id));
          },
        ),
        GoRoute(
          path: '/sante/pharmacy/cart',
          name: 'pharmacyCart',
          pageBuilder: (context, state) => NoTransitionPage(child: PharmacyCartPage()),
        ),

        // ---- THIX Money, Media, Reservation ----
        GoRoute(
          path: AppRoutes.thixMoney,
          name: 'thixMoney',
          pageBuilder: (context, state) => NoTransitionPage(child: ThixMoneyPage()),
        ),
        GoRoute(
          path: AppRoutes.thixMedia,
          name: 'thixMedia',
          pageBuilder: (context, state) => NoTransitionPage(child: ThixMediaPage()),
        ),
        GoRoute(
          path: AppRoutes.thixMediaVideo,
          name: 'thixMediaVideo',
          pageBuilder: (context, state) {
            final title = (state.uri.queryParameters['title'] ?? '').trim();
            final url = (state.uri.queryParameters['url'] ?? '').trim();
            return NoTransitionPage(
              child: VideoPlayerPage(title: title.isEmpty ? 'Lecture vidéo' : title, videoUrl: url),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.reservation,
          name: 'reservation',
          pageBuilder: (context, state) => NoTransitionPage(child: ThixReservationPage()),
        ),

        // ---- THIX Événement ----
        GoRoute(
          path: AppRoutes.thixEvent,
          name: 'thixEvent',
          pageBuilder: (context, state) => NoTransitionPage(child: ThixEventHome()),
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
          pageBuilder: (context, state) => NoTransitionPage(child: EventSearchPage()),
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
          pageBuilder: (context, state) => NoTransitionPage(child: MyTicketsPage()),
        ),
        GoRoute(
          path: AppRoutes.thixEventFavorites,
          name: 'thixEventFavorites',
          pageBuilder: (context, state) => NoTransitionPage(child: FavoriteEventsPage()),
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

        // ---- Jobs & Opportunités ----
        GoRoute(
          path: AppRoutes.jobs,
          name: 'jobs',
          pageBuilder: (context, state) => NoTransitionPage(child: JobsPage()),
        ),
        GoRoute(
          path: AppRoutes.jobDashboard,
          name: 'jobDashboard',
          pageBuilder: (context, state) => NoTransitionPage(child: JobDashboardPage()),
        ),
        GoRoute(
          path: AppRoutes.recruiter,
          name: 'recruiter',
          pageBuilder: (context, state) => NoTransitionPage(child: RecruiterPortalPage()),
        ),
        GoRoute(
          path: AppRoutes.opportunities,
          name: 'opportunities',
          pageBuilder: (context, state) => NoTransitionPage(child: OpportunitiesPage()),
        ),
        GoRoute(
          path: '/opportunities/:opportunityId',
          name: 'opportunityDetails',
          pageBuilder: (context, state) {
            final opportunityId = state.pathParameters['opportunityId'] ?? '';
            final applied = (state.uri.queryParameters['applied'] ?? '').trim() == '1';
            return NoTransitionPage(
              child: OpportunityDetailsPage(opportunityId: opportunityId, applied: applied),
            );
          },
        ),
        GoRoute(
          path: '/opportunities/:opportunityId/apply',
          name: 'opportunityApply',
          pageBuilder: (context, state) {
            final opportunityId = state.pathParameters['opportunityId'] ?? '';
            return NoTransitionPage(child: OpportunityApplyPage(opportunityId: opportunityId));
          },
        ),
        GoRoute(
          path: '/jobs/:jobId',
          name: 'jobDetails',
          pageBuilder: (context, state) {
            final jobId = state.pathParameters['jobId'] ?? '';
            final applied = (state.uri.queryParameters['applied'] ?? '').trim() == '1';
            return NoTransitionPage(child: JobDetailsPage(jobId: jobId, applied: applied));
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

        // ---- Éducation (importée) ----
        ...educationRoutes,
        ...instructorRoutes,

        // ---- Modérateur ----
        GoRoute(
          path: '/moderator',
          name: 'moderatorHome',
          builder: (context, state) {
            final authProvider = context.read<AuthProvider>();
            if (!authProvider.isModerator) return const ThixEventHome();
            return const ModeratorHome();
          },
          routes: [
            GoRoute(
              path: 'events',
              name: 'moderatorEvents',
              builder: (context, state) => const ModeratorEventList(),
            ),
            GoRoute(
              path: 'event/create',
              name: 'moderatorEventCreate',
              builder: (context, state) => const ModeratorEventForm(),
            ),
            GoRoute(
              path: 'event/edit/:id',
              name: 'moderatorEventEdit',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return ModeratorEventForm(eventId: id);
              },
            ),
          ],
        ),

        // ---- Admin ----
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
          redirect: (_, __) => '${AppRoutes.admin}/${AdminModule.overview.slug}',
        ),
        GoRoute(
          path: AppRoutes.adminMedia,
          name: 'adminMedia',
          pageBuilder: (context, state) => NoTransitionPage(child: AdminMediaPage()),
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
