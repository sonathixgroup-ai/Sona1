// lib/providers/certificate_provider.dart
import 'package:flutter/material.dart';
import '../services/education_service.dart';
import '../models/certificate.dart';

class CertificateProvider extends ChangeNotifier {
  final EducationService _service;

  List<Certificate> _certificates = [];
  Certificate? _currentCertificate;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Certificate> get certificates => _certificates;
  Certificate? get currentCertificate => _currentCertificate;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CertificateProvider(this._service);

  // ─── CHARGEMENT ──────────────────────────────────────────────────

  Future<void> loadCertificates(String userId) async {
    _setLoading(true);
    try {
      // Récupérer toutes les formations terminées de l'utilisateur
      final formations = await _service.getMyFormations(userId);
      _certificates = [];

      for (final formation in formations) {
        final cert = await _service.getCertificate(userId, formation.id);
        if (cert != null) {
          _certificates.add(cert);
        }
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading certificates: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<Certificate?> getCertificate(String userId, String formationId) async {
    _setLoading(true);
    try {
      final cert = await _service.getCertificate(userId, formationId);
      if (cert != null) {
        _currentCertificate = cert;
      }
      _error = null;
      return cert;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching certificate: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ─── GÉNÉRATION ──────────────────────────────────────────────────

  Future<Certificate?> generateCertificate(String userId, String formationId) async {
    _setLoading(true);
    try {
      final certificate = await _service.generateCertificate(userId, formationId);
      _currentCertificate = certificate;
      await loadCertificates(userId); // Recharger la liste
      _error = null;
      return certificate;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error generating certificate: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ─── UTILITAIRES ──────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _certificates = [];
    _currentCertificate = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
