// lib/presentation/mon_pays/sections/authorities_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/authorities_provider.dart';
import '../models/authority.dart';

class AuthoritiesSection extends ConsumerWidget {
  const AuthoritiesSection({super.key});

  // Charte THIX ID
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color gold = Color(0xFFE3B23C);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10182B);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color hairline = Color(0xFFE7EAF3);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On charge toutes les autorités
    final authoritiesAsync = ref.watch(authoritiesProvider('Tous'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.account_balance_rounded, color: navyDeep, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Hautes Autorités',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: darkText),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        authoritiesAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: navy),
            ),
          ),
          error: (err, stack) => Center(child: Text('Erreur : $err', style: const TextStyle(color: Colors.red))),
          data: (authorities) {
            
            // 1. Recherche Intelligente (Tolérante aux erreurs de frappe/catégorie)
            final president = _findPresident(authorities);
            final pm = _findPM(authorities);
            final assemblee = _findAssemblee(authorities);
            final senat = _findSenat(authorities);

            // 2. Préparation des données pour la grille
            final vips = [
              {'role': 'Président de la République', 'data': president},
              {'role': 'Première Ministre', 'data': pm},
              {'role': 'Assemblée Nationale', 'data': assemblee},
              {'role': 'Sénat', 'data': senat},
            ];

            // 3. Affichage en grille 2x2
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                final vip = vips[index];
                final authority = vip['data'] as Authority?;
                final defaultRole = vip['role'] as String;

                return _buildVipCard(context, authority, defaultRole);
              },
            );
          },
        ),
      ],
    );
  }

  // --- FONCTIONS DE RECHERCHE INTELLIGENTE ---

  Authority? _findPresident(List<Authority> auths) {
    try {
      return auths.firstWhere((a) {
        final cat = a.category.toLowerCase();
        final tit = a.title.toLowerCase();
        return cat.contains('président de la r') || tit.contains('président') || tit.contains('president');
      });
    } catch (_) { return null; }
  }

  Authority? _findPM(List<Authority> auths) {
    try {
      return auths.firstWhere((a) {
        final tit = a.title.toLowerCase();
        return tit.contains('premier') || tit.contains('première') || tit.contains('premiere');
      });
    } catch (_) { return null; }
  }

  Authority? _findAssemblee(List<Authority> auths) {
    try {
      return auths.firstWhere((a) {
        final cat = a.category.toLowerCase();
        final tit = a.title.toLowerCase();
        return cat.contains('assemblée') || tit.contains('assemblée') || tit.contains('assemblee');
      });
    } catch (_) { return null; }
  }

  Authority? _findSenat(List<Authority> auths) {
    try {
      return auths.firstWhere((a) {
        final cat = a.category.toLowerCase();
        final tit = a.title.toLowerCase();
        return cat.contains('sénat') || cat.contains('senat') || tit.contains('sénat') || tit.contains('senat');
      });
    } catch (_) { return null; }
  }

  // --- DESIGN DE LA CARTE ---

  Widget _buildVipCard(BuildContext context, Authority? authority, String defaultRole) {
    final hasData = authority != null;
    final name = hasData ? authority.name : 'Non assigné';
    final title = hasData ? authority.title : defaultRole;
    final imageUrl = hasData ? authority.imageUrl : null;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: hasData ? () => context.push('/mon-pays/authority/${authority.id}') : null,
      child: Container(
        decoration: BoxDecoration(
          color: pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hairline),
          boxShadow: [
            BoxShadow(color: navyDeep.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF6F7FB),
                border: Border.all(color: gold, width: 2),
                image: imageUrl != null && imageUrl.isNotEmpty
                    ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: imageUrl == null || imageUrl.isEmpty
                  ? const Icon(Icons.person_rounded, color: mutedText, size: 32)
                  : null,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: hasData ? darkText : mutedText),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: hasData ? navy : mutedText, fontWeight: FontWeight.w700, height: 1.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
