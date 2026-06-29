// 📁 lib/presentation/thix_sante/common/widgets/section_title.dart

import 'package:flutter/material.dart';

/// Titre de section avec option "Voir tout"
class SectionTitle extends StatelessWidget {
  final String title;
  final String? seeAllText;
  final VoidCallback? onSeeAll;
  final bool showDivider;

  const SectionTitle({
    Key? key,
    required this.title,
    this.seeAllText,
    this.onSeeAll,
    this.showDivider = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.3,
                ),
              ),
              if (onSeeAll != null && seeAllText != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text(
                    seeAllText!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 0, thickness: 0.5, color: Colors.grey.shade200),
      ],
    );
  }
}
