// ============================================================
// FICHIER 22 : admin/admin_government_form_page.dart
// ============================================================
// lib/presentation/mon_pays/admin/admin_government_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/province_government.dart';
import '../models/province_minister.dart';
import '../providers/provinces_provider.dart';

class AdminGovernmentFormPage extends ConsumerStatefulWidget {
  final String provinceId;
  const AdminGovernmentFormPage({required this.provinceId, super.key});

  @override
  ConsumerState<AdminGovernmentFormPage> createState() => _AdminGovernmentFormPageState();
}

class _AdminGovernmentFormPageState extends ConsumerState<AdminGovernmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _governorIdController;
  late TextEditingController _viceGovernorIdController;
  final List<ProvinceMinister> _ministers = [];
  final List<TextEditingController> _ministerPortfolios = [];
  final List<TextEditingController> _ministerAuthorityIds = [];

  @override
  void initState() {
    super.initState();
    _governorIdController = TextEditingController();
    _viceGovernorIdController = TextEditingController();
    // Charger le gouvernement existant
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGovernment();
    });
  }

  Future<void> _loadGovernment() async {
    final service = ref.read(provincesServiceProvider);
    final gov = await service.getGovernment(widget.provinceId);
    if (gov != null && mounted) {
      setState(() {
        _governorIdController.text = gov.governorId ?? '';
        _viceGovernorIdController.text = gov.viceGovernorId ?? '';
        _ministers.clear();
        _ministers.addAll(gov.ministers);
        _ministerPortfolios.clear();
        _ministerAuthorityIds.clear();
        for (var m in gov.ministers) {
          _ministerPortfolios.add(TextEditingController(text: m.portfolio));
          _ministerAuthorityIds.add(TextEditingController(text: m.authorityId ?? ''));
        }
      });
    }
  }

  @override
  void dispose() {
    _governorIdController.dispose();
    _viceGovernorIdController.dispose();
    for (var c in _ministerPortfolios) c.dispose();
    for (var c in _ministerAuthorityIds) c.dispose();
    super.dispose();
  }

  void _addMinister() {
    setState(() {
      _ministerPortfolios.add(TextEditingController());
      _ministerAuthorityIds.add(TextEditingController());
    });
  }

  void _removeMinister(int index) {
    setState(() {
      _ministerPortfolios[index].dispose();
      _ministerAuthorityIds[index].dispose();
      _ministerPortfolios.removeAt(index);
      _ministerAuthorityIds.removeAt(index);
      if (index < _ministers.length) {
        _ministers.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gouvernement provincial'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gouverneur', style: TextStyle(fontWeight: FontWeight.bold)),
                TextFormField(
                  controller: _governorIdController,
                  decoration: const InputDecoration(
                    labelText: 'ID du gouverneur (référence authorities)',
                    hintText: 'UUID de l\'autorité',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Vice-gouverneur', style: TextStyle(fontWeight: FontWeight.bold)),
                TextFormField(
                  controller: _viceGovernorIdController,
                  decoration: const InputDecoration(
                    labelText: 'ID du vice-gouverneur (référence authorities)',
                    hintText: 'UUID de l\'autorité',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ministres provinciaux', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: _addMinister,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un ministre'),
                    ),
                  ],
                ),
                ..._ministerPortfolios.asMap().entries.map((entry) {
                  final index = entry.key;
                  final portfolioCtrl = entry.value;
                  final authorityCtrl = _ministerAuthorityIds[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: portfolioCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Portfolio (ex: Santé)',
                                  ),
                                ),
                                TextFormField(
                                  controller: authorityCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'ID du ministre (référence authorities)',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeMinister(index),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Enregistrer le gouvernement'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Récupérer les ministres existants + nouveaux
    final existingMinisters = List<ProvinceMinister>.from(_ministers);
    final newMinisters = <ProvinceMinister>[];

    for (int i = 0; i < _ministerPortfolios.length; i++) {
      final portfolio = _ministerPortfolios[i].text.trim();
      final authorityId = _ministerAuthorityIds[i].text.trim();
      if (portfolio.isNotEmpty) {
        if (i < existingMinisters.length) {
          // Mettre à jour existant
          existingMinisters[i] = ProvinceMinister(
            id: existingMinisters[i].id,
            governmentId: existingMinisters[i].governmentId,
            authorityId: authorityId.isEmpty ? null : authorityId,
            portfolio: portfolio,
          );
        } else {
          // Nouveau ministre
          newMinisters.add(ProvinceMinister(
            id: '',
            governmentId: '',
            authorityId: authorityId.isEmpty ? null : authorityId,
            portfolio: portfolio,
          ));
        }
      }
    }

    // Créer/mettre à jour le gouvernement
    final service = ref.read(provincesServiceProvider);
    final existingGov = await service.getGovernment(widget.provinceId);

    try {
      if (existingGov == null) {
        // Créer nouveau gouvernement
        final newGov = ProvinceGovernment(
          id: '',
          provinceId: widget.provinceId,
          governorId: _governorIdController.text.trim().isEmpty ? null : _governorIdController.text.trim(),
          viceGovernorId: _viceGovernorIdController.text.trim().isEmpty ? null : _viceGovernorIdController.text.trim(),
          ministers: newMinisters,
        );
        await service.createGovernment(newGov);
      } else {
        // Mettre à jour existant
        final updatedGov = ProvinceGovernment(
          id: existingGov.id,
          provinceId: widget.provinceId,
          governorId: _governorIdController.text.trim().isEmpty ? null : _governorIdController.text.trim(),
          viceGovernorId: _viceGovernorIdController.text.trim().isEmpty ? null : _viceGovernorIdController.text.trim(),
          ministers: existingMinisters,
        );
        await service.updateGovernment(updatedGov);
        // Ajouter les nouveaux ministres
        for (var m in newMinisters) {
          await service.addMinister(m);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gouvernement enregistré avec succès'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
