import 'package:flutter/material.dart';
import 'package:thix_id/presentation/thix_sante/health_router.dart';
import 'package:thix_id/presentation/thix_sante/thix_role.dart';
import 'package:thix_id/presentation/thix_sante/thix_sante_page.dart';

/// Page utilitaire: force un rôle (patient/médecin/pharmacie) puis affiche
/// le router santé.
///
/// Utilisée par certaines routes (ex: /sante/patient) pour offrir une
/// entrée directe tout en gardant le comportement du module.
class ThixSanteRolePage extends StatefulWidget {
  final ThixRole role;
  const ThixSanteRolePage({super.key, required this.role});

  @override
  State<ThixSanteRolePage> createState() => _ThixSanteRolePageState();
}

class _ThixSanteRolePageState extends State<ThixSanteRolePage> {
  @override
  void initState() {
    super.initState();
    ThixRoleController.instance.selectRole(widget.role, manual: true);
  }

  @override
  Widget build(BuildContext context) {
    return HealthRouter(
      // Si quelque chose empêche la résolution du rôle, on retombe sur
      // la page principale (qui inclut la sélection de rôle).
      fallback: const ThixSantePage(),
    );
  }
}
