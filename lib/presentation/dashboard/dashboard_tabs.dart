import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../theme.dart';
import '../../nav.dart';
import 'dashboard_ui.dart';

class ProfileTab extends StatelessWidget {
  final dynamic authUser, profile; final int score; final dynamic profileService, userService;
  const ProfileTab({super.key, required this.authUser, required this.profile, required this.score, required this.profileService, required this.userService});
  @override Widget build(BuildContext context) {
    final isActivated = authUser.thixId.trim().toUpperCase() != 'THIX-PENDING';
    return TabScaffold(children: [
      if(!isActivated && !authUser.hasActiveTrial) ActivationCalloutCard(onActivate: (){ final r = Uri.encodeComponent(AppRoutes.activationReceipt); context.go('${AppRoutes.payment}?returnTo=$r'); }),
      DashboardCard(icon: Icons.badge, title: 'Profil Pro', subtitle: 'Données THIX ID', child: Column(children: [
        DashboardInfoRow(label: 'THIX ID', value: profile.thixId), DashboardInfoRow(label: 'Email', value: authUser.email), DashboardInfoRow(label: 'Tel', value: authUser.phone ?? '—'),
      ])),
    ]);
  }
}
class DocumentsTab extends StatelessWidget {
  final String uid; final dynamic docs, userService; final String filter; final ValueChanged<String> onChangeFilter;
  const DocumentsTab({super.key, required this.uid, required this.docs, required this.userService, required this.filter, required this.onChangeFilter});
  @override Widget build(BuildContext context) => TabScaffold(children: [
    DashboardCard(icon: Icons.folder_special, title: 'Documents', subtitle: 'Portefeuille', child: Column(children: [
      Wrap(spacing: 6, children: ['Tous','CIN','Passeport','Diplôme','Autre'].map((f) => ChoiceChip(label: Text(f, style: const TextStyle(fontSize:11)), selected: filter==f, onSelected: (_)=> onChangeFilter(f))).toList()),
      const SizedBox(height: 12),
      StreamBuilder<List<Map<String,dynamic>>>(stream: docs.streamDocuments(uid), builder: (c,s){ final all=s.data??[]; if(all.isEmpty) return const Text('Aucun doc', style: TextStyle(color: Colors.grey, fontSize:12)); return Column(children: all.take(8).map((d)=> DocRow(name: d['title']??'Doc', date: d['doc_id']??'—', status: d['status']??'pending', statusBg: Colors.orange.shade50, statusText: Colors.orange.shade800)).toList()); }),
      const SizedBox(height:12), ElevatedButton.icon(onPressed: ()=> context.push(AppRoutes.vault), icon: const Icon(Icons.upload, color: Color(0xFF123B7A)), label: const Text('Uploader (1 USD)', style: TextStyle(color: Color(0xFF123B7A))), style: ElevatedButton.styleFrom(backgroundColor: LightModeColors.accent)),
    ]))
  ]);
}
class ExperienceSkillsTab extends StatelessWidget { final dynamic profile, profileService; const ExperienceSkillsTab({super.key, required this.profile, required this.profileService}); @override Widget build(BuildContext context) => TabScaffold(children: [DashboardCard(icon: Icons.work_history, title: 'Expériences', subtitle: '${profile.experience.length}', child: Column(children: profile.experience.isEmpty ? [const Text('Aucune', style: TextStyle(color: Colors.grey, fontSize:12))] : profile.experience.map<Widget>((e)=> ListTile(dense:true, contentPadding: EdgeInsets.zero, title: Text(e['title']??'—', style: const TextStyle(fontWeight: FontWeight.bold, fontSize:13)), subtitle: Text('${e['org']??''}'))).toList()))]); }
class FormationsTab extends StatelessWidget { final dynamic user, userService; const FormationsTab({super.key, required this.user, required this.userService}); @override Widget build(BuildContext context) => TabScaffold(children: [DashboardCard(icon: Icons.school, title: 'Formations', subtitle: 'Suivi', child: Column(children: [if(user.enrollments.isEmpty) const Text('Aucune formation', style: TextStyle(color: Colors.grey, fontSize:12)) else ...user.enrollments.map((e)=> Container(margin: const EdgeInsets.only(bottom:8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF6F6F6), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e['title']??'Formation', style: const TextStyle(fontWeight: FontWeight.bold)), LinearProgressIndicator(value: ((e['progress']??0)/100).clamp(0.0,1.0))]))), ElevatedButton.icon(onPressed: ()=> context.push(AppRoutes.education), icon: const Icon(Icons.explore, color: Color(0xFF123B7A)), label: const Text('Parcourir', style: TextStyle(color: Color(0xFF123B7A))), style: ElevatedButton.styleFrom(backgroundColor: LightModeColors.accent))]))); }
class CvTab extends StatefulWidget { final dynamic user; const CvTab({super.key, required this.user}); @override State<CvTab> createState()=> _CvTabState(); }
class _CvTabState extends State<CvTab> { bool _exp=false; Future<Uint8List> _pdf() async { final d=pw.Document(); d.addPage(pw.MultiPage(build: (_)=> [pw.Text('THIX ID - ${widget.user.displayName}', style: pw.TextStyle(fontSize:18, fontWeight: pw.FontWeight.bold))])); return d.save(); } @override Widget build(BuildContext context) => TabScaffold(children: [DashboardCard(icon: Icons.description, title: 'CV', subtitle: 'Numérique', child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(12)), child: Text(widget.user.displayName, style: const TextStyle(fontWeight: FontWeight.w900))), const SizedBox(height:16), SizedBox(height:52, child: ElevatedButton.icon(onPressed: _exp?null:() async { setState(()=> _exp=true); try{ final b=await _pdf(); await Printing.layoutPdf(onLayout: (_)=> Future.value(b)); } finally{ if(mounted) setState(()=> _exp=false);} }, icon: const Icon(Icons.download, color: Color(0xFF123B7A)), label: const Text('Télécharger PDF', style: TextStyle(color: Color(0xFF123B7A), fontWeight: FontWeight.w900)), style: ElevatedButton.styleFrom(backgroundColor: LightModeColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)))))]))]); }
class PaymentsTab extends StatelessWidget { final String uid; final dynamic userService, user; const PaymentsTab({super.key, required this.uid, required this.userService, required this.user}); @override Widget build(BuildContext context) => TabScaffold(children: [DashboardCard(icon: Icons.payments, title: 'Paiements', subtitle: 'Historique', child: StreamBuilder<List<Map<String,dynamic>>>(stream: userService.streamPayments(uid), builder: (c,s){ final l=s.data??[]; if(l.isEmpty) return const Text('Aucune tx', style: TextStyle(color: Colors.grey, fontSize:12)); return Column(children: l.take(10).map((d)=> ListTile(dense:true, contentPadding: EdgeInsets.zero, title: Text(d['title']??'Tx', style: const TextStyle(fontSize:13, fontWeight: FontWeight.w700)), trailing: Text('${d['amount']??0} ${d['currency']??'USD}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize:12)))).toList()); }))]); }
class SecurityTab extends StatelessWidget { final String uid; final dynamic user, userService; const SecurityTab({super.key, required this.uid, required this.user, required this.userService}); @override Widget build(BuildContext context) => TabScaffold(children: [DashboardCard(icon: Icons.security, title: 'Sécurité', subtitle: 'Protection', child: Column(children: [SwitchListTile(value: user.biometricsEnabled??false, onChanged: (v)=> userService.updateProfile(uid: uid, biometricsEnabled: v), title: const Text('Biométrie', style: TextStyle(fontSize:13)), secondary: const Icon(Icons.fingerprint)), SwitchListTile(value: user.twoFaEnabled??false, onChanged: (v)=> userService.updateProfile(uid: uid, twoFaEnabled: v), title: const Text('2FA', style: TextStyle(fontSize:13)), secondary: const Icon(Icons.vpn_key))]))]); }
