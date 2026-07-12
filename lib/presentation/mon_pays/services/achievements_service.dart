// lib/presentation/mon_pays/services/achievements_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/province_achievement.dart'; // ✅ IMPORT AJOUTÉ

class AchievementsService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ProvinceAchievement>> getAchievementsByProvince(String provinceId) async {
    try {
      final response = await _client
          .from('province_achievements')
          .select('*')
          .eq('province_id', provinceId)
          .order('date', ascending: false);
      return response.map((e) => ProvinceAchievement.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Erreur chargement réalisations: $e');
    }
  }

  Future<ProvinceAchievement> createAchievement(ProvinceAchievement achievement) async {
    try {
      final data = achievement.toJson();
      data.remove('id');
      final response = await _client
          .from('province_achievements')
          .insert(data)
          .select()
          .single();
      return ProvinceAchievement.fromJson(response);
    } catch (e) {
      throw Exception('Erreur création réalisation: $e');
    }
  }

  Future<ProvinceAchievement> updateAchievement(ProvinceAchievement achievement) async {
    try {
      final response = await _client
          .from('province_achievements')
          .update(achievement.toJson())
          .eq('id', achievement.id)
          .select()
          .single();
      return ProvinceAchievement.fromJson(response);
    } catch (e) {
      throw Exception('Erreur mise à jour réalisation: $e');
    }
  }

  Future<void> deleteAchievement(String id) async {
    try {
      await _client.from('province_achievements').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erreur suppression réalisation: $e');
    }
  }
}
