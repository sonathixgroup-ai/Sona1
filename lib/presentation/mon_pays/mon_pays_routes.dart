// lib/presentation/mon_pays/mon_pays_routes.dart
// Définition des routes internes du module

import 'package:flutter/material.dart';
import 'pages/authorities/authorities_page.dart';
import 'pages/authorities/authority_profile_page.dart';
import 'admin/admin_authorities_page.dart';
import 'admin/admin_authority_form_page.dart';
import 'mon_pays_page.dart';

class MonPaysRoutes {
  static const String home = '/mon-pays';
  static const String authorities = '/mon-pays/authorities';
  static const String authorityProfile = '/mon-pays/authority/:id';
  static const String adminAuthorities = '/mon-pays/admin/authorities';
  static const String adminAuthorityForm = '/mon-pays/admin/authority/form';

  static Map<String, WidgetBuilder> get routes => {
    home: (context) => const MonPaysPage(),
    authorities: (context) => const AuthoritiesPage(),
    adminAuthorities: (context) => const AdminAuthoritiesPage(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case authorityProfile:
        final id = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => AuthorityProfilePage(authorityId: id),
        );
      case adminAuthorityForm:
        final authority = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => AdminAuthorityFormPage(authority: authority as dynamic),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page non trouvée')),
          ),
        );
    }
  }
}
