// lib/presentation/thix_sante/patient/providers/patient_dashboard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_record_model.dart';
import '../services/health_record_service.dart';
import '../services/patient_link_service.dart';

final healthRecordServiceProvider = Provider((ref)=> HealthRecordService());
final patientLinkServiceProvider = Provider((ref)=> PatientLinkService());

final recentRecordsProvider = FutureProvider<List<HealthRecordModel>>((ref) async {
  return ref.read(healthRecordServiceProvider).getMyRecords();
});
