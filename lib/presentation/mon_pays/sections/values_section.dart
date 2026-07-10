// lib/presentation/mon_pays/sections/values_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routes/app_routes.dart';
import '../cards/value_card.dart';
import '../providers/values_provider.dart';
import '../widgets/section_title.dart';

class ValuesSection extends ConsumerWidget {
  const ValuesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valuesAsync = ref.watch(valuesProvider);

    return valuesAsync.when(
      data: (values) {
        if (values.isEmpty) return const SizedBox.shrink();
        final displayValues = values.take(8).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: 'Valeurs & Lois',
              subtitle: 'Les fondements de la Nation',
              seeAllText: 'Voir tout',
              onSeeAll: () {
                context.push(AppRoutes.monPaysValues);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: displayValues.length,
                itemBuilder: (context, index) {
                  final value = displayValues[index];
                  return ValueCard(
                    value: value,
                    onTap: () {
                      context.push(
                        '${AppRoutes.monPaysValueDetail}'.replaceFirst(':id', value.id),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox(
        height: 200,
        child: Center(child: Text('Erreur de chargement')),
      ),
    );
  }
}
