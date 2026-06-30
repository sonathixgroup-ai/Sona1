// presentation/thix_sante/patient/details/patient_profile_page.dart
import 'package:flutter/material.dart';
import 'package:thix_id/auth/auth_controller.dart';

class PatientProfilePage extends StatelessWidget {
  const PatientProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthController.instance.currentUser;
    final name = user?.firstName ?? 'Michel';

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 60,
                child: Icon(Icons.person, size: 60),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.email),
              title: Text('Email'),
              subtitle: Text('michel@example.com'),
            ),
            const ListTile(
              leading: Icon(Icons.phone),
              title: Text('Téléphone'),
              subtitle: Text('06 12 34 56 78'),
            ),
            const ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Date de naissance'),
              subtitle: Text('15/03/1985'),
            ),
            const ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Groupe sanguin'),
              subtitle: Text('A+'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Modifier profil
              },
              child: const Text('Modifier le profil'),
            ),
          ],
        ),
      ),
    );
  }
}
