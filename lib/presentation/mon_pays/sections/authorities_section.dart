// lib/presentation/mon_pays/sections/authorities_section.dart
// Section des autorités sur la page d'accueil avec :
// - Affichage des 5 premières autorités
// - Navigation vers la liste complète
// - États de chargement et d'erreur
// - Bouton "Voir tout"

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/authorities_provider.dart';
import '../providers/favorites_provider.dart';
import '../cards/authority_card.dart';
import '../pages/authorities/authority_profile_page.dart';

class AuthoritiesSection extends ConsumerStatefulWidget {
  const AuthoritiesSection({super.key});

  @override
  ConsumerState<AuthoritiesSection> createState() => _AuthoritiesSectionState();
}

class _AuthoritiesSectionState extends ConsumerState<AuthoritiesSection> {
  final int _maxDisplay = 5;

  @override
  Widget build(BuildContext context) {
    final authoritiesAsync = ref.watch(authoritiesProvider(null));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de la section
        _buildSectionHeader(context),
        const SizedBox(height: 8),
        // Contenu
        authoritiesAsync.when(
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error),
          data: (authorities) => _buildDataState(authorities, context),
        ),
      ],
    );
  }

  // ==================== SECTION HEADER ====================

  Widget _buildSectionHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A5276).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: Color(0xFF1A5276),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Autorités',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () {
              context.go('/mon-pays/authorities');
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A5276).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Text(
                    'Voir tout',
                    style: TextStyle(
                      color: Color(0xFF1A5276),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF1A5276),
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== LOADING STATE ====================

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A5276)),
              strokeWidth: 2,
            ),
            SizedBox(height: 12),
            Text(
              'Chargement des autorités...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ERROR STATE ====================

  Widget _buildErrorState(Object error) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade400,
                size: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Impossible de charger les autorités',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                ref.invalidate(authoritiesProvider(null));
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Réessayer'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1A5276),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DATA STATE ====================

  Widget _buildDataState(List<Authority> authorities, BuildContext context) {
    if (authorities.isEmpty) {
      return _buildEmptyState();
    }

    final displayList = authorities.take(_maxDisplay).toList();
    final remainingCount = authorities.length - _maxDisplay;

    return Column(
      children: [
        // Liste des autorités
        ...displayList.map((authority) {
          return AuthorityCard(
            authority: authority,
            onTap: () {
              context.go('/mon-pays/authority/${authority.id}');
            },
          );
        }).toList(),
        // Message "et X autres"
        if (remainingCount > 0) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: InkWell(
              onTap: () {
                context.go('/mon-pays/authorities');
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF1A5276).withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Et $remainingCount autre${remainingCount > 1 ? 's' : ''} →',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        // Ligne de séparation
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1),
        ),
      ],
    );
  }

  // ==================== EMPTY STATE ====================

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'Aucune autorité enregistrée',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Les autorités seront bientôt disponibles',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
