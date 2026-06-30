import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class DoctorTeleconsultationCreatePage extends StatefulWidget {
  final String? patientId;
  const DoctorTeleconsultationCreatePage({super.key, this.patientId});

  @override
  State<DoctorTeleconsultationCreatePage> createState() => _DoctorTeleconsultationCreatePageState();
}

class _DoctorTeleconsultationCreatePageState extends State<DoctorTeleconsultationCreatePage> {
  final _patientIdCtrl = TextEditingController();
  final _patientNameCtrl = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _patientIdCtrl.text = widget.patientId ?? '';
  }

  @override
  void dispose() {
    _patientIdCtrl.dispose();
    _patientNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final doctorId = AuthController.instance.currentUser?.id;
    if (doctorId == null) return;
    final pid = _patientIdCtrl.text.trim();
    if (pid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('patient_id requis.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await HealthService.instance.createAppointment(
        Appointment(
          id: '',
          doctorId: doctorId,
          doctorName: AuthController.instance.currentUser?.displayName ?? 'Médecin',
          patientId: pid,
          patientName: _patientNameCtrl.text.trim().isEmpty ? null : _patientNameCtrl.text.trim(),
          date: _date,
          type: AppointmentType.teleconsultation,
          status: AppointmentStatus.scheduled,
        ),
      );
      if (!mounted) return;
      context.pop();
    } catch (e, st) {
      debugPrint('DoctorTeleconsultationCreatePage save failed: $e');
      debugPrint(st.toString());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur création téléconsultation.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une téléconsultation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/doctor/dashboard'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _patientIdCtrl, enabled: !_loading, decoration: const InputDecoration(labelText: 'patient_id')),
          const SizedBox(height: 12),
          TextField(controller: _patientNameCtrl, enabled: !_loading, decoration: const InputDecoration(labelText: 'Nom patient (optionnel)')),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: _loading
                ? null
                : () async {
                    final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)), initialDate: _date);
                    if (d == null) return;
                    if (!mounted) return;
                    setState(() => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
                  },
          ),
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
