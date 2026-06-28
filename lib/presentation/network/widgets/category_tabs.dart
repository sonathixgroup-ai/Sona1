// lib/presentation/network/widgets/category_tabs.dart
import 'package:flutter/material.dart';

class CategoryTabs extends StatefulWidget {
  const CategoryTabs({Key? key}) : super(key: key);

  @override
  State<CategoryTabs> createState() => _CategoryTabsState();
}

class _CategoryTabsState extends State<CategoryTabs> {
  final _tabs = ['Accueil', 'Réseau', 'Opportunités', 'Vidéos'];
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == _selected;
          return GestureDetector(
            onTap: () => setState(() => _selected = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? Colors.blue.shade50 : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? Colors.blue : Colors.transparent),
              ),
              child: Text(_tabs[index], style: TextStyle(fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
            ),
          );
        },
      ),
    );
  }
}
