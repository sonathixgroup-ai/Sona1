// lib/presentation/mon_pays/providers/news_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/news_model.dart';
import '../repositories/news_repository.dart';
import 'mon_pays_provider.dart';

final newsProvider = FutureProvider<List<News>>((ref) async {
  final repo = ref.watch(newsRepositoryProvider);
  return repo.getAll();
});

final newsItemProvider = FutureProvider.family<News, String>((ref, id) async {
  final repo = ref.watch(newsRepositoryProvider);
  return repo.getById(id);
});
