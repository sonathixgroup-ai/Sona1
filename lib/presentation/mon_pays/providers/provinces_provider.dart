// ============================================================
// PROVIDERS – PHASE 2B
// ============================================================
// Fichiers 13 à 16
// ============================================================

// Fichier n°13 : providers/provinces_provider.dart
// lib/presentation/mon_pays/providers/provinces_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/province.dart';
import '../models/province_government.dart';
import '../models/province_minister.dart';
import '../models/province_economic.dart';
import '../models/province_tourism.dart';
import '../models/province_emergency.dart';
import '../models/province_administrative.dart';
import '../models/province_budget.dart';
import '../services/provinces_service.dart';

// ============================================================
// SERVICE PROVIDER
// ============================================================
final provincesServiceProvider = Provider<ProvincesService>((ref) {
  return ProvincesService();
});

// ============================================================
// LISTE PUBLIQUE (avec filtres)
// ============================================================
final provincesProvider = FutureProvider.family<List<Province>, String?>((ref, region) async {
  final service = ref.watch(provincesServiceProvider);
  return service.getProvinces(region: region);
});

// Recherche
final searchProvincesProvider = FutureProvider.family<List<Province>, String>((ref, query) async {
  final service = ref.watch(provincesServiceProvider);
  return service.getProvinces(search: query);
});

// ============================================================
// PROVINCE COMPLÈTE (avec toutes les relations)
// ============================================================
final provinceWithAllRelationsProvider = FutureProvider.family<Province, String>((ref, id) async {
  final service = ref.watch(provincesServiceProvider);
  return service.getProvinceWithAllRelations(id);
});

// ============================================================
// SOUS-RESSOURCES D'UNE PROVINCE
// ============================================================
final provinceGovernmentProvider = FutureProvider.family<ProvinceGovernment?, String>((ref, provinceId) async {
  final service = ref.watch(provincesServiceProvider);
  return service.getGovernment(provinceId);
});

final provinceMinistersProvider = FutureProvider.family<List<ProvinceMinister>, String>((ref, provinceId) async {
  final service = ref.watch(provincesServiceProvider);
  final gov = await service.getGovernment(provinceId);
  return gov?.ministers ?? [];
});

final provinceEconomicResourcesProvider = FutureProvider.family<List<ProvinceEconomicResource>, String>((ref, provinceId) async {
  final service = ref.watch(provincesServiceProvider);
  return service.getEconomicResources(provinceId);
});

final provinceBudgetPrioritiesProvider = FutureProvider.family<List<ProvinceBudgetPriority>, String>((ref, provinceId) async {
  final service = ref.watch(provincesServiceProvider);
  return service.getBudgetPriorities(provinceId);
});

final provinceTourismSitesProvider = FutureProvider.family<List<ProvinceTourism>, String>((ref, provinceId) async {
  final service = ref.watch(provincesServiceProvider);
  return service.getTourismSites(provinceId);
});

final provinceEmergencyContactsProvider = FutureProvider.family<List<ProvinceEmergencyContact>, String>((ref, provinceId) async {
  final service = ref.watch(provincesServiceProvider);
  return service.getEmergencyContacts(provinceId);
});

final provinceAdministrativeDivisionsProvider = FutureProvider.family<List<ProvinceAdministrativeDivision>, String>((ref, provinceId) async {
  final service = ref.watch(provincesServiceProvider);
  return service.getAdministrativeDivisions(provinceId);
});

// ============================================================
// ADMIN PROVINCES (CRUD avec StateNotifier)
// ============================================================
final adminProvincesProvider = StateNotifierProvider<AdminProvincesNotifier, AsyncValue<List<Province>>>((ref) {
  return AdminProvincesNotifier(ref);
});

class AdminProvincesNotifier extends StateNotifier<AsyncValue<List<Province>>> {
  final Ref _ref;

  AdminProvincesNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadProvinces();
  }

  Future<void> loadProvinces() async {
    state = const AsyncValue.loading();
    try {
      final service = _ref.read(provincesServiceProvider);
      final list = await service.getProvinces();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createProvince(Province province) async {
    try {
      final service = _ref.read(provincesServiceProvider);
      await service.createProvince(province);
      await loadProvinces();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProvince(Province province) async {
    try {
      final service = _ref.read(provincesServiceProvider);
      await service.updateProvince(province);
      await loadProvinces();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteProvince(String id) async {
    try {
      final service = _ref.read(provincesServiceProvider);
      await service.deleteProvince(id);
      await loadProvinces();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Gestion du gouvernement
  Future<void> updateGovernment(ProvinceGovernment gov) async {
    try {
      final service = _ref.read(provincesServiceProvider);
      await service.updateGovernment(gov);
      // Recharger la province concernée
      await loadProvinces();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Gestion des ministres
  Future<void> addMinister(ProvinceMinister minister) async {
    try {
      final service = _ref.read(provincesServiceProvider);
      await service.addMinister(minister);
      await loadProvinces();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeMinister(String ministerId) async {
    try {
      final service = _ref.read(provincesServiceProvider);
      await service.removeMinister(ministerId);
      await loadProvinces();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Gestion des ressources économiques
  Future<void> addEconomicResource(ProvinceEconomicResource resource) async {
    try {
      final service = _ref.read(provincesServiceProvider);
      await service.addEconomicResource(resource);
      await loadProvinces();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteEconomicResource(String id) async {
    try {
      final service = _ref.read(provincesServiceProvider);
      await service.deleteEconomicResource(id);
      await loadProvinces();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Gestion du budget
  Future<void> addBudgetPriority(ProvinceBudgetPriority budget) async {
    try {
      final service = _ref.read(provincesServiceProvider);
      await service.addBudgetPriority(budget);
      await loadProvinces();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteBudgetPriority(String id) async {
    try {
      final service = _ref.read(provincesServiceProvider);
      await service.deleteBudgetPriority(id);
      await loadProvinces();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Gestion du tourisme
  Future<void> addTourismSite(ProvinceTourism site) async {
    try {
      final service = _ref.read(provincesServiceProvider);
      await service.addTourismSite(site);
      await loadProvinces();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteTourismSite(String id) async {
    try {
      final service = _ref.read(provincesServiceProvider);
      await service.deleteTourismSite(id);
      await loadProvinces();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Gestion des urgences
  Future<void> addEmergencyContact(ProvinceEmergencyContact contact) async {
    try {
      final service = _ref.read(provincesServiceProvider);
      await service.addEmergencyContact(contact);
      await loadProvinces();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteEmergencyContact(String id) async {
    try {
      final service = _ref.read(provincesServiceProvider);
      await service.deleteEmergencyContact(id);
      await loadProvinces();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Gestion du découpage administratif
  Future<void> addAdministrativeDivision(ProvinceAdministrativeDivision division) async {
    try {
      final service = _ref.read(provincesServiceProvider);
      await service.addAdministrativeDivision(division);
      await loadProvinces();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteAdministrativeDivision(String id) async {
    try {
      final service = _ref.read(provincesServiceProvider);
      await service.deleteAdministrativeDivision(id);
      await loadProvinces();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
