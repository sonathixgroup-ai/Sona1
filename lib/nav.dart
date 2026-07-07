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
// ---- RÉSEAU PRO (tous les imports) ----
import 'package:thix_id/presentation/network/network_pro_home.dart';
import 'package:thix_id/presentation/network/search_network_page.dart';
import 'package:thix_id/presentation/network/notifications/notifications_page.dart';
import 'package:thix_id/presentation/network/messages/conversations_list.dart';
import 'package:thix_id/presentation/network/messages/chat_screen.dart';
import 'package:thix_id/presentation/network/connections_list_page.dart';
import 'package:thix_id/presentation/network/community_detail_page.dart';
import 'package:thix_id/presentation/network/communities_list_page.dart';        // ✅ AJOUT
import 'package:thix_id/presentation/network/create_community_page.dart';          // ✅ AJOUT
import 'package:thix_id/presentation/network/post_detail_page.dart';
import 'package:thix_id/presentation/network/profile_page.dart';
import 'package:thix_id/presentation/network/profile_settings_page.dart';
import 'package:thix_id/presentation/network/blocked_users_page.dart';
import 'package:thix_id/presentation/network/discover_tab.dart';                  // ✅ AJOUT
import 'package:thix_id/presentation/network/story_viewer_screen.dart';           // ✅ AJOUT
import 'package:thix_id/presentation/network/comments_page.dart';                 // ✅ AJOUT
import 'package:thix_id/presentation/network/hashtag_page.dart';                  // ✅ AJOUT

import 'presentation/jobs/jobs_page.dart';
import 'package:thix_id/presentation/jobs/job_apply_page.dart';
import 'package:thix_id/presentation/jobs/job_details_page.dart';
import 'package:thix_id/presentation/jobs/job_dashboard_page.dart';
import 'package:thix_id/presentation/recruiter/recruiter_portal_page.dart';
import 'package:thix_id/presentation/opportunities/opportunities_page.dart';
import 'package:thix_id/presentation/opportunities/opportunity_apply_page.dart';
import 'package:thix_id/presentation/opportunities/opportunity_details_page.dart';

import 'package:thix_id/presentation/admin/admin_page.dart';
import 'package:thix_id/presentation/admin/admin_routes.dart';

// ==================== THIX INFO ====================
import 'package:thix_id/presentation/thix_info/thix_info_home.dart';
import 'package:thix_id/presentation/thix_info/article_detail_page.dart';
// ✅ Import avec préfixe pour résoudre le conflit avec le SearchPage du Market
import 'package:thix_id/presentation/thix_info/search_page.dart' as info;
import 'package:thix_id/presentation/thix_info/category_articles_page.dart';
import 'package:thix_id/presentation/thix_info/saved_articles_page.dart';
import 'package:thix_id/presentation/thix_info/breaking_news_page.dart';
import 'package:thix_id/presentation/admin/pages/admin_news_dashboard.dart';
import 'package:thix_id/presentation/admin/pages/admin_news_page.dart';
import 'package:thix_id/presentation/admin/pages/create_news_page.dart';

// ===== IMPORTS THIX MARKET (ajoutés) =====
import 'package:thix_id/presentation/thix_market/pages/market_home_page.dart';
// ✅ Import avec préfixe pour le SearchPage du Market (facultatif mais clair)
import 'package:thix_id/presentation/thix_market/pages/search_page.dart' as market;
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
// ===== IMPORTS THIX SANTÉ =====
import 'package:thix_id/presentation/thix_sante/thix_sante_page.dart';
import 'package:thix_id/presentation/thix_sante/thix_role.dart' ;
import 'package:thix_id/presentation/thix_sante/thix_sante_role_page.dart';

// Pages patient principales
import 'package:thix_id/presentation/thix_sante/patient/patient_dashboard_page.dart' as patient;
import 'package:thix_id/presentation/thix_sante/patient/patient_health_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/patient_care_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/patient_life_page.dart';
import 'package:thix_id/presentation/thix_sante/patient/patient_connect_page.dart';

// Pages patient détails
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

// Pages médecin
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

// Pages pharmacie
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

// Autres modules
import 'package:thix_id/presentation/thix_reservation/thix_reservation_page.dart';
import 'package:thix_id/presentation/thix_money/thix_money_page.dart';
import 'package:thix_id/presentation/thix_media/thix_media_page.dart';
import 'package:thix_id/presentation/thix_media/video_player_page.dart';
import 'package:thix_id/presentation/admin/pages/admin_media_page.dart';
import 'package:thix_id/presentation/splash/thix_id_start_page.dart';

// THIX ÉVÉNEMENT
import 'package:thix_id/presentation/thix_event/thix_event_home.dart';
import 'package:thix_id/presentation/thix_event/event_detail_page.dart';
import 'package:thix_id/presentation/thix_event/event_search_page.dart';
import 'package:thix_id/presentation/thix_event/event_category_page.dart';
import 'package:thix_id/presentation/thix_event/event_reservation_page.dart';
import 'package:thix_id/presentation/thix_event/my_tickets_page.dart';
import 'package:thix_id/presentation/thix_event/favorite_events_page.dart';
import 'package:thix_id/presentation/thix_event/seat_selection_page.dart';
import 'package:thix_id/presentation/thix_event/waiting_queue_page.dart';

// ===== THIX Chat – Écrans principaux =====
import 'package:thix_id/presentation/chat/screens/chat_status_screen.dart';
import 'package:thix_id/presentation/chat/screens/chat_status_update_screen.dart';
import 'package:thix_id/presentation/chat/screens/chat_spaces_screen.dart';
import 'package:thix_id/presentation/chat/screens/chat_call_screen.dart';
import 'package:thix_id/presentation/chat/screens/chat_incoming_call_screen.dart';

// ===== THIX Chat – Paramètres & personnalisation =====
import 'package:thix_id/presentation/chat/settings/ephemeral_settings_screen.dart';
import 'package:thix_id/presentation/chat/settings/translation_settings_screen.dart';
import 'package:thix_id/presentation/chat/settings/theme_selector_screen.dart';
import 'package:thix_id/presentation/chat/settings/bubble_customizer_screen.dart';
import 'package:thix_id/presentation/chat/settings/notification_sounds_screen.dart';
import 'package:thix_id/presentation/chat/settings/chat_wallpaper_screen.dart';
import 'package:thix_id/presentation/chat/settings/font_size_selector_screen.dart';
import 'package:thix_id/presentation/chat/settings/theme_preview_screen.dart';
import 'package:thix_id/presentation/chat/settings/status_settings_screen.dart';
import 'package:thix_id/presentation/chat/online_status/availability_schedule.dart';
import 'package:thix_id/presentation/chat/settings/status_presets_screen.dart';

// ===== THIX Chat – Archives =====
import 'package:thix_id/presentation/chat/archive/archive_screen.dart';
import 'package:thix_id/presentation/chat/archive/export_chat_screen.dart';
import 'package:thix_id/presentation/chat/archive/export_encrypted_screen.dart';

// ===== THIX Chat – Économie de données =====
import 'package:thix_id/presentation/chat/data_saver/low_data_mode_screen.dart';

// ===== THIX Chat – Widgets maison =====
import 'package:thix_id/presentation/chat/home_widgets/chat_widget_config_screen.dart';
import 'package:thix_id/presentation/chat/home_widgets/widget_preview_screen.dart';

// ===== THIX Chat – Sécurité avancée =====
import 'package:thix_id/presentation/chat/security/fingerprint_lock_screen.dart';
import 'package:thix_id/presentation/chat/security/secret_chat_folder_screen.dart';
import 'package:thix_id/presentation/chat/security/secret_conversation_screen.dart';
import 'package:thix_id/presentation/chat/security/self_destruct_screen.dart';
import 'package:thix_id/presentation/chat/security/anti_screenshot_screen.dart';
import 'package:thix_id/presentation/chat/security/fake_interface_screen.dart';
import 'package:thix_id/presentation/chat/security/theft_protection_screen.dart';
import 'package:thix_id/presentation/chat/security/session_manager_screen.dart';
import 'package:thix_id/presentation/chat/security/encryption_screen.dart';

// ===== THIX Chat – Hors ligne =====
import 'package:thix_id/presentation/chat/offline/offline_settings_screen.dart';

// ===== THIX Chat – Fonctionnalités diverses =====
import 'package:thix_id/presentation/chat/contact_share/contact_share_screen.dart';
import 'package:thix_id/presentation/chat/video_message/video_message_screen.dart';
import 'package:thix_id/presentation/chat/message_reminder/message_reminder_screen.dart';
import 'package:thix_id/presentation/chat/confidential_message/confidential_message_screen.dart';
import 'package:thix_id/presentation/chat/smart_notifications/smart_notifications_screen.dart';
import 'package:thix_id/presentation/chat/voice_translation/voice_translation_screen.dart';
import 'package:thix_id/presentation/chat/group_waiting_room/waiting_room_screen.dart';
import 'package:thix_id/presentation/chat/scheduled_recurring/recurring_schedule_screen.dart';

// ===== THIX Chat – NOUVELLES PAGES (placeholders) =====
import 'package:thix_id/presentation/chat/search/chat_search_page.dart';
import 'package:thix_id/presentation/chat/notifications/chat_notifications_page.dart';
import 'package:thix_id/presentation/chat/stats/chat_stats_page.dart';
import 'package:thix_id/presentation/chat/new_chat/new_chat_page.dart';
import 'package:thix_id/presentation/chat/filters/chat_filters_page.dart';
import 'package:thix_id/presentation/chat/online_users/online_users_page.dart';
import 'package:thix_id/presentation/chat/stories/new_story_page.dart';
import 'package:thix_id/presentation/chat/stories/story_detail_page.dart';

import 'package:thix_id/presentation/education/education_routes.dart';
// ============================================================
// Classes utilitaires
// ============================================================
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

// ============================================================
// AppRoutes – toutes les routes constantes
// ============================================================
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
  static const String admin = '/admin';
  static const String thixMarket = '/market';
  // ─── Éducation ───
  static const String education = '/education';          
  static const String trainingHome = '/education';
  static const String trainingDetailsBasePath = '/education';
  static const String instructorDashboard = '/instructor/dashboard';
  static const String instructorCourses = '/instructor/courses';
  
  // THIX Santé
  static const String thixSante = '/sante';
  static const String thixSantePatient = '/sante/patient';
  static const String thixSanteDoctor = '/sante/medecin';
  static const String thixSantePharmacy = '/sante/pharmacie';
  static const String reservation = '/reservation';
  static const String thixMoney = '/thix-money';
  static const String thixMedia = '/thix-media';
  static const String thixMediaVideo = '/thix-media/video';
  static const String adminMedia = '/admin/media';
  
  // THIX INFO
  static const String thixInfo = '/thix-info';
  static const String thixInfoArticle = '/thix-info/article/:articleId';
  static const String thixInfoSearch = '/thix-info/search';
  static const String thixInfoCategory = '/thix-info/category/:category';
  static const String thixInfoSaved = '/thix-info/saved';
  static const String thixInfoBreaking = '/thix-info/breaking';
  static const String thixInfoAdmin = '/thix-info/admin';
  static const String thixInfoCreate = '/thix-info/admin/create';
  static const String thixInfoEdit = '/thix-info/admin/edit/:articleId';

  // ===== THIX Chat – Routes principales =====
  static const String chatStatus = '/chat/status';
  static const String chatStatusUpdate = '/chat/status/update';
  static const String chatSpaces = '/chat/spaces';
  static const String chatCall = '/chat/call';
  static const String chatIncomingCall = '/chat/incoming';

  // ===== THIX Chat – Routes ajoutées pour les fonctionnalités manquantes =====
  static const String chatSearch = '/chat/search';
  static const String chatNotifications = '/chat/notifications';
  static const String chatStats = '/chat/stats';
  static const String chatNew = '/chat/new';
  static const String chatFilters = '/chat/filters';
  static const String chatOnline = '/chat/online';
  static const String chatStoryNew = '/chat/story/new';
  static const String chatStoryDetail = '/chat/story/:storyId';

  // ===== THIX Chat – Paramètres & personnalisation =====
  static const String chatEphemeralSettings = '/chat/ephemeral/settings';
  static const String chatTranslationSettings = '/chat/translation/settings';
  static const String chatThemes = '/chat/themes';
  static const String chatBubbleCustomize = '/chat/bubble/customize';
  static const String chatNotificationSounds = '/chat/notification/sounds';
  static const String chatWallpaper = '/chat/wallpaper';
  static const String chatFontSize = '/chat/font/size';
  static const String chatThemePreview = '/chat/theme/preview';
  static const String chatStatusSettings = '/chat/status/settings';
  static const String chatAvailabilitySchedule = '/chat/availability/schedule';
  static const String chatStatusPresets = '/chat/status/presets';

  // ===== THIX Chat – Archives & export =====
  static const String chatArchive = '/chat/archive';
  static const String chatExport = '/chat/export/:id';
  static const String chatExportEncrypted = '/chat/export/encrypted/:id';

  // ===== THIX Chat – Économie de données =====
  static const String chatDataSaver = '/chat/data/saver';

  // ===== THIX Chat – Widgets maison =====
  static const String chatWidgetsConfig = '/chat/widgets/config';
  static const String chatWidgetsPreview = '/chat/widgets/preview';

  // ===== THIX Chat – Sécurité avancée =====
  static const String chatSecurityLock = '/chat/security/lock';
  static const String chatSecretFolder = '/chat/secret/folder';
  static const String chatSecretConversation = '/chat/secret/conversation/:id';
  static const String chatSelfDestruct = '/chat/self-destruct';
  static const String chatAntiScreenshot = '/chat/anti-screenshot';
  static const String chatFakeInterface = '/chat/fake-interface';
  static const String chatTheftProtection = '/chat/theft-protection';
  static const String chatSessionManager = '/chat/session';
  static const String chatEncryption = '/chat/encryption';

  // ===== THIX Chat – Hors ligne =====
  static const String chatOfflineSettings = '/chat/offline/settings';

  // ===== THIX Chat – Fonctionnalités diverses =====
  static const String chatContactShare = '/chat/contact/share/:userId';
  static const String chatVideoMessage = '/chat/video-message';
  static const String chatMessageReminder = '/chat/reminder';
  static const String chatConfidentialMessage = '/chat/confidential';
  static const String chatSmartNotifications = '/chat/smart-notifications';
  static const String chatVoiceTranslation = '/chat/voice-translation';
  static const String chatGroupWaitingRoom = '/chat/group/waiting-room';
  static const String chatRecurringSchedule = '/chat/scheduled/recurring';
  
  // THIX ÉVÉNEMENT
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
  
  static String networkChat(String userId) => '$networkChatBasePath/$userId';
  static String networkPost(String postId) => '$networkPostBasePath/$postId';
  static String networkCommunity(String communityId) => '$networkCommunityBasePath/$communityId';
  static String networkProfile(String userId) => '$networkProfileBasePath/$userId';
}

// ============================================================
// GoRouter – création du routeur
// ============================================================
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
          pageBuilder: (context, state) =>
              NoTransitionPage(child: ThixIdStartPage()),
        ),
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: HomePagePremium()),
        ),
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: LoginPage()),
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
              NoTransitionPage(child: EnterpriseRegistrationPage()),
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
              NoTransitionPage(child: UserDashboardPage()),
        ),
        GoRoute(
          path: AppRoutes.enterpriseDashboard,
          name: 'enterpriseDashboard',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: EnterpriseDashboardPage()),
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

        // ============================================================
        // THIX CHAT – Routes principales + toutes les fonctionnalités
        // ============================================================
        GoRoute(
          path: AppRoutes.chat,
          name: 'chat',
          pageBuilder: (context, state) => NoTransitionPage(child: ThixChatPage()),
          routes: [
            // Conversation
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
            // === Routes fonctionnelles ajoutées ===
            GoRoute(
              path: 'search',
              name: 'chatSearch',
              pageBuilder: (context, state) => NoTransitionPage(child: ChatSearchPage()),
            ),
            GoRoute(
              path: 'notifications',
              name: 'chatNotifications',
              pageBuilder: (context, state) => NoTransitionPage(child: ChatNotificationsPage()),
            ),
            GoRoute(
              path: 'stats',
              name: 'chatStats',
              pageBuilder: (context, state) => NoTransitionPage(child: ChatStatsPage()),
            ),
            GoRoute(
              path: 'new',
              name: 'chatNew',
              pageBuilder: (context, state) => NoTransitionPage(child: NewChatPage()),
            ),
            GoRoute(
              path: 'filters',
              name: 'chatFilters',
              pageBuilder: (context, state) => NoTransitionPage(child: ChatFiltersPage()),
            ),
            GoRoute(
              path: 'online',
              name: 'chatOnline',
              pageBuilder: (context, state) => NoTransitionPage(child: OnlineUsersPage()),
            ),
            GoRoute(
              path: 'story/new',
              name: 'chatStoryNew',
              pageBuilder: (context, state) => NoTransitionPage(child: NewStoryPage()),
            ),
            GoRoute(
              path: 'story/:storyId',
              name: 'chatStoryDetail',
              pageBuilder: (context, state) {
                final storyId = state.pathParameters['storyId']!;
                return NoTransitionPage(child: StoryDetailPage(storyId: storyId));
              },
            ),

            // === Routes de statut ===
            GoRoute(
              path: 'status',
              name: 'chatStatus',
              pageBuilder: (context, state) => NoTransitionPage(child: ChatStatusScreen()),
            ),
            GoRoute(
              path: 'status/update',
              name: 'chatStatusUpdate',
              pageBuilder: (context, state) => NoTransitionPage(child: ChatStatusUpdateScreen()),
            ),
            GoRoute(
              path: 'spaces',
              name: 'chatSpaces',
              pageBuilder: (context, state) => NoTransitionPage(child: ChatSpacesScreen()),
            ),
            GoRoute(
              path: 'call',
              name: 'chatCall',
              pageBuilder: (context, state) {
                final extra = state.extra as Map?;
                return NoTransitionPage(
                  child: ChatCallScreen(
                    callId: extra?['callId'] ?? '',
                    callName: extra?['callName'] ?? 'Appel',
                    participants: extra?['participants'] ?? [],
                    isVideoCall: extra?['isVideoCall'] ?? false,
                  ),
                );
              },
            ),
            GoRoute(
              path: 'incoming',
              name: 'chatIncomingCall',
              pageBuilder: (context, state) {
                final extra = state.extra as Map?;
                return NoTransitionPage(
                  child: ChatIncomingCallScreen(
                    callerName: extra?['callerName'] ?? 'Appel entrant',
                    callType: extra?['callType'] ?? 'audio',
                  ),
                );
              },
            ),

            // === Paramètres et personnalisation ===
            GoRoute(
              path: 'ephemeral/settings',
              name: 'chatEphemeralSettings',
              pageBuilder: (context, state) => NoTransitionPage(child: EphemeralSettingsScreen()),
            ),
            GoRoute(
              path: 'translation/settings',
              name: 'chatTranslationSettings',
              pageBuilder: (context, state) => NoTransitionPage(child: TranslationSettingsScreen()),
            ),
            GoRoute(
              path: 'themes',
              name: 'chatThemes',
              pageBuilder: (context, state) => NoTransitionPage(child: ThemeSelectorScreen()),
            ),
            GoRoute(
              path: 'bubble/customize',
              name: 'chatBubbleCustomize',
              pageBuilder: (context, state) => NoTransitionPage(child: BubbleCustomizerScreen()),
            ),
            GoRoute(
              path: 'notification/sounds',
              name: 'chatNotificationSounds',
              pageBuilder: (context, state) => NoTransitionPage(child: NotificationSoundsScreen()),
            ),
            GoRoute(
              path: 'wallpaper',
              name: 'chatWallpaper',
              pageBuilder: (context, state) => NoTransitionPage(child: ChatWallpaperScreen()),
            ),
            GoRoute(
              path: 'font/size',
              name: 'chatFontSize',
              pageBuilder: (context, state) => NoTransitionPage(child: FontSizeSelectorScreen()),
            ),
            GoRoute(
              path: 'theme/preview',
              name: 'chatThemePreview',
              pageBuilder: (context, state) => NoTransitionPage(child: ThemePreviewScreen()),
            ),
            GoRoute(
              path: 'status/settings',
              name: 'chatStatusSettings',
              pageBuilder: (context, state) => NoTransitionPage(child: StatusSettingsScreen()),
            ),
            GoRoute(
              path: 'availability/schedule',
              name: 'availabilitySchedule',
              pageBuilder: (context, state) => NoTransitionPage(
                child: const AvailabilitySchedule(),
              ),
            ),
            GoRoute(
              path: 'status/presets',
              name: 'chatStatusPresets',
              pageBuilder: (context, state) => NoTransitionPage(child: StatusPresetsScreen()),
            ),

            // === Archives ===
            GoRoute(
              path: 'archive',
              name: 'chatArchive',
              pageBuilder: (context, state) => NoTransitionPage(child: ArchiveScreen()),
            ),
            GoRoute(
              path: 'export/:id',
              name: 'chatExport',
              pageBuilder: (context, state) {
                final conversationId = state.pathParameters['id']!;
                final conversationName = state.uri.queryParameters['name'] ?? 'Conversation';
                return NoTransitionPage(
                  child: ExportChatScreen(
                    conversationId: conversationId,
                    conversationName: conversationName,
                  ),
                );
              },
            ),
            GoRoute(
              path: 'export/encrypted/:id',
              name: 'chatExportEncrypted',
              pageBuilder: (context, state) {
                final conversationId = state.pathParameters['id']!;
                return NoTransitionPage(
                  child: ExportEncryptedScreen(conversationId: conversationId),
                );
              },
            ),

            // === Économie de données ===
            GoRoute(
              path: 'data/saver',
              name: 'chatDataSaver',
              pageBuilder: (context, state) => NoTransitionPage(child: LowDataModeScreen()),
            ),

            // === Widgets maison ===
            GoRoute(
              path: 'widgets/config',
              name: 'chatWidgetsConfig',
              pageBuilder: (context, state) => NoTransitionPage(child: ChatWidgetConfigScreen()),
            ),
            GoRoute(
              path: 'widgets/preview',
              name: 'chatWidgetsPreview',
              pageBuilder: (context, state) => NoTransitionPage(child: WidgetPreviewScreen()),
            ),

            // === Sécurité avancée ===
            GoRoute(
              path: 'security/lock',
              name: 'chatSecurityLock',
              pageBuilder: (context, state) => NoTransitionPage(child: FingerprintLockScreen()),
            ),
            GoRoute(
              path: 'secret/folder',
              name: 'chatSecretFolder',
              pageBuilder: (context, state) => NoTransitionPage(child: SecretChatFolderScreen()),
            ),
            GoRoute(
              path: 'secret/conversation/:id',
              name: 'chatSecretConversation',
              pageBuilder: (context, state) {
                final conversationId = state.pathParameters['id']!;
                return NoTransitionPage(
                  child: SecretConversationScreen(conversationId: conversationId),
                );
              },
            ),
            GoRoute(
              path: 'self-destruct',
              name: 'chatSelfDestruct',
              pageBuilder: (context, state) => NoTransitionPage(child: SelfDestructScreen()),
            ),
            GoRoute(
              path: 'anti-screenshot',
              name: 'chatAntiScreenshot',
              pageBuilder: (context, state) => NoTransitionPage(child: AntiScreenshotScreen()),
            ),
            GoRoute(
              path: 'fake-interface',
              name: 'chatFakeInterface',
              pageBuilder: (context, state) => NoTransitionPage(child: FakeInterfaceScreen()),
            ),
            GoRoute(
              path: 'theft-protection',
              name: 'chatTheftProtection',
              pageBuilder: (context, state) => NoTransitionPage(child: TheftProtectionScreen()),
            ),
            GoRoute(
              path: 'session',
              name: 'chatSessionManager',
              pageBuilder: (context, state) => NoTransitionPage(child: SessionManagerScreen()),
            ),
            GoRoute(
              path: 'encryption',
              name: 'chatEncryption',
              pageBuilder: (context, state) => NoTransitionPage(child: EncryptionScreen()),
            ),

            // === Hors ligne ===
            GoRoute(
              path: 'offline/settings',
              name: 'chatOfflineSettings',
              pageBuilder: (context, state) => NoTransitionPage(child: OfflineSettingsScreen()),
            ),

            // === Fonctionnalités diverses ===
            GoRoute(
              path: 'contact/share/:userId',
              name: 'chatContactShare',
              pageBuilder: (context, state) {
                final userId = state.pathParameters['userId']!;
                return NoTransitionPage(
                  child: ContactShareScreen(userId: userId),
                );
              },
            ),
            GoRoute(
              path: 'video-message',
              name: 'chatVideoMessage',
              pageBuilder: (context, state) => NoTransitionPage(child: VideoMessageScreen()),
            ),
            GoRoute(
              path: 'reminder',
              name: 'chatMessageReminder',
              pageBuilder: (context, state) => NoTransitionPage(child: MessageReminderScreen()),
            ),
            GoRoute(
              path: 'confidential',
              name: 'chatConfidentialMessage',
              pageBuilder: (context, state) => NoTransitionPage(child: ConfidentialMessageScreen()),
            ),
            GoRoute(
              path: 'smart-notifications',
              name: 'chatSmartNotifications',
              pageBuilder: (context, state) => NoTransitionPage(child: SmartNotificationsScreen()),
            ),
            GoRoute(
              path: 'voice-translation',
              name: 'chatVoiceTranslation',
              pageBuilder: (context, state) => NoTransitionPage(child: VoiceTranslationScreen()),
            ),
            GoRoute(
              path: 'group/waiting-room',
              name: 'chatGroupWaitingRoom',
              pageBuilder: (context, state) => NoTransitionPage(child: WaitingRoomScreen()),
            ),
            GoRoute(
              path: 'scheduled/recurring',
              name: 'chatRecurringSchedule',
              pageBuilder: (context, state) => NoTransitionPage(child: RecurringScheduleScreen()),
            ),
          ],
        ),

        // ---- Réseau ----
        GoRoute(
          path: AppRoutes.network,
          name: 'network',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: NetworkProHome()),
        ),
        GoRoute(
          path: AppRoutes.networkSearch,
          name: 'networkSearch',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: SearchNetworkPage()),
        ),
        GoRoute(
          path: AppRoutes.networkNotifications,
          name: 'networkNotifications',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: NotificationsPage()),
        ),
        GoRoute(
          path: AppRoutes.networkMessages,
          name: 'networkMessages',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: ConversationsList()),
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
              NoTransitionPage(child: ConnectionsListPage()),
        ),
        GoRoute(
          path: AppRoutes.networkProfileSettings,
          name: 'networkProfileSettings',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: ProfileSettingsPage()),
        ),
        GoRoute(
          path: AppRoutes.networkBlockedUsers,
          name: 'networkBlockedUsers',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: BlockedUsersPage()),
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
        // ---- Nouveautés Réseau Pro ----
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
    return NoTransitionPage(
      child: CommentsPage(
        postId: postId,
        currentProfileId: currentProfileId,
      ),
    );
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

// ✅ Correction de la route networkProfile
GoRoute(
  path: '${AppRoutes.networkProfileBasePath}/:userId',
  name: 'networkProfile',
  pageBuilder: (context, state) {
    final userId = state.pathParameters['userId']!; // ✅ ajout du !
    final currentProfileId = Supabase.instance.client.auth.currentUser?.id ?? '';
    return NoTransitionPage(
      child: ProfilePage(
        userId: userId,
        currentProfileId: currentProfileId, // ✅ ajout du paramètre requis
      ),
    );
  },
),
        GoRoute(
          path: AppRoutes.profile,
          name: 'profile',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: ProfilePage()),
        ),
        // === Routes supplémentaires pour le Réseau Pro ===
        GoRoute(
          path: '/video-upload',
          name: 'videoUpload',
          pageBuilder: (context, state) =>
              NoTransitionPage(
                child: Scaffold(
                  appBar: AppBar(title: const Text('Chargement vidéo')),
                  body: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_library, size: 80, color: Colors.blue),
                        SizedBox(height: 20),
                        Text('Page de chargement vidéo (à implémenter)'),
                        SizedBox(height: 10),
                        Text('Remplacez ce Scaffold par votre widget réel'),
                      ],
                    ),
                  ),
                ),
              ),
        ),
        GoRoute(
          path: '/opportunity-detail',
          name: 'opportunityDetail',
          pageBuilder: (context, state) {
            final extra = state.extra as Map?;
            final title = extra?['title'] ?? 'Opportunité';
            final sub = extra?['sub'] ?? '';
            return NoTransitionPage(
              child: Scaffold(
                appBar: AppBar(title: Text(title)),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📌 Opportunité : $title', style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 8),
                      Text('Sous-titre : $sub'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Retour'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
       
        // ==================== THIX INFO ====================
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
          // ✅ Utilisation du SearchPage préfixé (info)
          pageBuilder: (context, state) => NoTransitionPage(child: const info.SearchPage()),
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

        // ---- THIX Market ----
        GoRoute(
          path: AppRoutes.thixMarket,
          name: 'thixMarket',
          pageBuilder: (context, state) => NoTransitionPage(child: const MarketHomePage()),
          routes: [
            // Pages principales
            GoRoute(
              path: 'home',
              name: 'marketHome',
              pageBuilder: (context, state) => NoTransitionPage(child: const MarketHomePage()),
            ),
            GoRoute(
              path: 'search',
              name: 'marketSearch',
              // ✅ Utilisation du SearchPage préfixé (market)
              pageBuilder: (context, state) => NoTransitionPage(child: const market.SearchPage()),
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
            // Produits
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
            // Panier & commandes
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
                    conversationId: '', // sera créée à l'ouverture
                    shopId: shopId,
                    title: extra?['title'] ?? 'Vendeur',
                    avatar: extra?['userAvatar'],
                  ),
                );
              },
            ),            
            // Boutiques
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
            // Annonces
            GoRoute(
              path: 'announcement/publish',
              name: 'marketPublishAnnouncement',
              pageBuilder: (context, state) => NoTransitionPage(child: const PublishAnnouncementPage()),
            ),
            // Dans la section THIX Market
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
            // Live & enchères
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
            // Messages & litiges
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

        // ---- THIX Santé ----
        // Point d'entrée principal
        GoRoute(
          path: AppRoutes.thixSante,
          name: 'thixSante',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: ThixSantePage()),
        ),
        // Sélection de rôle
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
              NoTransitionPage(child: patient.PatientDashboardPage()),
        ),
        GoRoute(
          path: '/sante/patient/health',
          name: 'patientHealth',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PatientHealthPage()),
        ),
        GoRoute(
          path: '/sante/patient/care',
          name: 'patientCare',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PatientCarePage()),
        ),
        GoRoute(
          path: '/sante/patient/life',
          name: 'patientLife',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PatientLifePage()),
        ),
        GoRoute(
          path: '/sante/patient/connect',
          name: 'patientConnect',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PatientConnectPage()),
        ),

        // Détails Patient
        // Rendez-vous
        GoRoute(
          path: '/sante/patient/appointments',
          name: 'patientAppointmentsList',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PatientAppointmentsListPage()),
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
              NoTransitionPage(child: PatientAppointmentPage()),
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
              NoTransitionPage(child: PatientPrescriptionsListPage()),
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
              NoTransitionPage(child: PatientExamsListPage()),
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
              NoTransitionPage(child: PatientScanPage()),
        ),
        // Téléconsultation Jitsi (rejoindre)
        GoRoute(
          path: '/sante/patient/teleconsultation/:id',
          name: 'patientTeleconsultation',
          pageBuilder: (context, state) {
            final link = state.extra as String? ?? 'https://meet.jit.si/default';
            return NoTransitionPage(
              child: PatientTeleconsultationJitsiPage(link: link),
            );
          },
        ),
        // Téléconsultation - création
        GoRoute(
          path: '/sante/patient/teleconsultation/new',
          name: 'patientTeleconsultationNew',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PatientTeleconsultationPage()),
        ),
        // Téléconsultation - détail / édition
        GoRoute(
          path: '/sante/patient/teleconsultation/:id',
          name: 'patientTeleconsultationDetail',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            final isEditing = state.uri.queryParameters['edit'] == 'true';
            return NoTransitionPage(
              child: PatientTeleconsultationPage(
                consultationId: id,
                isEditing: isEditing,
              ),
            );
          },
        ),
        // Téléconsultation Jitsi (lancement direct)
        GoRoute(
          path: '/sante/patient/teleconsultation/jitsi',
          name: 'patientTeleconsultationJitsi',
          pageBuilder: (context, state) {
            final link = state.extra as String? ?? 'https://meet.jit.si/default';
            return NoTransitionPage(
              child: PatientTeleconsultationJitsiPage(link: link),
            );
          },
        ),
        // Score de santé
        GoRoute(
          path: '/sante/patient/health-score',
          name: 'patientHealthScore',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PatientHealthScorePage()),
        ),
        // Assurance
        GoRoute(
          path: '/sante/patient/insurance',
          name: 'patientInsurance',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PatientInsurancePage()),
        ),
        // Dossier médical
        GoRoute(
          path: '/sante/patient/record',
          name: 'patientRecord',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PatientRecordPage()),
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
              NoTransitionPage(child: PatientTeleexpertiseRequestPage()),
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
              NoTransitionPage(child: PatientSymptomPage()),
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
              NoTransitionPage(child: PatientVitalPage()),
        ),
        GoRoute(
          path: '/sante/patient/vitals/chart',
          name: 'patientVitalChart',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PatientVitalChartPage()),
        ),
        GoRoute(
          path: '/sante/patient/record/add',
          name: 'patientRecordAdd',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PatientRecordAddPage()),
        ),
        // Médicaments
        GoRoute(
          path: '/sante/patient/medications',
          name: 'patientMedications',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PatientMedicationsListPage()),
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
              NoTransitionPage(child: PatientMedicationPage()),
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
              NoTransitionPage(child: PatientVaccinationCalendarPage()),
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
              NoTransitionPage(child: PatientVaccinePage()),
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
              NoTransitionPage(child: PatientPregnancyPage()),
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
              NoTransitionPage(child: PatientFamilyPage()),
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
              NoTransitionPage(child: PatientSharingPage()),
        ),
        // IA Chat
        GoRoute(
          path: '/sante/patient/ia',
          name: 'patientIA',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PatientAIChatPage()),
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
              NoTransitionPage(child: PatientAlertPage()),
        ),
        GoRoute(
          path: '/sante/patient/alert/:id',
          name: 'patientAlert',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(child: PatientAlertPage(alertId: id));
          },
        ),
        // Grossesse - liste (sans ID)
        GoRoute(
          path: '/sante/patient/pregnancy',
          name: 'patientPregnancyList',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PatientPregnancyPage()),
        ),
        // Famille - liste (sans ID)
        GoRoute(
          path: '/sante/patient/family',
          name: 'patientFamilyList',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PatientFamilyPage()),
        ),
        // Partage - liste (sans ID)
        GoRoute(
          path: '/sante/patient/sharing',
          name: 'patientSharingList',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PatientSharingPage()),
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
              NoTransitionPage(child: PatientConsentPage()),
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
              NoTransitionPage(child: PatientNotificationsPage()),
        ),
        // Profil
        GoRoute(
          path: '/sante/patient/profile',
          name: 'patientProfile',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PatientProfilePage()),
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
              NoTransitionPage(child: PatientChatNewPage()),
        ),

        // ----- Module Médecin -----
        // Pages principales
        GoRoute(
          path: '/sante/doctor/dashboard',
          name: 'doctorDashboard',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: DoctorDashboardPage()),
        ),
        GoRoute(
          path: '/sante/doctor/care',
          name: 'doctorCare',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: DoctorCarePage()),
        ),
        GoRoute(
          path: '/sante/doctor/consult',
          name: 'doctorConsult',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: DoctorConsultPage()),
        ),
        GoRoute(
          path: '/sante/doctor/connect',
          name: 'doctorConnect',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: DoctorConnectPage()),
        ),
        // Détails Médecin
        // Patients
        GoRoute(
          path: '/sante/doctor/patients',
          name: 'doctorPatients',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: DoctorPatientsPage()),
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
              NoTransitionPage(child: DoctorPatientAddPage()),
        ),
        // Prescriptions
        GoRoute(
          path: '/sante/doctor/prescription/new',
          name: 'doctorPrescriptionNew',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: DoctorPrescriptionPage()),
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
              NoTransitionPage(child: DoctorTeleconsultPage()),
        ),
        GoRoute(
          path: '/sante/doctor/teleconsultation/jitsi',
          name: 'doctorJitsi',
          pageBuilder: (context, state) {
            final link = state.extra as String? ?? 'https://meet.jit.si/default';
            return NoTransitionPage(
                child: PatientTeleconsultationJitsiPage(link: link));
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
              NoTransitionPage(child: DoctorTeleexpertisePage()),
        ),
        // Agenda
        GoRoute(
          path: '/sante/doctor/agenda',
          name: 'doctorAgenda',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: DoctorAgendaPage()),
        ),
        GoRoute(
          path: '/sante/doctor/agenda/slots',
          name: 'doctorAgendaSlots',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: DoctorSlotManagementPage()),
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
              NoTransitionPage(child: DoctorNotePage()),
        ),
        // Statistiques
        GoRoute(
          path: '/sante/doctor/statistics',
          name: 'doctorStatistics',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: DoctorStatisticsPage()),
        ),
        // Terrain
        GoRoute(
          path: '/sante/doctor/terrain/scan',
          name: 'doctorTerrainScan',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: DoctorScanBraceletPage()),
        ),
        GoRoute(
          path: '/sante/doctor/terrain/dictation',
          name: 'doctorTerrainDictation',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: DoctorVoiceDictationPage()),
        ),
        GoRoute(
          path: '/sante/doctor/terrain/offline',
          name: 'doctorTerrainOffline',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: DoctorOfflinePatientsPage()),
        ),
        GoRoute(
          path: '/sante/doctor/terrain/photo',
          name: 'doctorTerrainPhoto',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: DoctorPhotoCapturePage()),
        ),
        // Chat
        GoRoute(
          path: '/sante/doctor/messages/:id',
          name: 'doctorChat',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            final name = state.extra as String?;
            return NoTransitionPage(
                child: DoctorChatPage(chatId: id, participantName: name));
          },
        ),
        GoRoute(
          path: '/sante/doctor/messages/new',
          name: 'doctorChatNew',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: DoctorChatPage(chatId: '')),
        ),
        // Alertes
        GoRoute(
          path: '/sante/doctor/alerts',
          name: 'doctorAlerts',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: DoctorAlertPage()),
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
              NoTransitionPage(child: PharmacyDashboardPage()),
        ),
        GoRoute(
          path: '/sante/pharmacy/orders',
          name: 'pharmacyOrders',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PharmacyOrdersPage()),
        ),
        GoRoute(
          path: '/sante/pharmacy/inventory',
          name: 'pharmacyInventory',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PharmacyInventoryPage()),
        ),
        GoRoute(
          path: '/sante/pharmacy/connect',
          name: 'pharmacyConnect',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PharmacyConnectPage()),
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
              NoTransitionPage(child: PharmacyOrderPage(orderId: '')),
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
              NoTransitionPage(child: PharmacyDispensingPage()),
        ),
        // Livraisons
        GoRoute(
          path: '/sante/pharmacy/delivery',
          name: 'pharmacyDelivery',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PharmacyDeliveryPage()),
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
              NoTransitionPage(child: PharmacyInventoryItemPage()),
        ),
        // Stock
        GoRoute(
          path: '/sante/pharmacy/stock',
          name: 'pharmacyStock',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PharmacyStockPage()),
        ),
        // Rapports
        GoRoute(
          path: '/sante/pharmacy/report',
          name: 'pharmacyReport',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PharmacyReportPage()),
        ),
        // Chat
        GoRoute(
          path: '/sante/pharmacy/chat/:id',
          name: 'pharmacyChat',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            final name = state.extra as String?;
            return NoTransitionPage(
                child: PharmacyChatPage(chatId: id, participantName: name));
          },
        ),
        GoRoute(
          path: '/sante/pharmacy/chat/new',
          name: 'pharmacyChatNew',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PharmacyChatPage(chatId: '')),
        ),

        // ---- Pages produits, détail produit et panier ----
        GoRoute(
          path: '/sante/pharmacy/products',
          name: 'pharmacyProducts',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PharmacyProductsPage()),
        ),
        GoRoute(
          path: '/sante/pharmacy/product/:id',
          name: 'pharmacyProductDetail',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(
              child: PharmacyProductDetailPage(productId: id),
            );
          },
        ),
        GoRoute(
          path: '/sante/pharmacy/cart',
          name: 'pharmacyCart',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: PharmacyCartPage()),
        ),

        // ---- Autres modules THIX ----
        GoRoute(
          path: AppRoutes.thixMoney,
          name: 'thixMoney',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: ThixMoneyPage()),
        ),
        GoRoute(
          path: AppRoutes.thixMedia,
          name: 'thixMedia',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: ThixMediaPage()),
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
          path: AppRoutes.reservation,
          name: 'reservation',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: ThixReservationPage()),
        ),

        // ==================== THIX ÉVÉNEMENT ====================
        GoRoute(
          path: AppRoutes.thixEvent,
          name: 'thixEvent',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: ThixEventHome()),
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
              NoTransitionPage(child: EventSearchPage()),
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
              NoTransitionPage(child: MyTicketsPage()),
        ),
        GoRoute(
          path: AppRoutes.thixEventFavorites,
          name: 'thixEventFavorites',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: FavoriteEventsPage()),
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
              NoTransitionPage(child: JobsPage()),
        ),
        GoRoute(
          path: AppRoutes.jobDashboard,
          name: 'jobDashboard',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: JobDashboardPage()),
        ),
        GoRoute(
          path: AppRoutes.recruiter,
          name: 'recruiter',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: RecruiterPortalPage()),
        ),
        // Opportunités
        GoRoute(
          path: AppRoutes.opportunities,
          name: 'opportunities',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: OpportunitiesPage()),
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
       
          GoRoute(
  path: '/education',
  name: 'educationTemp',
  pageBuilder: (context, state) => const NoTransitionPage(child: EducationHome()),
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
        ...educationRoutes,
        ...instructorRoutes,
        // Admin
        GoRoute(
          path: '${AppRoutes.admin}/:module',
          name: 'admin',
          pageBuilder: (context, state) {
            final module = AdminModuleX.fromSlug(
              state.pathParameters['module'],
            );
            return NoTransitionPage(
              child: AdminPage(module: module),
            );
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
              NoTransitionPage(child: AdminMediaPage()),
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
