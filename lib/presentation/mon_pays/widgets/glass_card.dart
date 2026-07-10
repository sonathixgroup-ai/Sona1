// lib/presentation/mon_pays/widgets/glass_card.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/mon_pays_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final List<BoxShadow>? shadows;

  const GlassCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.shadows,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MonPaysColors.primaryWhite.withOpacity(0.85),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: MonPaysColors.cardBorder.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: MonPaysColors.shadowLight,
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
