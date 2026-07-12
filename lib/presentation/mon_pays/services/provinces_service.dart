// lib/presentation/mon_pays/services/provinces_service.dart

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/province.dart';
import '../models/provincial_achievement.dart'; // Tu devras créer ce modèle aussi

class ProvincesService {
  final SupabaseClient _client = Supabase.instance.client;

  // ─── UPLOAD DE MÉDIAS (Blason, Couverture, Galerie) ───
  Future<String> uploadProvinceMedia(String fileName, Uint8List fileBytes, String folderName) async {
    try {
      final path = 'provinces/$folderName/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await _client.storage.from('media').uploadBinary(path, fileBytes);
      return _client.storage.from('media').getPublicUrl(path);
    } catch (e) {
      throw Exception('Erreur upload média: $e');
    }
  }

  // ─── GESTION DES PROVINCES (CRUD) ───
  
  // Récupérer toutes les provinces (avec lien vers gouverneur)
  Future<List<Province>> getProvinces() async {
    final response = await _client.from('provinces').select('*, governor:authorities(*)').order('name');
    return (response as List).map((json) => Province.fromJson(json)).toList();
  }

  // Récupérer une province par ID
  Future<Province> getProvinceById(String id) async {
    final response = await _client.from('provinces').select('*').eq('id', id).single();
    return Province.fromJson(response);
  }

  // Créer ou Modifier une province
  Future<Province> saveProvince(Province province) async {
    final data = province.toJson();
    if (data['id'] == null) data.remove('id');
    
    final response = await _client.from('provinces').upsert(data).select().single();
    return Province.fromJson(response);
  }

  Future<void> deleteProvince(String id) async {
    await _client.from('provinces').delete().eq('id', id);
  }

  // ─── GESTION DES RÉALISATIONS ───

  Future<List<ProvincialAchievement>> getAchievements(String provinceId) async {
    final response = await _client
        .from('provincial_achievements')
        .select('*')
        .eq('province_id', provinceId)
        .order('achievement_date', ascending: false);
    return (response as List).map((json) => ProvincialAchievement.fromJson(json)).toList();
  }

  Future<void> saveAchievement(ProvincialAchievement achievement) async {
    await _client.from('provincial_achievements').upsert(achievement.toJson());
  }
}
