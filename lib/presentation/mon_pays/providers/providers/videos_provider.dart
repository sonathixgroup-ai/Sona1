// lib/presentation/mon_pays/providers/videos_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/video_model.dart';
import '../repositories/videos_repository.dart';
import 'mon_pays_provider.dart';

final videosProvider = FutureProvider<List<Video>>((ref) async {
  final repo = ref.watch(videosRepositoryProvider);
  return repo.getAll();
});

final videoProvider = FutureProvider.family<Video, String>((ref, id) async {
  final repo = ref.watch(videosRepositoryProvider);
  return repo.getById(id);
});
