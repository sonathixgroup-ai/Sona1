import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/services/user_service.dart';
import '../../theme.dart';
import '../widgets/dashboard_card.dart';
import '../utils/receipt_pdf_generator.dart'; // L'utilitaire de reçu

class PaymentsTab extends StatelessWidget {
  final String uid;
  final UserService userService;
  final AppUser user;

  const PaymentsTab({
    super.key,
    required this.uid,
    required this.userService,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    // Colle ici le contenu de l'ancien build() de _PaymentsTab
    // Utilise ReceiptPdfGenerator.build() au lieu de _ReceiptPdf.build()
    return const SizedBox();
  }
}
