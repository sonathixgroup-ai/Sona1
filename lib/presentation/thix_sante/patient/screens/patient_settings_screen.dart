// 📁 lib/presentation/thix_sante/patient/screens/patient_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PatientSettingsScreen extends ConsumerStatefulWidget {
  const PatientSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PatientSettingsScreen> createState() => _PatientSettingsScreenState();
}

class _PatientSettingsScreenState extends ConsumerState<PatientSettingsScreen> {
  bool _notifications = true;
  bool _darkMode = false;
  bool _shareData = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          _buildSectionTitle('Notifications'),
          _buildSwitchTile('Activer les notifications', 'Recevez des rappels et alertes', _notifications, (v) => setState(() => _notifications = v)),
          _buildSwitchTile('Rappels médicaments', 'Notifications pour vos traitements', true, (_) {}),
          _buildDivider(),
          _buildSectionTitle('Confidentialité'),
          _buildSwitchTile('Partager anonymement mes données', 'Contribuer à la recherche médicale', _shareData, (v) => setState(() => _shareData = v)),
          _buildNavigationTile('Gérer les accès', 'Voir qui a accès à votre dossier', () {}),
          _buildNavigationTile('Historique des partages', 'Consultez les accès passés', () {}),
          _buildDivider(),
          _buildSectionTitle('Application'),
          _buildSwitchTile('Mode sombre', 'Adapter l\'apparence', _darkMode, (v) => setState(() => _darkMode = v)),
          _buildNavigationTile('Langue', 'Français', () {}),
          _buildNavigationTile('À propos', 'Version 1.0.0', () {}),
          _buildDivider(),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildNavigationTile(String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(height: 20, thickness: 0.5, color: Colors.grey.shade200);
  }
}
