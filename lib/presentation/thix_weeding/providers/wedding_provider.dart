// lib/presentation/thix_weeding/providers/wedding_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/failure.dart';
import '../data/repositories/wedding_repository_impl.dart';
import '../domain/entities/wedding_entity.dart';

part 'wedding_provider.g.dart';

/// Provider principal invité.
/// Famille autoDispose = mémoire libérée automatiquement quand l'écran est fermé
/// Supporte millions d'users car pas de state global gardé en RAM
@riverpod
class GuestWedding extends _$GuestWedding {
  @override
  Future<WeddingEntity> build(String weddingId) async {
    // Validation d'entrée = évite un appel réseau inutile
    final cleanId = weddingId.trim();
    if (cleanId.isEmpty || cleanId.length < 4) {
      throw const Failure('ID de mariage invalide');
    }

    // Pas de ref.watch ici = évite rebuild infini
    final repository = ref.read(weddingRepositoryProvider);
    
    // Future direct = Riverpod gère loading/error/data + cache
    return await repository.getWeddingById(cleanId);
  }

  /// Pour pull-to-refresh
  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// Pour garder le cache vivant 5min si besoin
  void keepAlive() {
    final link = ref.keepAlive();
    Future.delayed(const Duration(minutes: 5), () => link.close());
  }
}
