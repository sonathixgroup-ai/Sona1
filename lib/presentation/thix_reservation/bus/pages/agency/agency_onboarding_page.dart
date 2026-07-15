// lib/presentation/thix_reservation/bus/pages/agency/agency_onboarding_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgencyOnboardingPage extends StatefulWidget {
  const AgencyOnboardingPage({super.key});
  @override State<AgencyOnboardingPage> createState() => _AgencyOnboardingPageState();
}

class _AgencyOnboardingPageState extends State<AgencyOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'THIX TRANS');
  final _descCtrl = TextEditingController();
  String _country = 'RDC';
  bool _loading = false;

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw 'Non connecte';

      // Insert PROPRE avec tous les champs requis
      final res = await Supabase.instance.client.from('bus_agencies').insert({
        'owner_id': user.id,
        'name': _nameCtrl.text.trim(),
        'country': _country,
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'status': 'pending',
      }).select().single();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agence creee avec succes!'), backgroundColor: Color(0xFF0A3D91)));
      context.go('/agency/dashboard', extra: res);
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur Supabase: ${e.message}'), backgroundColor: Colors.red));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override Widget build(BuildContext context) {
    const kPrimary = Color(0xFF0A3D91);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(title: const Text('Devenir Agence Partenaire', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800)), backgroundColor: Colors.white, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)), onPressed: () => context.pop())),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const SizedBox(height: 10),
          const Icon(Icons.directions_bus_rounded, size: 80, color: kPrimary),
          const SizedBox(height: 16),
          const Text('Creez votre agence sur THIX', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          const Text('Votre THIX ID sera proprietaire. Vous recevrez vos reservations et paiements directement.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          const SizedBox(height: 28),
          TextFormField(controller: _nameCtrl, validator: (v) => v==null||v.trim().isEmpty? 'Nom requis': null, decoration: InputDecoration(labelText: "Nom de l'agence *", prefixIcon: const Icon(Icons.business_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(value: _country, decoration: InputDecoration(labelText: 'Pays', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white), items: const [DropdownMenuItem(value: 'RDC', child: Text('RDC')), DropdownMenuItem(value: 'Congo', child: Text('Congo')), DropdownMenuItem(value: 'CIV', child: Text('Cote d Ivoire')), DropdownMenuItem(value: 'Cameroun', child: Text('Cameroun'))], onChanged: (v)=> setState(()=> _country=v!)),
          const SizedBox(height: 16),
          TextFormField(controller: _descCtrl, maxLines: 4, decoration: InputDecoration(labelText: 'Description / Politique', alignLabelWithHint: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white)),
          const SizedBox(height: 24),
          SizedBox(height: 52, child: ElevatedButton(onPressed: _loading? null: _create, style: ElevatedButton.styleFrom(backgroundColor: kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: _loading? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)): const Text('Creer mon agence', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)))),
          const SizedBox(height: 12),
          const Center(child: Text('Statut initial: En attente de validation Super Admin', style: TextStyle(color: Color(0xFFEA9D2A), fontSize: 12, fontWeight: FontWeight.w600))),
        ]),
      ),
    );
  }
}
