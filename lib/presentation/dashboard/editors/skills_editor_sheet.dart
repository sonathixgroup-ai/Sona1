import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:thix_id/models/thix_profile.dart';
import 'package:thix_id/services/profile_service.dart';
import '../../theme.dart';

class SkillsEditorSheet {
  static Future<void> show(
    BuildContext context, {
    required ThixProfile profile,
    required ProfileService profileService,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SkillsEditorBody(
        profile: profile,
        profileService: profileService,
      ),
    );
  }
}

class _SkillsEditorBody extends StatefulWidget {
  final ThixProfile profile;
  final ProfileService profileService;
  
  const _SkillsEditorBody({
    required this.profile,
    required this.profileService,
  });

  @override
  State<_SkillsEditorBody> createState() => _SkillsEditorBodyState();
}

class _SkillsEditorBodyState extends State<_SkillsEditorBody> {
  // Colle ici le contenu de l'ancien _SkillsEditorBodyState
  // (Les TextEditingControllers, _loadForEdit, _save, _delete, etc.)

  @override
  Widget build(BuildContext context) {
    // Le code du build existant
    return const SizedBox();
  }
}
