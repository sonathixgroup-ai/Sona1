// lib/presentation/mon_pays/widgets/bottom_sheet.dart

import 'package:flutter/material.dart';
import '../utils/mon_pays_colors.dart';
import '../utils/mon_pays_text_styles.dart';

class MonPaysBottomSheet extends StatelessWidget {
  final Widget child;
  final double height;
  final bool showDragHandle;
  final Color backgroundColor;

  const MonPaysBottomSheet({
    Key? key,
    required this.child,
    this.height = 0.5,
    this.showDragHandle = true,
    this.backgroundColor = MonPaysColors.primaryWhite,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          if (showDragHandle) ...[
            const SizedBox(height: 8),
            Container(
              width: 35,
              height: 4,
              decoration: BoxDecoration(
                color: MonPaysColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(child: child),
        ],
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double height = 0.5,
    bool showDragHandle = true,
    Color backgroundColor = MonPaysColors.primaryWhite,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MonPaysBottomSheet(
        height: height,
        showDragHandle: showDragHandle,
        backgroundColor: backgroundColor,
        child: child,
      ),
    );
  }
}
