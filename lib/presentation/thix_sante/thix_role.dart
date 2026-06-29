// lib/presentation/thix_sante/thix_sante_page.dart
import 'package:flutter/material.dart';
import 'thix_role.dart'; // Import de l'énumération et du contrôleur

// Page d'accueil du module Santé (hub)
class ThixSantePage extends StatelessWidget {
  const ThixSantePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('THIX Santé'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.health_and_safety, size: 80, color: Colors.teal),
            const SizedBox(height: 20),
            const Text(
              'Bienvenue sur THIX Santé',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Choisissez votre espace ci-dessous',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: ThixRole.values.map((role) {
                return _RoleCard(role: role);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final ThixRole role;
  const _RoleCard({required this.role});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Utiliser le nom de la route définie dans AppRoutes (ou un push direct)
        // Ici on pousse directement la page rôle
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ThixSanteRolePage(role: role),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(role.icon, size: 50, color: role.accent),
              const SizedBox(height: 8),
              Text(
                role.label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                role.shortLabel,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Page spécifique pour un rôle
class ThixSanteRolePage extends StatelessWidget {
  final ThixRole role;
  const ThixSanteRolePage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(role.label),
        backgroundColor: role.accent,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: role.gradient,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(role.icon, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                Text(
                  role.headline,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  role.subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${role.ctaLabel} – Fonctionnalité à implémenter'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: role.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(role.ctaLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
