import 'package:supabase_flutter/supabase_flutter.dart'; // 👈 N'oubliez pas d'importer Supabase
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/failure.dart';
import '../../domain/entities/wedding_entity.dart';
import '../../models/program_item_model.dart'; 

final weddingRepositoryProvider = Provider<WeddingRepository>((ref) => WeddingRepositoryImpl());

abstract class WeddingRepository {
  Future<WeddingEntity> getWeddingById(String id);
  // ... (le reste de l'interface ne change pas)
  Future<List<String>> getGallery(String weddingId, {int page = 1});
  Future<void> submitRsvp(RsvpEntity rsvp);
  Future<void> submitLivreOr(String weddingId, String name, String message);
  Future<List<GiftItem>> getGifts(String weddingId);
  Future<List<ProgramItem>> getProgram(String weddingId); 
}

class WeddingRepositoryImpl implements WeddingRepository {
  
  // 👇 VOICI LA VRAIE FONCTION CONNECTÉE À SUPABASE
  @override
  Future<WeddingEntity> getWeddingById(String id) async {
    final cleanId = id.trim().toUpperCase(); // On nettoie et on met en majuscules
    
    if (cleanId.length < 4) {
      throw const Failure('ID de mariage invalide');
    }

    try {
      // 1. On interroge Supabase
      final response = await Supabase.instance.client
          .from('thix_weeding_weddings')
          .select()
          .eq('id', cleanId)
          .maybeSingle(); // maybeSingle() renvoie null si l'ID n'existe pas

      // 2. Si aucun mariage n'est trouvé, on déclenche une erreur
      if (response == null) {
        throw const Failure('Aucun mariage trouvé avec cet ID. Veuillez vérifier votre code.');
      }

      // 3. Si on trouve le mariage, on transforme les données de la base en WeddingEntity
      return WeddingEntity(
        id: response['id'] ?? cleanId,
        locationName: response['location_name'] ?? '',
        locationAddress: response['location_address'] ?? '',
        latitude: (response['latitude'] ?? 0).toDouble(),
        longitude: (response['longitude'] ?? 0).toDouble(),
        coupleNames: response['couple_names'] ?? '',
        welcomeMessage: response['welcome_message'] ?? '',
        announcement: response['announcement'] ?? '',
        date: DateTime.parse(response['date']),
        // Note: L'image n'est pas encore dans votre base SQL, on laisse un placeholder pour l'instant
        coverImageUrl: 'https://picsum.photos/800/600', 
      );

    } on Failure {
      rethrow; // On renvoie l'erreur personnalisée (Aucun mariage trouvé)
    } catch (e) {
      throw Failure('Erreur de connexion : ${e.toString()}');
    }
  }

  // ... (Le reste de vos méthodes getGallery, getGifts, etc. restent identiques pour le moment)
  // Vous pourrez les connecter à Supabase de la même manière ensuite !
