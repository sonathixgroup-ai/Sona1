import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:thix_id/models/app_user.dart';
import '../../theme.dart';
import '../widgets/dashboard_card.dart';
import '../utils/digital_cv_pdf_generator.dart'; // L'utilitaire qu'on a créé !

class CvTab extends StatefulWidget {
  final AppUser user;
  const CvTab({super.key, required this.user}); 

  @override
  State<CvTab> createState() => _CvTabState();
}

class _CvTabState extends State<CvTab> {
  bool _exporting = false;

  String _truncate(String v, int max) {
    final s = v.trim();
    if (s.length <= max) return s;
    return '${s.substring(0, max).trim()}…';
  }

  @override
  Widget build(BuildContext context) {
    // Colle ici le contenu de l'ancien build() de _CvTabState
    // Attention: à l'endroit où tu appelais _DigitalCvPdf.build(user), 
    // tu utiliseras maintenant DigitalCvPdfGenerator.build(user)
    return const SizedBox(); 
  }
}
