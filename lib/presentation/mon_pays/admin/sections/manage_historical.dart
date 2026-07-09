// lib/presentation/mon_pays/admin/sections/manage_historical.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../admin_controller.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/form_dialog.dart';
import '../../../models/historical_figure_model.dart';

class ManageHistorical extends StatelessWidget {
  final AdminController controller;

  const ManageHistorical({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return DataTableWidget<HistoricalFigure>(
        items: controller.historicalFigures,
        columns: const [
          DataColumnConfig(label: 'Nom'),
          DataColumnConfig(label: 'Période'),
          DataColumnConfig(label: 'Description'),
        ],
        cellBuilder: (figure) => [
          Text(
            figure.name,
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(figure.period),
          Text(
            figure.description ?? '-',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        onEdit: (figure) => _showEditDialog(context, figure),
        onDelete: (figure) => _confirmDelete(context, figure.id),
        isLoading: controller.isLoading,
        emptyMessage: 'Aucune figure historique enregistrée',
      );
    });
  }

  void _showAddDialog(BuildContext context) {
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
          hint: 'Description de la figure historique',
        ),
        FormFieldConfig(
          key: 'imageUrl',
          label: 'URL de l\'image',
          hint: 'https://exemple.com/image.jpg',
        ),
      ],
      onSubmit: (values) => controller.addHistoricalFigure(
        HistoricalFigure(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: values['name'],
          period: values['period'],
          description: values['description'],
          imageUrl: values['imageUrl'],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, HistoricalFigure figure) {
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
      ],
      isEditing: true,
      onSubmit: (values) => controller.updateHistoricalFigure(
        figure.copyWith(
          name: values['name'],
          period: values['period'],
          description: values['description'],
          imageUrl: values['imageUrl'],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
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
