// lib/presentation/mon_pays/pages/values/value_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/values_provider.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class ValueDetailPage extends ConsumerWidget {
  final String id;

  const ValueDetailPage({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valueAsync = ref.watch(valueProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détail',
          style: MonPaysTextStyles.heading6.copyWith(color: Colors.white),
        ),
        backgroundColor: MonPaysColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: valueAsync.when(
        data: (value) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: MonPaysColors.gradientBlueRed,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        value.iconCode != null
                            ? IconData(int.tryParse(value.iconCode!) ?? Icons.star.codePoint,
                                fontFamily: 'MaterialIcons')
                            : Icons.star,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        value.title,
                        style: MonPaysTextStyles.heading4.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (value.category != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          value.category!,
                          style: MonPaysTextStyles.bodySmall.copyWith(color: Colors.white70),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (value.description != null) ...[
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: MonPaysTextStyles.heading6.copyWith(
                              color: MonPaysColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          Text(value.description!, style: MonPaysTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Retour'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: MonPaysColors.primaryBlue),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: LoadingWidget()),
        error: (error, stack) => Center(
          child: MonPaysErrorWidget(
            message: 'Erreur de chargement : $error',
            onRetry: () => ref.refresh(valueProvider(id)),
          ),
        ),
      ),
    );
  }
}
