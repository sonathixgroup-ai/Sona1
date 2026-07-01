import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/services/profile_service.dart';
import 'package:thix_id/services/user_service.dart';
import 'package:thix_id/supabase/supabase_config.dart';

import '../../theme.dart';

class EduCategoryChip extends StatelessWidget {
  final String label;
  final bool selected;

  const EduCategoryChip({
    super.key,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: selected
            ? LightModeColors.accent
            : context.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: selected
              ? Colors.transparent
              : context.theme.dividerColor,
        ),
      ),
      child: Text(
        label,
        style: context.textStyles.labelMedium?.copyWith(
          color: selected
              ? const Color(0xFF0A2F5C)
              : LightModeColors.secondaryText,
        ),
      ),
    );
  }
}

class FormationCard extends StatelessWidget {
  final String title;
  final String instructor;
  final String rating;
  final String reviews;
  final String price;
  final String tag;
  final String imgDesc;

  const FormationCard({
    super.key,
    required this.title,
    required this.instructor,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.tag,
    required this.imgDesc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 140,
            child: Stack(
              children: [
                Container(color: LightModeColors.hint),
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: LightModeColors.accent,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      tag,
                      style: context.textStyles.labelSmall?.copyWith(
                        color: const Color(0xFF0A2F5C),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textStyles.titleMedium?.copyWith(
                    color: context.theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 14,
                      color: LightModeColors.secondaryText,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        instructor,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: LightModeColors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: LightModeColors.accent,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          rating,
                          style: context.textStyles.labelMedium?.copyWith(
                            color: context.theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          "($reviews)",
                          style: context.textStyles.bodySmall?.copyWith(
                            color: LightModeColors.hint,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9C74F).withOpacity(0.13),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        price,
                        style: context.textStyles.titleSmall?.copyWith(
                          color: context.theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EducationPage extends StatelessWidget {
  const EducationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final profileService = ProfileService();
    final userService = UserService(SupabaseConfig.client);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF0A3D62),
                border: Border(
                  bottom: BorderSide(
                    color: LightModeColors.accent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () =>
                            context.popOrGo(AppRoutes.home),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        "Formations Premium",
                        style: context.textStyles.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.search_rounded,
                          color: LightModeColors.accent,
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText:
                            "Rechercher une formation certifiée...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor:
                            context.theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    const SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          EduCategoryChip(
                            label: "Tous les cours",
                            selected: true,
                          ),
                          EduCategoryChip(
                            label: "Cybersécurité",
                            selected: false,
                          ),
                          EduCategoryChip(
                            label: "Blockchain ID",
                            selected: false,
                          ),
                          EduCategoryChip(
                            label: "Leadership",
                            selected: false,
                          ),
                          EduCategoryChip(
                            label: "Fintech",
                            selected: false,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    Text(
                      "Programmes Recommandés",
                      style: context.textStyles.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    const FormationCard(
                      title:
                          "Cadre Légal de l'Identité Numérique (RDC)",
                      instructor: "Cabinet du Numérique",
                      rating: "5.0",
                      reviews: "450",
                      price: "25 USD",
                      tag: "Officiel",
                      imgDesc: "legal documents gavel",
                    ),

                    const FormationCard(
                      title:
                          "Intégration API THIX pour Entreprises",
                      instructor: "THIX Dev Team",
                      rating: "4.9",
                      reviews: "890",
                      price: "60 USD",
                      tag: "Technique",
                      imgDesc: "software architecture diagram",
                    ),

                    const FormationCard(
                      title:
                          "Éthique et Gouvernance des Données",
                      instructor: "Prof. Albertine Mwamba",
                      rating: "4.8",
                      reviews: "320",
                      price: "Gratuit",
                      tag: "Gouvernement",
                      imgDesc: "ethics abstract concept",
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final auth =
                              context.read<AuthController>();

                          final me = auth.currentUser;

                          if (me == null) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Connexion requise.'),
                              ),
                            );
                            return;
                          }

                          try {
                            await userService
                                .addPaymentTransaction(
                              uid: me.id,
                              title: 'Inscription formation',
                              amount: 45,
                              currency: 'USD',
                              method: 'Simulé',
                              status: 'paid',
                            );

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Inscription enregistrée.',
                                ),
                              ),
                            );
                          } catch (e) {
                            debugPrint(
                              'EducationPage error: $e',
                            );

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Inscription impossible.',
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              LightModeColors.accent,
                          foregroundColor:
                              const Color(0xFF0A2F5C),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              AppRadius.full,
                            ),
                          ),
                        ),
                        child: Text(
                          "S'inscrire - 45 USD",
                          style: context.textStyles.labelLarge
                              ?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ Extension corrigée
extension ThemeHelper on BuildContext {
  ThemeData get theme => Theme.of(this);
}
