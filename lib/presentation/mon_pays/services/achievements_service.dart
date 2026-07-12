// lib/presentation/mon_pays/services/achievements_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/provincial_achievement.dart'; // Assure-toi que le fichier s'appelle bien provincial_achievement.dart

class AchievementsService {
  final SupabaseClient _client = Supabase.instance.client;

  // On utilise bien ProvincialAchievement (le nom complet)
  Future<List<ProvincialAchievement>> getAchievementsByProvince(String provinceId) async {
    try {
      final response = await _client
          .from('province_achievements')
          .select('*')
          .eq('province_id', provinceId)
          .order('achievement_date', ascending: false); // Correction : nom de colonne correct
      
      return (response as List).map((e) => ProvincialAchievement.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Erreur chargement réalisations: $e');
    }
  }

  Future<ProvincialAchievement> createAchievement(ProvincialAchievement achievement) async {
    try {
      final data = achievement.toJson();
      data.remove('id');
      final response = await _client
          .from('province_achievements')
          .insert(data)
          .select()
          .single();
      return ProvincialAchievement.fromJson(response);
    } catch (e) {
      throw Exception('Erreur création réalisation: $e');
    }
  }

  Future<ProvincialAchievement> updateAchievement(ProvincialAchievement achievement) async {
    try {
      final response = await _client
          .from('province_achievements')
          .update(achievement.toJson())
          .eq('id', achievement.id)
          .select()
          .single();
      return ProvincialAchievement.fromJson(response);
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
