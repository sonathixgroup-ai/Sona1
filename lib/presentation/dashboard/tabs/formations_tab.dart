import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/services/user_service.dart';
import '../../nav.dart';
import '../../theme.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/dashboard_shared_widgets.dart';

class FormationsTab extends StatelessWidget {
  final String uid;
  final AppUser user;
  final UserService userService;

  const FormationsTab({
    super.key,
    required this.uid,
    required this.user,
    required this.userService,
  });

  @override
  Widget build(BuildContext context) {
    // Colle ici le contenu du build() de l'ancien _FormationsTab
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        children: [
           // DashboardCard pour les formations...
        ],
      ),
    );
  }
}
