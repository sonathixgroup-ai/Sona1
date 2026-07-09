// lib/presentation/mon_pays/admin/sections/manage_videos.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../admin_controller.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/form_dialog.dart';
import '../../../models/video_model.dart';

class ManageVideos extends StatelessWidget {
  final AdminController controller;

  const ManageVideos({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return DataTableWidget<Video>(
        items: controller.videos,
        columns: const [
          DataColumnConfig(label: 'Titre'),
          DataColumnConfig(label: 'Durée'),
        ],
        cellBuilder: (video) => [
          Text(
            video.title,
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(video.duration),
        ],
        onEdit: (video) => _showEditDialog(context, video),
        onDelete: (video) => _confirmDelete(context, video.id),
        isLoading: controller.isLoading,
        emptyMessage: 'Aucune vidéo enregistrée',
      );
    });
  }

  void _showAddDialog(BuildContext context) {
    FormDialog.show(
      context: context,
      title: 'Ajouter une vidéo',
      fields: [
        FormFieldConfig(
          key: 'title',
          label: 'Titre',
          hint: 'Titre de la vidéo',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'duration',
          label: 'Durée',
          hint: 'Ex: 12:30',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'thumbnailUrl',
          label: 'URL de la miniature',
          hint: 'https://exemple.com/miniature.jpg',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'url',
          label: 'URL de la vidéo',
          hint: 'https://youtube.com/watch?v=...',
        ),
      ],
      onSubmit: (values) => controller.addVideo(
        Video(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: values['title'],
          duration: values['duration'],
          thumbnailUrl: values['thumbnailUrl'],
          url: values['url'],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Video video) {
    FormDialog.show(
      context: context,
      title: 'Modifier la vidéo',
      fields: [
        FormFieldConfig(
          key: 'title',
          label: 'Titre',
          defaultValue: video.title,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'duration',
          label: 'Durée',
          defaultValue: video.duration,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'thumbnailUrl',
          label: 'URL de la miniature',
          defaultValue: video.thumbnailUrl,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'url',
          label: 'URL de la vidéo',
          defaultValue: video.url,
        ),
      ],
      isEditing: true,
      onSubmit: (values) => controller.updateVideo(
        video.copyWith(
          title: values['title'],
          duration: values['duration'],
          thumbnailUrl: values['thumbnailUrl'],
          url: values['url'],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette vidéo ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteVideo(id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryRed),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
