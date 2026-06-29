// 📁 lib/presentation/thix_sante/common/widgets/search_bar.dart

import 'package:flutter/material.dart';

/// Barre de recherche personnalisée avec debounce
class CustomSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final String? hintText;
  final bool autofocus;
  final TextEditingController? controller;
  final VoidCallback? onFilterTap;

  const CustomSearchBar({
    Key? key,
    required this.onSearch,
    this.hintText,
    this.autofocus = false,
    this.controller,
    this.onFilterTap,
  }) : super(key: key);

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_controller.text == value) {
        widget.onSearch(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'Rechercher...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade500),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 16, color: Colors.grey.shade500),
                          onPressed: () {
                            _controller.clear();
                            widget.onSearch('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          if (widget.onFilterTap != null) ...[
            const SizedBox(width: 8),
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                icon: Icon(Icons.filter_list, size: 18, color: Colors.grey.shade700),
                onPressed: widget.onFilterTap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
