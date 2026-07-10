// lib/presentation/mon_pays/admin/sections/manage_documentaries.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_provider.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/form_dialog.dart';
import '../../models/documentary_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ManageDocumentaries extends ConsumerWidget {
  const ManageDocumentaries({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminControllerProvider);
    final controller = ref.read(adminControllerProvider.notifier);

    return DataTableWidget<Documentary>(
      items: state.documentaries,
      columns: const [
        DataColumnConfig(label: 'Titre'),
        DataColumnConfig(label: 'Catégorie'),
        DataColumnConfig(label: 'Durée'),
      ],
      cellBuilder: (doc) => [
        Text(
          doc.title,
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(doc.category),
        Text(doc.duration),
      ],
      onEdit: (doc) => _showEditDialog(context, doc, controller),
      onDelete: (doc) => _confirmDelete(context, doc.id, controller),
      isLoading: state.isLoading,
      emptyMessage: 'Aucun documentaire enregistré',
    );
  }

  void _showAddDialog(BuildContext context, AdminController controller) {
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
          hint: 'Ex: Histoire, Culture, Parcs',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'url',
          label: 'URL du documentaire',
          hint: 'https://vimeo.com/...',
        ),
        FormFieldConfig(
          key: 'description',
          label: 'Description',
          type: FormFieldType.multiline,
          hint: 'Description du documentaire',
        ),
        FormFieldConfig(
          key: 'year',
          label: 'Année',
          hint: 'Ex: 2024',
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
          description: values['description'],
          year: values['year'],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Documentary doc, AdminController controller) {
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
          defaultValue: doc.category,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'url',
          label: 'URL du documentaire',
          defaultValue: doc.url,
        ),
        FormFieldConfig(
          key: 'description',
          label: 'Description',
          type: FormFieldType.multiline,
          defaultValue: doc.description,
        ),
        FormFieldConfig(
          key: 'year',
          label: 'Année',
          defaultValue: doc.year,
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
          description: values['description'],
          year: values['year'],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, AdminController controller) {
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
