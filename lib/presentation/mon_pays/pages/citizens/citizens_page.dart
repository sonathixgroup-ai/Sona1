// lib/presentation/mon_pays/pages/citizens/citizens_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../nav.dart'; // ✅ IMPORT AJOUTÉ
import '../../cards/citizen_card.dart';
import '../../providers/citizens_provider.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_widget.dart';
import '../../widgets/error_widget.dart'; // ✅ Pour MonPaysErrorWidget

class CitizensPage extends ConsumerWidget {
  const CitizensPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citizensAsync = ref.watch(citizensProvider);

    return Scaffold(
      appBar: MonPaysAppBar(
        title: 'Citoyens Exemplaires',
      ),
      body: citizensAsync.when(
        data: (citizens) {
          if (citizens.isEmpty) {
            return const Center(
              child: Text('Aucun citoyen exemplaire disponible'),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: citizens.length,
            itemBuilder: (context, index) {
              final citizen = citizens[index];
              return CitizenCard(
                citizen: citizen,
                onTap: () {
                  context.push(
                    '${AppRoutes.monPaysCitizenDetail}'.replaceFirst(':id', citizen.id),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: LoadingWidget(message: 'Chargement des citoyens...'),
        ),
        error: (error, stack) => Center(
          child: MonPaysErrorWidget(
            message: 'Erreur de chargement : $error',
            onRetry: () => ref.refresh(citizensProvider),
          ),
        ),
      ),
    );
  }
}
