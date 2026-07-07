// lib/providers/education_provider.dart
import 'package:flutter/material.dart';
import '../services/education_service.dart';
import '../models/formation.dart';
import '../models/category.dart';
import '../models/module.dart';
import '../models/lesson.dart';
import '../models/enrollment.dart';

class EducationProvider extends ChangeNotifier {
  final EducationService _service;

  List<Formation> _formations = [];
  List<Category> _categories = [];
  List<Enrollment> _myEnrollments = [];
  Formation? _currentFormation;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Formation> get formations => _formations;
  List<Category> get categories => _categories;
  List<Enrollment> get myEnrollments => _myEnrollments;
  Formation? get currentFormation => _currentFormation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  EducationProvider(this._service);

  // ─── CHARGEMENT DES FORMATIONS ──────────────────────────────────

  Future<void> loadFormations({
    String? categoryId,
    String? level,
    String? search,
    int limit = 20,
    bool refresh = false,
  }) async {
    if (refresh) {
      _formations = [];
      _currentFormation = null;
    }

    _setLoading(true);
    try {
      final formations = await _service.getFormations(
        categoryId: categoryId,
        level: level,
        search: search,
        limit: limit,
      );
      if (refresh) {
        _formations = formations;
      } else {
        _formations.addAll(formations);
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading formations: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadFormationDetails(String formationId) async {
    _setLoading(true);
    try {
      _currentFormation = await _service.getFormationDetails(formationId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading formation details: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMyEnrollments(String userId) async {
    _setLoading(true);
    try {
      _myEnrollments = [];
      final formations = await _service.getMyFormations(userId);
      // Récupérer les détails d'inscription pour chaque formation
      for (final formation in formations) {
        final enrollment = await _service.getEnrollment(userId, formation.id);
        if (enrollment != null) {
          enrollment.formation = formation;
          _myEnrollments.add(enrollment);
        }
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading my enrollments: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ─── CATÉGORIES ──────────────────────────────────────────────────

  Future<void> loadCategories() async {
    _setLoading(true);
    try {
      _categories = await _service.getCategories();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading categories: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ─── INSCRIPTIONS ────────────────────────────────────────────────

  Future<Enrollment?> enrollUser(String userId, String formationId) async {
    _setLoading(true);
    try {
      final enrollment = await _service.enrollUser(userId, formationId);
      // Recharger la liste des inscriptions
      await loadMyEnrollments(userId);
      _error = null;
      return enrollment;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error enrolling user: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> isUserEnrolled(String userId, String formationId) async {
    try {
      final enrollment = await _service.getEnrollment(userId, formationId);
      return enrollment != null;
    } catch (e) {
      return false;
    }
  }

  Future<Enrollment?> getUserEnrollment(String userId, String formationId) async {
    try {
      return await _service.getEnrollment(userId, formationId);
    } catch (e) {
      return null;
    }
  }

  // ─── UTILITAIRES ──────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _formations = [];
    _categories = [];
    _myEnrollments = [];
    _currentFormation = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
