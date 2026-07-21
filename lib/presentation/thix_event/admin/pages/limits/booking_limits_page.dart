// lib/presentation/thix_event/admin/pages/limits/booking_limits_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_event_service.dart';
import '../../widgets/admin_app_bar.dart';
import '../../providers/admin_event_provider.dart';

class BookingLimitsPage extends StatefulWidget {
  const BookingLimitsPage({super.key});
  @override 
  State<BookingLimitsPage> createState() => _BookingLimitsPageState();
}

class _BookingLimitsPageState extends State<BookingLimitsPage> {
  String? _selectedEventId;
  final _maxPerPersonCtrl = TextEditingController(text: '4');
  final _maxPerTransCtrl = TextEditingController(text: '2');
  bool _requireId = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _maxPerPersonCtrl.dispose();
    _maxPerTransCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedEventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Veuillez sélectionner un événement ciblé.'), backgroundColor: Colors.orange)
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await context.read<AdminEventService>().upsertBookingLimit(_selectedEventId!, {
        'max_per_person': int.tryParse(_maxPerPersonCtrl.text) ?? 4,
        'max_per_transaction': int.tryParse(_maxPerTransCtrl.text) ?? 2,
        'require_id_verification': _requireId,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Limites et sécurité enregistrées avec succès', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Erreur : $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = context.watch<AdminEventProvider>().eventsState.items;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: const AdminAppBar(title: 'Anti-Fraude & Limites'),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20), 
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving 
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.security_rounded, size: 18),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0A1F44), 
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          label: Text(
            _isSaving ? 'ENREGISTREMENT...' : 'ENREGISTRER LES LIMITES', 
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)
          ),
        )
      ),
      body: ListView(
        padding: const EdgeInsets.all(16), 
        children: [
          // 🟢 SÉLECTION DE L'ÉVÉNEMENT
          const Text('Événement cible', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0A1F44))),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedEventId,
            decoration: _deco('Sélectionner un événement', Icons.event_rounded),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0A1F44)),
            items: events.map((e) => DropdownMenuItem(
              value: e.id, 
              child: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)
            )).toList(),
            onChanged: (v) => setState(() => _selectedEventId = v),
          ),
          const SizedBox(height: 24),

          // 🟢 CONFIGURATION DES LIMITES
          Container(
            padding: const EdgeInsets.all(20), 
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(16), 
              border: Border.all(color: const Color(0xFFE7EEFC)),
              boxShadow: [BoxShadow(color: const Color(0xFF0A1F44).withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.rule_rounded, color: Color(0xFF0A1F44), size: 18),
                    SizedBox(width: 8),
                    Text('Règles d\'achat', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0A1F44))),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _maxPerPersonCtrl, 
                  decoration: _deco('Maximum de billets par personne (Global)', Icons.person_outline_rounded), 
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0A1F44)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _maxPerTransCtrl, 
                  decoration: _deco('Maximum de billets par transaction (Panier)', Icons.shopping_cart_outlined), 
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0A1F44)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: Color(0xFFE7EEFC)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF0A1F44),
                  value: _requireId, 
                  onChanged: (v) => setState(() => _requireId = v), 
                  title: const Row(
                    children: [
                      Icon(Icons.badge_outlined, size: 18, color: Color(0xFF0A1F44)),
                      SizedBox(width: 8),
                      Text('Vérification THIX ID requise', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0A1F44))),
                    ],
                  ), 
                  subtitle: const Padding(
                    padding: EdgeInsets.only(left: 26, top: 4),
                    child: Text('Exige que l\'utilisateur ait un compte THIX vérifié. Recommandé pour les événements à très forte demande.', style: TextStyle(fontSize: 11, color: Color(0xFF7386A8), height: 1.4)),
                  )
                ),
            ]),
          ),
          const SizedBox(height: 24),

          // 🟢 INFO SCALABILITÉ
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF5FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD0E0FC)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF3B82F6)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Architecture Scalable', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1F44))),
                      SizedBox(height: 4),
                      Text(
                        'Ces limites sont appliquées via EventBookingLimitService.canUserBook() qui compte les réservations validées directement via SQL en temps réel, garantissant aucune surréservation même lors de pics de trafic (Race conditions).', 
                        style: TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.5)
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]
      ),
    );
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
    labelText: label, 
    labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF7386A8), fontWeight: FontWeight.w500),
    prefixIcon: Icon(icon, size: 18, color: const Color(0xFF7386A8)),
    filled: true, 
    fillColor: const Color(0xFFF7FAFF), 
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0A1F44), width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
