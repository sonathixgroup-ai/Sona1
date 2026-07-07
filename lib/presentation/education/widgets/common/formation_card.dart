// lib/presentation/education/widgets/common/formation_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:thix_id/presentation/education/models/formation.dart'; // ✅ Import unique

class FormationCard extends StatelessWidget {
  final Formation formation;
  final VoidCallback? onTap;
  final double? progress; // 0.0 à 1.0, optionnel (si l'utilisateur est inscrit)

  const FormationCard({
    super.key,
    required this.formation,
    this.onTap,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A1F44).withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image / thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: formation.imageUrl ?? '', // ✅ field correct
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 120,
                  color: const Color(0xFFF0F7FF),
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 120,
                  color: const Color(0xFFF0F7FF),
                  child: const Icon(Icons.image_rounded, color: Color(0xFF7386A8)),
                ),
              ),
            ),
            // Infos
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formation.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formation.category?.name ?? 'Non catégorisé',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7386A8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.school_rounded, size: 14, color: Color(0xFF7386A8)),
                      const SizedBox(width: 4),
                      Text(
                        formation.level == 'beginner' ? 'Débutant' :
                        formation.level == 'intermediate' ? 'Intermédiaire' : 'Avancé',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF7386A8)),
                      ),
                      const Spacer(),
                      if (formation.price > 0)
                        Text(
                          '${formation.price.toInt()} FC',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D6CDF),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D6CDF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Gratuit',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D6CDF),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress!.clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFFF0F7FF),
                        color: const Color(0xFF2D6CDF),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progression',
                          style: TextStyle(fontSize: 10, color: const Color(0xFF7386A8)),
                        ),
                        Text(
                          '${(progress! * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D6CDF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
