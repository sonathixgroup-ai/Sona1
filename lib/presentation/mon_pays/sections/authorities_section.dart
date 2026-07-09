// lib/presentation/mon_pays/sections/authorities_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routes/app_routes.dart';
import '../cards/authority_card.dart';
import '../providers/authorities_provider.dart';
import '../widgets/section_title.dart';

class AuthoritiesSection extends ConsumerWidget {
  const AuthoritiesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authoritiesAsync = ref.watch(authoritiesProvider);

    return authoritiesAsync.when(
      data: (authorities) {
        if (authorities.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: 'Autorités',
              subtitle: 'Les dirigeants de la Nation',
              seeAllText: 'Voir tout',
              onSeeAll: () {
                context.push(AppRoutes.monPaysAuthorities);
              },
            ),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: authorities.length,
                itemBuilder: (context, index) {
                  final authority = authorities[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: AuthorityCard(
                      authority: authority,
                      onTap: () {
                        context.push(
                          '${AppRoutes.monPaysAuthorityDetail}'.replaceFirst(':id', authority.id),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox(
        height: 180,
        child: Center(child: Text('Erreur de chargement')),
      ),
    );
  }
}
