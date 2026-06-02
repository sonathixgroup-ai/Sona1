import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminTrainingsPage extends StatefulWidget {
  const AdminTrainingsPage({super.key});

  @override
  State<AdminTrainingsPage> createState() => _AdminTrainingsPageState();
}

class _AdminTrainingsPageState extends State<AdminTrainingsPage> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _trainings = [];
  List<dynamic> _lessons = [];
  bool _loading = true;
  String? _selectedTrainingId;
  int _tabIndex = 0;

  static const _brandColor = Color(0xFF6366F1);
  static const _accentColor = Color(0xFFEEF2FF);
  static const _textDark = Color(0xFF1E293B);
  static const _textGrey = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadTrainings();
  }

  Future<void> _loadTrainings() async {
    setState(() => _loading = true);
    try {
      final res = await _supabase.from('thix_trainings').select('*').order('created_at', ascending: false);
      if (!mounted) return;
      setState(() => _trainings = res is List ? res : []);
    } catch (e) {
      debugPrint('Error loading trainings: \$e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadLessons(String trainingId) async {
    try {
      final res = await _supabase.from('thix_training_lessons').select('*').eq('training_id', trainingId).order('module_index').order('lesson_index');
      if (!mounted) return;
      setState(() => _lessons = res is List ? res : []);
    } catch (e) {
      debugPrint('Error loading lessons: \$e');
    }
  }

  void _showCreateTrainingDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final levelCtrl = TextEditingController(text: 'Beginner');
    final priceCtrl = TextEditingController(text: '0');
    bool isFree = true;
    bool certIncluded = true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer une Formation'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Titre *', hintText: 'Ex: Cybersecurity 101'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description', hintText: 'Description de la formation'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Catégorie', hintText: 'Ex: Cybersecurity'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: levelCtrl,
                  decoration: const InputDecoration(labelText: 'Niveau', hintText: 'Beginner, Intermediate, Advanced'),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: isFree,
                  onChanged: (v) => setState(() => isFree = v ?? false),
                  title: const Text('Formation Gratuite'),
                ),
                if (!isFree)
                  TextField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(labelText: 'Prix', hintText: '25'),
                    keyboardType: TextInputType.number,
                  ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: certIncluded,
                  onChanged: (v) => setState(() => certIncluded = v ?? false),
                  title: const Text('Certificat Inclus'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Titre requis')));
                return;
              }
              try {
                await _supabase.from('thix_trainings').insert({
                  'title': titleCtrl.text.trim(),
                  'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  'category': categoryCtrl.text.trim().isEmpty ? 'General' : categoryCtrl.text.trim(),
                  'level': levelCtrl.text.trim().isEmpty ? 'Beginner' : levelCtrl.text.trim(),
                  'language': 'FR',
                  'delivery_mode': 'online',
                  'is_free': isFree,
                  'price_amount': isFree ? 0 : double.tryParse(priceCtrl.text) ?? 0,
                  'currency': 'USD',
                  'certification_included': certIncluded,
                  'is_featured': false,
                  'is_published': false,
                });
                if (!mounted) return;
                Navigator.pop(context);
                _loadTrainings();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Formation créée!')));
              } catch (e) {
                debugPrint('Error creating training: \$e');
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: \$e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _brandColor),
            child: const Text('Créer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreateLessonDialog(String trainingId) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '30');
    final moduleCtrl = TextEditingController(text: '1');
    final lessonCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une Leçon'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Titre *', hintText: 'Introduction'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: moduleCtrl,
                      decoration: const InputDecoration(labelText: 'Module #'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: lessonCtrl,
                      decoration: const InputDecoration(labelText: 'Leçon #'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationCtrl,
                decoration: const InputDecoration(labelText: 'Durée (min)', hintText: '30'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Titre requis')));
                return;
              }
              try {
                await _supabase.from('thix_training_lessons').insert({
                  'training_id': trainingId,
                  'title': titleCtrl.text.trim(),
                  'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  'module_index': int.tryParse(moduleCtrl.text) ?? 1,
                  'lesson_index': int.tryParse(lessonCtrl.text) ?? 1,
                  'content_type': 'video',
                  'duration_minutes': int.tryParse(durationCtrl.text) ?? 30,
                  'is_preview': false,
                });
                if (!mounted) return;
                Navigator.pop(context);
                _loadLessons(trainingId);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leçon ajoutée!')));
              } catch (e) {
                debugPrint('Error creating lesson: \$e');
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: \$e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _brandColor),
            child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Gestion des Formations', style: TextStyle(color: _textDark, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: _loadTrainings,
            icon: const Icon(Icons.refresh_rounded, color: _brandColor),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brandColor))
          : Row(
              children: [
                // LISTE FORMATIONS (GAUCHE)
                Expanded(
                  flex: 2,
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Formations (${_trainings.length})',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: _textDark),
                              ),
                              ElevatedButton.icon(
                                onPressed: _showCreateTrainingDialog,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Nouvelle'),
                                style: ElevatedButton.styleFrom(backgroundColor: _brandColor),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _trainings.length,
                            itemBuilder: (context, i) {
                              final t = _trainings[i];
                              final isSelected = t['id'] == _selectedTrainingId;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? _brandColor : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isSelected ? _brandColor : const Color(0xFFE2E8F0)),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    setState(() => _selectedTrainingId = t['id']);
                                    _loadLessons(t['id']);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t['title'] ?? 'Sans titre',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : _textDark,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (t['is_published'] ?? false) ? Colors.green.shade200 : Colors.orange.shade200,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                (t['is_published'] ?? false) ? 'Publiée' : 'Brouillon',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: (t['is_published'] ?? false) ? Colors.green : Colors.orange,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${t['price_amount'] ?? 0} ${t['currency'] ?? 'USD'}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isSelected ? Colors.white70 : _textGrey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // DÉTAILS (DROITE)
                Expanded(
                  flex: 3,
                  child: _selectedTrainingId == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.school_rounded, size: 60, color: _textGrey),
                              SizedBox(height: 16),
                              Text('Sélectionnez une formation', style: TextStyle(color: _textGrey)),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // TAB BAR
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                              child: Row(
                                children: [
                                  _buildTab('Détails', 0),
                                  _buildTab('Leçons', 1),
                                  _buildTab('Statistiques', 2),
                                ],
                              ),
                            ),

                            // CONTENT
                            Expanded(
                              child: _buildTabContent(),
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildTab(String label, int index) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _tabIndex == index ? _brandColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: InkWell(
          onTap: () => setState(() => _tabIndex = index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: _tabIndex == index ? _brandColor : _textGrey,
                  fontWeight: _tabIndex == index ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    final training = _trainings.firstWhere((t) => t['id'] == _selectedTrainingId, orElse: () => null);
    if (training == null) return const SizedBox.shrink();

    switch (_tabIndex) {
      case 0:
        return _buildDetailsTab(training);
      case 1:
        return _buildLessonsTab();
      case 2:
        return _buildStatsTab(training);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDetailsTab(dynamic training) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildDetailRow('Titre', training['title'] ?? ''),
        _buildDetailRow('Catégorie', training['category'] ?? ''),
        _buildDetailRow('Niveau', training['level'] ?? ''),
        _buildDetailRow('Langue', training['language'] ?? ''),
        _buildDetailRow('Mode', training['delivery_mode'] ?? ''),
        _buildDetailRow('Prix', '${training['price_amount'] ?? 0} ${training['currency'] ?? 'USD'}'),
        _buildDetailRow('Gratuit', (training['is_free'] ?? false) ? 'Oui' : 'Non'),
        _buildDetailRow('Certificat', (training['certification_included'] ?? false) ? 'Inclus' : 'Non'),
        _buildDetailRow('Créée', training['created_at'] ?? ''),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: _textGrey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: _textDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showCreateLessonDialog(_selectedTrainingId!),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ajouter une Leçon'),
            style: ElevatedButton.styleFrom(backgroundColor: _brandColor),
          ),
        ),
        Expanded(
          child: _lessons.isEmpty
              ? const Center(
                  child: Text('Aucune leçon', style: TextStyle(color: _textGrey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lessons.length,
                  itemBuilder: (context, i) {
                    final l = _lessons[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l['title'] ?? 'Sans titre',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: _textDark),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text('Module ${l['module_index']}.${l['lesson_index']}', style: const TextStyle(fontSize: 11, color: _textGrey)),
                              const Spacer(),
                              Text('${l['duration_minutes']} min', style: const TextStyle(fontSize: 11, color: _textGrey)),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: () async {
                                  try {
                                    await _supabase.from('thix_training_lessons').delete().eq('id', l['id']);
                                    _loadLessons(_selectedTrainingId!);
                                  } catch (e) {
                                    debugPrint('Delete error: \$e');
                                  }
                                },
                                icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatsTab(dynamic training) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildStatCard('Inscrits', (training['students_count'] ?? 0).toString()),
        _buildStatCard('Taux de complétion', '${((training['completion_rate'] ?? 0) * 100).toStringAsFixed(1)}%'),
        _buildStatCard('Note moyenne', (training['rating'] ?? 0).toStringAsFixed(1)),
        _buildStatCard('Avis', (training['reviews_count'] ?? 0).toString()),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accentColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _textGrey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: _brandColor, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
