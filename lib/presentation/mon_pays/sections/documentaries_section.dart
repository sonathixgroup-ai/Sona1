// lib/presentation/mon_pays/sections/documentaries_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routes/app_routes.dart';
import '../cards/documentary_card.dart';
import '../providers/documentaries_provider.dart';
import '../widgets/section_title.dart';

class DocumentariesSection extends ConsumerWidget {
  const DocumentariesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentariesAsync = ref.watch(documentariesProvider);

    return documentariesAsync.when(
      data: (documentaries) {
        if (documentaries.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: 'Documentaires & Archives',
              subtitle: 'Plongez dans l\'histoire et la culture',
              seeAllText: 'Voir tout',
              onSeeAll: () {
                context.push(AppRoutes.monPaysDocumentaries);
              },
            ),
            SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: documentaries.length,
                itemBuilder: (context, index) {
                  final documentary = documentaries[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: DocumentaryCard(
                      documentary: documentary,
                      onTap: () {
                        context.push(
                          '${AppRoutes.monPaysDocumentaryDetail}'
                              .replaceFirst(':id', documentary.id),
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
        height: 190,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox(
        height: 190,
        child: Center(child: Text('Erreur de chargement')),
      ),
    );
  }
}
