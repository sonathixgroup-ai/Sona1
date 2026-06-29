// 📁 lib/presentation/thix_sante/common/widgets/pill_badge.dart

import 'package:flutter/material.dart';

/// Badge arrondi pour statuts, tags, catégories
class PillBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final double fontSize;
  final IconData? icon;
  final bool isOutlined;

  const PillBadge({
    Key? key,
    required this.text,
    this.color = Colors.green,
    this.textColor = Colors.white,
    this.fontSize = 11,
    this.icon,
    this.isOutlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : color,
        borderRadius: BorderRadius.circular(20),
        border: isOutlined ? Border.all(color: color) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: fontSize + 2,
              color: isOutlined ? color : textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: isOutlined ? color : textColor,
            ),
          ),
        ],
      ),
    );
  }

  // Statuts prédéfinis
  static PillBadge success(String text) => PillBadge(
        text: text,
        color: Colors.green,
        icon: Icons.check_circle_outline,
      );

  static PillBadge warning(String text) => PillBadge(
        text: text,
        color: Colors.orange,
        icon: Icons.warning_amber_outlined,
      );

  static PillBadge error(String text) => PillBadge(
        text: text,
        color: Colors.red,
        icon: Icons.error_outline,
      );

  static PillBadge info(String text) => PillBadge(
        text: text,
        color: Colors.blue,
        icon: Icons.info_outline,
      );
}
