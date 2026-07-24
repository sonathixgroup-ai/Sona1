import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/models/thix_profile.dart';
import 'package:thix_id/services/document_service.dart';
import 'package:thix_id/services/profile_photo_service.dart';
import 'package:thix_id/services/profile_service.dart';
import 'package:thix_id/services/user_service.dart';
import '../../theme.dart';
import '../widgets/dashboard_shared_widgets.dart'; // Si tu as besoin de widgets partagés

// Classe publique pour appeler le BottomSheet depuis n'importe où
class ProfileEditorSheet {
  static Future<void> show(
    BuildContext context, {
    required ThixProfile profile,
    required ProfileService profileService,
    required AppUser authUser,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileEditorBody(
        profile: profile,
        profileService: profileService,
        authUser: authUser,
      ),
    );
  }
}

// Le corps du formulaire reste privé à ce fichier
class _ProfileEditorBody extends StatefulWidget {
  final ThixProfile profile;
  final ProfileService profileService;
  final AppUser authUser;
  
  const _ProfileEditorBody({
    required this.profile,
    required this.profileService,
    required this.authUser,
  });

  @override
  State<_ProfileEditorBody> createState() => _ProfileEditorBodyState();
}

class _ProfileEditorBodyState extends State<_ProfileEditorBody> {
  // Ici, tu colles TOUT le code d'état de l'ancien _ProfileEditorBodyState
  // (Les TextEditingControllers, _save(), _pickPhoto(), build()...)
  
  @override
  Widget build(BuildContext context) {
    // Le code du build existant avec Container, Column, TextField...
    return const SizedBox(); 
  }
}
