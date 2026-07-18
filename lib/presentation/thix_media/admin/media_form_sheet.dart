import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/media_content.dart';
import '../../../services/media_service.dart';
import 'upload_progress.dart';

class MediaFormSheet extends StatefulWidget {
  final MediaContent? existing;
  final VoidCallback onSaved;
  const MediaFormSheet({super.key, this.existing, required this.onSaved});
  @override
  State<MediaFormSheet> createState() => _MediaFormSheetState();
}

class _MediaFormSheetState extends State<MediaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _title, _subtitle, _year;
  String _type = 'Films';
  bool _isPublished = true, _isNew = true, _isTrending = false;
  int? _rank = 1;
  PlatformFile? _coverFile, _videoFile;
  bool _saving = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _subtitle = TextEditingController(text: e?.subtitle ?? '');
    _year = TextEditingController(text: e?.year ?? DateTime.now().year.toString());
    _type = e?.type ?? 'Films';
    _isPublished = e?.isPublished ?? true;
    _isNew = e?.isNewRelease ?? true;
    _isTrending = e?.rankPosition != null;
    _rank = e?.rankPosition ?? 1;
  }

  Future<void> _pickCover() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (res != null) setState(() => _coverFile = res.files.first);
  }

  Future<void> _pickVideo() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
    if (res != null) setState(() => _videoFile = res.files.first);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.existing == null && (_coverFile == null || _videoFile == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cover + Vidéo obligatoires')));
      return;
    }
    
    setState(() {
      _saving = true;
      _status = 'Upload parallèle et sécurisation en cours...';
    });
    
    try {
      final service = MediaService(client: Supabase.instance.client, bucket: 'media');

      // Création de l'objet de base. 
      // L'ID vide sera automatiquement remplacé par un UUID sécurisé par le service.
      final baseItem = MediaContent(
        id: widget.existing?.id ?? '', 
        title: _title.text.trim(),
        subtitle: _subtitle.text.trim(),
        type: _type,
        year: _year.text.trim(),
        coverUrl: widget.existing?.coverUrl ?? '',
        videoUrl: widget.existing?.videoUrl ?? '',
        viewCount: widget.existing?.viewCount ?? 0,
        rankPosition: _isTrending ? _rank : null,
        isTrending: _isTrending,
        isNewRelease: _isNew,
        isRecommended: true,
        isPublished: _isPublished,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Le nouveau MediaService gère tout (Upload + Base de données) en une ligne !
      if (widget.existing == null) {
        await service.insertWithFiles(baseItem, coverFile: _coverFile, videoFile: _videoFile);
      } else {
        await service.updateWithFiles(baseItem, newCoverFile: _coverFile, newVideoFile: _videoFile);
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      padding: EdgeInsets.fromLTRB(18, 10, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: const Color(0xFFE7EEFC), borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 14),
              Text(widget.existing == null ? 'Nouvelle vidéo' : 'Modifier', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0A1F44))),
              const SizedBox(height: 14),
              
              if (_saving) ...[
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF2D6CDF)),
                      const SizedBox(height: 12),
                      Text(_status, style: const TextStyle(color: Color(0xFF7386A8), fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _saving ? null : _pickCover,
                      child: Container(
                        height: 110,
                        decoration: BoxDecoration(color: const Color(0xFFF7FAFF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE7EEFC))),
                        child: _coverFile != null
                            ? const Center(child: Icon(Icons.check_circle_rounded, color: Colors.green))
                            : widget.existing != null
                                ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(widget.existing!.coverUrl, fit: BoxFit.cover, width: double.infinity))
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_rounded, color: Color(0xFF2D6CDF)),
                                      Text('Cover *')
                                    ],
                                  ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _saving ? null : _pickVideo,
                      child: Container(
                        height: 110,
                        decoration: BoxDecoration(color: const Color(0xFFF7FAFF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE7EEFC))),
                        child: _videoFile != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Colors.green),
                                    Text('${(_videoFile!.size / 1024 / 1024).toStringAsFixed(1)} Mo', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))
                                  ],
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.video_library_rounded, color: Color(0xFF2D6CDF)),
                                  Text('Vidéo MP4 *')
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              TextFormField(controller: _title, validator: (v) => v!.isEmpty ? 'Titre requis' : null, decoration: InputDecoration(labelText: 'Titre *', filled: true, fillColor: const Color(0xFFF7FAFF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextFormField(controller: _subtitle, decoration: InputDecoration(labelText: 'Sous-titre', filled: true, fillColor: const Color(0xFFF7FAFF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _type,
                      items: ['Films', 'Séries', 'Vidéos', 'Musique'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _type = v!),
                      decoration: InputDecoration(labelText: 'Type', filled: true, fillColor: const Color(0xFFF7FAFF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(controller: _year, decoration: InputDecoration(labelText: 'Année', filled: true, fillColor: const Color(0xFFF7FAFF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  ),
                ],
              ),
              
              SwitchListTile(value: _isPublished, title: const Text('Publié'), activeColor: const Color(0xFF2D6CDF), onChanged: (v) => setState(() => _isPublished = v)),
              SwitchListTile(value: _isNew, title: const Text('Nouveauté (Banner)'), activeColor: const Color(0xFF2D6CDF), onChanged: (v) => setState(() => _isNew = v)),
              SwitchListTile(value: _isTrending, title: const Text('Tendance'), activeColor: const Color(0xFF2D6CDF), onChanged: (v) => setState(() => _isTrending = v)),
              const SizedBox(height: 18),
              
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A1F44), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(widget.existing == null ? 'Uploader et Publier' : 'Enregistrer', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
