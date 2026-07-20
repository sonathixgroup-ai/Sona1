// lib/presentation/thix_urgent/controllers/urgent_controller.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/emergency_alert_service.dart';
import 'permission_controller.dart';
import 'recording_controller.dart';
import '../services/sirene_service.dart';

enum EmergencyType { denoncer, accident, police, personne }

class UrgentController extends ChangeNotifier {
  EmergencyType? _selectedType;
  bool _isAlertActive = false;
  bool _isLoading = false;
  Position? _currentPos;
  String? _criseId;
  String? _error;

  // PAGINATION pour historique (scale 1M)
  List<Map<String, dynamic>> _alertHistory = [];
  bool _hasMoreHistory = true;
  int _historyPage = 0;
  static const int _pageSize = 20;

  final _alertService = EmergencyAlertService();
  final permissionCtrl = PermissionController();
  final recordingCtrl = RecordingController();
  final sireneService = SireneService();

  EmergencyType? get selectedType => _selectedType;
  bool get isAlertActive => _isAlertActive;
  bool get isLoading => _isLoading;
  Position? get currentPos => _currentPos;
  String? get criseId => _criseId;
  String? get error => _error;
  List<Map<String, dynamic>> get alertHistory => _alertHistory;
  bool get hasMoreHistory => _hasMoreHistory;

  Future<void> init(BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    try {
      await permissionCtrl.checkAll();
      if (permissionCtrl.location) {
        _currentPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 5))
        );
      }
      await loadHistory(refresh: true);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectType(EmergencyType type) {
    _selectedType = type;
    notifyListeners();
  }

  Future<void> loadHistory({bool refresh = false}) async {
    if (refresh) {
      _historyPage = 0;
      _alertHistory = [];
      _hasMoreHistory = true;
    }
    if (!_hasMoreHistory || _isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _alertService.getAlertHistoryPaginated(page: _historyPage, pageSize: _pageSize);
      if (data.length < _pageSize) _hasMoreHistory = false;
      _alertHistory.addAll(data);
      _historyPage++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> triggerAlert(BuildContext context) async {
    if (_selectedType == null) return;
    _isAlertActive = true;
    _isLoading = true;
    notifyListeners();
    try {
      await permissionCtrl.requestAll();
      await Future.wait([recordingCtrl.startLiveRecording(), sireneService.startIfNeeded(_selectedType!)]);
      _criseId = await _alertService.triggerEmergency(type: _selectedType!, position: _currentPos);
    } catch (e) {
      _error = e.toString();
      _isAlertActive = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _isAlertActive = false;
    _selectedType = null;
    _criseId = null;
    recordingCtrl.stop();
    sireneService.stop();
    notifyListeners();
  }
}
