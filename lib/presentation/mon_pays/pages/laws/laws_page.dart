// lib/presentation/mon_pays/pages/laws/laws_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/article.dart';
import 'article_type_page.dart';

class LawsPage extends StatelessWidget {
  const LawsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final types = ArticleType.values.where((t) => t != ArticleType.autre).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Valeurs & Lois'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: recherche globale
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recherche globale - bientôt disponible')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: types.length,
          itemBuilder: (context, index) {
            final type = types[index];
            return _menuItem(context, type);
          },
        ),
      ),
    );
  }

  Widget _menuItem(BuildContext context, ArticleType type) {
    final iconMap = {
      ArticleType.constitution: '📜',
      ArticleType.codePenal: '⚖️',
      ArticleType.codeCivil: '📘',
      ArticleType.codeTravail: '🛠️',
      ArticleType.codeFiscal: '💰',
      ArticleType.codeMinier: '⛏️',
      ArticleType.codeForestier: '🌳',
      ArticleType.codeElectoral: '🗳️',
      ArticleType.loiOrganique: '📋',
      ArticleType.ordonnance: '📄',
      ArticleType.decret: '📑',
    };
    final icon = iconMap[type] ?? '📌';
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleTypePage(type: type, title: type.label),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              type.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
