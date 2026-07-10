// lib/presentation/mon_pays/widgets/search_bar.dart

import 'package:flutter/material.dart';
import '../utils/mon_pays_colors.dart';
import '../utils/mon_pays_text_styles.dart';

class MonPaysSearchBar extends StatefulWidget {
  final Function(String)? onSearch;
  final String hintText;
  final bool autoFocus;

  const MonPaysSearchBar({
    Key? key,
    this.onSearch,
    this.hintText = 'Rechercher...',
    this.autoFocus = false,
  }) : super(key: key);

  @override
  State<MonPaysSearchBar> createState() => _MonPaysSearchBarState();
}

class _MonPaysSearchBarState extends State<MonPaysSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.autoFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: MonPaysColors.backgroundLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: MonPaysColors.primaryRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(
            Icons.search,
            color: MonPaysColors.primaryRed,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: MonPaysTextStyles.bodySmall.copyWith(
                  color: MonPaysColors.textHint,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              style: MonPaysTextStyles.bodySmall,
              onChanged: widget.onSearch,
            ),
          ),
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.clear,
                size: 18,
                color: MonPaysColors.textSecondary,
              ),
              onPressed: () {
                _controller.clear();
                widget.onSearch?.call('');
                setState(() {});
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
