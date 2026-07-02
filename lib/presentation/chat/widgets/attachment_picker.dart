// lib/presentation/chat/widgets/attachment_picker.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class AttachmentPicker {
  static Future<File?> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) return File(picked.path);
    return null;
  }

  static Future<File?> pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) return File(picked.path);
    return null;
  }

  static Future<File?> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  static void showPickerSheet(BuildContext context, Function(File) onSelected) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Image'),
              onTap: () async {
                final file = await pickImage();
                if (file != null) onSelected(file);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Vidéo'),
              onTap: () async {
                final file = await pickVideo();
                if (file != null) onSelected(file);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Fichier'),
              onTap: () async {
                final file = await pickFile();
                if (file != null) onSelected(file);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
