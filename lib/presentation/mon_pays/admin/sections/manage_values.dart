// lib/presentation/mon_pays/admin/sections/manage_values.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_provider.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/form_dialog.dart';
import '../../models/value_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ManageValues extends ConsumerWidget {
  const ManageValues({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminControllerProvider);
    final controller = ref.read(adminControllerProvider.notifier);

    return DataTableWidget<Value>(
      items: state.values,
      columns: const [
        DataColumnConfig(label: 'Titre'),
        DataColumnConfig(label: 'Catégorie'),
      ],
      cellBuilder: (value) => [
        Text(
          value.title,
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(value.category ?? '-'),
      ],
      onEdit: (value) => _showEditDialog(context, value, controller),
      onDelete: (value) => _confirmDelete(context, value.id, controller),
      isLoading: state.isLoading,
      emptyMessage: 'Aucune valeur enregistrée',
    );
  }

  void _showAddDialog(BuildContext context, AdminController controller) {
    FormDialog.show(
      context: context,
      title: 'Ajouter une valeur',
      fields: [
        FormFieldConfig(
          key: 'title',
          label: 'Titre',
          hint: 'Ex: Constitution',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'description',
          label: 'Description',
          type: FormFieldType.multiline,
          hint: 'Description de la valeur',
        ),
        FormFieldConfig(
          key: 'category',
          label: 'Catégorie',
          hint: 'Ex: Droit, Devoir, Institution',
        ),
        FormFieldConfig(
          key: 'iconCode',
          label: 'Code de l\'icône',
          hint: 'Code numérique de l\'icône Material',
        ),
      ],
      onSubmit: (values) => controller.addValue(
        Value(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: values['title'],
          description: values['description'],
          category: values['category'],
          iconCode: values['iconCode'],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Value value, AdminController controller) {
    FormDialog.show(
      context: context,
      title: 'Modifier la valeur',
      fields: [
        FormFieldConfig(
          key: 'title',
          label: 'Titre',
          defaultValue: value.title,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'description',
          label: 'Description',
          type: FormFieldType.multiline,
          defaultValue: value.description,
        ),
        FormFieldConfig(
          key: 'category',
          label: 'Catégorie',
          defaultValue: value.category,
        ),
        FormFieldConfig(
          key: 'iconCode',
          label: 'Code de l\'icône',
          defaultValue: value.iconCode,
        ),
      ],
      isEditing: true,
      onSubmit: (values) => controller.updateValue(
        value.copyWith(
          title: values['title'],
          description: values['description'],
          category: values['category'],
          iconCode: values['iconCode'],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, AdminController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette valeur ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteValue(id);
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
