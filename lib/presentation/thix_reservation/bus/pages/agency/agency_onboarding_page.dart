// lib/presentation/thix_reservation/bus/pages/agency/agency_onboarding_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/agency_dashboard_provider.dart';

class AgencyOnboardingPage extends StatefulWidget {
  const AgencyOnboardingPage({super.key});
  @override
  State<AgencyOnboardingPage> createState() => _AgencyOnboardingPageState();
}

class _AgencyOnboardingPageState extends State<AgencyOnboardingPage> {
  final _nameC = TextEditingController();
  final _descC = TextEditingController();
  String _country = 'CD';

  @override
  void dispose() { _nameC.dispose(); _descC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AgencyDashboardProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Devenir Agence Partenaire')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.directions_bus_filled, size: 64, color: Color(0xFF0D47A1)),
        const SizedBox(height: 12),
        const Text('Créez votre agence sur THIX', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Votre THIX ID sera propriétaire. Vous recevrez vos réservations et paiements directement.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 24),
        TextField(controller: _nameC, decoration: InputDecoration(labelText: 'Nom de l\'agence *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.business))),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: _country, decoration: InputDecoration(labelText: 'Pays', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), items: const [DropdownMenuItem(value: 'CD', child: Text('RDC')), DropdownMenuItem(value: 'CI', child: Text('Côte d\'Ivoire')), DropdownMenuItem(value: 'CM', child: Text('Cameroun')), DropdownMenuItem(value: 'SN', child: Text('Sénégal'))], onChanged: (v)=> setState(()=> _country=v!)),
        const SizedBox(height: 12),
        TextField(controller: _descC, maxLines: 3, decoration: InputDecoration(labelText: 'Description / Politique', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 24),
        SizedBox(height: 52, child: ElevatedButton(onPressed: provider.isCreating? null: () async { if(_nameC.text.trim().isEmpty){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nom requis'))); return; } final ok = await provider.createMyAgency(name: _nameC.text.trim(), countryCode: _country, description: _descC.text.trim()); if(ok && context.mounted){ context.go('/thix-reservation/bus/agency/dashboard'); } }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: provider.isCreating? const CircularProgressIndicator(color: Colors.white): const Text('Créer mon agence', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
        const SizedBox(height: 12),
        Text('Statut initial: En attente de validation Super Admin', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.orange.shade700)),
      ])),
    );
  }
}
