// lib/presentation/mon_pays/sections/authorities_section.dart
// Section des autorités sur la page d'accueil

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/authorities_provider.dart';
import '../cards/authority_card.dart';
import '../pages/authorities/authority_profile_page.dart';

class AuthoritiesSection extends ConsumerWidget {
  const AuthoritiesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authoritiesAsync = ref.watch(authoritiesProvider(null));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🏛 Autorités',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Voir tout →',
                style: TextStyle(
                  color: Color(0xFF1A5276),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        authoritiesAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Erreur: ${error.toString()}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(authoritiesProvider(null));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A5276),
                    ),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
          data: (authorities) {
            if (authorities.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Aucune autorité à afficher',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }
            // Affiche les 3 premières autorités
            final displayList = authorities.take(3).toList();
            return Column(
              children: displayList.map((authority) {
                return AuthorityCard(
                  authority: authority,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AuthorityProfilePage(
                          authorityId: authority.id,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
