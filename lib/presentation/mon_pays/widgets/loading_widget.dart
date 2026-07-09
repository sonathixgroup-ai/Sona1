// lib/presentation/mon_pays/widgets/loading_widget.dart

import 'package:flutter/material.dart';
import '../utils/mon_pays_colors.dart';
import '../utils/mon_pays_text_styles.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool showShimmer;

  const LoadingWidget({
    Key? key,
    this.message,
    this.showShimmer = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (showShimmer) {
      return const _ShimmerLoading();
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: MonPaysColors.primaryRed,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: MonPaysTextStyles.bodyMedium.copyWith(
                color: MonPaysColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _ShimmerLoading extends StatelessWidget {
  const _ShimmerLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: MonPaysColors.primaryRed,
      ),
    );
  }
}
