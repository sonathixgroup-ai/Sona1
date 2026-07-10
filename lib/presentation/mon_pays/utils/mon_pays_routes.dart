// lib/presentation/mon_pays/utils/mon_pays_routes.dart

/// Routes spécifiques au module Mon Pays
/// Ces constantes sont utilisées dans app_router.dart
class MonPaysRoutes {
  // Page principale
  static const String monPays = '/mon-pays';
  static const String monPaysAdmin = '/mon-pays/admin';

  // Pages "Voir tout" (listes complètes)
  static const String monPaysAuthorities = '/mon-pays/authorities';
  static const String monPaysGovernment = '/mon-pays/government';
  static const String monPaysMinistries = '/mon-pays/ministries';
  static const String monPaysAgencies = '/mon-pays/agencies';
  static const String monPaysHistory = '/mon-pays/history';
  static const String monPaysNews = '/mon-pays/news';
  static const String monPaysValues = '/mon-pays/values';
  static const String monPaysVideos = '/mon-pays/videos';
  static const String monPaysDocumentaries = '/mon-pays/documentaries';
  static const String monPaysWanted = '/mon-pays/wanted';
  static const String monPaysCitizens = '/mon-pays/citizens';
  static const String monPaysConsultations = '/mon-pays/consultations';
  static const String monPaysEmergency = '/mon-pays/emergency';

  // Pages de détail (avec paramètre :id)
  static const String monPaysAuthorityDetail = '/mon-pays/authority/:id';
  static const String monPaysGovernmentDetail = '/mon-pays/government/:id';
  static const String monPaysMinistryDetail = '/mon-pays/ministry/:id';
  static const String monPaysAgencyDetail = '/mon-pays/agency/:id';
  static const String monPaysAgencyServices = '/mon-pays/agency/:id/services';
  static const String monPaysHistoryDetail = '/mon-pays/history/:id';
  static const String monPaysNewsDetail = '/mon-pays/news/:id';
  static const String monPaysValueDetail = '/mon-pays/value/:id';
  static const String monPaysVideoDetail = '/mon-pays/video/:id';
  static const String monPaysDocumentaryDetail = '/mon-pays/documentary/:id';
  static const String monPaysWantedDetail = '/mon-pays/wanted/:id';
  static const String monPaysCitizenDetail = '/mon-pays/citizen/:id';
  static const String monPaysConsultationDetail = '/mon-pays/consultation/:id';

  // Pages spécifiques des valeurs
  static const String monPaysConstitution = '/mon-pays/constitution';
  static const String monPaysLaws = '/mon-pays/laws';
  static const String monPaysInstitutions = '/mon-pays/institutions';
  static const String monPaysRights = '/mon-pays/rights';
  static const String monPaysDuties = '/mon-pays/duties';
  static const String monPaysJustice = '/mon-pays/justice';

  // Pages de recherche
  static const String monPaysSearch = '/mon-pays/search';
  static const String monPaysSearchResult = '/mon-pays/search/result';
}
