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
  double _coverProgress = 0, _videoProgress = 0;
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cover + Vidéo obligatoires')));
      return;
    }
    setState(() => _saving = true);
    try {
      final service = MediaService(client: Supabase.instance.client, bucket: 'media');
      String coverUrl = widget.existing?.coverUrl ?? '';
      String videoUrl = widget.existing?.videoUrl ?? '';

      if (_coverFile != null) {
        setState(() => _status = 'Upload cover...');
        for (var i = 0; i <= 10; i++) {
          await Future.delayed(Duration(milliseconds: 80));
          if (mounted) setState(() => _coverProgress = i / 10);
        }
        final up = await service.uploadFile(file: _coverFile!, path: 'thix_media/covers');
        coverUrl = up['url']!;
        setState(() => _coverProgress = 1);
      }
      if (_videoFile != null) {
        setState(() => _status = 'Upload vidéo... ${_videoFile!.size ~/ 1024 ~/ 1024} Mo');
        for (var i = 0; i <= 10; i++) {
          await Future.delayed(Duration(milliseconds: 150));
          if (mounted) setState(() => _videoProgress = i / 10);
        }
        final up = await service.uploadFile(file: _videoFile!, path: 'thix_media/videos');
        videoUrl = up['url']!;
        setState(() => _videoProgress = 1);
      }

      setState(() => _status = 'Enregistrement en base...');

      if (widget.existing == null) {
        final newItem = MediaContent(
          id: 'temp', // ID bidon temporaire
          title: _title.text.trim(),
          subtitle: _subtitle.text.trim(),
          type: _type,
          year: _year.text.trim(),
          coverUrl: coverUrl,
          videoUrl: videoUrl,
          viewCount: 0,
          rankPosition: _isTrending ? _rank : null,
          isTrending: _isTrending,
          isNewRelease: _isNew,
          isRecommended: true,
          isPublished: _isPublished,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        // ✅ LA CORRECTION EST ICI :
        // On convertit l'objet en JSON et on supprime l'ID invalide
        // pour que Supabase génère automatiquement un vrai UUID.
        final insertData = newItem.toJson();
        insertData.remove('id');
        
        await Supabase.instance.client.from('media_content').insert(insertData);
        
      } else {
        await Supabase.instance.client.from('media_content').update({
          'title': _title.text.trim(),
          'subtitle': _subtitle.text.trim(),
          'type': _type,
          'year': _year.text.trim(),
          'cover_url': coverUrl,
          'video_url': videoUrl,
          'rank_position': _isTrending ? _rank : null,
          'is_trending': _isTrending,
          'is_new_release': _isNew,
          'is_published': _isPublished,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', widget.existing!.id);
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      padding: EdgeInsets.fromLTRB(18, 10, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Color(0xFFE7EEFC), borderRadius: BorderRadius.circular(10)))),
              SizedBox(height: 14),
              Text(widget.existing == null ? 'Nouvelle vidéo' : 'Modifier', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0A1F44))),
              SizedBox(height: 14),
              
              if (_saving) ...[
                if (_coverFile != null) UploadProgress(progress: _coverProgress, fileName: _coverFile!.name, status: 'Cover'),
                if (_coverFile != null && _videoFile != null) SizedBox(height: 8),
                if (_videoFile != null) UploadProgress(progress: _videoProgress, fileName: _videoFile!.name, status: _status),
                SizedBox(height: 14),
              ],
              
              Row(
                children: [
                  // SÉLECTEUR COVER
                  Expanded(
                    child: InkWell(
                      onTap: _saving ? null : _pickCover,
                      child: Container(
                        height: 110,
                        decoration: BoxDecoration(color: Color(0xFFF7FAFF), borderRadius: BorderRadius.circular(14), border: Border.all(color: Color(0xFFE7EEFC))),
                        child: _coverFile != null
                            ? Center(child: Icon(Icons.check_circle_rounded, color: Colors.green))
                            : widget.existing != null
                                ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(widget.existing!.coverUrl, fit: BoxFit.cover, width: double.infinity))
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_rounded, color: Color(0xFF2D6CDF)),
                                      Text('Cover *')
                                    ],
                                  ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // SÉLECTEUR VIDÉO
                  Expanded(
                    child: InkWell(
                      onTap: _saving ? null : _pickVideo,
                      child: Container(
                        height: 110,
                        decoration: BoxDecoration(color: Color(0xFFF7FAFF), borderRadius: BorderRadius.circular(14), border: Border.all(color: Color(0xFFE7EEFC))),
                        child: _videoFile != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Colors.green),
                                    Text('${(_videoFile!.size / 1024 / 1024).toStringAsFixed(1)} Mo', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700))
                                  ],
                                ),
                              )
                            : Column(
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
              
              SizedBox(height: 16),
              TextFormField(controller: _title, validator: (v) => v!.isEmpty ? 'Titre requis' : null, decoration: InputDecoration(labelText: 'Titre *', filled: true, fillColor: Color(0xFFF7FAFF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              SizedBox(height: 12),
              TextFormField(controller: _subtitle, decoration: InputDecoration(labelText: 'Sous-titre', filled: true, fillColor: Color(0xFFF7FAFF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _type,
                      items: ['Films', 'Séries', 'Vidéos', 'Musique'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _type = v!),
                      decoration: InputDecoration(labelText: 'Type', filled: true, fillColor: Color(0xFFF7FAFF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(controller: _year, decoration: InputDecoration(labelText: 'Année', filled: true, fillColor: Color(0xFFF7FAFF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  ),
                ],
              ),
              
              SwitchListTile(value: _isPublished, title: Text('Publié'), activeColor: Color(0xFF2D6CDF), onChanged: (v) => setState(() => _isPublished = v)),
              SwitchListTile(value: _isNew, title: Text('Nouveauté (Banner)'), activeColor: Color(0xFF2D6CDF), onChanged: (v) => setState(() => _isNew = v)),
              SwitchListTile(value: _isTrending, title: Text('Tendance'), activeColor: Color(0xFF2D6CDF), onChanged: (v) => setState(() => _isTrending = v)),
              SizedBox(height: 18),
              
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0A1F44), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  child: _saving
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(widget.existing == null ? 'Uploader et Publier' : 'Enregistrer', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
