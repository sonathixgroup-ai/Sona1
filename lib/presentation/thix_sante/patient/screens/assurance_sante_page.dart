// lib/presentation/thix_sante/sante/screens/assurance_sante_page.dart
// =============================================================================
// Screen: AssuranceSantePage - Service Sante 10/11
// Source reelle: public.insurance_claims (patient_uid, amount, status, invoice_url)
// + public.profiles thix_id pour carte numerique QR
// + Storage bucket invoices pour upload facture remboursement
// Zero mock - insert/select/update reel RLS
// =============================================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/thix_id_validator.dart';

final insuranceClaimsProvider = FutureProvider<List<Map<String,dynamic>>>((ref) async {
  final db = Supabase.instance.client;
  final uid = db.auth.currentUser!.id;
  final List<dynamic> data = await db.from('insurance_claims').select().eq('patient_uid', uid).order('created_at', ascending: false);
  return data.map((e) => e as Map<String,dynamic>).toList();
});

final insuranceStatsProvider = FutureProvider<Map<String,dynamic>>((ref) async {
  final claims = await ref.watch(insuranceClaimsProvider.future);
  final int total = claims.length;
  final int pending = claims.where((c) => c['status']=='pending').length;
  final int approved = claims.where((c) => c['status']=='approved').length;
  final double totalAmount = claims.fold<double>(0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble()?? 0));
  final double reimbursed = claims.where((c)=>c['status']=='approved').fold<double>(0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble()?? 0));
  return {'total': total, 'pending': pending, 'approved': approved, 'totalAmount': totalAmount, 'reimbursed': reimbursed};
});

class AssuranceSantePage extends ConsumerWidget {
  const AssuranceSantePage({super.key});

  Future<void> _uploadInvoice(BuildContext context, WidgetRef ref) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf','jpg','png'], withData: true);
    if (result==null || result.files.first.bytes==null) return;
    final file = result.files.first;
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser!.id;

    try {
      final String path = '$uid/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      await db.storage.from('invoices').uploadBinary(path, file.bytes!);
      final String publicUrl = db.storage.from('invoices').getPublicUrl(path);

      await db.from('insurance_claims').insert({
        'patient_uid': uid,
        'amount': 0,
        'status': 'pending',
        'invoice_url': publicUrl,
        'file_name': file.name,
        'description': 'Facture en attente de traitement - upload via THIX ID',
        'created_at': DateTime.now().toIso8601String(),
      });

      ref.invalidate(insuranceClaimsProvider);
      ref.invalidate(insuranceStatsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Facture uploadee - insurance_claims + Storage invoices'), backgroundColor: ThixSanteColors.success));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur Storage invoices ou table insurance_claims manquante: $e'), backgroundColor: ThixSanteColors.danger));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimsAsync = ref.watch(insuranceClaimsProvider);
    final statsAsync = ref.watch(insuranceStatsProvider);

    return Scaffold(
      backgroundColor: ThixSanteColors.background,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: const Text('Assurance Sante', style: TextStyle(color: ThixSanteColors.ink, fontWeight: FontWeight.w800)), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: ThixSanteColors.ink), onPressed: () => Navigator.pop(context)), actions: [IconButton(icon: const Icon(Icons.qr_code_rounded, color: ThixSanteColors.primary), onPressed: () async {
        final db = Supabase.instance.client;
        final profile = await db.from('profiles').select('thix_id, full_name').eq('uid', db.auth.currentUser!.id).single();
        if (!context.mounted) return;
        _showInsuranceCard(context, profile['thix_id'] as String, profile['full_name'] as String);
      })]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          statsAsync.when(
            data: (s) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED)]), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FutureBuilder<Map<String,dynamic>>(future: Supabase.instance.client.from('profiles').select('thix_id').eq('uid', Supabase.instance.client.auth.currentUser!.id).single(), builder: (c,snap) => Text('THIX Assurance • ${snap.data?['thix_id']?? 'THIX ID'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, fontFamily: 'monospace'))), const Text('Plan Famille - Couverture liee THIX ID UID', style: TextStyle(color: Colors.white70, fontSize: 11))]))]),
              const SizedBox(height: 14),
              Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Rembourse', style: TextStyle(color: Colors.white70, fontSize: 11)), Text('${(s['reimbursed'] as double).toStringAsFixed(0)} FC', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))])), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Demandes', style: TextStyle(color: Colors.white70, fontSize: 11)), Text('${s['total']} • ${s['pending']} en cours', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))]))]),
            ])),
            loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Colors.white))),
            error: (e,_) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: ThixSanteColors.dangerLight, borderRadius: BorderRadius.circular(12)), child: Text('Erreur insurance_claims: $e - creez table', style: const TextStyle(fontSize: 11, color: ThixSanteColors.danger))),
          ),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: SizedBox(height: 44, child: ElevatedButton.icon(onPressed: () => _uploadInvoice(context, ref), icon: const Icon(Icons.upload_file_rounded, size: 18), label: const Text('Soumettre facture', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)), style: ElevatedButton.styleFrom(backgroundColor: ThixSanteColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))), const SizedBox(width: 10), Expanded(child: SizedBox(height: 44, child: OutlinedButton.icon(onPressed: () async {
            final db = Supabase.instance.client;
            final profile = await db.from('profiles').select('thix_id, full_name').eq('uid', db.auth.currentUser!.id).single();
            if (!context.mounted) return;
            _showInsuranceCard(context, profile['thix_id'] as String, profile['full_name'] as String);
          }, icon: const Icon(Icons.card_membership_rounded, size: 18), label: const Text('Carte QR', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)), style: OutlinedButton.styleFrom(foregroundColor: ThixSanteColors.primary, side: const BorderSide(color: ThixSanteColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))))]),
          const SizedBox(height: 16),
          const Text('Mes remboursements - Source insurance_claims reel', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 10),
          claimsAsync.when(
            data: (claims) => claims.isEmpty? Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Column(children: [Icon(Icons.receipt_long_outlined, size: 40, color: ThixSanteColors.mutedLight.withOpacity(0.5)), const SizedBox(height: 10), const Text('Aucune demande', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), const Text('Uploadez facture PDF/JPG - stockage Supabase Storage bucket invoices + table insurance_claims', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: ThixSanteColors.muted))])): Column(children: claims.map((c) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: ThixSanteColors.borderLight)), child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: c['status']=='approved'? ThixSanteColors.successLight: c['status']=='pending'? ThixSanteColors.warningLight: ThixSanteColors.dangerLight, borderRadius: BorderRadius.circular(10)), child: Icon(c['status']=='approved'? Icons.check_circle_rounded: c['status']=='pending'? Icons.hourglass_top_rounded: Icons.cancel_rounded, color: c['status']=='approved'? ThixSanteColors.success: c['status']=='pending'? ThixSanteColors.warning: ThixSanteColors.danger, size: 20)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c['file_name']?? 'Facture', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis), Text('${c['amount']?? 0} FC • ${c['status']} • ${DateTime.parse(c['created_at'] as String).toLocal().toString().substring(0,10)}', style: const TextStyle(fontSize: 11, color: ThixSanteColors.muted)), if (c['description']!=null) Text(c['description'] as String, style: const TextStyle(fontSize: 10, color: ThixSanteColors.mutedLight), maxLines: 1, overflow: TextOverflow.ellipsis)])),
              if (c['invoice_url']!=null) IconButton(icon: const Icon(Icons.visibility_rounded, size: 18, color: ThixSanteColors.primary), onPressed: () {}),
            ]))).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e,_) => Text('Erreur: $e'),
          ),
        ],
      ),
    );
  }

  void _showInsuranceCard(BuildContext context, String thixId, String fullName) {
    showDialog(context: context, builder: (ctx) => Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED)]), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.shield_rounded, color: Colors.white), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)), Text(thixId, style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 10))]))])), const SizedBox(height: 16), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: ThixSanteColors.border)), child: QrImageView(data: 'https://thix.id/insurance/verify/$thixId', size: 160)), const SizedBox(height: 10), const Text('Carte assurance verifiable QR - THIX ID UID', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: ThixSanteColors.muted))]))));
  }
}
