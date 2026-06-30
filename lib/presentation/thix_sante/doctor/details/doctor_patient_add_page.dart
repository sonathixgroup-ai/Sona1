import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/supabase/supabase_config.dart';

/// Creates a patient record for the doctor.
///
/// Supabase table expected: `health_patients`.
/// Minimal columns used here: `id` (uuid), `doctor_id`, `first_name`, `last_name`, `phone`, `created_at`.
class DoctorPatientAddPage extends StatefulWidget {
  const DoctorPatientAddPage({super.key});

  @override
  State<DoctorPatientAddPage> createState() => _DoctorPatientAddPageState();
}

class _DoctorPatientAddPageState extends State<DoctorPatientAddPage> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final doctorId = AuthController.instance.currentUser?.id;
    if (doctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vous devez être connecté.')));
      return;
    }
    final first = _firstCtrl.text.trim();
    final last = _lastCtrl.text.trim();
    if (first.isEmpty || last.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nom et prénom requis.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await SupabaseConfig.client.from('health_patients').insert({
        'doctor_id': doctorId,
        'first_name': first,
        'last_name': last,
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      });
      if (!mounted) return;
      context.pop();
    } catch (e, st) {
      debugPrint('DoctorPatientAddPage save failed: $e');
      debugPrint(st.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la création du patient.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un patient'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/doctor/patients'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _firstCtrl, enabled: !_loading, decoration: const InputDecoration(labelText: 'Prénom')),
          const SizedBox(height: 12),
          TextField(controller: _lastCtrl, enabled: !_loading, decoration: const InputDecoration(labelText: 'Nom')),
          const SizedBox(height: 12),
          TextField(controller: _phoneCtrl, enabled: !_loading, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Téléphone (optionnel)')),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _save,
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}
