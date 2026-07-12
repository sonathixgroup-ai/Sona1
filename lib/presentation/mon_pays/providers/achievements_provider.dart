// Fichier n°15 : providers/achievements_provider.dart
// lib/presentation/mon_pays/providers/achievements_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/province_achievement.dart';
import '../services/achievements_service.dart';

final achievementsServiceProvider = Provider<AchievementsService>((ref) {
  return AchievementsService();
});

final achievementsByProvinceProvider = FutureProvider.family<List<ProvinceAchievement>, String>((ref, provinceId) async {
  final service = ref.watch(achievementsServiceProvider);
  return service.getAchievementsByProvince(provinceId);
});

// Admin
final adminAchievementsProvider = StateNotifierProvider<AdminAchievementsNotifier, AsyncValue<List<ProvinceAchievement>>>((ref) {
  return AdminAchievementsNotifier(ref);
});

class AdminAchievementsNotifier extends StateNotifier<AsyncValue<List<ProvinceAchievement>>> {
  final Ref _ref;
  String? _currentProvinceId;

  AdminAchievementsNotifier(this._ref) : super(const AsyncValue.loading());

  Future<void> loadAchievements(String provinceId) async {
    _currentProvinceId = provinceId;
    state = const AsyncValue.loading();
    try {
      final service = _ref.read(achievementsServiceProvider);
      final list = await service.getAchievementsByProvince(provinceId);
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createAchievement(ProvinceAchievement achievement) async {
    try {
      final service = _ref.read(achievementsServiceProvider);
      await service.createAchievement(achievement);
      if (_currentProvinceId != null) {
        await loadAchievements(_currentProvinceId!);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateAchievement(ProvinceAchievement achievement) async {
    try {
      final service = _ref.read(achievementsServiceProvider);
      await service.updateAchievement(achievement);
      if (_currentProvinceId != null) {
        await loadAchievements(_currentProvinceId!);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteAchievement(String id) async {
    try {
      final service = _ref.read(achievementsServiceProvider);
      await service.deleteAchievement(id);
      if (_currentProvinceId != null) {
        await loadAchievements(_currentProvinceId!);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
