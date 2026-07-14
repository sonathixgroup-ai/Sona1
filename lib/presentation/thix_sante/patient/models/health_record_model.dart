// lib/presentation/thix_sante/patient/models/health_record_model.dart
import 'package:flutter/material.dart';

enum RecordType { radiologie, ordonnance, analyse, vaccin, autre }

extension RecordTypeX on RecordType {
  String get label {
    switch(this){
      case RecordType.radiologie: return 'Radiologie';
      case RecordType.ordonnance: return 'Ordonnance';
      case RecordType.analyse: return 'Analyse';
      case RecordType.vaccin: return 'Vaccin';
      case RecordType.autre: return 'Autre';
    }
  }
  IconData get icon {
    switch(this){
      case RecordType.radiologie: return Icons.medical_services_rounded;
      case RecordType.ordonnance: return Icons.receipt_long_rounded;
      case RecordType.analyse: return Icons.biotech_rounded;
      case RecordType.vaccin: return Icons.vaccines_rounded;
      case RecordType.autre: return Icons.folder_rounded;
    }
  }
  Color get color {
    switch(this){
      case RecordType.radiologie: return const Color(0xFF0B63F6);
      case RecordType.ordonnance: return const Color(0xFFDC2626);
      case RecordType.analyse: return const Color(0xFF16A34A);
      case RecordType.vaccin: return const Color(0xFF9333EA);
      case RecordType.autre: return const Color(0xFF6B7280);
    }
  }
  Color get lightColor {
    switch(this){
      case RecordType.radiologie: return const Color(0xFFDBEAFE);
      case RecordType.ordonnance: return const Color(0xFFFEE2E2);
      case RecordType.analyse: return const Color(0xFFDCFCE7);
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

  // Champs legacy pour compat avec anciennes pages
  final String? _doctorNameLegacy;
  final String? _lotLegacy;

  HealthRecordModel({
    required this.id,
    required this.patientId,
    required this.title,
    required this.type,
    this.description,
    this.fileName,
    this.filePath,
    this.fileSize,
    this.mimeType,
    required this.examDate,
    required this.createdAt,
    String? doctorName,
    String? lot,
  }) : _doctorNameLegacy = doctorName,
       _lotLegacy = lot;

  // ===== GETTERS COMPATIBILITE ANCIEN CODE =====
  String? get doctorName => _doctorNameLegacy?? description;
  String? get lot => _lotLegacy?? fileName;
  DateTime? get examDateNullable => examDate;
  bool get hasFile => filePath!= null && filePath!.isNotEmpty;
  bool get isPdf => mimeType == 'application/pdf' || (fileName?.endsWith('.pdf')??false);
  IconData get typeIcon => type.icon;
  Color get typeColor => type.color;
  Color get typeLightColor => type.lightColor;
  String get fileSizeLabel {
    if(fileSize==null) return '';
    if(fileSize! < 1024) return '$fileSize B';
    if(fileSize! < 1048576) return '${(fileSize!/1024).toStringAsFixed(1)} KB';
    return '${(fileSize!/1048576).toStringAsFixed(1)} MB';
  }

  factory HealthRecordModel.fromJson(Map<String,dynamic> j){
    RecordType t;
    final raw = (j['type']??'autre').toString().toLowerCase();
    switch(raw){
      case 'radiologie': t=RecordType.radiologie; break;
      case 'ordonnance': t=RecordType.ordonnance; break;
      case 'analyse': case 'analyse_medicale': t=RecordType.analyse; break;
      case 'vaccin': case 'vaccination': t=RecordType.vaccin; break;
      default: t=RecordType.autre;
    }
    return HealthRecordModel(
      id: j['id'].toString(),
      patientId: (j['patient_id']??j['user_id']??'').toString(),
      title: (j['title']??j['nom']??'Document').toString(),
      type: t,
      description: j['description']?.toString(),
      fileName: (j['file_name']??j['fileName']??j['lot'])?.toString(),
      filePath: (j['file_path']??j['filePath'])?.toString(),
      fileSize: j['file_size']!=null? int.tryParse(j['file_size'].toString()): (j['size']!=null? int.tryParse(j['size'].toString()): null),
      mimeType: j['mime_type']?.toString(),
      examDate: j['exam_date']!=null? DateTime.tryParse(j['exam_date'].toString())?? DateTime.now() : (j['date']!=null? DateTime.tryParse(j['date'].toString())??DateTime.now() : DateTime.now()),
      createdAt: j['created_at']!=null? DateTime.tryParse(j['created_at'].toString())??DateTime.now() : DateTime.now(),
      doctorName: (j['doctor_name']??j['doctorName']??j['medecin'])?.toString(),
      lot: j['lot']?.toString(),
    );
  }
}
