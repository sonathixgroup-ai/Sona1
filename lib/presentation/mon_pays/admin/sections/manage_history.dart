// lib/presentation/mon_pays/admin/sections/manage_history.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_provider.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/form_dialog.dart';
import '../../models/history_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ManageHistory extends ConsumerWidget {
  const ManageHistory({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminControllerProvider);
    final controller = ref.read(adminControllerProvider.notifier);

    return DataTableWidget<HistoricalFigure>(
      items: state.historicalFigures,
      columns: const [
        DataColumnConfig(label: 'Nom'),
        DataColumnConfig(label: 'Période'),
      ],
      cellBuilder: (figure) => [
        Text(
          figure.name,
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(figure.period),
      ],
      onEdit: (figure) => _showEditDialog(context, figure, controller),
      onDelete: (figure) => _confirmDelete(context, figure.id, controller),
      isLoading: state.isLoading,
      emptyMessage: 'Aucune figure historique enregistrée',
    );
  }

  void _showAddDialog(BuildContext context, AdminController controller) {
    FormDialog.show(
      context: context,
      title: 'Ajouter une figure historique',
      fields: [
        FormFieldConfig(
          key: 'name',
          label: 'Nom complet',
          hint: 'Ex: Patrice Lumumba',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'period',
          label: 'Période',
          hint: 'Ex: 1925-1961',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'description',
          label: 'Description',
          type: FormFieldType.multiline,
          hint: 'Description de la figure',
        ),
        FormFieldConfig(
          key: 'imageUrl',
          label: 'URL de l\'image',
          hint: 'https://exemple.com/image.jpg',
        ),
        FormFieldConfig(
          key: 'biography',
          label: 'Biographie',
          type: FormFieldType.multiline,
          hint: 'Biographie complète',
        ),
      ],
      onSubmit: (values) => controller.addHistoricalFigure(
        HistoricalFigure(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: values['name'],
          period: values['period'],
          description: values['description'],
          imageUrl: values['imageUrl'],
          biography: values['biography'],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, HistoricalFigure figure, AdminController controller) {
    FormDialog.show(
      context: context,
      title: 'Modifier la figure historique',
      fields: [
        FormFieldConfig(
          key: 'name',
          label: 'Nom complet',
          defaultValue: figure.name,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'period',
          label: 'Période',
          defaultValue: figure.period,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'description',
          label: 'Description',
          type: FormFieldType.multiline,
          defaultValue: figure.description,
        ),
        FormFieldConfig(
          key: 'imageUrl',
          label: 'URL de l\'image',
          defaultValue: figure.imageUrl,
        ),
        FormFieldConfig(
          key: 'biography',
          label: 'Biographie',
          type: FormFieldType.multiline,
          defaultValue: figure.biography,
        ),
      ],
      isEditing: true,
      onSubmit: (values) => controller.updateHistoricalFigure(
        figure.copyWith(
          name: values['name'],
          period: values['period'],
          description: values['description'],
          imageUrl: values['imageUrl'],
          biography: values['biography'],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, AdminController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette figure historique ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteHistoricalFigure(id);
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
