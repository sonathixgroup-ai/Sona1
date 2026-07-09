// lib/presentation/mon_pays/widgets/header/search_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class MonPaysSearchBar extends StatefulWidget {
  final Function(String)? onSearch;
  final String hintText;
  final bool autoFocus;
  final ValueChanged<String>? onSubmitted;

  const MonPaysSearchBar({
    Key? key,
    this.onSearch,
    this.hintText = 'Rechercher...',
    this.autoFocus = false,
    this.onSubmitted,
  }) : super(key: key);

  @override
  _MonPaysSearchBarState createState() => _MonPaysSearchBarState();
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
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(
            Icons.search,
            color: AppColors.primaryRed,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              style: AppTextStyles.bodySmall,
              onChanged: widget.onSearch,
              onSubmitted: widget.onSubmitted,
              textInputAction: TextInputAction.search,
            ),
          ),
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.clear,
                size: 18,
                color: AppColors.textSecondary,
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
