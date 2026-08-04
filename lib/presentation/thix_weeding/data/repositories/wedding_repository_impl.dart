// lib/presentation/thix_weeding/data/repositories/wedding_repository_impl.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/failure.dart';
import '../../domain/entities/wedding_entity.dart';
import '../../domain/repositories/wedding_repository.dart';
import '../datasources/wedding_local_datasource.dart';
import '../datasources/wedding_remote_datasource.dart';
import '../models/wedding_dto.dart';
import '../../models/program_item_model.dart';
import '../../models/gift_model.dart';

part 'wedding_repository_impl.g.dart';

@Riverpod(keepAlive: true)
WeddingRepository weddingRepository(WeddingRepositoryRef ref) {
  return WeddingRepositoryImpl(
    remote: ref.watch(weddingRemoteDataSourceProvider),
    local: ref.watch(weddingLocalDataSourceProvider),
  );
}

class WeddingRepositoryImpl implements WeddingRepository {
  final WeddingRemoteDataSource remote;
  final WeddingLocalDataSource local;
  WeddingRepositoryImpl({required this.remote, required this.local});

  @override
  Future<WeddingEntity> getWeddingById(String id) async {
    try {
      final json = await remote.fetchWedding(id);
      await local.cacheWedding(id, json); // cache pour offline
      return WeddingDto.fromJson(json).toDomain();
    } on Failure {
      // Fallback cache si réseau KO = essentiel pour millions d'users
      final cached = await local.getCachedWedding(id);
      if (cached != null) return WeddingDto.fromJson(cached).toDomain();
      rethrow;
    }
  }

  @override
  Future<List<ProgramItem>> getProgram(String weddingId) async {
    final list = await remote.fetchProgram(weddingId);
    return list.map((e) => ProgramItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<GiftItem>> getGifts(String weddingId) async {
    final list = await remote.fetchGifts(weddingId);
    return list.map((e) => GiftItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<String>> getGallery(String weddingId, {int page = 1}) async {
    final list = await remote.fetchGallery(weddingId, page);
    return list.map((e) => e['url'] as String).toList();
  }

  @override
  Future<void> submitRsvp(RsvpEntity rsvp) {
    return remote.postRsvp(rsvp.toPayload());
  }

  @override
  Future<void> submitLivreOr(String weddingId, String name, String message) {
    return remote.postLivreOr(weddingId, {'guest_name': name, 'message': message});
  }

  @override
  Future<void> contributeGift(String giftId, double amount) async {
    // Appel Thix Money ici
  }
}
