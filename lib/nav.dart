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
  static const String instructorDashboard = '/';
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

  // ═══════════════════════════════════════════════════════════════════════
  // ─── THIX CHAT (Routes complètes) ───
  // ═══════════════════════════════════════════════════════════════════════
  static const String chat = '/chat';
  static const String chatNew = '/chat/new';
  static const String chatConversation = '/chat/:conversationId';
  static String chatDetail(String conversationId) => '/chat/$conversationId';

  // ─── Groupes ───
  static const String groupCreate = '/chat/group/create';
  static const String groupInfo = '/chat/group/:groupId/info';
  static const String groupSettings = '/chat/group/:groupId/settings';
  static const String groupMembers = '/chat/group/:groupId/members';
  static const String groupAddMembers = '/chat/group/:groupId/add-members';

  // Helpers pour les routes dynamiques (Groupes)
  static String groupInfoPath(String groupId) => '/chat/group/$groupId/info';
  static String groupSettingsPath(String groupId) => '/chat/group/$groupId/settings';
  static String groupMembersPath(String groupId) => '/chat/group/$groupId/members';
  static String groupAddMembersPath(String groupId) => '/chat/group/$groupId/add-members';

  // ─── Nouveauté : Messages protégés ───
  // Pas de route spécifique, géré dans ChatScreen via dialog

  // ─── Nouveauté : Appels audio/vidéo (à venir) ───
  static const String call = '/call';
  static const String callIncoming = '/call/incoming';
  static const String callOutgoing = '/call/outgoing';
  static String callWithUser(String userId) => '/call/$userId';

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

  // ═══════════════════════════════════════════════════════════════════════
  // ─── MON PAYS ───
  // ═══════════════════════════════════════════════════════════════════════
  // === Routes principales ===
  static const String monPays = '/mon-pays';
  
  // === Autorités ===
  static const String monPaysAuthorities = '/mon-pays/authorities';
  static const String monPaysAuthorityProfile = '/mon-pays/authority/:id';
  static const String monPaysAuthorityProfilePath(String id) => '/mon-pays/authority/$id';

  // === Valeurs & Lois ===
  static const String monPaysLaws = '/mon-pays/laws';
  static const String monPaysArticleType = '/mon-pays/laws/:type';
  static const String monPaysArticleTypePath(String type) => '/mon-pays/laws/$type';
  static const String monPaysArticleDetail = '/mon-pays/laws/article/:id';
  static const String monPaysArticleDetailPath(String id) => '/mon-pays/laws/article/$id';

  // === Administration ===
  static const String monPaysAdmin = '/mon-pays/admin';
  static const String monPaysAdminAuthorities = '/mon-pays/admin/authorities';
  static const String monPaysAdminForm = '/mon-pays/admin/form';
  static const String monPaysAdminFormPath({dynamic authority}) => '/mon-pays/admin/form';
  static const String monPaysAdminArticles = '/mon-pays/admin/articles';
  static const String monPaysAdminArticleForm = '/mon-pays/admin/articles/form';
  static const String monPaysAdminArticleFormPath({dynamic article}) => '/mon-pays/admin/articles/form';

  // === Helpers pour les routes dynamiques ===
  static String monPaysAuthorityProfilePath(String id) => '/mon-pays/authority/$id';
  static String monPaysAdminFormPath({dynamic authority}) => '/mon-pays/admin/form';

  // ========================================================================
  // HELPERS GÉNÉRIQUES
  // ========================================================================
  static String enterprisePortalBase(String slug) => '$enterprisePortalBasePath/$slug';
  static String enterprisePortalDashboard(String slug, String section) => '/company/$slug/dashboard/$section';
  static String networkChat(String userId) => '$networkChatBasePath/$userId';
  static String networkPost(String postId) => '$networkPostBasePath/$postId';
  static String networkCommunity(String communityId) => '$networkCommunityBasePath/$communityId';
  static String networkProfile(String userId) => '$networkProfileBasePath/$userId';
}
