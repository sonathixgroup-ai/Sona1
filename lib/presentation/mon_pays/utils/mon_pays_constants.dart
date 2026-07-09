// lib/presentation/mon_pays/utils/mon_pays_constants.dart

import 'package:flutter/material.dart';

/// Constantes globales pour le module Mon Pays
class MonPaysConstants {
  // ==================== URLs & endpoints ====================
  static const String baseUrl = 'https://api.monpays.cd/v1';
  static const String authorityEndpoint = '/authorities';
  static const String historicalEndpoint = '/historical-figures';
  static const String newsEndpoint = '/news';
  static const String agenciesEndpoint = '/agencies';
  static const String videosEndpoint = '/videos';
  static const String documentariesEndpoint = '/documentaries';
  static const String wantedEndpoint = '/wanted-persons';
  static const String citizensEndpoint = '/exemplary-citizens';
  static const String lawsEndpoint = '/laws';
  static const String consultationsEndpoint = '/consultations';

  // ==================== Cache ====================
  static const Duration defaultCacheDuration = Duration(minutes: 15);
  static const Duration longCacheDuration = Duration(hours: 24);

  // ==================== Messages ====================
  static const String genericError = 'Une erreur est survenue. Veuillez réessayer.';
  static const String networkError = 'Erreur de connexion. Vérifiez votre réseau.';
  static const String loadingMessage = 'Chargement en cours...';
  static const String emptyDataMessage = 'Aucune donnée disponible.';
  static const String saveSuccess = 'Enregistrement réussi !';
  static const String deleteSuccess = 'Suppression réussie !';
  static const String updateSuccess = 'Mise à jour réussie !';

  // ==================== Textes des sections ====================
  static const String sectionAuthorities = 'Autorités';
  static const String sectionHistorical = 'Figures Historiques';
  static const String sectionNews = 'À la Une';
  static const String sectionAgencies = 'Agences & Institutions';
  static const String sectionVideos = 'Vidéos Officielles';
  static const String sectionDocumentaries = 'Documentaires & Archives';
  static const String sectionWanted = 'Personnes Recherchées';
  static const String sectionCitizens = 'Citoyens Exemplaires';
  static const String sectionLaws = 'Valeurs & Lois';
  static const String sectionConsultations = 'Consultations Publiques';

  // ==================== Sous-titres ====================
  static const String subtitleAuthorities = 'Les dirigeants de la Nation';
  static const String subtitleHistorical = 'Découvrez ceux qui ont marqué notre histoire';
  static const String subtitleNews = 'Actualités officielles';
  static const String subtitleAgencies = 'Les piliers de l\'État';
  static const String subtitleVideos = 'Discours, conseils, projets';
  static const String subtitleDocumentaries = 'Plongez dans l\'histoire et la culture';
  static const String subtitleWanted = 'Signaler ou rechercher une personne';
  static const String subtitleCitizens = 'Ils bâtissent la RDC chaque jour';
  static const String subtitleLaws = 'Les fondements de la Nation';
  static const String subtitleConsultations = 'Participez à la construction du pays';

  // ==================== Catégories ====================
  static const List<String> newsCategories = [
    'OFFICIEL',
    'COMMUNIQUÉ',
    'NATIONAL',
  ];

  static const List<String> lawCategories = [
    'Constitution',
    'Institutions',
    'Symboles Nationaux',
    'Codes et Lois',
    'Droits du Citoyen',
    'Devoirs du Citoyen',
    'Justice',
    'Administration',
  ];

  static const List<String> documentaryCategories = [
    'Histoire',
    'Parcs Nationaux',
    'Culture',
    'Patrimoine',
    'Tourisme',
    'Économie',
    'Mines',
    'Innovation',
  ];

  static const List<String> citizenCategories = [
    'Entrepreneurs',
    'Médecins',
    'Enseignants',
    'Militaires',
    'Policiers',
    'Sportifs',
    'Artistes',
    'Innovateurs',
    'Étudiants',
  ];

  // ==================== Animation ====================
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 600);

  // ==================== Pagination ====================
  static const int defaultPageSize = 10;
  static const int largePageSize = 20;

  // ==================== Regex ====================
  static const String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phoneRegex = r'^\+?[0-9]{10,15}$';
  static const String dateRegex = r'^\d{4}-\d{2}-\d{2}$';
}
