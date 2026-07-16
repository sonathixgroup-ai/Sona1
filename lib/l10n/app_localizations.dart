import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:thix_id/l10n/locale_controller.dart';

class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)?? const AppLocalizations(Locale('fr'));

  static const _strings = <String, Map<String, String>>{
    'fr': {
      'language': 'Langue', 'choose_language': 'Choisir la langue', 'system_default': 'Langue du téléphone',
      'login': 'Se connecter', 'cancel': 'Annuler', 'later': 'Plus tard', 'settings': 'Paramètres', 'my_account': 'Mon compte', 'request_account': 'Demander un compte',
      'settings_title': 'Paramètres & Préférences', 'settings_language_group': 'LANGUE', 'settings_choose_ui_language': "Choisissez votre langue d'interface",
      'settings_appearance_group': 'APPARENCE', 'settings_dark_mode': 'Mode sombre', 'settings_dark_mode_sub': 'Activer le thème haute performance', 'settings_high_contrast': 'Contraste élevé', 'settings_high_contrast_sub': 'Optimiser pour la visibilité',
      'settings_security_group': 'SÉCURITÉ INSTITUTIONNELLE', 'settings_biometrics': 'Biométrie (Empreinte)', 'settings_biometrics_sub': 'Utiliser pour la connexion', 'settings_face_id': 'Face ID / Reconnaissance faciale', 'settings_face_id_sub': 'Niveau de sécurité 2', 'settings_change_password': 'Changer le mot de passe', 'settings_2fa': 'Double authentification (2FA)', 'settings_2fa_sub': 'Recommandé', 'settings_active': 'ACTIF',
      'settings_account_group': 'GESTION DU COMPTE', 'settings_data_privacy': 'Confidentialité des données', 'settings_activity_log': "Journal d'activité", 'settings_sign_out': 'Se déconnecter de THIX ID', 'settings_tagline': 'Identité sécurisée. Avenir de confiance.',
      'dashboard_security_title': 'Sécurité du compte', 'dashboard_security_subtitle': 'Paramètres de protection et journalisation', 'dashboard_biometrics_toggle': 'Biométrie (Face ID / Empreinte)', 'dashboard_2fa_toggle': 'Double authentification (2FA)',
      // HOME
      'headerGreeting': 'Mbote', 'commonSearch': 'Rechercher', 'bannerAnnouncements': 'Annonces et mises à jour', 'bannerHeadline': 'À la une',
      'quickThixIA': 'THIX IA', 'quickDocument': 'Document', 'quickChat': 'THIX CHAT', 'quickUrgence': 'URGENCE',
      'servicesTitle': 'Mes services', 'serviceMedia': 'THIX MEDIA', 'serviceReservation': 'Réservation', 'serviceMarket': 'THIX Market', 'serviceFormations': 'Formations', 'serviceMonPays': 'Mon Pays', 'serviceMoney': 'Thix Money', 'serviceEmplois': 'Emplois', 'serviceSante': 'THIX Santé', 'serviceReseauPro': 'Réseau Pro', 'serviceOpportunites': 'Opportunités', 'serviceInfo': 'THIX INFO', 'serviceEvenements': 'Événements',
      'marketTitle': 'Marché', 'marketCart': 'Panier', 'marketCheckout': 'Payer', 'marketAddToCart': 'Ajouter au panier', 'chatTitle': 'Messages', 'educationTitle': 'Formations', 'busTitle': 'Réservation Bus', 'eventTitle': 'Événements',
    },
    'en': {
      'language': 'Language', 'choose_language': 'Choose language', 'system_default': 'Device language',
      'login': 'Sign in', 'cancel': 'Cancel', 'later': 'Later', 'settings': 'Settings', 'my_account': 'My account', 'request_account': 'Request an account',
      'settings_title': 'Settings & Preferences', 'settings_language_group': 'LANGUAGE', 'settings_choose_ui_language': 'Choose your interface language',
      'settings_appearance_group': 'APPEARANCE', 'settings_dark_mode': 'Dark mode', 'settings_dark_mode_sub': 'Enable high-performance theme', 'settings_high_contrast': 'High contrast', 'settings_high_contrast_sub': 'Optimize for readability',
      'settings_security_group': 'INSTITUTIONAL SECURITY', 'settings_biometrics': 'Biometrics (Fingerprint)', 'settings_biometrics_sub': 'Use for sign-in', 'settings_face_id': 'Face ID / Facial recognition', 'settings_face_id_sub': 'Security level 2', 'settings_change_password': 'Change password', 'settings_2fa': 'Two-factor authentication (2FA)', 'settings_2fa_sub': 'Recommended', 'settings_active': 'ACTIVE',
      'settings_account_group': 'ACCOUNT MANAGEMENT', 'settings_data_privacy': 'Data privacy', 'settings_activity_log': 'Activity log', 'settings_sign_out': 'Sign out of THIX ID', 'settings_tagline': 'Secure identity. Trusted future.',
      'dashboard_security_title': 'Account security', 'dashboard_security_subtitle': 'Protection settings & audit logs', 'dashboard_biometrics_toggle': 'Biometrics (Face ID / Fingerprint)', 'dashboard_2fa_toggle': 'Two-factor authentication (2FA)',
      'headerGreeting': 'Hello', 'commonSearch': 'Search', 'bannerAnnouncements': 'Announcements & Updates', 'bannerHeadline': 'Featured',
      'quickThixIA': 'THIX AI', 'quickDocument': 'Documents', 'quickChat': 'THIX CHAT', 'quickUrgence': 'EMERGENCY',
      'servicesTitle': 'My services', 'serviceMedia': 'THIX MEDIA', 'serviceReservation': 'Booking', 'serviceMarket': 'THIX Market', 'serviceFormations': 'Training', 'serviceMonPays': 'My Country', 'serviceMoney': 'Thix Money', 'serviceEmplois': 'Jobs', 'serviceSante': 'THIX Health', 'serviceReseauPro': 'Pro Network', 'serviceOpportunites': 'Opportunities', 'serviceInfo': 'THIX INFO', 'serviceEvenements': 'Events',
      'marketTitle': 'Market', 'marketCart': 'Cart', 'marketCheckout': 'Checkout', 'marketAddToCart': 'Add to cart', 'chatTitle': 'Messages', 'educationTitle': 'Courses', 'busTitle': 'Bus Booking', 'eventTitle': 'Events',
    },
    'pt': {
      'language': 'Idioma', 'choose_language': 'Escolher idioma', 'system_default': 'Idioma do telefone',
      'login': 'Entrar', 'cancel': 'Cancelar', 'later': 'Mais tarde', 'settings': 'Configurações', 'my_account': 'Minha conta', 'request_account': 'Solicitar conta',
      'settings_title': 'Configurações e Preferências', 'settings_language_group': 'IDIOMA', 'settings_choose_ui_language': 'Escolha o idioma da interface',
      'settings_appearance_group': 'APARÊNCIA', 'settings_dark_mode': 'Modo escuro', 'settings_dark_mode_sub': 'Ativar tema de alto desempenho', 'settings_high_contrast': 'Alto contraste', 'settings_high_contrast_sub': 'Otimizar legibilidade',
      'settings_security_group': 'SEGURANÇA INSTITUCIONAL', 'settings_biometrics': 'Biometria (Impressão digital)', 'settings_biometrics_sub': 'Usar para login', 'settings_face_id': 'Face ID / Reconhecimento facial', 'settings_face_id_sub': 'Nível de segurança 2', 'settings_change_password': 'Alterar senha', 'settings_2fa': 'Autenticação de dois fatores (2FA)', 'settings_2fa_sub': 'Recomendado', 'settings_active': 'ATIVO',
      'settings_account_group': 'GERENCIAMENTO DE CONTA', 'settings_data_privacy': 'Privacidade de dados', 'settings_activity_log': 'Registro de atividades', 'settings_sign_out': 'Sair do THIX ID', 'settings_tagline': 'Identidade segura. Futuro confiável.',
      'dashboard_security_title': 'Segurança da conta', 'dashboard_security_subtitle': 'Configurações de proteção e logs', 'dashboard_biometrics_toggle': 'Biometria (Face ID / Digital)', 'dashboard_2fa_toggle': 'Autenticação de dois fatores (2FA)',
      'headerGreeting': 'Olá', 'commonSearch': 'Pesquisar', 'bannerAnnouncements': 'Anúncios e atualizações', 'bannerHeadline': 'Em destaque',
      'quickThixIA': 'THIX IA', 'quickDocument': 'Documentos', 'quickChat': 'THIX CHAT', 'quickUrgence': 'EMERGÊNCIA',
      'servicesTitle': 'Meus serviços', 'serviceMedia': 'THIX MEDIA', 'serviceReservation': 'Reserva', 'serviceMarket': 'THIX Market', 'serviceFormations': 'Formações', 'serviceMonPays': 'Meu País', 'serviceMoney': 'Thix Money', 'serviceEmplois': 'Empregos', 'serviceSante': 'THIX Saúde', 'serviceReseauPro': 'Rede Pro', 'serviceOpportunites': 'Oportunidades', 'serviceInfo': 'THIX INFO', 'serviceEvenements': 'Eventos',
      'marketTitle': 'Mercado', 'marketCart': 'Carrinho', 'marketCheckout': 'Pagar', 'marketAddToCart': 'Adicionar', 'chatTitle': 'Mensagens', 'educationTitle': 'Cursos', 'busTitle': 'Reserva Ônibus', 'eventTitle': 'Eventos',
    },
    'ar': {
      'language': 'اللغة', 'choose_language': 'اختر اللغة', 'system_default': 'لغة الهاتف',
      'login': 'تسجيل الدخول', 'cancel': 'إلغاء', 'later': 'لاحقًا', 'settings': 'الإعدادات', 'my_account': 'حسابي', 'request_account': 'طلب حساب',
      'settings_title': 'الإعدادات والتفضيلات', 'settings_language_group': 'اللغة', 'settings_choose_ui_language': 'اختر لغة الواجهة',
      'settings_appearance_group': 'المظهر', 'settings_dark_mode': 'الوضع الداكن', 'settings_dark_mode_sub': 'تفعيل السمة عالية الأداء', 'settings_high_contrast': 'تباين عالٍ', 'settings_high_contrast_sub': 'تحسين سهولة القراءة',
      'settings_security_group': 'الأمان المؤسسي', 'settings_biometrics': 'البصمة', 'settings_biometrics_sub': 'استخدمها لتسجيل الدخول', 'settings_face_id': 'Face ID / التعرف على الوجه', 'settings_face_id_sub': 'مستوى أمان 2', 'settings_change_password': 'تغيير كلمة المرور', 'settings_2fa': 'المصادقة الثنائية', 'settings_2fa_sub': 'موصى بها', 'settings_active': 'مُفعّل',
      'settings_account_group': 'إدارة الحساب', 'settings_data_privacy': 'خصوصية البيانات', 'settings_activity_log': 'سجل النشاط', 'settings_sign_out': 'تسجيل الخروج', 'settings_tagline': 'هوية آمنة. مستقبل موثوق.',
      'dashboard_security_title': 'أمان الحساب', 'dashboard_security_subtitle': 'إعدادات الحماية وسجلات التدقيق', 'dashboard_biometrics_toggle': 'القياسات الحيوية', 'dashboard_2fa_toggle': 'المصادقة الثنائية',
      'headerGreeting': 'مرحبا', 'commonSearch': 'بحث', 'bannerAnnouncements': 'الإعلانات', 'bannerHeadline': 'أهم الأخبار',
      'quickThixIA': 'THIX AI', 'quickDocument': 'المستندات', 'quickChat': 'دردشة', 'quickUrgence': 'طوارئ',
      'servicesTitle': 'خدماتي', 'serviceMedia': 'ميديا', 'serviceReservation': 'حجز', 'serviceMarket': 'السوق', 'serviceFormations': 'تدريب', 'serviceMonPays': 'بلدي', 'serviceMoney': 'مالي', 'serviceEmplois': 'وظائف', 'serviceSante': 'الصحة', 'serviceReseauPro': 'الشبكة', 'serviceOpportunites': 'فرص', 'serviceInfo': 'معلومات', 'serviceEvenements': 'فعاليات',
      'marketTitle': 'السوق', 'marketCart': 'السلة', 'marketCheckout': 'الدفع', 'marketAddToCart': 'أضف', 'chatTitle': 'الرسائل', 'educationTitle': 'الدورات', 'busTitle': 'حجز الحافلات', 'eventTitle': 'الفعاليات',
    },
    'zh': {
      'language': '语言', 'choose_language': '选择语言', 'system_default': '系统语言',
      'login': '登录', 'cancel': '取消', 'later': '稍后', 'settings': '设置', 'my_account': '我的账户', 'request_account': '申请账户',
      'settings_title': '设置与偏好', 'settings_language_group': '语言', 'settings_choose_ui_language': '选择界面语言',
      'settings_appearance_group': '外观', 'settings_dark_mode': '深色模式', 'settings_dark_mode_sub': '启用高性能主题', 'settings_high_contrast': '高对比度', 'settings_high_contrast_sub': '优化可读性',
      'settings_security_group': '机构安全', 'settings_biometrics': '生物识别', 'settings_biometrics_sub': '用于登录', 'settings_face_id': '面容识别', 'settings_face_id_sub': '安全等级 2', 'settings_change_password': '修改密码', 'settings_2fa': '双重验证', 'settings_2fa_sub': '推荐', 'settings_active': '已激活',
      'settings_account_group': '账户管理', 'settings_data_privacy': '数据隐私', 'settings_activity_log': '活动日志', 'settings_sign_out': '退出 THIX ID', 'settings_tagline': '安全身份，可信未来。',
      'dashboard_security_title': '账户安全', 'dashboard_security_subtitle': '保护设置和日志', 'dashboard_biometrics_toggle': '生物识别', 'dashboard_2fa_toggle': '双重验证',
      'headerGreeting': '你好', 'commonSearch': '搜索', 'bannerAnnouncements': '公告', 'bannerHeadline': '头条',
      'quickThixIA': 'THIX AI', 'quickDocument': '文档', 'quickChat': '聊天', 'quickUrgence': '紧急',
      'servicesTitle': '我的服务', 'serviceMedia': '媒体', 'serviceReservation': '预订', 'serviceMarket': '市场', 'serviceFormations': '培训', 'serviceMonPays': '我的国家', 'serviceMoney': '钱包', 'serviceEmplois': '工作', 'serviceSante': '健康', 'serviceReseauPro': '人脉', 'serviceOpportunites': '机会', 'serviceInfo': '资讯', 'serviceEvenements': '活动',
      'marketTitle': '市场', 'marketCart': '购物车', 'marketCheckout': '结算', 'marketAddToCart': '加入', 'chatTitle': '消息', 'educationTitle': '课程', 'busTitle': '巴士预订', 'eventTitle': '活动',
    },
    'sw': {
      'language': 'Lugha', 'choose_language': 'Chagua lugha', 'system_default': 'Lugha ya simu',
      'login': 'Ingia', 'cancel': 'Ghairi', 'later': 'Baadaye', 'settings': 'Mipangilio', 'my_account': 'Akaunti yangu', 'request_account': 'Omba akaunti',
      'settings_title': 'Mipangilio na Mapendeleo', 'settings_language_group': 'LUGHA', 'settings_choose_ui_language': 'Chagua lugha ya matumizi',
      'settings_appearance_group': 'MWONEKANO', 'settings_dark_mode': 'Hali ya giza', 'settings_dark_mode_sub': 'Washa mandhari ya utendaji wa juu', 'settings_high_contrast': 'Tofauti ya juu', 'settings_high_contrast_sub': 'Boresha usomaji',
      'settings_security_group': 'USALAMA WA TAASISI', 'settings_biometrics': 'Biometria', 'settings_biometrics_sub': 'Tumia kuingia', 'settings_face_id': 'Face ID', 'settings_face_id_sub': 'Kiwango cha usalama 2', 'settings_change_password': 'Badilisha nenosiri', 'settings_2fa': 'Uthibitishaji wa hatua mbili', 'settings_2fa_sub': 'Inapendekezwa', 'settings_active': 'INAWAKA',
      'settings_account_group': 'USIMAMIZI WA AKAUNTI', 'settings_data_privacy': 'Faragha ya data', 'settings_activity_log': 'Rekodi ya shughuli', 'settings_sign_out': 'Toka THIX ID', 'settings_tagline': 'Utambulisho salama. Kesho ya uaminifu.',
      'dashboard_security_title': 'Usalama wa akaunti', 'dashboard_security_subtitle': 'Mipangilio ya ulinzi na kumbukumbu', 'dashboard_biometrics_toggle': 'Biometria', 'dashboard_2fa_toggle': 'Uthibitishaji wa hatua mbili',
      'headerGreeting': 'Jambo', 'commonSearch': 'Tafuta', 'bannerAnnouncements': 'Matangazo', 'bannerHeadline': 'Habari kuu',
      'quickThixIA': 'THIX IA', 'quickDocument': 'Nyaraka', 'quickChat': 'THIX CHAT', 'quickUrgence': 'DHARURA',
      'servicesTitle': 'Huduma zangu', 'serviceMedia': 'MEDIA', 'serviceReservation': 'Uhifadhi', 'serviceMarket': 'Soko', 'serviceFormations': 'Mafunzo', 'serviceMonPays': 'Nchi Yangu', 'serviceMoney': 'Pesa', 'serviceEmplois': 'Ajira', 'serviceSante': 'Afya', 'serviceReseauPro': 'Mtandao', 'serviceOpportunites': 'Fursa', 'serviceInfo': 'Habari', 'serviceEvenements': 'Matukio',
      'marketTitle': 'Soko', 'marketCart': 'Kikapu', 'marketCheckout': 'Lipa', 'marketAddToCart': 'Weka', 'chatTitle': 'Ujumbe', 'educationTitle': 'Mafunzo', 'busTitle': 'Basi', 'eventTitle': 'Matukio',
    },
    'ln': {
      'language': 'Lokóta', 'choose_language': 'Pona lokóta', 'system_default': 'Lokóta ya telefone',
      'login': 'Kokóta', 'cancel': 'Tika', 'later': 'Sima', 'settings': 'Paramɛtrɛ', 'my_account': 'Konti na ngai', 'request_account': 'Senga konti',
      'settings_title': 'Paramɛtrɛ & Preferansi', 'settings_language_group': 'LOKÓTA', 'settings_choose_ui_language': "Pona lokóta ya interface",
      'settings_appearance_group': 'BOMÓNI', 'settings_dark_mode': 'Mode ya molili', 'settings_dark_mode_sub': 'Pesa tema ya performance', 'settings_high_contrast': 'Contraste makasi', 'settings_high_contrast_sub': 'Bongisa ndenge ya komona',
      'settings_security_group': 'SÉCURITÉ YA INSTITUTION', 'settings_biometrics': 'Biométrie', 'settings_biometrics_sub': 'Salela mpo na kokóta', 'settings_face_id': 'Face ID', 'settings_face_id_sub': 'Niveau ya sécurité 2', 'settings_change_password': 'Bongola mot de passe', 'settings_2fa': 'Double authentification', 'settings_2fa_sub': 'Esengeli', 'settings_active': 'AKTIF',
      'settings_account_group': 'GESTION YA KONTI', 'settings_data_privacy': 'Confidentialité', 'settings_activity_log': 'Journal ya misala', 'settings_sign_out': 'Bimá na THIX ID', 'settings_tagline': 'Identité ya libateli.',
      'dashboard_security_title': 'SÉCURITÉ ya konti', 'dashboard_security_subtitle': 'Paramɛtrɛ ya libateli', 'dashboard_biometrics_toggle': 'Biométrie', 'dashboard_2fa_toggle': 'Double authentification',
      'headerGreeting': 'Mbote', 'commonSearch': 'Luka', 'bannerAnnouncements': 'Nsango', 'bannerHeadline': 'Ya motuya',
      'quickThixIA': 'THIX IA', 'quickDocument': 'Mikanda', 'quickChat': 'THIX CHAT', 'quickUrgence': 'LISUNGI',
      'servicesTitle': 'Misala na ngai', 'serviceMedia': 'MEDIA', 'serviceReservation': 'Kobuka', 'serviceMarket': 'Zando', 'serviceFormations': 'Mateya', 'serviceMonPays': 'Mboka', 'serviceMoney': 'Mbongo', 'serviceEmplois': 'Misala', 'serviceSante': 'Nzoto', 'serviceReseauPro': 'Réseau', 'serviceOpportunites': 'Mabaku', 'serviceInfo': 'INFO', 'serviceEvenements': 'Makita',
      'marketTitle': 'Zando', 'marketCart': 'Panier', 'marketCheckout': 'Futa', 'marketAddToCart': 'Tia', 'chatTitle': 'Nsango', 'educationTitle': 'Mateya', 'busTitle': 'Bis', 'eventTitle': 'Makita',
    },
    'kg': {
      'language': 'Ndinga', 'choose_language': 'Pona ndinga', 'system_default': 'Ndinga ya telefone',
      'login': 'Kota', 'cancel': 'Bika', 'later': 'Ntangu yankaka', 'settings': 'Paramètre', 'my_account': 'Konti ama', 'request_account': 'Lomba konti',
      'settings_title': 'Paramètre ye luzolo', 'settings_language_group': 'NDINGA', 'settings_choose_ui_language': 'Pona ndinga ya interface',
      'settings_appearance_group': 'MOMONO', 'settings_dark_mode': 'Mode ya mpimpa', 'settings_dark_mode_sub': 'Sa thème ya ngolo', 'settings_high_contrast': 'Contraste ya ngolo', 'settings_high_contrast_sub': 'Kubonga meso',
      'settings_security_group': 'Lutaninu ya institution', 'settings_biometrics': 'Biométrie', 'settings_biometrics_sub': 'Sadila mu kota', 'settings_face_id': 'Face ID', 'settings_face_id_sub': 'Niveau 2', 'settings_change_password': 'Kubula mot de passe', 'settings_2fa': '2FA', 'settings_2fa_sub': 'Mfunu', 'settings_active': 'KELE',
      'settings_account_group': 'KUBUNGA KONTA', 'settings_data_privacy': 'Kinsweki ya data', 'settings_activity_log': 'Journal ya bisalu', 'settings_sign_out': 'Vaika mu THIX ID', 'settings_tagline': 'Kizizi kya luvovomo.',
      'dashboard_security_title': 'Lutaninu ya konti', 'dashboard_security_subtitle': 'Bisalu ya lutaninu', 'dashboard_biometrics_toggle': 'Biométrie', 'dashboard_2fa_toggle': '2FA',
      'headerGreeting': 'Mbote', 'commonSearch': 'Sosa', 'bannerAnnouncements': 'Nsangu', 'bannerHeadline': 'Ya nene',
      'quickThixIA': 'THIX IA', 'quickDocument': 'Mikanda', 'quickChat': 'THIX CHAT', 'quickUrgence': 'NSWA',
      'servicesTitle': 'Bisalu biama', 'serviceMedia': 'MEDIA', 'serviceReservation': 'Kubuka', 'serviceMarket': 'Zandu', 'serviceFormations': 'Malongi', 'serviceMonPays': 'Nsi', 'serviceMoney': 'Mbongo', 'serviceEmplois': 'Bisalu', 'serviceSante': 'Mavimpi', 'serviceReseauPro': 'Réseau', 'serviceOpportunites': 'Mavwanga', 'serviceInfo': 'INFO', 'serviceEvenements': 'Bikabu',
      'marketTitle': 'Zandu', 'marketCart': 'Panier', 'marketCheckout': 'Futa', 'marketAddToCart': 'Tula', 'chatTitle': 'Nsangu', 'educationTitle': 'Malongi', 'busTitle': 'Bis', 'eventTitle': 'Bikabu',
    },
  };

  String t(String key) {
    final lang = locale.languageCode;
    return _strings[lang]?[key]?? _strings['fr']?[key]?? key;
  }

  static String localeLabel(Locale locale) {
    switch (locale.languageCode) {
      case 'fr': return 'Français';
      case 'en': return 'English';
      case 'sw': return 'Kiswahili';
      case 'ln': return 'Lingála';
      case 'ar': return 'العربية';
      case 'zh': return '中文';
      case 'pt': return 'Português';
      case 'kg': return 'Kikongo';
      default: return locale.languageCode;
    }
  }
}

class _AppLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocDelegate();
  @override
  bool isSupported(Locale locale) => LocaleController.supportedLocales.any((l) => l.languageCode == locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) async => SynchronousFuture(AppLocalizations(locale));
  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

extension AppLocX on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this);
  String tr(String key) => AppLocalizations.of(this).t(key);
}
