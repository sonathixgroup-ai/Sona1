// presentation/thix_sante/doctor/details/doctor_terrain_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DoctorTerrainPage extends StatelessWidget {
  const DoctorTerrainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mobile terrain')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTile(
            context,
            icon: Icons.qr_code_scanner,
            title: 'Scan bracelet patient',
            subtitle: 'Identifier un patient rapidement',
            color: Colors.blue,
            route: '/sante/doctor/terrain/scan',
          ),
          _buildTile(
            context,
            icon: Icons.mic,
            title: 'Dictée vocale',
            subtitle: 'Prenez des notes médicales par voix',
            color: Colors.orange,
            route: '/sante/doctor/terrain/dictation',
          ),
          _buildTile(
            context,
            icon: Icons.offline_bolt,
            title: 'Mode hors ligne',
            subtitle: 'Accédez aux dossiers sans connexion',
            color: Colors.green,
            route: '/sante/doctor/terrain/offline',
          ),
          _buildTile(
            context,
            icon: Icons.camera_alt,
            title: 'Prise de photo',
            subtitle: 'Capturer des images de documents',
            color: Colors.purple,
            route: '/sante/doctor/terrain/photo',
          ),
          const SizedBox(height: 16),
          const Text('Derniers patients consultés sur le terrain', style: TextStyle(fontWeight: FontWeight.bold)),
          ListTile(
            leading: const CircleAvatar(child: Text('M')),
            title: const Text('Michel L.'),
            subtitle: const Text('Consultation à domicile - 10/03'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required String route}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          context.push(route);
        },
      ),
    );
  }
}
