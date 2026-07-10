// lib/presentation/mon_pays/pages/emergency/emergency_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/emergency_provider.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class EmergencyPage extends ConsumerWidget {
  const EmergencyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(emergencyContactsProvider);

    return Scaffold(
      appBar: MonPaysAppBar(title: 'Urgence & Sécurité'),
      body: contactsAsync.when(
        data: (contacts) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MonPaysColors.dangerRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MonPaysColors.dangerRed, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: MonPaysColors.dangerRed, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'En cas d\'urgence, composez immédiatement le numéro approprié.',
                        style: MonPaysTextStyles.bodyMedium.copyWith(
                          color: MonPaysColors.dangerRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Numéros d\'urgence',
                style: MonPaysTextStyles.heading5.copyWith(
                  color: MonPaysColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...contacts.map((contact) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: MonPaysColors.dangerRed,
                    child: const Icon(Icons.phone, color: Colors.white),
                  ),
                  title: Text(
                    contact.name,
                    style: MonPaysTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: contact.category != null
                      ? Text(contact.category!, style: MonPaysTextStyles.bodySmall)
                      : null,
                  trailing: Text(
                    contact.phoneNumber,
                    style: MonPaysTextStyles.heading5.copyWith(
                      color: MonPaysColors.dangerRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )),
            ],
          );
        },
        loading: () => const Center(child: LoadingWidget(message: 'Chargement...')),
        error: (error, stack) => Center(
          child: MonPaysErrorWidget(
            message: 'Erreur de chargement : $error',
            onRetry: () => ref.refresh(emergencyContactsProvider),
          ),
        ),
      ),
    );
  }
}
