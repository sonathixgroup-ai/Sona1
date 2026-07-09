// lib/presentation/mon_pays/admin/sections/manage_agencies.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../admin_controller.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/form_dialog.dart';
import '../../../models/agency_model.dart';

class ManageAgencies extends StatelessWidget {
  final AdminController controller;

  const ManageAgencies({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return DataTableWidget<Agency>(
        items: controller.agencies,
        columns: const [
          DataColumnConfig(label: 'Nom'),
          DataColumnConfig(label: 'Description'),
        ],
        cellBuilder: (agency) => [
          Text(
            agency.name,
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(agency.description ?? '-'),
        ],
        onEdit: (agency) => _showEditDialog(context, agency),
        onDelete: (agency) => _confirmDelete(context, agency.id),
        isLoading: controller.isLoading,
        emptyMessage: 'Aucune agence enregistrée',
      );
    });
  }

  void _showAddDialog(BuildContext context) {
    FormDialog.show(
      context: context,
      title: 'Ajouter une agence',
      fields: [
        FormFieldConfig(
          key: 'name',
          label: 'Nom de l\'agence',
          hint: 'Ex: CENI',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'description',
          label: 'Description',
          type: FormFieldType.multiline,
          hint: 'Description de l\'agence',
        ),
        FormFieldConfig(
          key: 'logoUrl',
          label: 'URL du logo',
          hint: 'https://exemple.com/logo.png',
        ),
      ],
      onSubmit: (values) => controller.addAgency(
        Agency(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: values['name'],
          description: values['description'],
          logoUrl: values['logoUrl'],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Agency agency) {
    FormDialog.show(
      context: context,
      title: 'Modifier l\'agence',
      fields: [
        FormFieldConfig(
          key: 'name',
          label: 'Nom de l\'agence',
          defaultValue: agency.name,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'description',
          label: 'Description',
          type: FormFieldType.multiline,
          defaultValue: agency.description,
        ),
        FormFieldConfig(
          key: 'logoUrl',
          label: 'URL du logo',
          defaultValue: agency.logoUrl,
        ),
      ],
      isEditing: true,
      onSubmit: (values) => controller.updateAgency(
        agency.copyWith(
          name: values['name'],
          description: values['description'],
          logoUrl: values['logoUrl'],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette agence ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteAgency(id);
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
