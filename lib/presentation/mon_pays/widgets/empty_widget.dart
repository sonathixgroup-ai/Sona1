// lib/presentation/mon_pays/widgets/empty_widget.dart

import 'package:flutter/material.dart';
import '../utils/mon_pays_colors.dart';
import '../utils/mon_pays_text_styles.dart';

class EmptyWidget extends StatelessWidget {
  final String message;
  final String? title;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyWidget({
    Key? key,
    required this.message,
    this.title,
    this.icon = Icons.inbox,
    this.onAction,
    this.actionLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: MonPaysColors.textHint,
          ),
          const SizedBox(height: 16),
          if (title != null)
            Text(
              title!,
              style: MonPaysTextStyles.heading6.copyWith(
                color: MonPaysColors.textPrimary,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            message,
            style: MonPaysTextStyles.bodyMedium.copyWith(
              color: MonPaysColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: MonPaysColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
