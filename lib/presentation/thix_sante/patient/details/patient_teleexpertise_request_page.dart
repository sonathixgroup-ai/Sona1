import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientTeleexpertiseRequestPage extends StatefulWidget {
  const PatientTeleexpertiseRequestPage({super.key});

  @override
  State<PatientTeleexpertiseRequestPage> createState() => _PatientTeleexpertiseRequestPageState();
}

class _PatientTeleexpertiseRequestPageState extends State<PatientTeleexpertiseRequestPage> {
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final patientId = AuthController.instance.currentUser?.id;
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vous devez être connecté.')));
      return;
    }
    final subject = _subjectCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajoute un sujet.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final id = await HealthService.instance.createTeleexpertiseRequest(patientId: patientId, subject: subject, description: desc.isEmpty ? null : desc);
      if (!mounted) return;
      context.go('/sante/patient/teleexpertise/${Uri.encodeComponent(id)}');
    } catch (e, st) {
      debugPrint('PatientTeleexpertiseRequestPage submit failed: $e');
      debugPrint(st.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la création de la demande.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle téléexpertise'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/patient/dashboard'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _subjectCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Sujet', hintText: 'Ex: Avis dermatologie pour éruption cutanée'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(labelText: 'Description (optionnel)', hintText: 'Symptômes, historique, traitements déjà essayés…'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
