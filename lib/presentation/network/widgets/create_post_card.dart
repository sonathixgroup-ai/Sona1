// lib/presentation/network/widgets/create_post_card.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class CreatePostCard extends StatefulWidget {
  final Future<void> Function(String text, List<PlatformFile>? files) onCreate;
  const CreatePostCard({Key? key, required this.onCreate}) : super(key: key);

  @override
  State<CreatePostCard> createState() => _CreatePostCardState();
}

class _CreatePostCardState extends State<CreatePostCard> {
  final _controller = TextEditingController();
  List<PlatformFile> _picked = [];
  bool _loading = false;

  Future<void> _pickFiles() async {
    final res = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.image, withData: true);
    if (res == null) return;
    setState(() => _picked = res.files);
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _picked.isEmpty) return;
    setState(() => _loading = true);
    try {
      await widget.onCreate(text, _picked.isEmpty ? null : _picked);
      _controller.clear();
      setState(() => _picked = []);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _controller, decoration: const InputDecoration.collapsed(hintText: "Quoi de neuf ?"))),
              ],
            ),
            if (_picked.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _picked.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final p = _picked[i];
                    return Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]),
                          child: p.bytes != null ? Image.memory(p.bytes!, fit: BoxFit.cover) : (p.path != null ? Image.file(File(p.path!), fit: BoxFit.cover) : SizedBox.shrink()),
                        ),
                        Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => setState(() => _picked.removeAt(i)), child: CircleAvatar(radius: 12, child: Icon(Icons.close, size: 14))))
                      ],
                    );
                  },
                ),
              )
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(onPressed: _pickFiles, icon: const Icon(Icons.photo), label: const Text('Photo')),
                const Spacer(),
                ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Publier'))
              ],
            )
          ],
        ),
      ),
    );
  }
}
