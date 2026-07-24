// ============================================================
// FICHIER 22 : admin/admin_government_form_page.dart
// ============================================================
// lib/presentation/mon_pays/admin/admin_government_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/province.dart';
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
  
  // Champs de la tête de l'exécutif
  late TextEditingController _governorIdController;
  late TextEditingController _viceGovernorIdController;
  late TextEditingController _cabinetChiefIdController;
  late TextEditingController _mandateController;
  late TextEditingController _inaugurationDateController;
  late TextEditingController _programController;

  // Sélection de la province (pour basculer ou classer facilement)
  String? _selectedProvinceId;

  // Listes dynamiques des ministres
  final List<ProvinceMinister> _ministers = [];
  final List<TextEditingController> _ministerPortfolios = [];
  final List<TextEditingController> _ministerAuthorityIds = [];
  final List<TextEditingController> _ministerNames = [];
  final List<TextEditingController> _ministerBios = [];

  bool _isBusy = false;
  bool _isLoadingData = true;

  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color redThix = Color(0xFFD32F2F);
  static const Color lightBg = Color(0xFFF6F7FB);
  static const Color hairline = Color(0xFFE7EAF3);

  @override
  void initState() {
    super.initState();
    _selectedProvinceId = widget.provinceId;
    _governorIdController = TextEditingController();
    _viceGovernorIdController = TextEditingController();
    _cabinetChiefIdController = TextEditingController();
    _mandateController = TextEditingController();
    _inaugurationDateController = TextEditingController();
    _programController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGovernment(_selectedProvinceId!);
    });
  }

  Future<void> _loadGovernment(String provId) async {
    setState(() => _isLoadingData = true);
    try {
      final service = ref.read(provincesServiceProvider);
      final gov = await service.getGovernment(provId);
      
      if (gov != null && mounted) {
        setState(() {
          _governorIdController.text = gov.governorId ?? '';
          _viceGovernorIdController.text = gov.viceGovernorId ?? '';
          _cabinetChiefIdController.text = gov.cabinetChiefId ?? '';
          _mandateController.text = gov.mandate ?? '';
          _inaugurationDateController.text = gov.inaugurationDate ?? '';
          _programController.text = gov.programDescription ?? '';

          _ministers.clear();
          _ministers.addAll(gov.ministers);
          _ministerPortfolios.clear();
          _ministerAuthorityIds.clear();
          _ministerNames.clear();
          _ministerBios.clear();
          
          for (var m in gov.ministers) {
            _ministerPortfolios.add(TextEditingController(text: m.portfolio));
            _ministerAuthorityIds.add(TextEditingController(text: m.authorityId ?? ''));
            _ministerNames.add(TextEditingController(text: m.name ?? ''));
            _ministerBios.add(TextEditingController(text: m.biography ?? ''));
          }
        });
      } else {
        // Vider si aucun gouvernement pour cette province
        setState(() {
          _governorIdController.clear();
          _viceGovernorIdController.clear();
          _cabinetChiefIdController.clear();
          _mandateController.clear();
          _inaugurationDateController.clear();
          _programController.clear();
          _ministers.clear();
          _ministerPortfolios.clear();
          _ministerAuthorityIds.clear();
          _ministerNames.clear();
          _ministerBios.clear();
        });
      }
    } catch (e) {
      // Ignorer si inexistant
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  @override
  void dispose() {
    _governorIdController.dispose();
    _viceGovernorIdController.dispose();
    _cabinetChiefIdController.dispose();
    _mandateController.dispose();
    _inaugurationDateController.dispose();
    _programController.dispose();
    for (var c in _ministerPortfolios) { c.dispose(); }
    for (var c in _ministerAuthorityIds) { c.dispose(); }
    for (var c in _ministerNames) { c.dispose(); }
    for (var c in _ministerBios) { c.dispose(); }
    super.dispose();
  }

  void _addMinister() {
    setState(() {
      _ministerPortfolios.add(TextEditingController());
      _ministerAuthorityIds.add(TextEditingController());
      _ministerNames.add(TextEditingController());
      _ministerBios.add(TextEditingController());
    });
  }

  void _removeMinister(int index) {
    setState(() {
      _ministerPortfolios[index].dispose();
      _ministerAuthorityIds[index].dispose();
      _ministerNames[index].dispose();
      _ministerBios[index].dispose();
      
      _ministerPortfolios.removeAt(index);
      _ministerAuthorityIds.removeAt(index);
      _ministerNames.removeAt(index);
      _ministerBios.removeAt(index);
      if (index < _ministers.length) {
        _ministers.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provincesAsync = ref.watch(provincesProvider(null));

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: const Text('Gestion du Gouvernement Provincial', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: redThix,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          provincesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: navyDeep)),
            error: (err, _) => Center(child: Text('Erreur de chargement des provinces : $err')),
            data: (provinces) {
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      
                      // ── SÉLECTION DE LA PROVINCE POUR CLASSEMENT ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.filter_alt, color: redThix, size: 20),
                                SizedBox(width: 8),
                                Text('Classement par Province *', style: TextStyle(fontWeight: FontWeight.bold, color: navyDeep, fontSize: 15)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: _selectedProvinceId,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              hint: const Text('Sélectionner une province'),
                              items: provinces.map((Province p) {
                                return DropdownMenuItem<String>(
                                  value: p.id,
                                  child: Text('${p.name} (${p.region})', style: const TextStyle(fontWeight: FontWeight.w600)),
                                );
                              }).toList(),
                              onChanged: (String? newId) {
                                if (newId != null) {
                                  setState(() => _selectedProvinceId = newId);
                                  _loadGovernment(newId); // Recharge les données de la nouvelle province sélectionnée
                                }
                              },
                              validator: (v) => v == null ? 'Veuillez sélectionner une province' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_isLoadingData)
                        const Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(child: CircularProgressIndicator(color: navyDeep)),
                        )
                      else ...[
                        // ── TÊTE DE L'EXÉCUTIF ──
                        _buildSectionCard(
                          title: 'Tête de l\'Exécutif',
                          icon: Icons.account_balance,
                          children: [
                            _buildTextField(_governorIdController, 'ID ou Nom du Gouverneur', Icons.person, hintText: 'Nom ou UUID de l\'autorité'),
                            const SizedBox(height: 12),
                            _buildTextField(_viceGovernorIdController, 'ID ou Nom du Vice-gouverneur', Icons.person_outline, hintText: 'Nom ou UUID de l\'autorité'),
                            const SizedBox(height: 12),
                            _buildTextField(_cabinetChiefIdController, 'ID ou Nom du Directeur de Cabinet', Icons.badge, hintText: 'Optionnel'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── DÉTAILS DU MANDAT ──
                        _buildSectionCard(
                          title: 'Détails du Mandat & Programme',
                          icon: Icons.history_edu,
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildTextField(_mandateController, 'Période (ex: 2024-2028)', Icons.calendar_today)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildTextField(_inaugurationDateController, 'Investiture (Date)', Icons.event)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(_programController, 'Vision et Programme du Gouvernement', Icons.visibility, maxLines: 3),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── MINISTRES PROVINCIAUX (LISTE DYNAMIQUE) ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ministres Provinciaux', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: navyDeep)),
                            ElevatedButton.icon(
                              onPressed: _addMinister,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Ajouter un ministre'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: navyDeep.withOpacity(0.1),
                                foregroundColor: navyDeep,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_ministerPortfolios.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: hairline)),
                            child: const Center(child: Text('Aucun ministre ajouté pour le moment.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
                          ),

                        ..._ministerPortfolios.asMap().entries.map((entry) {
                          return _buildMinisterCard(entry.key);
                        }),

                        const SizedBox(height: 32),

                        ElevatedButton(
                          onPressed: _isBusy ? null : _save,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: navyDeep,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child: const Text('Enregistrer le gouvernement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          if (_isBusy) Container(color: Colors.black.withOpacity(0.4), child: const Center(child: CircularProgressIndicator(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hairline),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: navyDeep, size: 22), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: navyDeep))]),
          const Divider(height: 24, thickness: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {String? hintText, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: maxLines == 1 ? Icon(icon, color: Colors.grey.shade600, size: 20) : Padding(padding: const EdgeInsets.only(bottom: 48), child: Icon(icon, color: Colors.grey.shade600, size: 20)),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: navyDeep, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildMinisterCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hairline),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: navyDeep.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('Ministre #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: navyDeep)),
              ),
              InkWell(
                onTap: () => _removeMinister(index),
                child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.delete_outline, color: Colors.red, size: 20)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(_ministerPortfolios[index], 'Portefeuille (ex: Ministre de l\'Intérieur)', Icons.work),
          const SizedBox(height: 12),
          _buildTextField(_ministerNames[index], 'Nom complet du ministre', Icons.person),
          const SizedBox(height: 12),
          _buildTextField(_ministerBios[index], 'Courte biographie ou note', Icons.description, maxLines: 2),
        ],
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate() || _selectedProvinceId == null) return;
    
    setState(() => _isBusy = true);

    final existingMinisters = List<ProvinceMinister>.from(_ministers);
    final newMinisters = <ProvinceMinister>[];

    for (int i = 0; i < _ministerPortfolios.length; i++) {
      final portfolio = _ministerPortfolios[i].text.trim();
      final name = _ministerNames[i].text.trim();
      final bio = _ministerBios[i].text.trim();

      if (portfolio.isNotEmpty) {
        if (i < existingMinisters.length) {
          existingMinisters[i] = ProvinceMinister(
            id: existingMinisters[i].id,
            governmentId: existingMinisters[i].governmentId,
            portfolio: portfolio,
            name: name.isEmpty ? null : name,
            biography: bio.isEmpty ? null : bio,
          );
        } else {
          newMinisters.add(ProvinceMinister(
            id: '',
            governmentId: '',
            portfolio: portfolio,
            name: name.isEmpty ? null : name,
            biography: bio.isEmpty ? null : bio,
          ));
        }
      }
    }

    final service = ref.read(provincesServiceProvider);
    
    try {
      final existingGov = await service.getGovernment(_selectedProvinceId!);

      if (existingGov == null) {
        final newGov = ProvinceGovernment(
          id: '',
          provinceId: _selectedProvinceId!,
          governorId: _governorIdController.text.trim().isEmpty ? null : _governorIdController.text.trim(),
          viceGovernorId: _viceGovernorIdController.text.trim().isEmpty ? null : _viceGovernorIdController.text.trim(),
          cabinetChiefId: _cabinetChiefIdController.text.trim().isEmpty ? null : _cabinetChiefIdController.text.trim(),
          mandate: _mandateController.text.trim().isEmpty ? null : _mandateController.text.trim(),
          inaugurationDate: _inaugurationDateController.text.trim().isEmpty ? null : _inaugurationDateController.text.trim(),
          programDescription: _programController.text.trim().isEmpty ? null : _programController.text.trim(),
          ministers: newMinisters,
        );
        
        await service.createGovernment(newGov);
      } else {
        final updatedGov = ProvinceGovernment(
          id: existingGov.id,
          provinceId: _selectedProvinceId!,
          governorId: _governorIdController.text.trim().isEmpty ? null : _governorIdController.text.trim(),
          viceGovernorId: _viceGovernorIdController.text.trim().isEmpty ? null : _viceGovernorIdController.text.trim(),
          cabinetChiefId: _cabinetChiefIdController.text.trim().isEmpty ? null : _cabinetChiefIdController.text.trim(),
          mandate: _mandateController.text.trim().isEmpty ? null : _mandateController.text.trim(),
          inaugurationDate: _inaugurationDateController.text.trim().isEmpty ? null : _inaugurationDateController.text.trim(),
          programDescription: _programController.text.trim().isEmpty ? null : _programController.text.trim(),
          ministers: existingMinisters,
        );

        await service.updateGovernment(updatedGov);
        
        for (var m in newMinisters) {
          await service.addMinister(m);
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gouvernement enregistré avec succès'), backgroundColor: Colors.green));
        context.pop();
      }
    } catch (e) {
      setState(() => _isBusy = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }
}
