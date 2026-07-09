// lib/presentation/mon_pays/providers/history_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/history_model.dart';
import '../repositories/history_repository.dart';
import 'mon_pays_provider.dart';

final historyProvider = FutureProvider<List<HistoricalFigure>>((ref) async {
  final repo = ref.watch(historyRepositoryProvider);
  return repo.getAll();
});

final historicalFigureProvider = FutureProvider.family<HistoricalFigure, String>((ref, id) async {
  final repo = ref.watch(historyRepositoryProvider);
  return repo.getById(id);
});
