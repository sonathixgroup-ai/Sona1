// lib/presentation/thix_reservation/bus/pages/agency/agency_onboarding_page.dart - FIX DEFINITIF
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgencyOnboardingPage extends StatefulWidget {
  const AgencyOnboardingPage({super.key});
  @override State<AgencyOnboardingPage> createState() => _AgencyOnboardingPageState();
}

class _AgencyOnboardingPageState extends State<AgencyOnboardingPage> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  String _country = 'RDC';
  bool _loading = false;
  String? _error;

  Future<void> _create() async {
    setState(() { _loading = true; _error = null; });
    try {
      final supa = Supabase.instance.client;
      final user = supa.auth.currentUser;
      if (user == null) throw 'Vous n etes pas connecte. Reconnectez-vous.';

      // On essaie 2 schemas possibles pour ne plus jamais bloquer
      Map<String, dynamic> payload1 = {
        'owner_id': user.id,
        'name': _name.text.trim(),
        'country': _country,
        'description': _desc.text.trim(),
        'status': 'pending',
      };

      try {
        final res = await supa.from('bus_agencies').insert(payload1).select().single();
        if (!mounted) return;
        context.go('/agency/dashboard');
        return;
      } on PostgrestException catch (e) {
        // Si colonne owner_id n'existe pas, on essaie avec user_id / thix_id
        if (e.message.contains('owner_id') || e.code == '42703') {
          final payload2 = {
            'user_id': user.id,
            'name': _name.text.trim(),
            'country': _country,
            'description': _desc.text.trim(),
            'status': 'pending',
          };
          final res2 = await supa.from('bus_agencies').insert(payload2).select().single();
          if (!mounted) return;
          context.go('/agency/dashboard');
          return;
        }
        rethrow;
      }
    } catch (e) {
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error!), backgroundColor: Colors.red, duration: const Duration(seconds: 6)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override Widget build(BuildContext context) {
    const kPrimary = Color(0xFF0B4FE3);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(title: const Text('Devenir Agence Partenaire', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))), backgroundColor: Colors.white, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> context.pop())),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Icon(Icons.directions_bus_rounded, size: 72, color: kPrimary),
        const SizedBox(height: 12),
        const Text('Creez votre agence sur THIX', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Votre THIX ID sera proprietaire.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 20),
        if (_error != null) Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)), child: Text(_error!, style: TextStyle(color: Colors.red.shade800, fontSize: 12))),
        if (_error != null) const SizedBox(height: 12),
        TextField(controller: _name, decoration: InputDecoration(labelText: "Nom de l'agence *", prefixIcon: const Icon(Icons.business), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white)),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(value: _country, decoration: InputDecoration(labelText: 'Pays', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white), items: const [DropdownMenuItem(value: 'RDC', child: Text('RDC')), DropdownMenuItem(value: 'CIV', child: Text('CIV')), DropdownMenuItem(value: 'Cameroun', child: Text('Cameroun')), DropdownMenuItem(value: 'Congo', child: Text('Congo'))], onChanged: (v)=> setState(()=> _country = v!)),
        const SizedBox(height: 14),
        TextField(controller: _desc, maxLines: 4, decoration: InputDecoration(hintText: 'Description / Politique', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white)),
        const SizedBox(height: 22),
        SizedBox(height: 52, child: ElevatedButton(onPressed: _loading? null : _create, style: ElevatedButton.styleFrom(backgroundColor: kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _loading? const CircularProgressIndicator(color: Colors.white) : const Text('Creer mon agence', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)))),
        const SizedBox(height: 10),
        const Center(child: Text('Statut initial: En attente de validation Super Admin', style: TextStyle(color: Colors.orange, fontSize: 11))),
      ]),
    );
  }
}
