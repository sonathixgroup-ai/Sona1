import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientRecordAddPage extends StatefulWidget {
  const PatientRecordAddPage({super.key});

  @override
  State<PatientRecordAddPage> createState() => _PatientRecordAddPageState();
}

class _PatientRecordAddPageState extends State<PatientRecordAddPage> {
  VitalType _type = VitalType.weight;
  final _valueCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: 'kg');
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  void dispose() {
    _valueCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDate: _date,
    );
    if (d == null) return;
    if (!mounted) return;
    setState(() => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
  }

  Future<void> _save() async {
    final patientId = AuthController.instance.currentUser?.id;
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vous devez être connecté.')));
      return;
    }

    final value = double.tryParse(_valueCtrl.text.trim().replaceAll(',', '.'));
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valeur invalide.')));
      return;
    }

    setState(() => _loading = true);
    try {
      await HealthService.instance.addVitalSign(
        VitalSign(id: '', patientId: patientId, type: _type, value: value, unit: _unitCtrl.text.trim(), date: _date),
      );
      if (!mounted) return;
      context.pop();
    } catch (e, st) {
      debugPrint('PatientRecordAddPage save failed: $e');
      debugPrint(st.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'enregistrement.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une mesure'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/patient/vitals/chart'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<VitalType>(
            value: _type,
            items: VitalType.values
                .map((t) => DropdownMenuItem(value: t, child: Text(_label(t))))
                .toList(),
            onChanged: _loading ? null : (v) => setState(() => _type = v ?? _type),
            decoration: const InputDecoration(labelText: 'Type'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _valueCtrl,
                  enabled: !_loading,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Valeur'),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _unitCtrl,
                  enabled: !_loading,
                  decoration: const InputDecoration(labelText: 'Unité'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: _loading ? null : _pickDate,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _save,
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  String _label(VitalType t) {
    switch (t) {
      case VitalType.weight:
        return 'Poids';
      case VitalType.bloodPressure:
        return 'Tension artérielle';
      case VitalType.heartRate:
        return 'Fréquence cardiaque';
      case VitalType.temperature:
        return 'Température';
      case VitalType.glucose:
        return 'Glycémie';
    }
  }
}
