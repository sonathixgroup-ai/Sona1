// lib/presentation/mon_pays/pages/laws/laws_page.dart
// Page d'accueil du module Valeurs & Lois

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LawsPage extends StatelessWidget {
  const LawsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Valeurs & Lois'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigation vers la recherche (à implémenter plus tard)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recherche de lois - bientôt disponible')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _menuItem(context, '⚖️ Constitution', 'Texte fondamental', () => context.push('/mon-pays/laws/constitution')),
            _menuItem(context, '📚 Codes', 'Liste des codes', () => context.push('/mon-pays/laws/codes')),
            _menuItem(context, '🛡️ Droits', 'Droits des citoyens', () => context.push('/mon-pays/laws/rights')),
            _menuItem(context, '📋 Devoirs', 'Devoirs des citoyens', () => context.push('/mon-pays/laws/duties')),
            _menuItem(context, '🏛️ Institutions', 'Institutions de la République', () => context.push('/mon-pays/laws/institutions')),
            _menuItem(context, '⚖️ Justice', 'Système judiciaire', () => context.push('/mon-pays/laws/justice')),
            _menuItem(context, '📁 Administration', 'Administration publique', () => context.push('/mon-pays/laws/administration')),
            _menuItem(context, '🎨 Symboles Nationaux', 'Drapeau, hymne, devise, blason', () => context.push('/mon-pays/laws/symbols')),
            _menuItem(context, '👥 Citoyenneté', 'Droits et devoirs du citoyen', () => context.push('/mon-pays/laws/citizenship')),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(BuildContext context, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gavel, size: 32, color: Color(0xFF1A5276)),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
