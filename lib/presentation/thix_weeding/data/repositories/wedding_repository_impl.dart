// lib/presentation/thix_weeding/data/repositories/wedding_repository_impl.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/failure.dart';
import '../../domain/entities/wedding_entity.dart';

final weddingRepositoryProvider = Provider<WeddingRepository>((ref) => WeddingRepositoryImpl());

abstract class WeddingRepository {
  Future<WeddingEntity> getWeddingById(String id);
  Future<List<String>> getGallery(String weddingId, {int page = 1});
  Future<void> submitRsvp(RsvpEntity rsvp);
  Future<void> submitLivreOr(String weddingId, String name, String message);
  Future<List<GiftItem>> getGifts(String weddingId);
}

class WeddingRepositoryImpl implements WeddingRepository {
  @override
  Future<WeddingEntity> getWeddingById(String id) async {
    if (id.trim().length < 4) throw const Failure('ID de mariage invalide');
    await Future.delayed(const Duration(milliseconds: 500));
    // En prod: call Supabase / Dio
    return WeddingEntity(
      id: id,
      locationName: 'Salle des fêtes La Riviera',
      locationAddress: 'Cocody, Abidjan',
      latitude: 5.359,
      longitude: -4.008,
      coupleNames: 'Sarah & David',
      welcomeMessage: 'Merci d’être là pour célébrer notre amour',
      announcement: 'Parking disponible à partir de 15h',
    );
  }

  @override
  Future<List<String>> getGallery(String weddingId, {int page = 1}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.generate(20, (i) => 'https://picsum.photos/400/400?random=${page * 20 + i}');
  }

  @override
  Future<void> submitRsvp(RsvpEntity rsvp) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // En prod: await supabase.from('rsvp').insert(...)
  }

  @override
  Future<void> submitLivreOr(String weddingId, String name, String message) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<List<GiftItem>> getGifts(String weddingId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      const GiftItem(id: '1', name: 'Lune de miel', imageUrl: 'https://picsum.photos/200', price: 500000, contributed: 150000),
      const GiftItem(id: '2', name: 'Service à vaisselle', imageUrl: 'https://picsum.photos/200', price: 200000, contributed: 200000),
    ];
  }
}
