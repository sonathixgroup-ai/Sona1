// lib/presentation/mon_pays/utils/extensions/list_extensions.dart

import 'package:flutter/material.dart';

extension ListExtensions<T> on List<T> {
  /// Retourne vrai si la liste est nulle ou vide
  bool get isNullOrEmpty => isEmpty;

  /// Retourne vrai si la liste n'est pas nulle et non vide
  bool get isNotNullOrEmpty => isNotEmpty;

  /// Retourne la liste groupée par une clé
  Map<K, List<T>> groupBy<K>(K Function(T) keyFunction) {
    final map = <K, List<T>>{};
    for (var item in this) {
      final key = keyFunction(item);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  /// Retourne la liste triée par une clé
  List<T> sortBy<K extends Comparable<K>>(K Function(T) keyFunction) {
    final list = List<T>.from(this);
    list.sort((a, b) => keyFunction(a).compareTo(keyFunction(b)));
    return list;
  }

  /// Retourne la liste triée par une clé en ordre décroissant
  List<T> sortByDesc<K extends Comparable<K>>(K Function(T) keyFunction) {
    final list = List<T>.from(this);
    list.sort((a, b) => keyFunction(b).compareTo(keyFunction(a)));
    return list;
  }

  /// Retourne les éléments distincts par une clé
  List<T> distinctBy<K>(K Function(T) keyFunction) {
    final seen = <K>{};
    return where((element) => seen.add(keyFunction(element))).toList();
  }

  /// Pagine la liste
  List<T> paginate(int page, int pageSize) {
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, length);
    return sublist(start, end);
  }

  /// Divise la liste en chunks
  List<List<T>> chunked(int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += chunkSize) {
      chunks.add(sublist(i, (i + chunkSize).clamp(0, length)));
    }
    return chunks;
  }

  /// Retourne un widget Wrap avec les éléments
  Widget toWrap({
    required Widget Function(T item) builder,
    Axis direction = Axis.horizontal,
    double spacing = 8,
    double runSpacing = 8,
  }) {
    return Wrap(
      direction: direction,
      spacing: spacing,
      runSpacing: runSpacing,
      children: map((item) => builder(item)).toList(),
    );
  }

  /// Retourne un widget Column avec les éléments
  Widget toColumn({
    required Widget Function(T item) builder,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    double spacing = 0,
  }) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: map((item) => builder(item)).toList().addSpacing(spacing),
    );
  }

  /// Retourne un widget Row avec les éléments
  Widget toRow({
    required Widget Function(T item) builder,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    double spacing = 0,
  }) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: map((item) => builder(item)).toList().addSpacing(spacing),
    );
  }
}

/// Extension sur List<Widget> pour ajouter des espaces
extension WidgetListExtensions on List<Widget> {
  List<Widget> addSpacing(double spacing) {
    if (spacing <= 0 || length <= 1) return this;
    final result = <Widget>[];
    for (var i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) {
        result.add(SizedBox(width: spacing, height: spacing));
      }
    }
    return result;
  }
}
