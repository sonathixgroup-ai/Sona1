// 📁 lib/presentation/thix_sante/common/widgets/custom_bottom_sheet.dart

import 'package:flutter/material.dart';

/// Bottom sheet personnalisée avec titre et actions
class CustomBottomSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final double? height;
  final List<Widget>? actions;

  const CustomBottomSheet({
    Key? key,
    required this.title,
    required this.children,
    this.height,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.3,
                ),
              ),
              if (actions != null) Row(children: actions!),
            ],
          ),
          const Divider(height: 24),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<Widget> children,
    double? height,
    List<Widget>? actions,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomBottomSheet(
        title: title,
        children: children,
        height: height,
        actions: actions,
      ),
    );
  }
}
