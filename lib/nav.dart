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
  static const String thixMediaVideo = '/thix-media-video'; 
static const String adminMedia = '/admin-media';
static const String thixMedia = '/thix-media';
static const String thixMoney = '/thix-money';
static const String reservation = '/reservation';

  
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

  // ═══════════════════════════════════════
  // ─── THIX CHAT (Routes complètes) ───
  // ═══════════════════════════════════════════════════════════════════════
  static const String chat = '/chat';
  static const String chatNew = '/chat/new';
  static const String chatConversation = '/chat/:conversationId';
  static String chatDetail(String conversationId) => '/chat/$conversationId';
// ==================== CHAT ESCALATION ====================
static const String chatEscalate = '/chat/escalate/:conversationId';
static const String chatEscalationHandle = '/chat/escalation/handle/:escalationId';
static const String chatEscalationHistory = '/chat/escalation/history/:conversationId';
static const String chatEscalationDashboard = '/chat/escalation/dashboard';
  static const String chatEscalationReceived = '/chat/escalation/received';
  // ─── Groupes ───
  static const String groupCreate = '/chat/group/create';
  static const String groupInfo = '/chat/group/:groupId/info';
  static const String groupSettings = '/chat/group/:groupId/settings';
  static const String groupMembers = '/chat/group/:groupId/members';
  static const String groupAddMembers = '/chat/group/:groupId/add-members';

  static String groupInfoPath(String groupId) => '/chat/group/$groupId/info';
  static String groupSettingsPath(String groupId) => '/chat/group/$groupId/settings';
  static String groupMembersPath(String groupId) => '/chat/group/$groupId/members';
  static String groupAddMembersPath(String groupId) => '/chat/group/$groupId/add-members';

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
  static const String monPays = '/mon-pays';
  static const String monPaysAuthorities = '/mon-pays/authorities';
  static const String monPaysAuthorityProfile = '/mon-pays/authority/:id';
  static String monPaysAuthorityProfilePath(String id) => '/mon-pays/authority/$id';

  static const String monPaysProvinces = '/mon-pays/provinces';
  static const String monPaysProvinceDetail = '/mon-pays/provinces/:id';
  static const String monPaysAdminProvinces = '/mon-pays/admin/provinces';
  static const String monPaysAdminProvinceForm = '/mon-pays/admin/provinces/form';
  static const String monPaysAdminGovernmentForm = '/mon-pays/admin/provinces/government/:provinceId';
  static const String monPaysAdminEconomicForm = '/mon-pays/admin/provinces/economic/:provinceId';
  static const String monPaysAdminBudgetForm = '/mon-pays/admin/provinces/budget/:provinceId';
  static const String monPaysAdminTourismForm = '/mon-pays/admin/provinces/tourism/:provinceId';
  static const String monPaysAdminEmergencyForm = '/mon-pays/admin/provinces/emergency/:provinceId';
  static const String monPaysAdminAdministrativeForm = '/mon-pays/admin/provinces/administrative/:provinceId';
  static const String monPaysAdminAchievementForm = '/mon-pays/admin/provinces/achievement/:provinceId';
  static const String monPaysAdminMediaForm = '/mon-pays/admin/provinces/media/:provinceId';

  static String monPaysProvinceDetailPath(String id) => '/mon-pays/provinces/$id';
  static String monPaysAdminProvinceFormPath({dynamic province}) => '/mon-pays/admin/provinces/form';
  static String monPaysAdminGovernmentFormPath(String provinceId) => '/mon-pays/admin/provinces/government/$provinceId';
  static String monPaysAdminEconomicFormPath(String provinceId) => '/mon-pays/admin/provinces/economic/$provinceId';
  static String monPaysAdminBudgetFormPath(String provinceId) => '/mon-pays/admin/provinces/budget/$provinceId';
  static String monPaysAdminTourismFormPath(String provinceId) => '/mon-pays/admin/provinces/tourism/$provinceId';
  static String monPaysAdminEmergencyFormPath(String provinceId) => '/mon-pays/admin/provinces/emergency/$provinceId';
  static String monPaysAdminAdministrativeFormPath(String provinceId) => '/mon-pays/admin/provinces/administrative/$provinceId';
  static String monPaysAdminAchievementFormPath(String provinceId) => '/mon-pays/admin/provinces/achievement/$provinceId';
  static String monPaysAdminMediaFormPath(String provinceId) => '/mon-pays/admin/provinces/media/$provinceId';

  static const String monPaysLaws = '/mon-pays/laws';
  static const String monPaysArticleType = '/mon-pays/laws/:type';
  static const String monPaysArticleDetail = '/mon-pays/laws/article/:id';
  static String monPaysArticleTypePath(String type) => '/mon-pays/laws/$type';
  static String monPaysArticleDetailPath(String id) => '/mon-pays/laws/article/$id';

  static const String monPaysAdmin = '/mon-pays/admin';
  static const String monPaysAdminAuthorities = '/mon-pays/admin/authorities';
  static const String monPaysAdminForm = '/mon-pays/admin/form';
  static const String monPaysAdminArticles = '/mon-pays/admin/articles';
  static const String monPaysAdminArticleForm = '/mon-pays/admin/articles/form';
  static String monPaysAdminFormPath({dynamic authority}) => '/mon-pays/admin/form';
  static String monPaysAdminArticleFormPath({dynamic article}) => '/mon-pays/admin/articles/form';

  // ========================================================================
  // ─── THIX SANTÉ - 31 Routes Complètes (20 Rapides + 11 Santé) ───
  // Source réelle Supabase RLS - THIX ID UID - Sans mock
  // ========================================================================

  // Base
  static const String thixSante = '/thix-sante';
  static const String thixSanteDashboard = '/thix-sante/dashboard';

  // ─── Services Rapides 20/20 (capture exacte, Don d'organes supprimé) ───
  static const String santeConsulterMedecin = '/thix-sante/consulter-medecin';
  static const String santeDossierMedical = '/thix-sante/dossier-medical';
  static const String santeResultatsExamens = '/thix-sante/resultats-examens';
  static const String santeOrdonnances = '/thix-sante/ordonnances';
  static const String santeTrouverHopital = '/thix-sante/trouver-hopital';
  static const String santeTrouverMedicament = '/thix-sante/trouver-medicament';
  static const String santePharmaciesProches = '/thix-sante/pharmacies-proches';
  static const String santeUrgencesProches = '/thix-sante/urgences-proches';
  static const String santePrendreRdv = '/thix-sante/prendre-rdv';
  static const String santeTeleconsultation = '/thix-sante/teleconsultation';
  static const String santeAssistantIA = '/thix-sante/assistant-ia';
  static const String santeDossierPartage = '/thix-sante/dossier-partage';
  static const String santeEpidemies = '/thix-sante/epidemies';
  static const String santeDonSang = '/thix-sante/don-sang';
  static const String santeMonMedecinTraitant = '/thix-sante/mon-medecin-traitant'; // NEW - health_links
  static const String santeDossierFamille = '/thix-sante/dossier-famille'; // NEW - family_links
  static const String santeSecondAvis = '/thix-sante/second-avis'; // NEW - second_opinion_requests
  static const String santeRappelsVaccin = '/thix-sante/rappels-vaccin';
  static const String santeCertificatMedical = '/thix-sante/certificat-medical';
  static const String santeAssurance = '/thix-sante/assurance';

  // ─── Services Santé 11/11 (sans mock, Supabase réel) ───
  static const String santeEnfants = '/thix-sante/sante-enfants'; // family_links relation=enfant
  static const String santeCarnetVaccination = '/thix-sante/carnet-vaccination'; // health_records type=vaccin + QR
  static const String santeSuiviGrossesse = '/thix-sante/suivi-grossesse'; // health_records ilike %grossesse% + calcul SA
  static const String santeAnalysePredictive = '/thix-sante/analyse-predictive'; // health_records+prescriptions+links -> score
  static const String santeBienEtreMental = '/thix-sante/bien-etre-mental'; // mood_entries
  static const String santeNutrition = '/thix-sante/nutrition'; // nutrition_logs + IMC réel
  static const String santeActivitePhysique = '/thix-sante/activite-physique'; // activity_logs
  static const String santeGestionStress = '/thix-sante/gestion-stress'; // stress_logs + timer
  static const String santeAssuranceSanteDetail = '/thix-sante/assurance-sante'; // insurance_claims + Storage invoices
  static const String santePlusServices = '/thix-sante/plus-services'; // service_catalog + user_favorites

  // ─── Helpers dynamiques THIX Santé ───
  static String santeOrdonnanceDetail(String id) => '/thix-sante/ordonnances/$id';
  static String santeDossierDetail(String recordId) => '/thix-sante/dossier-medical/$recordId';
  static String santeTeleconsultationRoom(String roomId) => '/thix-sante/teleconsultation/$roomId';
  static String santeHopitalDetail(String hopitalId) => '/thix-sante/trouver-hopital/$hopitalId';
  static String santePharmacieDetail(String pharmacieId) => '/thix-sante/pharmacies-proches/$pharmacieId';

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
