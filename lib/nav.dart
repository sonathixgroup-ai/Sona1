// lib/nav.dart
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
  
  // Éducation
  static const String education = '/education';
  static const String trainingHome = '/education';
  static const String trainingDetailsBasePath = '/education';
  static const String instructorDashboard = '/instructor/dashboard';
  static const String instructorCourses = '/instructor/courses';
  
  // Santé
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

  // THIX Chat
  static const String chatStatus = '/chat/status';
  static const String chatStatusUpdate = '/chat/status/update';
  static const String chatSpaces = '/chat/spaces';
  static const String chatCall = '/chat/call';
  static const String chatIncomingCall = '/chat/incoming';
  static const String chatSearch = '/chat/search';
  static const String chatNotifications = '/chat/notifications';
  static const String chatStats = '/chat/stats';
  static const String chatNew = '/chat/new';
  static const String chatFilters = '/chat/filters';
  static const String chatOnline = '/chat/online';
  static const String chatStoryNew = '/chat/story/new';
  static const String chatStoryDetail = '/chat/story/:storyId';
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
  static const String chatArchive = '/chat/archive';
  static const String chatExport = '/chat/export/:id';
  static const String chatExportEncrypted = '/chat/export/encrypted/:id';
  static const String chatDataSaver = '/chat/data/saver';
  static const String chatWidgetsConfig = '/chat/widgets/config';
  static const String chatWidgetsPreview = '/chat/widgets/preview';
  static const String chatSecurityLock = '/chat/security/lock';
  static const String chatSecretFolder = '/chat/secret/folder';
  static const String chatSecretConversation = '/chat/secret/conversation/:id';
  static const String chatSelfDestruct = '/chat/self-destruct';
  static const String chatAntiScreenshot = '/chat/anti-screenshot';
  static const String chatFakeInterface = '/chat/fake-interface';
  static const String chatTheftProtection = '/chat/theft-protection';
  static const String chatSessionManager = '/chat/session';
  static const String chatEncryption = '/chat/encryption';
  static const String chatOfflineSettings = '/chat/offline/settings';
  static const String chatContactShare = '/chat/contact/share/:userId';
  static const String chatVideoMessage = '/chat/video-message';
  static const String chatMessageReminder = '/chat/reminder';
  static const String chatConfidentialMessage = '/chat/confidential';
  static const String chatSmartNotifications = '/chat/smart-notifications';
  static const String chatVoiceTranslation = '/chat/voice-translation';
  static const String chatGroupWaitingRoom = '/chat/group/waiting-room';
  static const String chatRecurringSchedule = '/chat/scheduled/recurring';

  // THIX Événement
  static const String thixEvent = '/thix-event';
  static const String thixEventDetail = '/thix-event/event/:eventId';
  static const String thixEventSearch = '/thix-event/search';
  static const String thixEventCategory = '/thix-event/category/:category';
  static const String thixEventReservation = '/thix-event/reservation/:eventId';
  static const String thixEventMyTickets = '/thix-event/my-tickets';
  static const String thixEventFavorites = '/thix-event/favorites';
  static const String thixEventSeatSelection = '/thix-event/seat-selection/:eventId';
  static const String thixEventWaitingQueue = '/thix-event/waiting-queue/:eventId';

  // Modérateur
  static const String moderatorHome = '/moderator';
  static const String moderatorEvents = '/moderator/events';
  static const String moderatorEventCreate = '/moderator/event/create';
  static const String moderatorEventEdit = '/moderator/event/edit/:id';

  // Helpers
  static String enterprisePortalBase(String slug) => '$enterprisePortalBasePath/$slug';
  static String enterprisePortalDashboard(String slug, String section) => '/company/$slug/dashboard/$section';
  static String networkChat(String userId) => '$networkChatBasePath/$userId';
  static String networkPost(String postId) => '$networkPostBasePath/$postId';
  static String networkCommunity(String communityId) => '$networkCommunityBasePath/$communityId';
  static String networkProfile(String userId) => '$networkProfileBasePath/$userId';
}
