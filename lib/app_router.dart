// lib/app_router.dart - BUILD VERT - Toutes routes conservees
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/nav.dart';

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

// BUS 
import 'package:thix_id/presentation/thix_reservation/bus/pages/client/bus_search_result_page.dart';
import 'package:thix_id/presentation/thix_reservation/bus/pages/client/bus_trip_detail_page.dart';
import 'package:thix_id/presentation/thix_reservation/bus/pages/client/bus_seat_selection_page.dart';
import 'package:thix_id/presentation/thix_reservation/bus/pages/client/bus_payment_page.dart';
import 'package:thix_id/presentation/thix_reservation/bus/pages/client/bus_ticket_page.dart';
import 'package:thix_id/presentation/thix_reservation/bus/pages/agency/agency_onboarding_page.dart';
import 'package:thix_id/presentation/thix_reservation/bus/pages/agency/agency_dashboard_page.dart';
import 'package:thix_id/presentation/thix_reservation/bus/pages/agency/agency_create_trip_page.dart';
import 'package:thix_id/presentation/thix_reservation/bus/pages/agency/agency_qr_scan_page.dart';
import 'package:thix_id/presentation/thix_reservation/bus/data/models/bus_trip_model.dart';
import 'package:thix_id/presentation/thix_reservation/bus/data/models/booking_model.dart';
// THIX SANTE
import 'presentation/thix_sante/patient/patient_dashboard_page.dart';
import 'presentation/thix_sante/patient/screens/mon_medecin_traitant_page.dart';
import 'presentation/thix_sante/patient/screens/dossier_famille_page.dart';
import 'presentation/thix_sante/patient/screens/second_avis_page.dart';
import 'presentation/thix_sante/patient/screens/consulter_medecin_page.dart';
import 'presentation/thix_sante/patient/screens/dossier_medical_page.dart';
import 'presentation/thix_sante/patient/screens/resultats_examens_page.dart';
import 'presentation/thix_sante/patient/screens/mes_ordonnances_page.dart';
import 'presentation/thix_sante/patient/screens/trouver_hopital_page.dart';
import 'presentation/thix_sante/patient/screens/trouver_medicament_page.dart';
import 'presentation/thix_sante/patient/screens/pharmacies_proches_page.dart';
import 'presentation/thix_sante/patient/screens/urgences_proches_page.dart';
import 'presentation/thix_sante/patient/screens/prendre_rdv_page.dart';
import 'presentation/thix_sante/patient/screens/teleconsultation_page.dart';
import 'presentation/thix_sante/patient/screens/assistant_ia_page.dart';
import 'presentation/thix_sante/patient/screens/dossier_partage_page.dart';
import 'presentation/thix_sante/patient/screens/epidemies_page.dart';
import 'presentation/thix_sante/patient/screens/don_sang_page.dart';
import 'presentation/thix_sante/patient/screens/nutrition_page.dart';
import 'presentation/thix_sante/patient/screens/activite_physique_page.dart';
import 'presentation/thix_sante/patient/screens/gestion_stress_page.dart';
import 'presentation/thix_sante/patient/screens/assurance_sante_page.dart';
import 'presentation/thix_sante/patient/screens/plus_services_page.dart';
import 'presentation/thix_sante/patient/screens/analyse_predictive_page.dart';
import 'presentation/thix_sante/patient/screens/bien_etre_mental_page.dart';
import 'presentation/thix_sante/patient/screens/sante_enfants_page.dart';
import 'presentation/thix_sante/patient/screens/carnet_vaccination_page.dart';
import 'presentation/thix_sante/patient/screens/suivi_grossesse_page.dart';

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

// Jobs, Opportunites
import 'presentation/jobs/jobs_page.dart';
import 'package:thix_id/presentation/jobs/job_apply_page.dart';
import 'package:thix_id/presentation/jobs/job_details_page.dart';
import 'package:thix_id/presentation/jobs/job_dashboard_page.dart';
import 'package:thix_id/presentation/recruiter/recruiter_portal_page.dart';
import 'package:thix_id/presentation/opportunities/opportunities_page.dart';
import 'package:thix_id/presentation/opportunities/opportunity_apply_page.dart';
import 'package:thix_id/presentation/opportunities/opportunity_details_page.dart';

// Admin générique
import 'package:thix_id/presentation/admin/admin_page.dart';
import 'package:thix_id/presentation/admin/admin_routes.dart';
import 'package:thix_id/presentation/admin/pages/admin_media_page.dart';

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
import 'package:thix_id/presentation/thix_info/article_detail_page.dart' as thixInfoArticle;
import 'package:thix_id/presentation/thix_info/search_page.dart' as infoSearch;
import 'package:thix_id/presentation/thix_info/category_articles_page.dart';
import 'package:thix_id/presentation/thix_info/saved_articles_page.dart';
import 'package:thix_id/presentation/thix_info/breaking_news_page.dart';

// THIX Evenement
import 'package:thix_id/presentation/thix_event/thix_event_home.dart';
import 'package:thix_id/presentation/thix_event/event_detail_page.dart';
import 'package:thix_id/presentation/thix_event/event_search_page.dart';
import 'package:thix_id/presentation/thix_event/event_category_page.dart';
import 'package:thix_id/presentation/thix_event/event_reservation_page.dart';
import 'package:thix_id/presentation/thix_event/my_tickets_page.dart';
import 'package:thix_id/presentation/thix_event/favorite_events_page.dart';
import 'package:thix_id/presentation/thix_event/seat_selection_page.dart';
import 'package:thix_id/presentation/thix_event/waiting_queue_page.dart';

// Moderateur
import 'package:thix_id/presentation/moderator/moderator_home.dart';
import 'package:thix_id/presentation/moderator/moderator_event_list.dart';
import 'package:thix_id/presentation/moderator/moderator_event_form.dart';
import 'package:thix_id/providers/auth_provider.dart';

// Education
import 'package:thix_id/presentation/education/education_routes.dart';

// THIX Money, Media, Reservation
import 'package:thix_id/presentation/thix_money/thix_money_page.dart';
import 'package:thix_id/presentation/thix_media/thix_media_page.dart';
import 'package:thix_id/presentation/thix_media/video_player_page.dart';
import 'package:thix_id/presentation/thix_reservation/thix_reservation_page.dart';
import 'package:thix_id/presentation/splash/thix_id_start_page.dart';

// THIX Chat
import 'package:thix_id/models/chat/chat_conversation.dart';
import 'package:thix_id/presentation/chat/chat_list_page.dart';
import 'package:thix_id/presentation/chat/chat_screen.dart' as ThixChat;
import 'package:thix_id/presentation/chat/new_conversation_page.dart';
import 'package:thix_id/presentation/chat/screens/group_create_page.dart';
import 'package:thix_id/presentation/chat/screens/group_info_page.dart';
import 'package:thix_id/presentation/chat/screens/group_settings_page.dart';

// MON PAYS
import 'presentation/mon_pays/mon_pays_page.dart';
import 'presentation/mon_pays/pages/authorities/authorities_page.dart';
import 'presentation/mon_pays/pages/authorities/authority_profile_page.dart';
import 'presentation/mon_pays/admin/admin_dashboard_page.dart';
import 'presentation/mon_pays/admin/admin_authorities_page.dart';
import 'presentation/mon_pays/admin/admin_authority_form_page.dart';
import 'presentation/mon_pays/admin/admin_articles_page.dart' as monpays_articles;
import 'presentation/mon_pays/admin/admin_article_form_page.dart' as monpays_form;
import 'presentation/mon_pays/pages/laws/laws_page.dart';
import 'presentation/mon_pays/pages/laws/article_type_page.dart';
import 'presentation/mon_pays/pages/laws/article_detail_page.dart' as monPaysArticle;
import 'presentation/mon_pays/models/article.dart';
import 'presentation/mon_pays/pages/provinces/provinces_page.dart';
import 'presentation/mon_pays/pages/provinces/province_detail_page.dart';
import 'presentation/mon_pays/admin/admin_provinces_page.dart';
import 'presentation/mon_pays/admin/admin_province_form_page.dart';
import 'presentation/mon_pays/admin/admin_government_form_page.dart';
import 'presentation/mon_pays/admin/admin_economic_form_page.dart';
import 'presentation/mon_pays/admin/admin_budget_form_page.dart';
import 'presentation/mon_pays/admin/admin_tourism_form_page.dart';
import 'presentation/mon_pays/admin/admin_emergency_form_page.dart';
import 'presentation/mon_pays/admin/admin_administrative_form_page.dart';
import 'presentation/mon_pays/admin/admin_achievement_form_page.dart';
import 'presentation/mon_pays/admin/admin_media_form_page.dart';
import 'package:thix_id/presentation/mon_pays/models/province.dart';

// -------- THIX INFO ADMIN - ALIAS POUR EVITER CONFLIT --------
import 'presentation/admin/admin_home_page.dart' as thix_admin;
import 'presentation/admin/admin_articles_list_page.dart' as thix_admin_list;
import 'presentation/admin/admin_article_form_page.dart' as thix_admin_form;

class NoTransitionPage<T> extends Page<T> {
  final Widget child;
  const NoTransitionPage({required this.child, super.key});
  @override
  Route<T> createRoute(BuildContext context) => PageRouteBuilder<T>(
        settings: this,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (c,a,s) => child,
        transitionsBuilder: (c,a,s,ch) => ch,
      );
}

class AppRouter {
  static GoRouter create(AuthController auth, {Listenable? extraRefreshListenable}) {
    final refresh = extraRefreshListenable ?? auth;
    return GoRouter(
      initialLocation: AppRoutes.home,
      refreshListenable: refresh,
      redirect: (context, state) {
        final loc = state.matchedLocation;
        final logged = auth.isAuthenticated;
        final isAuth = loc == AppRoutes.login || loc == AppRoutes.personalReg || loc == AppRoutes.enterpriseReg;
        final isAdmin = loc == AppRoutes.admin || loc.startsWith('${AppRoutes.admin}/');
        final isPortal = loc.startsWith('${AppRoutes.enterprisePortalBasePath}/') || loc == AppRoutes.enterprisePortalBasePath;
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
        GoRoute(path: AppRoutes.start, name: 'start', pageBuilder: (_, __) => NoTransitionPage(child: ThixIdStartPage())),
        GoRoute(path: AppRoutes.home, name: 'home', pageBuilder: (_, __) => NoTransitionPage(child: HomePagePremium())),
        GoRoute(path: AppRoutes.login, name: 'login', pageBuilder: (_, __) => NoTransitionPage(child: LoginPage())),
        GoRoute(path: AppRoutes.personalReg, name: 'personalReg', pageBuilder: (_, state) {
          final step = int.tryParse(state.uri.queryParameters['step'] ?? '') ?? 1;
          return NoTransitionPage(child: PersonalRegistrationPage(initialStep: step));
        }),
        GoRoute(path: AppRoutes.enterpriseReg, name: 'enterpriseReg', pageBuilder: (_, __) => NoTransitionPage(child: EnterpriseRegistrationPage())),
        GoRoute(path: AppRoutes.payment, name: 'payment', pageBuilder: (_, state) => NoTransitionPage(child: PaymentGatewayPage(returnTo: state.uri.queryParameters['returnTo']))),
        GoRoute(path: AppRoutes.activationReceipt, name: 'activationReceipt', pageBuilder: (_, state) {
          final qp = state.uri.queryParameters;
          return NoTransitionPage(child: ActivationReceiptPage(txRef: qp['txRef'], method: qp['method'], amount: qp['amount'], currency: qp['currency'], paidAt: DateTime.tryParse(qp['paidAt'] ?? '')));
        }),
        GoRoute(path: AppRoutes.publicProfile, name: 'publicProfile', pageBuilder: (_, state) => NoTransitionPage(child: PublicProfilePage(initialThixId: state.uri.queryParameters['thixId']))),
        GoRoute(path: AppRoutes.userDashboard, name: 'userDashboard', pageBuilder: (_, __) => NoTransitionPage(child: UserDashboardPage())),
        GoRoute(path: AppRoutes.enterpriseDashboard, name: 'enterpriseDashboard', pageBuilder: (_, __) => NoTransitionPage(child: EnterpriseDashboardPage())),
        GoRoute(path: AppRoutes.enterprise, name: 'enterpriseEntry', redirect: (_, __) {
          if (!auth.isAuthenticated) return AppRoutes.login;
          return auth.currentUser?.accountType == AccountType.enterprise ? AppRoutes.enterpriseDashboard : AppRoutes.enterpriseReg;
        }),
        GoRoute(path: '/entreprise/:slug', name: 'enterprisePortalAliasFr', redirect: (_, state) => '${AppRoutes.enterprisePortalBase(state.pathParameters['slug']!)}/dashboard/overview'),
        GoRoute(path: '${AppRoutes.enterprisePortalBasePath}/:slug', name: 'enterprisePortal', pageBuilder: (_, state) => NoTransitionPage(child: EnterprisePortalPage(companySlug: state.pathParameters['slug']!)), routes: [
          GoRoute(path: 'dashboard/:section', name: 'enterprisePortalDashboard', pageBuilder: (_, state) => NoTransitionPage(child: EnterpriseDashboardShellPage(companySlug: state.pathParameters['slug']!, section: state.pathParameters['section'] ?? 'overview'))),
          GoRoute(path: 'dashboard', name: 'enterprisePortalDashboardRoot', redirect: (_, state) => '${AppRoutes.enterprisePortalBase(state.pathParameters['slug']!)}/dashboard/overview'),
        ]),

        // CHAT
        GoRoute(path: AppRoutes.chat, name: 'chat', pageBuilder: (_, __) => const NoTransitionPage(child: ChatListPage())),
        GoRoute(path: AppRoutes.chatNew, name: 'chat_new', pageBuilder: (_, __) => const NoTransitionPage(child: NewConversationPage())),
        GoRoute(path: AppRoutes.chatConversation, name: 'chat_conversation', pageBuilder: (_, state) {
          final convId = state.pathParameters['conversationId']!;
          final conv = state.extra as ChatConversation? ?? ChatConversation(id: convId, isGroup: false, participantIds: [], updatedAt: DateTime.now());
          return NoTransitionPage(child: ThixChat.ChatScreen(conversationId: convId, conversation: conv));
        }),
        GoRoute(path: AppRoutes.groupCreate, name: 'group_create', pageBuilder: (_, __) => const NoTransitionPage(child: GroupCreatePage())),
        GoRoute(path: AppRoutes.groupInfo, name: 'group_info', pageBuilder: (_, state) => NoTransitionPage(child: GroupInfoPage(groupId: state.pathParameters['groupId']!))),
        GoRoute(path: AppRoutes.groupSettings, name: 'group_settings', pageBuilder: (_, state) => NoTransitionPage(child: GroupSettingsPage(groupId: state.pathParameters['groupId']!))),

        GoRoute(path: AppRoutes.vault, name: 'document-vault', pageBuilder: (_, __) => NoTransitionPage(child: DocumentVaultPage())),
        GoRoute(path: AppRoutes.settings, name: 'settings', pageBuilder: (_, __) => NoTransitionPage(child: SettingsPage())),

        // Reseau
        GoRoute(path: AppRoutes.network, name: 'network', pageBuilder: (_, __) => NoTransitionPage(child: NetworkProHome())),
        GoRoute(path: AppRoutes.networkSearch, name: 'networkSearch', pageBuilder: (_, __) => NoTransitionPage(child: SearchNetworkPage())),
        GoRoute(path: AppRoutes.networkNotifications, name: 'networkNotifications', pageBuilder: (_, __) => NoTransitionPage(child: NotificationsPage())),
        GoRoute(path: AppRoutes.networkMessages, name: 'networkMessages', pageBuilder: (_, __) => NoTransitionPage(child: ConversationsList())),
        GoRoute(path: '${AppRoutes.networkChatBasePath}/:userId', name: 'networkChat', pageBuilder: (_, state) {
          final uid = state.pathParameters['userId']!;
          final extra = state.extra;
          String name = 'Discussion'; String? avatar;
          if (extra is String) name = extra; else if (extra is Map) { name = extra['userName'] as String? ?? name; avatar = extra['userAvatar'] as String?; }
          return NoTransitionPage(child: network_chat.ChatScreen(userId: uid, userName: name, userAvatar: avatar));
        }),
        GoRoute(path: AppRoutes.networkConnections, name: 'networkConnections', pageBuilder: (_, __) => NoTransitionPage(child: ConnectionsListPage())),
        GoRoute(path: AppRoutes.networkProfileSettings, name: 'networkProfileSettings', pageBuilder: (_, __) => NoTransitionPage(child: ProfileSettingsPage())),
        GoRoute(path: AppRoutes.networkBlockedUsers, name: 'networkBlockedUsers', pageBuilder: (_, __) => NoTransitionPage(child: BlockedUsersPage())),
        GoRoute(path: '/network/discover', name: 'networkDiscover', pageBuilder: (_, __) => NoTransitionPage(child: const DiscoverTab())),
        GoRoute(path: '/network/communities', name: 'networkCommunities', pageBuilder: (_, __) => NoTransitionPage(child: const CommunitiesListPage())),
        GoRoute(path: '/network/community/create', name: 'networkCommunityCreate', pageBuilder: (_, __) => NoTransitionPage(child: const CreateCommunityPage())),
        GoRoute(path: '${AppRoutes.networkCommunityBasePath}/:communityId', name: 'networkCommunityDetail', pageBuilder: (_, state) => NoTransitionPage(child: CommunityDetailPage(communityId: state.pathParameters['communityId']!))),
        GoRoute(path: '/network/story/:storyId', name: 'networkStoryViewer', pageBuilder: (_, state) => NoTransitionPage(child: StoryViewerScreen(storyId: state.pathParameters['storyId']!))),
        GoRoute(path: '/network/comments/:postId', name: 'networkComments', pageBuilder: (_, state) => NoTransitionPage(child: CommentsPage(postId: state.pathParameters['postId']!, currentProfileId: Supabase.instance.client.auth.currentUser?.id ?? ''))),
        GoRoute(path: '/network/hashtag/:tag', name: 'networkHashtag', pageBuilder: (_, state) => NoTransitionPage(child: HashtagPage(tag: state.pathParameters['tag']!))),
        GoRoute(path: '${AppRoutes.networkPostBasePath}/:postId', name: 'networkPostDetail', pageBuilder: (_, state) => NoTransitionPage(child: PostDetailPage(postId: state.pathParameters['postId']!))),
        GoRoute(path: '${AppRoutes.networkProfileBasePath}/:userId', name: 'networkProfile', pageBuilder: (_, state) => NoTransitionPage(child: ProfilePage(userId: state.pathParameters['userId']!, currentProfileId: Supabase.instance.client.auth.currentUser?.id ?? ''))),
        GoRoute(path: AppRoutes.profile, name: 'profile', pageBuilder: (_, __) => NoTransitionPage(child: ProfilePage())),
  
        // THIX SANTE
        GoRoute(path: AppRoutes.thixSante, redirect: (_, __) => AppRoutes.thixSanteDashboard),
        GoRoute(path: AppRoutes.thixSanteDashboard, builder: (c, s) => PatientDashboardPage()),
        GoRoute(path: AppRoutes.santeMonMedecinTraitant, builder: (c, s) => MonMedecinTraitantPage()),
        GoRoute(path: AppRoutes.santeDossierFamille, builder: (c, s) => DossierFamillePage()),
        GoRoute(path: AppRoutes.santeSecondAvis, builder: (c, s) => SecondAvisPage()),
        GoRoute(path: AppRoutes.santeDossierMedical, builder: (c, s) => DossierMedicalPage()),
        GoRoute(path: AppRoutes.santeOrdonnances, builder: (c, s) => MesOrdonnancesPage()),
        GoRoute(path: AppRoutes.santeResultatsExamens, builder: (c, s) => ResultatsExamensPage()),
        GoRoute(path: AppRoutes.santePrendreRdv, builder: (c, s) => PrendreRdvPage()),
        GoRoute(path: AppRoutes.santeTeleconsultation, builder: (c, s) => TeleconsultationPage()),
        GoRoute(path: AppRoutes.santeTrouverHopital, builder: (c, s) => TrouverHopitalPage()),
        GoRoute(path: AppRoutes.santeTrouverMedicament, builder: (c, s) => TrouverMedicamentPage()),
        GoRoute(path: AppRoutes.santePharmaciesProches, builder: (c, s) => PharmaciesProchesPage()),
        GoRoute(path: AppRoutes.santeUrgencesProches, builder: (c, s) => UrgencesProchesPage()),
        GoRoute(path: AppRoutes.santeEpidemies, builder: (c, s) => EpidemiesPage()),
        GoRoute(path: AppRoutes.santeDonSang, builder: (c, s) => DonSangPage()),
        GoRoute(path: AppRoutes.santeEnfants, builder: (c, s) => SanteEnfantsPage()),
        GoRoute(path: AppRoutes.santeCarnetVaccination, builder: (c, s) => CarnetVaccinationPage()),
        GoRoute(path: AppRoutes.santeSuiviGrossesse, builder: (c, s) => SuiviGrossessePage()),
        GoRoute(path: AppRoutes.santeAnalysePredictive, builder: (c, s) => AnalysePredictivePage()),
        GoRoute(path: AppRoutes.santeBienEtreMental, builder: (c, s) => BienEtreMentalPage()),
        GoRoute(path: AppRoutes.santeNutrition, builder: (c, s) => NutritionPage()),
        GoRoute(path: AppRoutes.santeActivitePhysique, builder: (c, s) => ActivitePhysiquePage()),
        GoRoute(path: AppRoutes.santeGestionStress, builder: (c, s) => GestionStressPage()),
        GoRoute(path: AppRoutes.santeAssuranceSanteDetail, builder: (c, s) => AssuranceSantePage()),
        GoRoute(path: AppRoutes.santePlusServices, builder: (c, s) => PlusServicesPage()),
        
        // Jobs & Opportunites
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

        // Education
        ...educationRoutes,
        ...instructorRoutes,

        // Moderateur
        GoRoute(
          path: '/moderator',
          name: 'moderatorHome',
          builder: (context, state) => const ModeratorHome(),
          routes: [
            GoRoute(path: 'events', name: 'moderatorEvents', builder: (context, state) => const ModeratorEventList()),
            GoRoute(path: 'event/create', name: 'moderatorEventCreate', builder: (context, state) => const ModeratorEventForm()),
            GoRoute(path: 'event/edit/:id', name: 'moderatorEventEdit', builder: (context, state) => ModeratorEventForm(eventId: state.pathParameters['id']!)),
          ],
        ),
    
        // THIX Info - CORRIGE VIRGULES
        GoRoute(path: AppRoutes.thixInfo, name: 'thixInfo', pageBuilder: (_, __) => NoTransitionPage(child: const ThixInfoHome())),
        GoRoute(path: AppRoutes.thixInfoArticle, name: 'thixInfoArticle', pageBuilder: (_, state) {
          return NoTransitionPage(child: thixInfoArticle.ArticleDetailPage(articleId: state.pathParameters['articleId']!));
        }),
        GoRoute(path: AppRoutes.thixInfoSearch, name: 'thixInfoSearch', pageBuilder: (_, __) => NoTransitionPage(child: const infoSearch.SearchPage())),
        GoRoute(path: AppRoutes.thixInfoCategory, name: 'thixInfoCategory', pageBuilder: (_, state) {
          return NoTransitionPage(child: CategoryArticlesPage(category: state.pathParameters['category']!));
        }),
        GoRoute(path: AppRoutes.thixInfoSaved, name: 'thixInfoSaved', pageBuilder: (_, __) => NoTransitionPage(child: const SavedArticlesPage())),
        GoRoute(path: AppRoutes.thixInfoBreaking, name: 'thixInfoBreaking', pageBuilder: (_, __) => NoTransitionPage(child: const BreakingNewsPage())),

        // THIX Money, Media, Reservation
        GoRoute(path: AppRoutes.thixMoney, name: 'thixMoney', pageBuilder: (_, __) => NoTransitionPage(child: ThixMoneyPage())),
        GoRoute(path: AppRoutes.thixMedia, name: 'thixMedia', pageBuilder: (_, __) => NoTransitionPage(child: ThixMediaPage())),
        GoRoute(path: AppRoutes.thixMediaVideo, name: 'thixMediaVideo', pageBuilder: (_, state) {
          final title = (state.uri.queryParameters['title'] ?? '').trim();
          final url = (state.uri.queryParameters['url'] ?? '').trim();
          return NoTransitionPage(child: VideoPlayerPage(title: title.isEmpty ? 'Lecture vidéo' : title, videoUrl: url));
        }),
        GoRoute(path: AppRoutes.reservation, name: 'reservation', pageBuilder: (_, __) => NoTransitionPage(child: ThixReservationPage())),

        // THIX Evenement
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


        
// BUS
GoRoute(path: '/thix-reservation/bus', builder: (_, __) => const BusHomePage()),
GoRoute(path: '/thix-reservation/bus/search', builder: (_, __) => const BusSearchResultPage()),
GoRoute(path: '/thix-reservation/bus/trip/:id', builder: (ctx, state) { final trip = state.extra as BusTripModel; return BusTripDetailPage(trip: trip); }),
GoRoute(path: '/thix-reservation/bus/seats/:id', builder: (ctx, state) { final trip = state.extra as BusTripModel; return BusSeatSelectionPage(trip: trip); }),
GoRoute(path: '/thix-reservation/bus/passenger', builder: (ctx, state) { final data = state.extra as Map<String,dynamic>; return BusPaymentPage(trip: data['trip'] as BusTripModel, seats: data['seats'] as List<String>); }),
GoRoute(path: '/thix-reservation/bus/ticket/:id', builder: (ctx, state) { final b = state.extra as BookingModel; return BusTicketPage(booking: b); }),
// Agence SaaS
GoRoute(path: '/thix-reservation/bus/agency/onboarding', builder: (_, __) => const AgencyOnboardingPage()),
GoRoute(path: '/thix-reservation/bus/agency/dashboard', builder: (_, __) => const AgencyDashboardPage()),
GoRoute(path: '/thix-reservation/bus/agency/create-trip', builder: (_, __) => const AgencyCreateTripPage()),
GoRoute(path: '/thix-reservation/bus/agency/scan', builder: (_, __) => const AgencyQrScanPage()),
       
        // THIX Market
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
            GoRoute(path: 'product/:productId', name: 'marketProductDetail', pageBuilder: (_, state) => NoTransitionPage(child: ProductDetailPage(productId: state.pathParameters['productId']!))),
            GoRoute(path: 'shop/:shopId', name: 'marketShopDetail', pageBuilder: (_, state) => NoTransitionPage(child: ShopDetailPage(shopId: state.pathParameters['shopId']!))),
            GoRoute(path: 'compare', name: 'marketProductComparator', pageBuilder: (_, __) => NoTransitionPage(child: const ProductComparatorPage())),
            GoRoute(path: 'price-alerts', name: 'marketPriceAlerts', pageBuilder: (_, __) => NoTransitionPage(child: const PriceAlertsPage())),
            GoRoute(path: 'cart', name: 'marketCart', pageBuilder: (_, __) => NoTransitionPage(child: const CartPage())),
            GoRoute(path: 'checkout', name: 'marketCheckout', pageBuilder: (_, __) => NoTransitionPage(child: const CheckoutPage())),
            GoRoute(path: 'orders', name: 'marketOrders', pageBuilder: (_, __) => NoTransitionPage(child: const OrderHistoryPage())),
            GoRoute(path: 'order/:orderId', name: 'marketOrderDetail', pageBuilder: (_, state) => NoTransitionPage(child: OrderDetailPage(orderId: state.pathParameters['orderId']!))),
            GoRoute(path: 'chat/:shopId', name: 'marketChatSeller', pageBuilder: (_, state) {
              final shopId = state.pathParameters['shopId']!;
              final extra = state.extra as Map?;
              return NoTransitionPage(child: ChatPage(conversationId: '', shopId: shopId, title: extra?['title'] ?? 'Vendeur', avatar: extra?['userAvatar'] as String?));
            }),
            GoRoute(path: 'shop/create', name: 'marketCreateShop', pageBuilder: (_, __) => NoTransitionPage(child: const CreateShopPage())),
            GoRoute(path: 'shop/:shopId/manage', name: 'marketManageShop', pageBuilder: (_, state) => NoTransitionPage(child: ManageShopPage(shopId: state.pathParameters['shopId']!))),
            GoRoute(path: 'shop/:shopId/stats', name: 'marketShopStats', pageBuilder: (_, state) => NoTransitionPage(child: ShopStatisticsPage(shopId: state.pathParameters['shopId']!))),
            GoRoute(path: 'announcement/publish', name: 'marketPublishAnnouncement', pageBuilder: (_, __) => NoTransitionPage(child: const PublishAnnouncementPage())),
            GoRoute(path: 'vendor/dashboard', name: 'vendorDashboard', pageBuilder: (_, __) => NoTransitionPage(child: const VendorDashboard())),
            GoRoute(path: 'deliveries', name: 'deliveryManagement', pageBuilder: (_, __) => NoTransitionPage(child: const DeliveryManagementPage())),
            GoRoute(path: 'announcement/:announcementId/edit', name: 'marketEditAnnouncement', pageBuilder: (_, state) => NoTransitionPage(child: EditAnnouncementPage(announcementId: state.pathParameters['announcementId']!))),
            GoRoute(path: 'live/:liveId', name: 'marketLiveStream', pageBuilder: (_, state) => NoTransitionPage(child: LiveStreamPage(liveId: state.pathParameters['liveId']!))),
            GoRoute(path: 'live/create', name: 'marketCreateLive', pageBuilder: (_, __) => NoTransitionPage(child: const CreateLivePage())),
            GoRoute(path: 'live/:liveId/replay', name: 'marketLiveReplay', pageBuilder: (_, state) => NoTransitionPage(child: LiveReplayPage(liveId: state.pathParameters['liveId']!))),
            GoRoute(path: 'auction/:auctionId', name: 'marketAuction', pageBuilder: (_, state) => NoTransitionPage(child: AuctionPage(auctionId: state.pathParameters['auctionId']!))),
            GoRoute(path: 'chat/:conversationId', name: 'marketChat', pageBuilder: (_, state) => NoTransitionPage(child: ChatPage(conversationId: state.pathParameters['conversationId']!))),
            GoRoute(path: 'dispute/:disputeId', name: 'marketDispute', pageBuilder: (_, state) => NoTransitionPage(child: DisputeDetailPage(disputeId: state.pathParameters['disputeId']!))),
            GoRoute(path: 'notifications', name: 'marketNotifications', pageBuilder: (_, __) => NoTransitionPage(child: const NotificationPage())),
          ],
        ),

        // THIX INFO ADMIN - OUVERT - ALIAS
        GoRoute(path: '/admin', builder: (context, state) => const thix_admin.AdminHomePage()),
        GoRoute(path: '/admin/articles', builder: (context, state) => const thix_admin_list.AdminArticlesListPage()),
        GoRoute(path: '/admin/articles/new', builder: (context, state) => const thix_admin_form.AdminArticleFormPage()),
        GoRoute(path: '/admin/articles/:id/edit', builder: (context, state) => thix_admin_form.AdminArticleFormPage(articleId: state.pathParameters['id'])),

        // MON PAYS
        GoRoute(path: AppRoutes.monPays, name: 'monPays', pageBuilder: (_, __) => const NoTransitionPage(child: MonPaysPage()), routes: [
          GoRoute(path: 'authorities', name: 'monPaysAuthorities', pageBuilder: (_, __) => const NoTransitionPage(child: AuthoritiesPage())),
          GoRoute(path: 'authority/:id', name: 'monPaysAuthorityProfile', pageBuilder: (_, state) => NoTransitionPage(child: AuthorityProfilePage(authorityId: state.pathParameters['id']!))),
          GoRoute(path: 'laws', name: 'monPaysLaws', pageBuilder: (_, __) => const NoTransitionPage(child: LawsPage())),
          GoRoute(path: 'laws/:type', name: 'monPaysArticleType', pageBuilder: (_, state) => NoTransitionPage(child: ArticleTypePage(type: ArticleType.fromString(state.pathParameters['type']!), title: ArticleType.fromString(state.pathParameters['type']!).label))),
          GoRoute(path: 'laws/article/:id', name: 'monPaysArticleDetail', pageBuilder: (_, state) => NoTransitionPage(child: monPaysArticle.ArticleDetailPage(articleId: state.pathParameters['id']!))),
          GoRoute(path: 'provinces', name: 'monPaysProvinces', pageBuilder: (_, __) => const NoTransitionPage(child: ProvincesPage())),
          GoRoute(path: 'provinces/:id', name: 'monPaysProvinceDetail', pageBuilder: (_, state) => NoTransitionPage(child: ProvinceDetailPage(provinceId: state.pathParameters['id']!))),
          GoRoute(path: 'admin', name: 'monPaysAdmin', pageBuilder: (_, __) => const NoTransitionPage(child: AdminDashboardPage())),
          GoRoute(path: 'admin/authorities', name: 'monPaysAdminAuthorities', pageBuilder: (_, __) => const NoTransitionPage(child: AdminAuthoritiesPage())),
          GoRoute(path: 'admin/form', name: 'monPaysAdminForm', pageBuilder: (_, state) => NoTransitionPage(child: AdminAuthorityFormPage(authority: state.extra as dynamic))),
          GoRoute(path: 'admin/articles', name: 'monPaysAdminArticles', pageBuilder: (_, __) => const NoTransitionPage(child: monpays_articles.AdminArticlesPage())),
          GoRoute(path: 'admin/articles/form', name: 'monPaysAdminArticleForm', pageBuilder: (_, state) => NoTransitionPage(child: monpays_form.AdminArticleFormPage(article: state.extra as Article?))),
          GoRoute(path: 'admin/provinces', name: 'monPaysAdminProvinces', pageBuilder: (_, __) => const NoTransitionPage(child: AdminProvincesPage())),
          GoRoute(path: 'admin/provinces/form', name: 'monPaysAdminProvinceForm', pageBuilder: (_, state) => NoTransitionPage(child: AdminProvinceFormPage(province: state.extra as Province?))),
          GoRoute(path: 'admin/provinces/government/:provinceId', name: 'monPaysAdminGovernmentForm', pageBuilder: (_, state) => NoTransitionPage(child: AdminGovernmentFormPage(provinceId: state.pathParameters['provinceId']!))),
          GoRoute(path: 'admin/provinces/economic/:provinceId', name: 'monPaysAdminEconomicForm', pageBuilder: (_, state) => NoTransitionPage(child: AdminEconomicFormPage(provinceId: state.pathParameters['provinceId']!))),
          GoRoute(path: 'admin/provinces/budget/:provinceId', name: 'monPaysAdminBudgetForm', pageBuilder: (_, state) => NoTransitionPage(child: AdminBudgetFormPage(provinceId: state.pathParameters['provinceId']!))),
          GoRoute(path: 'admin/provinces/tourism/:provinceId', name: 'monPaysAdminTourismForm', pageBuilder: (_, state) => NoTransitionPage(child: AdminTourismFormPage(provinceId: state.pathParameters['provinceId']!))),
          GoRoute(path: 'admin/provinces/emergency/:provinceId', name: 'monPaysAdminEmergencyForm', pageBuilder: (_, state) => NoTransitionPage(child: AdminEmergencyFormPage(provinceId: state.pathParameters['provinceId']!))),
          GoRoute(path: 'admin/provinces/administrative/:provinceId', name: 'monPaysAdminAdministrativeForm', pageBuilder: (_, state) => NoTransitionPage(child: AdminAdministrativeFormPage(provinceId: state.pathParameters['provinceId']!))),
          GoRoute(path: 'admin/provinces/achievement/:provinceId', name: 'monPaysAdminAchievementForm', pageBuilder: (_, state) => NoTransitionPage(child: AdminAchievementFormPage(provinceId: state.pathParameters['provinceId']!))),
          GoRoute(path: 'admin/provinces/media/:provinceId', name: 'monPaysAdminMediaForm', pageBuilder: (_, state) => NoTransitionPage(child: AdminMediaFormPage(provinceId: state.pathParameters['provinceId']!))),
        ]),
        GoRoute(path: '${AppRoutes.admin}/:module', name: 'admin', pageBuilder: (_, state) => NoTransitionPage(child: AdminPage(module: AdminModuleX.fromSlug(state.pathParameters['module'])))),
        GoRoute(path: AppRoutes.admin, name: 'adminRoot', redirect: (_, __) => '${AppRoutes.admin}/${AdminModule.overview.slug}'),
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
