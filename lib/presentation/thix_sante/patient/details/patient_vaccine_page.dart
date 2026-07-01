// presentation/thix_sante/patient/details/patient_vaccine_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class PatientVaccinePage extends StatefulWidget {
  final String? vaccineId;
  final bool isEditing;

  const PatientVaccinePage({
    super.key,
    this.vaccineId,
    this.isEditing = false,
  });

  @override
  State<PatientVaccinePage> createState() =>
      _PatientVaccinePageState();
}

class _PatientVaccinePageState
    extends State<PatientVaccinePage> {
  final HealthService _healthService =
      HealthService.instance;

  final SupabaseClient _supabase =
      SupabaseConfig.client;

  final _nameController =
      TextEditingController();

  final _batchController =
      TextEditingController();

  final _administeredByController =
      TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  String? _error;

  Vaccine? _vaccine;

  DateTime _administeredDate =
      DateTime.now();

  DateTime? _boosterDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _batchController.dispose();
    _administeredByController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.vaccineId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await _supabase
          .from('health_vaccines')
          .select('*')
          .eq('id', widget.vaccineId!)
          .maybeSingle();

      if (response == null) {
        throw Exception(
          'Vaccin introuvable',
        );
      }

      final data =
          response as Map<String, dynamic>;

      final vaccine = Vaccine(
        id: data['id'] as String,
        patientId:
            data['patient_id'] as String,
        name: data['name'] as String,
        dateAdministered:
            DateTime.parse(
          data['date_administered']
              as String,
        ),
        boosterDate:
            data['booster_date'] != null
                ? DateTime.parse(
                    data['booster_date']
                        as String,
                  )
                : null,
        batchNumber:
            data['batch_number']
                as String?,
        administeredBy:
            data['administered_by']
                as String?,
      );

      setState(() {
        _vaccine = vaccine;

        _nameController.text =
            vaccine.name;

        _administeredDate =
            vaccine.dateAdministered;

        _boosterDate =
            vaccine.boosterDate;

        _batchController.text =
            vaccine.batchNumber ?? '';

        _administeredByController
                .text =
            vaccine.administeredBy ??
                '';

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    final name =
        _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez entrer le nom du vaccin.',
          ),
          backgroundColor:
              Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user =
          AuthController
              .instance
              .currentUser;

      if (user == null) {
        throw Exception(
          'Utilisateur non connecté',
        );
      }

      final payload = {
        'patient_id': user.id,
        'name': name,
        'date_administered':
            _administeredDate
                .toIso8601String(),
        'booster_date':
            _boosterDate
                ?.toIso8601String(),
        'batch_number':
            _batchController
                    .text
                    .trim()
                    .isNotEmpty
                ? _batchController.text
                    .trim()
                : null,
        'administered_by':
            _administeredByController
                    .text
                    .trim()
                    .isNotEmpty
                ? _administeredByController
                    .text
                    .trim()
                : null,
      };

      if (widget.vaccineId == null) {
        final created =
            await _healthService
                .addVaccine(
          Vaccine(
            id: '',
            patientId: user.id,
            name: name,
            dateAdministered:
                _administeredDate,
            boosterDate:
                _boosterDate,
            batchNumber:
                _batchController
                        .text
                        .trim()
                        .isNotEmpty
                    ? _batchController.text
                        .trim()
                    : null,
            administeredBy:
                _administeredByController
                        .text
                        .trim()
                        .isNotEmpty
                    ? _administeredByController
                        .text
                        .trim()
                    : null,
          ),
        );

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Vaccin ajouté avec succès.',
            ),
            backgroundColor:
                Colors.green,
          ),
        );

        if (!mounted) return;

        context.push(
          '/sante/patient/vaccine/${created.id}',
        );
      } else {
        await _supabase
            .from('health_vaccines')
            .update(payload)
            .eq('id', widget.vaccineId!);

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Vaccin mis à jour.',
            ),
            backgroundColor:
                Colors.green,
          ),
        );

        if (!mounted) return;

        context.pop(true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Erreur : $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    if (widget.vaccineId == null) {
      return;
    }

    try {
      await _supabase
          .from('health_vaccines')
          .delete()
          .eq('id', widget.vaccineId!);

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Vaccin supprimé.',
          ),
          backgroundColor:
              Colors.orange,
        ),
      );

      if (!mounted) return;

      context.pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Erreur : $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew =
        widget.vaccineId == null;

    final title = isNew
        ? 'Ajouter un vaccin'
        : widget.isEditing
            ? 'Modifier le vaccin'
            : 'Détail du vaccin';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Text(
                    'Erreur : $_error',
                  ),
                )
              : SingleChildScrollView(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller:
                            _nameController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Nom du vaccin',
                          border:
                              OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.vaccines,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // ✅ CORRECTION ICI
                      TextField(
                        controller:
                            _batchController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Numéro de lot',
                          border:
                              OutlineInputBorder(),

                          prefixIcon: Icon(
                            Icons.qr_code,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      TextField(
                        controller:
                            _administeredByController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Administré par',
                          border:
                              OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.person,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : _save,
                        style:
                            ElevatedButton.styleFrom(
                          minimumSize:
                              const Size(
                            double.infinity,
                            48,
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator()
                            : Text(
                                isNew
                                    ? 'Ajouter'
                                    : 'Enregistrer',
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
