import 'package:freezed_annotation/freezed_annotation.dart';
part 'appointment_model.freezed.dart';
part 'appointment_model.g.dart';

@freezed
class AppointmentModel with _$AppointmentModel {
  const factory AppointmentModel({
    String? id,
    @JsonKey(name: 'patient_id') required String patientId,
    @JsonKey(name: 'doctor_id') required String doctorId,
    @JsonKey(name: 'date_rdv') required DateTime dateRdv,
    required String type,
    required String motif,
    String? creneau,
    @Default('demande') String statut,
    int? prix,
    @JsonKey(name: 'duree_minutes') int? dureeMinutes,
    @JsonKey(name: 'pj_path') String? pjPath,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    Map<String, dynamic>? doctor,
  }) = _AppointmentModel;
  factory AppointmentModel.fromJson(Map<String, dynamic> json) => _$AppointmentModelFromJson(json);
}
