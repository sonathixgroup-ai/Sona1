// lib/presentation/mon_pays/providers/featured_provinces_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'provinces_provider.dart';

// Fournisseur pour récupérer les provinces en vedette ou la liste générale
final featuredProvincesProvider = FutureProvider((ref) async {
  final provinces = await ref.watch(provincesProvider.future);
  // Retourne par exemple les 5 premières provinces ou filtre selon vos critères
  return provinces;
});
