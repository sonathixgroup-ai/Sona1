// lib/app_router.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/nav.dart' show AppRoutes;

// Pages générales
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
import 'presentation/vault/document_vault_page.dart';
import 'presentation/settings/settings_page.dart';

// Réseau Pro
import 'package:thix_id/presentation/network/network_pro_home.dart';
import 'package:thix_id/presentation/network/search_network_page.dart';
import 'package:thix_id/presentation/network/notifications/notifications_page.dart';
import 'package:thix_id/presentation/network/messages/conversations_list.dart';
import 'package:thix_id/presentation/network/messages/chat_screen.dart' as network_chat;
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

// Jobs, Opportunités
import 'presentation/jobs/jobs_page.dart';
import 'package:thix_id/presentation/jobs/job_apply_page.dart';
import 'package:thix_id/presentation/jobs/job_details_page.dart';
import 'package:thix_id/presentation/jobs/job_dashboard_page.dart';
import 'package:thix_id/presentation/recruiter/recruiter_portal_page.dart';
import 'package:thix_id/presentation/opportunities/opportunities_page.dart';
import 'package:thix_id/presentation/opportunities/opportunity_apply_page.dart';
import 'package:thix_id/presentation/opportunities/opportunity_details_page.dart';

// Admin
import 'package:thix_id/presentation/admin/admin_page.dart';
import 'package:thix_id/presentation/admin/admin_routes.dart';

// THIX Market
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

// THIX Info
import 'package:thix_id/presentation/thix_info/thix_info_home.dart';
import 'package:thix_id/presentation/thix_info/article_detail_page.dart';
import 'package:thix_id/presentation/thix_info/search_page.dart' as infoSearch;
import 'package:thix_id/presentation/thix_info/category_articles_page.dart';
import 'package:thix_id/presentation/thix_info/saved_articles_page.dart';
import 'package:thix_id/presentation/thix_info/breaking_news_page.dart';
import 'package:thix_id/presentation/admin/pages/admin_news_dashboard.dart';
import 'package:thix_id/presentation/admin/pages/create_news_page.dart';

// THIX Santé
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

// THIX Événement
import 'package:thix_id/presentation/thix_event/thix_event_home.dart';
import 'package:thix_id/presentation/thix_event/event_detail_page.dart';
import 'package:thix_id/presentation/thix_event/event_search_page.dart';
import 'package:thix_id/presentation/thix_event/event_category_page.dart';
import 'package:thix_id/presentation/thix_event/event_reservation_page.dart';
import 'package:thix_id/presentation/thix_event/my_tickets_page.dart';
import 'package:thix_id/presentation/thix_event/favorite_events_page.dart';
import 'package:thix_id/presentation/thix_event/seat_selection_page.dart';
import 'package:thix_id/presentation/thix_event/waiting_queue_page.dart';

// Modérateur
import 'package:thix_id/presentation/moderator/moderator_home.dart';
import 'package:thix_id/presentation/moderator/moderator_event_list.dart';
import 'package:thix_id/presentation/moderator/moderator_event_form.dart';
import 'package:thix_id/providers/auth_provider.dart';

// Éducation
import 'package:thix_id/presentation/education/education_routes.dart';

// THIX Money, Media, Reservation
import 'package:thix_id/presentation/thix_money/thix_money_page.dart';
import 'package:thix_id/presentation/thix_media/thix_media_page.dart';
import 'package:thix_id/presentation/thix_media/video_player_page.dart';
import 'package:thix_id/presentation/thix_reservation/thix_reservation_page.dart';
import 'package:thix_id/presentation/admin/pages/admin_media_page.dart';
import 'package:thix_id/presentation/splash/thix_id_start_page.dart';

// ---- THIX Chat ----
import 'package:thix_id/models/chat/chat_conversation.dart';
import 'package:thix_id/presentation/chat/chat_list_page.dart';
import 'package:thix_id/presentation/chat/chat_screen.dart' as ThixChat;
import 'package:thix_id/presentation/chat/new_conversation_page.dart';
import 'package:thix_id/presentation/chat/screens/group_create_page.dart';
import 'package:thix_id/presentation/chat/screens/group_info_page.dart';
import 'package:thix_id/presentation/chat/screens/group_settings_page.dart';

// ===== MON PAYS =====
import 'presentation/mon_pays/mon_pays_page.dart';
import 'presentation/mon_pays/pages/authorities/authorities_page.dart';
import 'presentation/mon_pays/pages/authorities/authority_profile_page.dart';
import 'presentation/mon_pays/admin/admin_authorities_page.dart';
import 'presentation/mon_pays/admin/admin_authority_form_page.dart';


// ==================== TRANSITION SANS ANIMATION ====================
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

/// ==================== ROUTER ====================
class AppRouter {
  static GoRouter create(AuthController auth, {Listenable? extraRefreshListenable}) {
    final refresh = extraRefreshListenable ?? auth;
    return GoRouter(
      initialLocation: AppRoutes.home,
      refreshListenable: refresh,
      
      // ⬇️ LE NOUVEAU REDIRECT SE PLACE ICI, JUSTE AVANT "routes: [" ⬇️
      redirect: (context, state) {
        final loc = state.matchedLocation;
        final logged = auth.isAuthenticated;
        final isAuth = loc == AppRoutes.login || loc == AppRoutes.personalReg || loc == AppRoutes.enterpriseReg;
        final isAdmin = loc == AppRoutes.admin || loc.startsWith('${AppRoutes.admin}/');
        final isPortal = loc.startsWith('${AppRoutes.enterprisePortalBasePath}/') || loc == AppRoutes.enterprisePortalBasePath;
        
        // C'EST ICI QUE ÇA CHANGE : Ajout de loc.startsWith(AppRoutes.monPays)
        final isPublic = loc == AppRoutes.start || loc == AppRoutes.home || loc == AppRoutes.publicProfile ||
            loc == AppRoutes.jobs || loc == AppRoutes.opportunities || loc == AppRoutes.education ||
            loc == AppRoutes.trainingHome || loc.startsWith('${AppRoutes.trainingDetailsBasePath}/') || 
            loc == AppRoutes.monPays || loc.startsWith('${AppRoutes.monPays}/'); 

        if (!logged && !isPublic && !isAuth) return AppRoutes.login;
        if (isAdmin && !logged) return AppRoutes.login;
        if (logged) {
          final t = auth.currentUser?.accountType;
          if (loc == AppRoutes.userDashboard && t == AccountType.enterprise) return AppRoutes.enterpriseDashboard;
          if (loc == AppRoutes.enterpriseDashboard && t == AccountType.personal) return AppRoutes.userDashboard;
        }
        if (logged && isAuth) {
          return auth.currentUser?.accountType == AccountType.enterprise ? AppRoutes.enterpriseDashboard : AppRoutes.userDashboard;
        }
        if (isPortal) return null;
        return null;
      },

      routes: [
        // ---- Générales ----
        GoRoute(path: AppRoutes.start, name: 'start', pageBuilder: (_, __) => NoTransitionPage(child: ThixIdStartPage())),
        GoRoute(path: AppRoutes.home, name: 'home', pageBuilder: (_, __) => NoTransitionPage(child: HomePagePremium())),
        GoRoute(path: AppRoutes.login, name: 'login', pageBuilder: (_, __) => NoTransitionPage(child: LoginPage())),
        GoRoute(path: AppRoutes.personalReg, name: 'personalReg', pageBuilder: (_, state) {
          final step = int.tryParse(state.uri.queryParameters['step'] ?? '') ?? 1;
          return NoTransitionPage(child: PersonalRegistrationPage(initialStep: step));
        }),
        GoRoute(path: AppRoutes.enterpriseReg, name: 'enterpriseReg', pageBuilder: (_, __) => NoTransitionPage(child: EnterpriseRegistrationPage())),
        GoRoute(path: AppRoutes.payment, name: 'payment', pageBuilder: (_, state) {
          return NoTransitionPage(child: PaymentGatewayPage(returnTo: state.uri.queryParameters['returnTo']));
        }),
        GoRoute(path: AppRoutes.activationReceipt, name: 'activationReceipt', pageBuilder: (_, state) {
          final qp = state.uri.queryParameters;
          return NoTransitionPage(child: ActivationReceiptPage(
            txRef: qp['txRef'], method: qp['method'], amount: qp['amount'],
            currency: qp['currency'], paidAt: DateTime.tryParse(qp['paidAt'] ?? '')
          ));
        }),
        GoRoute(path: AppRoutes.publicProfile, name: 'publicProfile', pageBuilder: (_, state) {
          return NoTransitionPage(child: PublicProfilePage(initialThixId: state.uri.queryParameters['thixId']));
        }),
        GoRoute(path: AppRoutes.userDashboard, name: 'userDashboard', pageBuilder: (_, __) => NoTransitionPage(child: UserDashboardPage())),
        GoRoute(path: AppRoutes.enterpriseDashboard, name: 'enterpriseDashboard', pageBuilder: (_, __) => NoTransitionPage(child: EnterpriseDashboardPage())),
        GoRoute(path: AppRoutes.enterprise, name: 'enterpriseEntry', redirect: (_, __) {
          if (!auth.isAuthenticated) return AppRoutes.login;
          return auth.currentUser?.accountType == AccountType.enterprise ? AppRoutes.enterpriseDashboard : AppRoutes.enterpriseReg;
        }),
        GoRoute(path: '/entreprise/:slug', name: 'enterprisePortalAliasFr', redirect: (_, state) {
          final slug = state.pathParameters['slug']!;
          return '${AppRoutes.enterprisePortalBase(slug)}/dashboard/overview';
        }),
        GoRoute(path: '${AppRoutes.enterprisePortalBasePath}/:slug', name: 'enterprisePortal', pageBuilder: (_, state) {
          final slug = state.pathParameters['slug']!;
          return NoTransitionPage(child: EnterprisePortalPage(companySlug: slug));
        }, routes: [
          GoRoute(path: 'dashboard/:section', name: 'enterprisePortalDashboard', pageBuilder: (_, state) {
            final slug = state.pathParameters['slug']!;
            final section = state.pathParameters['section'] ?? 'overview';
            return NoTransitionPage(child: EnterpriseDashboardShellPage(companySlug: slug, section: section));
          }),
          GoRoute(path: 'dashboard', name: 'enterprisePortalDashboardRoot', redirect: (_, state) {
            final slug = state.pathParameters['slug']!;
            return '${AppRoutes.enterprisePortalBase(slug)}/dashboard/overview';
          }),
        ]),

        // ---- THIX Chat ----
        GoRoute(
          path: AppRoutes.chat,
          name: 'chat',
          pageBuilder: (_, __) => const NoTransitionPage(child: ChatListPage()),
        ),
        GoRoute(
          path: AppRoutes.chatNew, 
          name: 'chat_new',
          pageBuilder: (_, __) => const NoTransitionPage(child: NewConversationPage()),
        ),
        GoRoute(
          path: AppRoutes.chatConversation,
          name: 'chat_conversation',
          pageBuilder: (_, state) {
            final convId = state.pathParameters['conversationId']!;
            final conv = state.extra as ChatConversation? ??
                ChatConversation(id: convId, isGroup: false, participantIds: [], updatedAt: DateTime.now());
                
            return NoTransitionPage(
              child: ThixChat.ChatScreen(
                conversationId: convId, 
                conversation: conv
              ),
            );
          },
        ),

        // ─── Groupes ───
        GoRoute(
          path: AppRoutes.groupCreate,
          name: 'group_create',
          builder: (context, state) => const GroupCreatePage(),
        ),
        GoRoute(
          path: AppRoutes.groupInfo,
          name: 'group_info',
          builder: (context, state) {
            final groupId = state.pathParameters['groupId']!;
            return GroupInfoPage(groupId: groupId);
          },
        ),
        GoRoute(
          path: AppRoutes.groupSettings,
          name: 'group_settings',
          builder: (context, state) {
            final groupId = state.pathParameters['groupId']!;
            return GroupSettingsPage(groupId: groupId);
          },
        ),

        // ---- Vault & Settings ----
        GoRoute(path: AppRoutes.vault, name: 'document-vault', pageBuilder: (_, __) => NoTransitionPage(child: DocumentVaultPage())),
        GoRoute(path: AppRoutes.settings, name: 'settings', pageBuilder: (_, __) => NoTransitionPage(child: SettingsPage())),

        // ---- Réseau Pro ----
        GoRoute(path: AppRoutes.network, name: 'network', pageBuilder: (_, __) => NoTransitionPage(child: NetworkProHome())),
        GoRoute(path: AppRoutes.networkSearch, name: 'networkSearch', pageBuilder: (_, __) => NoTransitionPage(child: SearchNetworkPage())),
        GoRoute(path: AppRoutes.networkNotifications, name: 'networkNotifications', pageBuilder: (_, __) => NoTransitionPage(child: NotificationsPage())),
        GoRoute(path: AppRoutes.networkMessages, name: 'networkMessages', pageBuilder: (_, __) => NoTransitionPage(child: ConversationsList())),
        GoRoute(path: '${AppRoutes.networkChatBasePath}/:userId', name: 'networkChat', pageBuilder: (_, state) {
          final uid = state.pathParameters['userId']!;
          final extra = state.extra;
          String name = 'Discussion';
          String? avatar;
          if (extra is String) name = extra;
          else if (extra is Map) {
            name = extra['userName'] as String? ?? name;
            avatar = extra['userAvatar'] as String?;
          }
          return NoTransitionPage(child: network_chat.ChatScreen(userId: uid, userName: name, userAvatar: avatar));
        }),
        GoRoute(path: AppRoutes.networkConnections, name: 'networkConnections', pageBuilder: (_, __) => NoTransitionPage(child: ConnectionsListPage())),
        GoRoute(path: AppRoutes.networkProfileSettings, name: 'networkProfileSettings', pageBuilder: (_, __) => NoTransitionPage(child: ProfileSettingsPage())),
        GoRoute(path: AppRoutes.networkBlockedUsers, name: 'networkBlockedUsers', pageBuilder: (_, __) => NoTransitionPage(child: BlockedUsersPage())),
        GoRoute(path: '/network/discover', name: 'networkDiscover', pageBuilder: (_, __) => NoTransitionPage(child: const DiscoverTab())),
        GoRoute(path: '/network/communities', name: 'networkCommunities', pageBuilder: (_, __) => NoTransitionPage(child: const CommunitiesListPage())),
        GoRoute(path: '/network/community/create', name: 'networkCommunityCreate', pageBuilder: (_, __) => NoTransitionPage(child: const CreateCommunityPage())),
        GoRoute(path: '${AppRoutes.networkCommunityBasePath}/:communityId', name: 'networkCommunityDetail', pageBuilder: (_, state) {
          return NoTransitionPage(child: CommunityDetailPage(communityId: state.pathParameters['communityId']!));
        }),
        GoRoute(path: '/network/story/:storyId', name: 'networkStoryViewer', pageBuilder: (_, state) {
          return NoTransitionPage(child: StoryViewerScreen(storyId: state.pathParameters['storyId']!));
        }),
        GoRoute(path: '/network/comments/:postId', name: 'networkComments', pageBuilder: (_, state) {
          final postId = state.pathParameters['postId']!;
          final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
          return NoTransitionPage(child: CommentsPage(postId: postId, currentProfileId: uid));
        }),
        GoRoute(path: '/network/hashtag/:tag', name: 'networkHashtag', pageBuilder: (_, state) {
          return NoTransitionPage(child: HashtagPage(tag: state.pathParameters['tag']!));
        }),
        GoRoute(path: '${AppRoutes.networkPostBasePath}/:postId', name: 'networkPostDetail', pageBuilder: (_, state) {
          return NoTransitionPage(child: PostDetailPage(postId: state.pathParameters['postId']!));
        }),
        GoRoute(path: '${AppRoutes.networkProfileBasePath}/:userId', name: 'networkProfile', pageBuilder: (_, state) {
          final uid = state.pathParameters['userId']!;
          final current = Supabase.instance.client.auth.currentUser?.id ?? '';
          return NoTransitionPage(child: ProfilePage(userId: uid, currentProfileId: current));
        }),
        GoRoute(path: AppRoutes.profile, name: 'profile', pageBuilder: (_, __) => NoTransitionPage(child: ProfilePage())),

        // ---- THIX Market ----
        GoRoute(
          path: AppRoutes.thixMarket,
          name: 'thixMarket',
          pageBuilder: (_, __) => NoTransitionPage(child: const MarketHomePage()),
          routes: [
            GoRoute(path: 'home', name: 'marketHome', pageBuilder: (_, __) => NoTransitionPage(child: const MarketHomePage())),
            GoRoute(path: 'search', name: 'marketSearch', pageBuilder: (_, __) => NoTransitionPage(child: const marketSearch.SearchPage())),
            GoRoute(path: 'shops', name: 'marketShops', pageBuilder: (_, __) => NoTransitionPage(child: const ShopsPage())),
            GoRoute(path: 'buy', name: 'marketBuy', pageBuilder: (_, __) => NoTransitionPage(child: const BuyPage())),
            GoRoute(path: 'sell', name: 'marketSell', pageBuilder: (_, __) => NoTransitionPage(child: const SellPage())),
            GoRoute(path: 'messages', name: 'marketMessages', pageBuilder: (_, __) => NoTransitionPage(child: const MessagesPage())),
            GoRoute(path: 'live', name: 'marketLive', pageBuilder: (_, __) => NoTransitionPage(child: const LivePage())),
            GoRoute(path: 'activity', name: 'marketActivity', pageBuilder: (_, __) => NoTransitionPage(child: const MyActivityPage())),
            GoRoute(path: 'settings', name: 'marketSettings', pageBuilder: (_, __) => NoTransitionPage(child: const MarketSettingsPage())),
            GoRoute(path: 'help', name: 'marketHelp', pageBuilder: (_, __) => NoTransitionPage(child: const HelpSupportPage())),
            GoRoute(path: 'product/:productId', name: 'marketProductDetail', pageBuilder: (_, state) {
              return NoTransitionPage(child: ProductDetailPage(productId: state.pathParameters['productId']!));
            }),
            GoRoute(path: 'shop/:shopId', name: 'marketShopDetail', pageBuilder: (_, state) {
              return NoTransitionPage(child: ShopDetailPage(shopId: state.pathParameters['shopId']!));
            }),
            GoRoute(path: 'compare', name: 'marketProductComparator', pageBuilder: (_, __) => NoTransitionPage(child: const ProductComparatorPage())),
            GoRoute(path: 'price-alerts', name: 'marketPriceAlerts', pageBuilder: (_, __) => NoTransitionPage(child: const PriceAlertsPage())),
            GoRoute(path: 'cart', name: 'marketCart', pageBuilder: (_, __) => NoTransitionPage(child: const CartPage())),
            GoRoute(path: 'checkout', name: 'marketCheckout', pageBuilder: (_, __) => NoTransitionPage(child: const CheckoutPage())),
            GoRoute(path: 'orders', name: 'marketOrders', pageBuilder: (_, __) => NoTransitionPage(child: const OrderHistoryPage())),
            GoRoute(path: 'order/:orderId', name: 'marketOrderDetail', pageBuilder: (_, state) {
              return NoTransitionPage(child: OrderDetailPage(orderId: state.pathParameters['orderId']!));
            }),
            GoRoute(path: 'chat/:shopId', name: 'marketChatSeller', pageBuilder: (_, state) {
              final shopId = state.pathParameters['shopId']!;
              final extra = state.extra as Map?;
              return NoTransitionPage(child: ChatPage(
                conversationId: '',
                shopId: shopId,
                title: extra?['title'] ?? 'Vendeur',
                avatar: extra?['userAvatar'] as String?,
              ));
            }),
            GoRoute(path: 'shop/create', name: 'marketCreateShop', pageBuilder: (_, __) => NoTransitionPage(child: const CreateShopPage())),
            GoRoute(path: 'shop/:shopId/manage', name: 'marketManageShop', pageBuilder: (_, state) {
              return NoTransitionPage(child: ManageShopPage(shopId: state.pathParameters['shopId']!));
            }),
            GoRoute(path: 'shop/:shopId/stats', name: 'marketShopStats', pageBuilder: (_, state) {
              return NoTransitionPage(child: ShopStatisticsPage(shopId: state.pathParameters['shopId']!));
            }),
            GoRoute(path: 'announcement/publish', name: 'marketPublishAnnouncement', pageBuilder: (_, __) => NoTransitionPage(child: const PublishAnnouncementPage())),
            GoRoute(path: 'vendor/dashboard', name: 'vendorDashboard', pageBuilder: (_, __) => NoTransitionPage(child: const VendorDashboard())),
            GoRoute(path: 'deliveries', name: 'deliveryManagement', pageBuilder: (_, __) => NoTransitionPage(child: const DeliveryManagementPage())),
            GoRoute(path: 'announcement/:announcementId/edit', name: 'marketEditAnnouncement', pageBuilder: (_, state) {
              return NoTransitionPage(child: EditAnnouncementPage(announcementId: state.pathParameters['announcementId']!));
            }),
            GoRoute(path: 'live/:liveId', name: 'marketLiveStream', pageBuilder: (_, state) {
              return NoTransitionPage(child: LiveStreamPage(liveId: state.pathParameters['liveId']!));
            }),
            GoRoute(path: 'live/create', name: 'marketCreateLive', pageBuilder: (_, __) => NoTransitionPage(child: const CreateLivePage())),
            GoRoute(path: 'live/:liveId/replay', name: 'marketLiveReplay', pageBuilder: (_, state) {
              return NoTransitionPage(child: LiveReplayPage(liveId: state.pathParameters['liveId']!));
            }),
            GoRoute(path: 'auction/:auctionId', name: 'marketAuction', pageBuilder: (_, state) {
              return NoTransitionPage(child: AuctionPage(auctionId: state.pathParameters['auctionId']!));
            }),
            GoRoute(path: 'chat/:conversationId', name: 'marketChat', pageBuilder: (_, state) {
              return NoTransitionPage(child: ChatPage(conversationId: state.pathParameters['conversationId']!));
            }),
            GoRoute(path: 'dispute/:disputeId', name: 'marketDispute', pageBuilder: (_, state) {
              return NoTransitionPage(child: DisputeDetailPage(disputeId: state.pathParameters['disputeId']!));
            }),
            GoRoute(path: 'notifications', name: 'marketNotifications', pageBuilder: (_, __) => NoTransitionPage(child: const NotificationPage())),
          ],
        ),

        // ---- THIX Info ----
        GoRoute(path: AppRoutes.thixInfo, name: 'thixInfo', pageBuilder: (_, __) => NoTransitionPage(child: const ThixInfoHome())),
        GoRoute(path: AppRoutes.thixInfoArticle, name: 'thixInfoArticle', pageBuilder: (_, state) {
          return NoTransitionPage(child: ArticleDetailPage(articleId: state.pathParameters['articleId']!));
        }),
        GoRoute(path: AppRoutes.thixInfoSearch, name: 'thixInfoSearch', pageBuilder: (_, __) => NoTransitionPage(child: const infoSearch.SearchPage())),
        GoRoute(path: AppRoutes.thixInfoCategory, name: 'thixInfoCategory', pageBuilder: (_, state) {
          return NoTransitionPage(child: CategoryArticlesPage(category: state.pathParameters['category']!));
        }),
        GoRoute(path: AppRoutes.thixInfoSaved, name: 'thixInfoSaved', pageBuilder: (_, __) => NoTransitionPage(child: const SavedArticlesPage())),
        GoRoute(path: AppRoutes.thixInfoBreaking, name: 'thixInfoBreaking', pageBuilder: (_, __) => NoTransitionPage(child: const BreakingNewsPage())),
        GoRoute(path: AppRoutes.thixInfoAdmin, name: 'thixInfoAdmin', pageBuilder: (_, __) => NoTransitionPage(child: const AdminNewsDashboard())),
        GoRoute(path: AppRoutes.thixInfoCreate, name: 'thixInfoCreate', pageBuilder: (_, __) => NoTransitionPage(child: const CreateNewsPage())),

        // ---- THIX Santé ----
        GoRoute(path: AppRoutes.thixSante, name: 'thixSante', pageBuilder: (_, __) => NoTransitionPage(child: ThixSantePage())),
        GoRoute(path: AppRoutes.thixSantePatient, name: 'thixSantePatient', pageBuilder: (_, __) => NoTransitionPage(child: ThixSanteRolePage(role: ThixRole.patient))),
        GoRoute(path: AppRoutes.thixSanteDoctor, name: 'thixSanteDoctor', pageBuilder: (_, __) => NoTransitionPage(child: ThixSanteRolePage(role: ThixRole.doctor))),
        GoRoute(path: AppRoutes.thixSantePharmacy, name: 'thixSantePharmacy', pageBuilder: (_, __) => NoTransitionPage(child: ThixSanteRolePage(role: ThixRole.pharmacy))),

        // ---- Patient ----
        GoRoute(path: '/sante/patient/dashboard', name: 'patientDashboard', pageBuilder: (_, __) => NoTransitionPage(child: patientDash.PatientDashboardPage())),
        GoRoute(path: '/sante/patient/health', name: 'patientHealth', pageBuilder: (_, __) => NoTransitionPage(child: PatientHealthPage())),
        GoRoute(path: '/sante/patient/care', name: 'patientCare', pageBuilder: (_, __) => NoTransitionPage(child: PatientCarePage())),
        GoRoute(path: '/sante/patient/life', name: 'patientLife', pageBuilder: (_, __) => NoTransitionPage(child: PatientLifePage())),
        GoRoute(path: '/sante/patient/connect', name: 'patientConnect', pageBuilder: (_, __) => NoTransitionPage(child: PatientConnectPage())),
        GoRoute(path: '/sante/patient/appointments', name: 'patientAppointmentsList', pageBuilder: (_, __) => NoTransitionPage(child: PatientAppointmentsListPage())),
        GoRoute(path: '/sante/patient/appointment/:id', name: 'patientAppointmentDetail', pageBuilder: (_, state) {
          final id = state.pathParameters['id'];
          final edit = state.uri.queryParameters['edit'] == 'true';
          return NoTransitionPage(child: PatientAppointmentPage(appointmentId: id, isEditing: edit));
        }),
        GoRoute(path: '/sante/patient/appointment/new', name: 'patientAppointmentNew', pageBuilder: (_, __) => NoTransitionPage(child: PatientAppointmentPage())),
        GoRoute(path: '/sante/patient/consultation/:id', name: 'patientConsultation', pageBuilder: (_, state) {
          return NoTransitionPage(child: PatientConsultationPage(consultationId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/patient/prescriptions', name: 'patientPrescriptions', pageBuilder: (_, __) => NoTransitionPage(child: PatientPrescriptionsListPage())),
        GoRoute(path: '/sante/patient/prescription/:id', name: 'patientPrescription', pageBuilder: (_, state) {
          return NoTransitionPage(child: PatientPrescriptionPage(prescriptionId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/patient/exams', name: 'patientExams', pageBuilder: (_, __) => NoTransitionPage(child: PatientExamsListPage())),
        GoRoute(path: '/sante/patient/exam/:id', name: 'patientExam', pageBuilder: (_, state) {
          return NoTransitionPage(child: PatientExamPage(examId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/patient/scan', name: 'patientScan', pageBuilder: (_, __) => NoTransitionPage(child: PatientScanPage())),
        GoRoute(path: '/sante/patient/teleconsultation/:id', name: 'patientTeleconsultation', pageBuilder: (_, state) {
          final link = state.extra as String? ?? 'https://meet.jit.si/default';
          return NoTransitionPage(child: PatientTeleconsultationJitsiPage(link: link));
        }),
        GoRoute(path: '/sante/patient/teleconsultation/new', name: 'patientTeleconsultationNew', pageBuilder: (_, __) => NoTransitionPage(child: PatientTeleconsultationPage())),
        GoRoute(path: '/sante/patient/teleconsultation/:id', name: 'patientTeleconsultationDetail', pageBuilder: (_, state) {
          final id = state.pathParameters['id']!;
          final edit = state.uri.queryParameters['edit'] == 'true';
          return NoTransitionPage(child: PatientTeleconsultationPage(consultationId: id, isEditing: edit));
        }),
        GoRoute(path: '/sante/patient/teleconsultation/jitsi', name: 'patientTeleconsultationJitsi', pageBuilder: (_, state) {
          final link = state.extra as String? ?? 'https://meet.jit.si/default';
          return NoTransitionPage(child: PatientTeleconsultationJitsiPage(link: link));
        }),
        GoRoute(path: '/sante/patient/health-score', name: 'patientHealthScore', pageBuilder: (_, __) => NoTransitionPage(child: PatientHealthScorePage())),
        GoRoute(path: '/sante/patient/insurance', name: 'patientInsurance', pageBuilder: (_, __) => NoTransitionPage(child: PatientInsurancePage())),
        GoRoute(path: '/sante/patient/record', name: 'patientRecord', pageBuilder: (_, __) => NoTransitionPage(child: PatientRecordPage())),
        GoRoute(path: '/sante/patient/teleexpertise/:id', name: 'patientTeleexpertise', pageBuilder: (_, state) {
          return NoTransitionPage(child: PatientTeleexpertiseDetailPage(expertiseId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/patient/teleexpertise/request', name: 'patientTeleexpertiseRequest', pageBuilder: (_, __) => NoTransitionPage(child: PatientTeleexpertiseRequestPage())),
        GoRoute(path: '/sante/patient/symptom/:id', name: 'patientSymptom', pageBuilder: (_, state) {
          return NoTransitionPage(child: PatientSymptomPage(symptomId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/patient/symptom/new', name: 'patientSymptomNew', pageBuilder: (_, __) => NoTransitionPage(child: PatientSymptomPage())),
        GoRoute(path: '/sante/patient/vital/:id', name: 'patientVital', pageBuilder: (_, state) {
          return NoTransitionPage(child: PatientVitalPage(vitalId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/patient/vital/new', name: 'patientVitalNew', pageBuilder: (_, __) => NoTransitionPage(child: PatientVitalPage())),
        GoRoute(path: '/sante/patient/vitals/chart', name: 'patientVitalChart', pageBuilder: (_, __) => NoTransitionPage(child: PatientVitalChartPage())),
        GoRoute(path: '/sante/patient/record/add', name: 'patientRecordAdd', pageBuilder: (_, __) => NoTransitionPage(child: PatientRecordAddPage())),
        GoRoute(path: '/sante/patient/medications', name: 'patientMedications', pageBuilder: (_, __) => NoTransitionPage(child: PatientMedicationsListPage())),
        GoRoute(path: '/sante/patient/medication/:id', name: 'patientMedication', pageBuilder: (_, state) {
          return NoTransitionPage(child: PatientMedicationPage(medicationId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/patient/medication/new', name: 'patientMedicationNew', pageBuilder: (_, __) => NoTransitionPage(child: PatientMedicationPage())),
        GoRoute(path: '/sante/patient/medication/:id/reminders', name: 'patientMedicationReminders', pageBuilder: (_, state) {
          return NoTransitionPage(child: PatientMedicationRemindersPage(medicationId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/patient/vaccinations', name: 'patientVaccinations', pageBuilder: (_, __) => NoTransitionPage(child: PatientVaccinationCalendarPage())),
        GoRoute(path: '/sante/patient/vaccine/:id', name: 'patientVaccine', pageBuilder: (_, state) {
          return NoTransitionPage(child: PatientVaccinePage(vaccineId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/patient/vaccine/new', name: 'patientVaccineNew', pageBuilder: (_, __) => NoTransitionPage(child: PatientVaccinePage())),
        GoRoute(path: '/sante/patient/pregnancy/:id', name: 'patientPregnancy', pageBuilder: (_, state) {
          return NoTransitionPage(child: PatientPregnancyPage(pregnancyId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/patient/pregnancy/new', name: 'patientPregnancyNew', pageBuilder: (_, __) => NoTransitionPage(child: PatientPregnancyPage())),
        GoRoute(path: '/sante/patient/pregnancy', name: 'patientPregnancyList', pageBuilder: (_, __) => NoTransitionPage(child: PatientPregnancyPage())),
        GoRoute(path: '/sante/patient/family/:id', name: 'patientFamily', pageBuilder: (_, state) {
          return NoTransitionPage(child: PatientFamilyPage(memberId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/patient/family/new', name: 'patientFamilyNew', pageBuilder: (_, __) => NoTransitionPage(child: PatientFamilyPage())),
        GoRoute(path: '/sante/patient/family', name: 'patientFamilyList', pageBuilder: (_, __) => NoTransitionPage(child: PatientFamilyPage())),
        GoRoute(path: '/sante/patient/sharing/:id', name: 'patientSharing', pageBuilder: (_, state) {
          return NoTransitionPage(child: PatientSharingPage(shareId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/patient/sharing/new', name: 'patientSharingNew', pageBuilder: (_, __) => NoTransitionPage(child: PatientSharingPage())),
        GoRoute(path: '/sante/patient/sharing', name: 'patientSharingList', pageBuilder: (_, __) => NoTransitionPage(child: PatientSharingPage())),
        GoRoute(path: '/sante/patient/ia', name: 'patientIA', pageBuilder: (_, __) => NoTransitionPage(child: PatientAIChatPage())),
        GoRoute(path: '/sante/patient/ia/history/:id', name: 'patientIAHistory', pageBuilder: (_, state) {
          return NoTransitionPage(child: PatientAIChatPage(conversationId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/patient/alerts', name: 'patientAlerts', pageBuilder: (_, __) => NoTransitionPage(child: PatientAlertPage())),
        GoRoute(path: '/sante/patient/alert/:id', name: 'patientAlert', pageBuilder: (_, state) {
          return NoTransitionPage(child: PatientAlertPage(alertId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/patient/map/:type', name: 'patientMap', pageBuilder: (_, state) {
          return NoTransitionPage(child: PatientMapPage(type: state.pathParameters['type']!));
        }),
        GoRoute(path: '/sante/patient/map/pharmacy/:id', name: 'patientMapPharmacy', pageBuilder: (_, state) {
          return NoTransitionPage(child: PatientPharmacyDetailPage(pharmacyId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/patient/wellness/:id', name: 'patientWellness', pageBuilder: (_, state) {
          return NoTransitionPage(child: PatientWellnessPage(programId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/patient/wellness/:id/track', name: 'patientWellnessTrack', pageBuilder: (_, state) {
          return NoTransitionPage(child: PatientWellnessPage(programId: state.pathParameters['id']!, isTracking: true));
        }),
        GoRoute(path: '/sante/patient/consents', name: 'patientConsents', pageBuilder: (_, __) => NoTransitionPage(child: PatientConsentPage())),
        GoRoute(path: '/sante/patient/consent/:id', name: 'patientConsent', pageBuilder: (_, state) {
          return NoTransitionPage(child: PatientConsentPage(consentId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/patient/notifications', name: 'patientNotifications', pageBuilder: (_, __) => NoTransitionPage(child: PatientNotificationsPage())),
        GoRoute(path: '/sante/patient/profile', name: 'patientProfile', pageBuilder: (_, __) => NoTransitionPage(child: PatientProfilePage())),
        GoRoute(path: '/sante/patient/article/:id', name: 'patientArticle', pageBuilder: (_, state) {
          return NoTransitionPage(child: PatientArticlePage(articleId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/patient/chat/:id', name: 'patientChat', pageBuilder: (_, state) {
          return NoTransitionPage(child: PatientChatPage(chatId: state.pathParameters['id']!, recipientName: state.extra as String?));
        }),
        GoRoute(path: '/sante/patient/chat/new', name: 'patientChatNew', pageBuilder: (_, __) => NoTransitionPage(child: PatientChatNewPage())),

        // ---- Doctor ----
        GoRoute(path: '/sante/doctor/dashboard', name: 'doctorDashboard', pageBuilder: (_, __) => NoTransitionPage(child: DoctorDashboardPage())),
        GoRoute(path: '/sante/doctor/care', name: 'doctorCare', pageBuilder: (_, __) => NoTransitionPage(child: DoctorCarePage())),
        GoRoute(path: '/sante/doctor/consult', name: 'doctorConsult', pageBuilder: (_, __) => NoTransitionPage(child: DoctorConsultPage())),
        GoRoute(path: '/sante/doctor/connect', name: 'doctorConnect', pageBuilder: (_, __) => NoTransitionPage(child: DoctorConnectPage())),
        GoRoute(path: '/sante/doctor/patients', name: 'doctorPatients', pageBuilder: (_, __) => NoTransitionPage(child: DoctorPatientsPage())),
        GoRoute(path: '/sante/doctor/patient/:id', name: 'doctorPatient', pageBuilder: (_, state) {
          return NoTransitionPage(child: DoctorPatientPage(patientId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/doctor/patient/new', name: 'doctorPatientNew', pageBuilder: (_, __) => NoTransitionPage(child: DoctorPatientAddPage())),
        GoRoute(path: '/sante/doctor/prescription/new', name: 'doctorPrescriptionNew', pageBuilder: (_, __) => NoTransitionPage(child: DoctorPrescriptionPage())),
        GoRoute(path: '/sante/doctor/prescription/:id', name: 'doctorPrescription', pageBuilder: (_, state) {
          return NoTransitionPage(child: DoctorPrescriptionPage(prescriptionId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/doctor/teleconsult', name: 'doctorTeleconsult', pageBuilder: (_, __) => NoTransitionPage(child: DoctorTeleconsultPage())),
        GoRoute(path: '/sante/doctor/teleconsultation/jitsi', name: 'doctorJitsi', pageBuilder: (_, state) {
          return NoTransitionPage(child: PatientTeleconsultationJitsiPage(link: state.extra as String? ?? 'https://meet.jit.si/default'));
        }),
        GoRoute(path: '/sante/doctor/teleexpertise/:id', name: 'doctorTeleexpertise', pageBuilder: (_, state) {
          return NoTransitionPage(child: DoctorTeleexpertisePage(requestId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/doctor/teleexpertise/new', name: 'doctorTeleexpertiseNew', pageBuilder: (_, __) => NoTransitionPage(child: DoctorTeleexpertisePage())),
        GoRoute(path: '/sante/doctor/agenda', name: 'doctorAgenda', pageBuilder: (_, __) => NoTransitionPage(child: DoctorAgendaPage())),
        GoRoute(path: '/sante/doctor/agenda/slots', name: 'doctorAgendaSlots', pageBuilder: (_, __) => NoTransitionPage(child: DoctorSlotManagementPage())),
        GoRoute(path: '/sante/doctor/note/:id', name: 'doctorNote', pageBuilder: (_, state) {
          return NoTransitionPage(child: DoctorNotePage(noteId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/doctor/note/new', name: 'doctorNoteNew', pageBuilder: (_, __) => NoTransitionPage(child: DoctorNotePage())),
        GoRoute(path: '/sante/doctor/statistics', name: 'doctorStatistics', pageBuilder: (_, __) => NoTransitionPage(child: DoctorStatisticsPage())),
        GoRoute(path: '/sante/doctor/terrain/scan', name: 'doctorTerrainScan', pageBuilder: (_, __) => NoTransitionPage(child: DoctorScanBraceletPage())),
        GoRoute(path: '/sante/doctor/terrain/dictation', name: 'doctorTerrainDictation', pageBuilder: (_, __) => NoTransitionPage(child: DoctorVoiceDictationPage())),
        GoRoute(path: '/sante/doctor/terrain/offline', name: 'doctorTerrainOffline', pageBuilder: (_, __) => NoTransitionPage(child: DoctorOfflinePatientsPage())),
        GoRoute(path: '/sante/doctor/terrain/photo', name: 'doctorTerrainPhoto', pageBuilder: (_, __) => NoTransitionPage(child: DoctorPhotoCapturePage())),
        GoRoute(path: '/sante/doctor/messages/:id', name: 'doctorChat', pageBuilder: (_, state) {
          return NoTransitionPage(child: DoctorChatPage(chatId: state.pathParameters['id']!, participantName: state.extra as String?));
        }),
        GoRoute(path: '/sante/doctor/messages/new', name: 'doctorChatNew', pageBuilder: (_, __) => NoTransitionPage(child: DoctorChatPage(chatId: ''))),
        GoRoute(path: '/sante/doctor/alerts', name: 'doctorAlerts', pageBuilder: (_, __) => NoTransitionPage(child: DoctorAlertPage())),
        GoRoute(path: '/sante/doctor/alert/:patientName', name: 'doctorAlertPatient', pageBuilder: (_, state) {
          return NoTransitionPage(child: DoctorAlertPage(patientName: state.pathParameters['patientName']!));
        }),

        // ---- Pharmacy ----
        GoRoute(path: '/sante/pharmacy/dashboard', name: 'pharmacyDashboard', pageBuilder: (_, __) => NoTransitionPage(child: PharmacyDashboardPage())),
        GoRoute(path: '/sante/pharmacy/orders', name: 'pharmacyOrders', pageBuilder: (_, __) => NoTransitionPage(child: PharmacyOrdersPage())),
        GoRoute(path: '/sante/pharmacy/inventory', name: 'pharmacyInventory', pageBuilder: (_, __) => NoTransitionPage(child: PharmacyInventoryPage())),
        GoRoute(path: '/sante/pharmacy/connect', name: 'pharmacyConnect', pageBuilder: (_, __) => NoTransitionPage(child: PharmacyConnectPage())),
        GoRoute(path: '/sante/pharmacy/order/:id', name: 'pharmacyOrder', pageBuilder: (_, state) {
          return NoTransitionPage(child: PharmacyOrderPage(orderId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/pharmacy/order/new', name: 'pharmacyOrderNew', pageBuilder: (_, __) => NoTransitionPage(child: PharmacyOrderPage(orderId: ''))),
        GoRoute(path: '/sante/pharmacy/prescription/:id', name: 'pharmacyPrescription', pageBuilder: (_, state) {
          return NoTransitionPage(child: PharmacyPrescriptionPage(prescriptionId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/pharmacy/dispensing', name: 'pharmacyDispensing', pageBuilder: (_, __) => NoTransitionPage(child: PharmacyDispensingPage())),
        GoRoute(path: '/sante/pharmacy/delivery', name: 'pharmacyDelivery', pageBuilder: (_, __) => NoTransitionPage(child: PharmacyDeliveryPage())),
        GoRoute(path: '/sante/pharmacy/inventory/item/:id', name: 'pharmacyInventoryItem', pageBuilder: (_, state) {
          return NoTransitionPage(child: PharmacyInventoryItemPage(itemId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/pharmacy/inventory/item/new', name: 'pharmacyInventoryItemNew', pageBuilder: (_, __) => NoTransitionPage(child: PharmacyInventoryItemPage())),
        GoRoute(path: '/sante/pharmacy/stock', name: 'pharmacyStock', pageBuilder: (_, __) => NoTransitionPage(child: PharmacyStockPage())),
        GoRoute(path: '/sante/pharmacy/report', name: 'pharmacyReport', pageBuilder: (_, __) => NoTransitionPage(child: PharmacyReportPage())),
        GoRoute(path: '/sante/pharmacy/chat/:id', name: 'pharmacyChat', pageBuilder: (_, state) {
          return NoTransitionPage(child: PharmacyChatPage(chatId: state.pathParameters['id']!, participantName: state.extra as String?));
        }),
        GoRoute(path: '/sante/pharmacy/chat/new', name: 'pharmacyChatNew', pageBuilder: (_, __) => NoTransitionPage(child: PharmacyChatPage(chatId: ''))),
        GoRoute(path: '/sante/pharmacy/products', name: 'pharmacyProducts', pageBuilder: (_, __) => NoTransitionPage(child: PharmacyProductsPage())),
        GoRoute(path: '/sante/pharmacy/product/:id', name: 'pharmacyProductDetail', pageBuilder: (_, state) {
          return NoTransitionPage(child: PharmacyProductDetailPage(productId: state.pathParameters['id']!));
        }),
        GoRoute(path: '/sante/pharmacy/cart', name: 'pharmacyCart', pageBuilder: (_, __) => NoTransitionPage(child: PharmacyCartPage())),

        // ---- THIX Money, Media, Reservation ----
        GoRoute(path: AppRoutes.thixMoney, name: 'thixMoney', pageBuilder: (_, __) => NoTransitionPage(child: ThixMoneyPage())),
        GoRoute(path: AppRoutes.thixMedia, name: 'thixMedia', pageBuilder: (_, __) => NoTransitionPage(child: ThixMediaPage())),
        GoRoute(path: AppRoutes.thixMediaVideo, name: 'thixMediaVideo', pageBuilder: (_, state) {
          final title = (state.uri.queryParameters['title'] ?? '').trim();
          final url = (state.uri.queryParameters['url'] ?? '').trim();
          return NoTransitionPage(child: VideoPlayerPage(title: title.isEmpty ? 'Lecture vidéo' : title, videoUrl: url));
        }),
        GoRoute(path: AppRoutes.reservation, name: 'reservation', pageBuilder: (_, __) => NoTransitionPage(child: ThixReservationPage())),

        // ---- THIX Événement ----
        GoRoute(path: AppRoutes.thixEvent, name: 'thixEvent', pageBuilder: (_, __) => NoTransitionPage(child: ThixEventHome())),
        GoRoute(path: AppRoutes.thixEventDetail, name: 'thixEventDetail', pageBuilder: (_, state) {
          return NoTransitionPage(child: EventDetailPage(eventId: state.pathParameters['eventId']!));
        }),
        GoRoute(path: AppRoutes.thixEventSearch, name: 'thixEventSearch', pageBuilder: (_, __) => NoTransitionPage(child: EventSearchPage())),
        GoRoute(path: AppRoutes.thixEventCategory, name: 'thixEventCategory', pageBuilder: (_, state) {
          return NoTransitionPage(child: EventCategoryPage(category: state.pathParameters['category']!));
        }),
        GoRoute(path: AppRoutes.thixEventReservation, name: 'thixEventReservation', pageBuilder: (_, state) {
          final eventId = state.pathParameters['eventId']!;
          final quantity = int.tryParse(state.uri.queryParameters['quantity'] ?? '1') ?? 1;
          return NoTransitionPage(child: EventReservationPage(eventId: eventId, quantity: quantity));
        }),
        GoRoute(path: AppRoutes.thixEventMyTickets, name: 'thixEventMyTickets', pageBuilder: (_, __) => NoTransitionPage(child: MyTicketsPage())),
        GoRoute(path: AppRoutes.thixEventFavorites, name: 'thixEventFavorites', pageBuilder: (_, __) => NoTransitionPage(child: FavoriteEventsPage())),
        GoRoute(path: AppRoutes.thixEventSeatSelection, name: 'thixEventSeatSelection', pageBuilder: (_, state) {
          return NoTransitionPage(child: SeatSelectionPage(eventId: state.pathParameters['eventId']!));
        }),
        GoRoute(path: AppRoutes.thixEventWaitingQueue, name: 'thixEventWaitingQueue', pageBuilder: (_, state) {
          final eventId = state.pathParameters['eventId']!;
          final quantity = int.tryParse(state.uri.queryParameters['quantity'] ?? '1') ?? 1;
          return NoTransitionPage(child: WaitingQueuePage(eventId: eventId, requestedQuantity: quantity));
        }),

        // ---- Jobs & Opportunités ----
        GoRoute(path: AppRoutes.jobs, name: 'jobs', pageBuilder: (_, __) => NoTransitionPage(child: JobsPage())),
        GoRoute(path: AppRoutes.jobDashboard, name: 'jobDashboard', pageBuilder: (_, __) => NoTransitionPage(child: JobDashboardPage())),
        GoRoute(path: AppRoutes.recruiter, name: 'recruiter', pageBuilder: (_, __) => NoTransitionPage(child: RecruiterPortalPage())),
        GoRoute(path: AppRoutes.opportunities, name: 'opportunities', pageBuilder: (_, __) => NoTransitionPage(child: OpportunitiesPage())),
        GoRoute(path: '/opportunities/:opportunityId', name: 'opportunityDetails', pageBuilder: (_, state) {
          final oppId = state.pathParameters['opportunityId'] ?? '';
          final applied = (state.uri.queryParameters['applied'] ?? '').trim() == '1';
          return NoTransitionPage(child: OpportunityDetailsPage(opportunityId: oppId, applied: applied));
        }),
        GoRoute(path: '/opportunities/:opportunityId/apply', name: 'opportunityApply', pageBuilder: (_, state) {
          return NoTransitionPage(child: OpportunityApplyPage(opportunityId: state.pathParameters['opportunityId'] ?? ''));
        }),
        GoRoute(path: '/jobs/:jobId', name: 'jobDetails', pageBuilder: (_, state) {
          final jobId = state.pathParameters['jobId'] ?? '';
          final applied = (state.uri.queryParameters['applied'] ?? '').trim() == '1';
          return NoTransitionPage(child: JobDetailsPage(jobId: jobId, applied: applied));
        }),
        GoRoute(path: '/jobs/:jobId/apply', name: 'jobApply', pageBuilder: (_, state) {
          return NoTransitionPage(child: JobApplyPage(jobId: state.pathParameters['jobId'] ?? ''));
        }),

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
            GoRoute(path: 'events', name: 'moderatorEvents', builder: (context, state) => const ModeratorEventList()),
            GoRoute(path: 'event/create', name: 'moderatorEventCreate', builder: (context, state) => const ModeratorEventForm()),
            GoRoute(path: 'event/edit/:id', name: 'moderatorEventEdit', builder: (context, state) => ModeratorEventForm(eventId: state.pathParameters['id']!)),
          ],
        ),

        // ===== MON PAYS =====
        GoRoute(
          path: AppRoutes.monPays,
          name: 'monPays',
          pageBuilder: (_, __) => const NoTransitionPage(child: MonPaysPage()),
          routes: [
            // Autorités - Liste
            GoRoute(
              path: 'authorities',
              name: 'monPaysAuthorities',
              pageBuilder: (_, __) => const NoTransitionPage(child: AuthoritiesPage()),
            ),
            // Autorités - Détail
            GoRoute(
              path: 'authority/:id',
              name: 'monPaysAuthorityProfile',
              pageBuilder: (_, state) {
                final id = state.pathParameters['id']!;
                return NoTransitionPage(child: AuthorityProfilePage(authorityId: id));
              },
            ),
            // Admin - Liste
            GoRoute(
              path: 'admin',
              name: 'monPaysAdmin',
              pageBuilder: (_, __) => const NoTransitionPage(child: AdminAuthoritiesPage()),
            ),
            // Admin - Formulaire (création/modification)
            GoRoute(
              path: 'admin/form',
              name: 'monPaysAdminForm',
              pageBuilder: (_, state) {
                final authority = state.extra;
                return NoTransitionPage(
                  child: AdminAuthorityFormPage(authority: authority as dynamic),
                );
              },
            ),
          ],
        ),

        // ---- Admin ----
        GoRoute(
          path: '${AppRoutes.admin}/:module',
          name: 'admin',
          pageBuilder: (_, state) {
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
          pageBuilder: (_, __) => NoTransitionPage(child: AdminMediaPage()),
        ),
      ],
    );
  }
}

extension GoRouterBackHelpers on BuildContext {
  void popOrGo(String fallbackLocation) {
    final router = GoRouter.of(this);
    if (router.canPop()) { pop(); return; }
    go(fallbackLocation);
  }
}
