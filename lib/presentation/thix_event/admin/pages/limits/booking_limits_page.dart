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

  Future<void> _save() async {
    if (_selectedEventId == null) return;
    setState(() => _isSaving = true);
    try {
      await context.read<AdminEventService>().upsertBookingLimit(_selectedEventId!, {
        'max_per_person': int.parse(_maxPerPersonCtrl.text),
        'max_per_transaction': int.parse(_maxPerTransCtrl.text),
        'require_id_verification': _requireId,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Limites enregistrées')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = context.watch<AdminEventProvider>().eventsState.items;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: const AdminAppBar(title: 'Anti-Fraude • Limites'),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16), 
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A1F44), padding: const EdgeInsets.symmetric(vertical: 14)),
          child: _isSaving 
            ? const CircularProgressIndicator(color: Colors.white) 
            : const Text('ENREGISTRER LIMITES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        )
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<String>(
          value: _selectedEventId,
          decoration: _deco('Événement cible'),
          items: events.map((e) => DropdownMenuItem(
            value: e.id, 
            child: Text(e.title, overflow: TextOverflow.ellipsis)
          )).toList(),
          onChanged: (v) => setState(() => _selectedEventId = v),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14), 
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EEFC))), 
          child: Column(children: [
            TextFormField(controller: _maxPerPersonCtrl, decoration: _deco('Max par personne'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextFormField(controller: _maxPerTransCtrl, decoration: _deco('Max par transaction'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _requireId, 
              onChanged: (v) => setState(() => _requireId = v), 
              title: const Text('Vérification ID requise', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), 
              subtitle: const Text('Pour concerts à forte demande', style: TextStyle(fontSize: 11))
            ),
        ])),
        const SizedBox(height: 16),
        const Text('Logique scalable: EventBookingLimitService.canUserBook() est appelé AVANT chaque réservation. Il compte déjà les bookings confirmés en SQL, pas en mémoire.', style: TextStyle(fontSize: 11, color: Color(0xFF7386A8))),
      ]),
    );
  }

  InputDecoration _deco(String l) => InputDecoration(
    labelText: l, 
    filled: true, 
    fillColor: Colors.white, 
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE7EEFC)))
  );
}
