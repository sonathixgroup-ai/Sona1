// lib/presentation/mon_pays/providers/search_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/search_result_model.dart';
import '../repositories/search_repository.dart';
import 'mon_pays_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.family<List<SearchResult>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final repo = ref.watch(searchRepositoryProvider);
  return repo.search(query);
});
