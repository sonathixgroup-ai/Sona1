// presentation/thix_sante/patient/details/patient_teleexpertise_request_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientTeleexpertiseRequestPage extends StatefulWidget {
  const PatientTeleexpertiseRequestPage({super.key});

  @override
  State<PatientTeleexpertiseRequestPage> createState() =>
      _PatientTeleexpertiseRequestPageState();
}

class _PatientTeleexpertiseRequestPageState
    extends State<PatientTeleexpertiseRequestPage> {
  final HealthService _healthService = HealthService.instance;
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _specialtyController = TextEditingController();

  bool _isSubmitting = false;
  String? _error;

  // Liste des spécialités suggérées
  final List<String> _specialties = [
    'Cardiologue',
    'Dermatologue',
    'Gynécologue',
    'Neurologue',
    'Ophtalmologue',
    'Pédiatre',
    'Psychiatre',
    'Radiologue',
    'Rhumatologue',
    'Urologue',
    'Autre',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final patientId = user.id;
      final subject =
          '${_specialtyController.text.trim()} - ${_subjectController.text.trim()}';

      final requestId = await _healthService.createTeleexpertiseRequest(
        patientId: patientId,
        subject: subject,
        description: _descriptionController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande de téléexpertise envoyée avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      // Rediriger vers la liste des demandes (ou le détail de celle-ci)
      context.go('/sante/patient/teleexpertise/$requestId');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demande de téléexpertise'),
        backgroundColor: const Color(0xFF2563FF),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icône et description
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.medical_services,
                          size: 28,
                          color: Color(0xFF2563FF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Demander un avis médical',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Un spécialiste vous répondra dans les plus brefs délais.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Spécialité (autocomplete)
                  DropdownButtonFormField<String>(
                    value: _specialtyController.text.isNotEmpty
                        ? _specialtyController.text
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Spécialité *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.medical_information),
                    ),
                    items: _specialties.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _specialtyController.text = value ?? '';
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez choisir une spécialité';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Sujet
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Sujet de la demande *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez indiquer le sujet';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description détaillée',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez décrire votre demande';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Message d'erreur
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Bouton de soumission
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563FF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Envoyer la demande'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Annuler'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
