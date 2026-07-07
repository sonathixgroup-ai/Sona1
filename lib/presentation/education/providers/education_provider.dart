import 'package:flutter/material.dart';
import '../services/education_service.dart';
import '../models/formation.dart';
import '../models/category.dart';
import '../models/enrollment.dart';

class EducationProvider extends ChangeNotifier {
  final EducationService _service;

  List<Formation> _formations = [];
  List<Category> _categories = [];
  List<Enrollment> _myEnrollments = [];
  Formation? _currentFormation;
  bool _isLoading = false;
  String? _error;

  List<Formation> get formations => _formations;
  List<Category> get categories => _categories;
  List<Enrollment> get myEnrollments => _myEnrollments;
  Formation? get currentFormation => _currentFormation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  EducationProvider(this._service);

  Future<void> loadFormations({String? categoryId, String? level, String? search, bool force = false}) async {
    if (!force && _formations.isNotEmpty) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _formations = await _service.getFormations(
        categoryId: categoryId,
        level: level,
        search: search,
        status: 'published',
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Dans education_provider.dart, méthode loadCategories :
Future<void> loadCategories() async {
  try {
    _categories = await _service.getCategories(); // ✅ Correction
    notifyListeners();
  } catch (e) {
    _error = e.toString();
    notifyListeners();
  }
}
  Future<void> loadFormationDetails(String formationId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentFormation = await _service.getFormationDetails(formationId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyEnrollments(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final formations = await _service.getMyFormations(userId);
      _myEnrollments = [];
      for (final f in formations) {
        final enrollment = await _service.getEnrollment(userId, f.id);
        if (enrollment != null) {
          enrollment.formation = f;
          _myEnrollments.add(enrollment);
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Enrollment?> enrollUser(String userId, String formationId) async {
    try {
      final enrollment = await _service.enrollUser(userId, formationId);
      await loadMyEnrollments(userId);
      return enrollment;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> isUserEnrolled(String userId, String formationId) async {
    final enrollment = await _service.getEnrollment(userId, formationId);
    return enrollment != null;
  }

  Future<void> createFormation(Formation formation) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.createFormation(formation);
      await loadFormations(force: true);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
