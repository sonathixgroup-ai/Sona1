// 📁 lib/presentation/thix_sante/onboarding/screens/permissions_screen.dart

import 'package:flutter/material.dart';
import '../widgets/permission_tile.dart';
import '../../auth/widgets/auth_button.dart';

class PermissionsScreen extends StatefulWidget {
  final VoidCallback onAllGranted;

  const PermissionsScreen({Key? key, required this.onAllGranted}) : super(key: key);

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final Map<String, bool> _permissions = {
    'notifications': false,
    'location': false,
    'camera': false,
    'storage': false,
  };

  bool get _allGranted => _permissions.values.every((v) => v == true);

  void _requestPermission(String key) {
    // Simuler une demande de permission
    setState(() {
      _permissions[key] = true;
    });
    // Ici, appeler les vrais services de permissions (permission_handler)
    // Exemple pour notifications:
    // Permission.notification.request().then((status) {
    //   if (status.isGranted) {
    //     setState(() => _permissions[key] = true);
    //   }
    // });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Permission "$key" accordée'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                '🔒 Permissions nécessaires',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pour profiter pleinement de THIX SANTÉ, nous avons besoin de quelques autorisations.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              PermissionTile(
                title: 'Notifications',
                description: 'Recevez vos rappels de médicaments et alertes santé.',
                icon: Icons.notifications_active,
                isGranted: _permissions['notifications']!,
                onRequest: () => _requestPermission('notifications'),
              ),
              const SizedBox(height: 12),
              PermissionTile(
                title: 'Localisation',
                description: 'Trouvez les pharmacies et hôpitaux à proximité.',
                icon: Icons.location_on,
                isGranted: _permissions['location']!,
                onRequest: () => _requestPermission('location'),
              ),
              const SizedBox(height: 12),
              PermissionTile(
                title: 'Appareil photo',
                description: 'Scannez vos ordonnances et documents médicaux.',
                icon: Icons.camera_alt,
                isGranted: _permissions['camera']!,
                onRequest: () => _requestPermission('camera'),
              ),
              const SizedBox(height: 12),
              PermissionTile(
                title: 'Stockage',
                description: 'Enregistrez vos analyses, radios et rapports.',
                icon: Icons.folder,
                isGranted: _permissions['storage']!,
                onRequest: () => _requestPermission('storage'),
              ),
              const Spacer(),
              AuthButton(
                text: 'Continuer',
                onPressed: _allGranted ? widget.onAllGranted : null,
                icon: Icons.arrow_forward,
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _allGranted ? '' : 'Veuillez autoriser toutes les permissions',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade400),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
