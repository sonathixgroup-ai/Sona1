// lib/presentation/thix_sante/patient/models/health_record_model.dart
import 'package:flutter/material.dart';

enum RecordType { radiologie, ordonnance, analyse, vaccin, autre, laboratoire }

extension RecordTypeX on RecordType {
  String get label {
    switch(this){
      case RecordType.radiologie: return 'Radiologie';
      case RecordType.ordonnance: return 'Ordonnance';
      case RecordType.analyse: return 'Analyse';
      case RecordType.laboratoire: return 'Laboratoire';
      case RecordType.vaccin: return 'Vaccin';
      case RecordType.autre: return 'Autre';
    }
  }
  IconData get icon {
    switch(this){
      case RecordType.radiologie: return Icons.medical_services_rounded;
      case RecordType.ordonnance: return Icons.receipt_long_rounded;
      case RecordType.analyse: case RecordType.laboratoire: return Icons.biotech_rounded;
      case RecordType.vaccin: return Icons.vaccines_rounded;
      case RecordType.autre: return Icons.folder_rounded;
    }
  }
  Color get color {
    switch(this){
      case RecordType.radiologie: return const Color(0xFF0B63F6);
      case RecordType.ordonnance: return const Color(0xFFDC2626);
      case RecordType.analyse: case RecordType.laboratoire: return const Color(0xFF16A34A);
      case RecordType.vaccin: return const Color(0xFF9333EA);
      case RecordType.autre: return const Color(0xFF6B7280);
    }
  }
  Color get lightColor {
    switch(this){
      case RecordType.radiologie: return const Color(0xFFDBEAFE);
      case RecordType.ordonnance: return const Color(0xFFFEE2E2);
      case RecordType.analyse: case RecordType.laboratoire: return const Color(0xFFDCFCE7);
      case RecordType.vaccin: return const Color(0xFFF3E8FF);
      case RecordType.autre: return const Color(0xFFF3F4F6);
    }
  }
}

class HealthRecordModel {
  final String id;
  final String patientId;
  final String title;
  final RecordType type;
  final String? description;
  final String? fileName;
  final String? filePath;
  final int? fileSize;
  final String? mimeType;
  final DateTime examDate;
  final DateTime createdAt;
  final String? _doctorNameLegacy;

  HealthRecordModel({
    required this.id, required this.patientId, required this.title, required this.type,
    this.description, this.fileName, this.filePath, this.fileSize, this.mimeType,
    required this.examDate, required this.createdAt, String? doctorName,
  }) : _doctorNameLegacy = doctorName;

  String? get doctorName => _doctorNameLegacy?? description;
  bool get hasFile => filePath!= null && filePath!.isNotEmpty;
  bool get isPdf => mimeType == 'application/pdf' || (fileName?.endsWith('.pdf')??false);
  IconData get typeIcon => type.icon;
  Color get typeColor => type.color;
  Color get typeLightColor => type.lightColor;
  String get fileSizeLabel => fileSize==null? '' : fileSize! < 1048576? '${(fileSize!/1024).toStringAsFixed(1)} KB' : '${(fileSize!/1048576).toStringAsFixed(1)} MB';

  factory HealthRecordModel.fromJson(Map<String,dynamic> j){
    RecordType t;
    final raw = (j['type']??'autre').toString().toLowerCase();
    if(raw=='laboratoire'||raw=='labo') t=RecordType.laboratoire;
    else if(raw=='radiologie') t=RecordType.radiologie;
    else if(raw=='ordonnance') t=RecordType.ordonnance;
    else if(raw.contains('analys')) t=RecordType.analyse;
    else if(raw=='vaccin') t=RecordType.vaccin;
    else t=RecordType.autre;

    return HealthRecordModel(
      id: j['id'].toString(),
      patientId: (j['patient_id']??'').toString(),
      title: (j['title']??'Document').toString(),
      type: t,
      description: j['description']?.toString(),
      fileName: j['file_name']?.toString(),
      filePath: j['file_path']?.toString(),
      fileSize: j['file_size']!=null? int.tryParse(j['file_size'].toString()): null,
      mimeType: j['mime_type']?.toString(),
      examDate: j['exam_date']!=null? DateTime.tryParse(j['exam_date'].toString())??DateTime.now() : DateTime.now(),
      createdAt: j['created_at']!=null? DateTime.tryParse(j['created_at'].toString())??DateTime.now() : DateTime.now(),
      doctorName: j['doctor_name']?.toString(),
    );
  }
}
