// lib/presentation/mon_pays/admin/sections/manage_documentaries.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../admin_controller.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/form_dialog.dart';
import '../../../models/documentary_model.dart';

class ManageDocumentaries extends StatelessWidget {
  final AdminController controller;

  const ManageDocumentaries({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return DataTableWidget<Documentary>(
        items: controller.documentaries,
        columns: const [
          DataColumnConfig(label: 'Titre'),
          DataColumnConfig(label: 'Durée'),
        ],
        cellBuilder: (doc) => [
          Text(
            doc.title,
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(doc.duration),
        ],
        onEdit: (doc) => _showEditDialog(context, doc),
        onDelete: (doc) => _confirmDelete(context, doc.id),
        isLoading: controller.isLoading,
        emptyMessage: 'Aucun documentaire enregistré',
      );
    });
  }

  void _showAddDialog(BuildContext context) {
    FormDialog.show(
      context: context,
      title: 'Ajouter un documentaire',
      fields: [
        FormFieldConfig(
          key: 'title',
          label: 'Titre',
          hint: 'Titre du documentaire',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'duration',
          label: 'Durée',
          hint: 'Ex: 45:00',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'thumbnailUrl',
          label: 'URL de la miniature',
          hint: 'https://exemple.com/miniature.jpg',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'category',
          label: 'Catégorie',
          type: FormFieldType.dropdown,
          dropdownItems: [
            'Histoire',
            'Parcs Nationaux',
            'Culture',
            'Patrimoine',
            'Tourisme',
            'Économie',
            'Mines',
            'Innovation',
          ],
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'url',
          label: 'URL du documentaire',
          hint: 'https://vimeo.com/...',
        ),
      ],
      onSubmit: (values) => controller.addDocumentary(
        Documentary(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: values['title'],
          duration: values['duration'],
          thumbnailUrl: values['thumbnailUrl'],
          category: values['category'],
          url: values['url'],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Documentary doc) {
    FormDialog.show(
      context: context,
      title: 'Modifier le documentaire',
      fields: [
        FormFieldConfig(
          key: 'title',
          label: 'Titre',
          defaultValue: doc.title,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'duration',
          label: 'Durée',
          defaultValue: doc.duration,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'thumbnailUrl',
          label: 'URL de la miniature',
          defaultValue: doc.thumbnailUrl,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'category',
          label: 'Catégorie',
          type: FormFieldType.dropdown,
          dropdownItems: [
            'Histoire',
            'Parcs Nationaux',
            'Culture',
            'Patrimoine',
            'Tourisme',
            'Économie',
            'Mines',
            'Innovation',
          ],
          defaultValue: doc.category,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'url',
          label: 'URL du documentaire',
          defaultValue: doc.url,
        ),
      ],
      isEditing: true,
      onSubmit: (values) => controller.updateDocumentary(
        doc.copyWith(
          title: values['title'],
          duration: values['duration'],
          thumbnailUrl: values['thumbnailUrl'],
          category: values['category'],
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
        content: const Text('Voulez-vous vraiment supprimer ce documentaire ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteDocumentary(id);
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
