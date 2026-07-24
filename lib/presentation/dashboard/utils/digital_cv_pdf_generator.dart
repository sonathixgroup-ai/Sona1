import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:thix_id/models/app_user.dart';

class DigitalCvPdfGenerator {
  static Future<Uint8List> build(AppUser u) async {
    final doc = pw.Document();
    final theme = pw.ThemeData.withFont();
    
    doc.addPage(
      pw.MultiPage(
        theme: theme,
        build: (_) {
          return [
            pw.Text('THIX ID — CV Numérique', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text(u.displayName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text(u.thixId, style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 8),
            pw.Text([u.occupation, u.countryOrOrigin].where((v) => (v ?? '').trim().isNotEmpty).map((v) => v!.trim()).join(' • ')),
            pw.SizedBox(height: 10),
            pw.Text('Bio', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text((u.bio ?? '').trim().isEmpty ? '—' : u.bio!.trim()),
            pw.SizedBox(height: 12),
            pw.Text('Expériences', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            if (u.experience.isEmpty) pw.Text('—') else ...u.experience.map((e) {
              final title = (e['title'] as String?) ?? '';
              final org = (e['org'] as String?) ?? (e['company'] as String?) ?? '';
              final date = (e['date'] as String?) ?? (e['period'] as String?) ?? '';
              final tasks = (e['tasks'] as String?) ?? (e['missions'] as String?) ?? '';
              final line = [title, org, date].where((v) => v.trim().isNotEmpty).join(' • ');
              final detail = tasks.trim().isEmpty ? '' : ' — ${_truncate(tasks, 140)}';
              return pw.Bullet(text: (line + detail).trim().isEmpty ? '—' : (line + detail));
            }).toList(growable: false),
            pw.SizedBox(height: 12),
            pw.Text('Formations', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            if (u.education.isEmpty) pw.Text('—') else ...u.education.map((e) {
              final inst = (e['institution'] as String?) ?? '';
              final degree = (e['degree'] as String?) ?? '';
              final period = (e['period'] as String?) ?? '';
              final line = [inst, degree, period].where((v) => v.trim().isNotEmpty).join(' • ');
              return pw.Bullet(text: line.trim().isEmpty ? '—' : line);
            }).toList(growable: false),
            pw.SizedBox(height: 12),
            pw.Text('Compétences', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            if (u.skills.isEmpty) pw.Text('—') else ...u.skills.map((s) {
              final n = (s['name'] as String?) ?? '';
              final l = (s['level'] as String?) ?? '';
              final details = (s['details'] as String?) ?? '';
              final line = [n, l].where((v) => v.trim().isNotEmpty).join(' — ');
              final detail = details.trim().isEmpty ? '' : ' (${_truncate(details, 110)})';
              return pw.Bullet(text: (line + detail).trim().isEmpty ? '—' : (line + detail));
            }).toList(growable: false),
            pw.SizedBox(height: 12),
            pw.Text('Langues', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text(u.languages.isEmpty ? '—' : u.languages.join(' • ')),
          ];
        },
      ),
    );
    return doc.save();
  }

  static String _truncate(String v, int max) {
    final s = v.trim();
    if (s.length <= max) return s;
    return '${s.substring(0, max).trim()}…';
  }
}
