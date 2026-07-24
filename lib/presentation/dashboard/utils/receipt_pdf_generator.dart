import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:thix_id/models/app_user.dart';

class ReceiptPdfGenerator {
  static Future<Uint8List> build({required AppUser user, required Map<String, dynamic> tx}) async {
    final title = (tx['title'] as String?) ?? 'Transaction';
    final amount = tx['amount'];
    final currency = (tx['currency'] as String?) ?? 'USD';
    final method = (tx['method'] as String?) ?? '—';
    final status = (tx['status'] as String?) ?? 'paid';
    final created = tx['created_at'];
    final dt = created is DateTime ? created : (created is String ? DateTime.tryParse(created) : null);
    final dateStr = dt == null ? '—' : '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final amountStr = '${(amount is num ? amount.toStringAsFixed(2) : amount?.toString() ?? '0.00')} $currency';

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (_) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('THIX ID — Reçu', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 12),
                pw.Text('Utilisateur: ${user.displayName}'),
                pw.Text('THIX ID: ${user.thixId}'),
                pw.SizedBox(height: 12),
                pw.Text('Opération: $title', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Montant: $amountStr'),
                pw.Text('Méthode: $method'),
                pw.Text('Statut: $status'),
                pw.Text('Date: $dateStr'),
                pw.SizedBox(height: 18),
                pw.Text('Ce reçu est généré automatiquement (simulation).'),
              ],
            ),
          );
        },
      ),
    );
    return doc.save();
  }
}
