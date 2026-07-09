// lib/presentation/mon_pays/admin/sections/manage_citizens.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../admin_controller.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/form_dialog.dart';
import '../../../models/exemplary_citizen_model.dart';

class ManageCitizens extends StatelessWidget {
  final AdminController controller;

  const ManageCitizens({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return DataTableWidget<ExemplaryCitizen>(
        items: controller.exemplaryCitizens,
        columns: const [
          DataColumnConfig(label: 'Nom'),
          DataColumnConfig(label: 'Profession'),
        ],
        cellBuilder: (citizen) => [
          Text(
            citizen.name,
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(citizen.occupation),
        ],
        onEdit: (citizen) => _showEditDialog(context, citizen),
        onDelete: (citizen) => _confirmDelete(context, citizen.id),
        isLoading: controller.isLoading,
        emptyMessage: 'Aucun citoyen exemplaire enregistré',
      );
    });
  }

  void _showAddDialog(BuildContext context) {
    FormDialog.show(
      context: context,
      title: 'Ajouter un citoyen exemplaire',
      fields: [
        FormFieldConfig(
          key: 'name',
          label: 'Nom complet',
          hint: 'Ex: Marie Mukendi',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'occupation',
          label: 'Profession',
          hint: 'Ex: Médecin',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'quote',
          label: 'Citation',
          type: FormFieldType.multiline,
          hint: 'Une phrase inspirante...',
        ),
        FormFieldConfig(
          key: 'photoUrl',
          label: 'URL de la photo',
          hint: 'https://exemple.com/photo.jpg',
        ),
      ],
      onSubmit: (values) => controller.addExemplaryCitizen(
        ExemplaryCitizen(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: values['name'],
          occupation: values['occupation'],
          quote: values['quote'],
          photoUrl: values['photoUrl'],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, ExemplaryCitizen citizen) {
    FormDialog.show(
      context: context,
      title: 'Modifier le citoyen exemplaire',
      fields: [
        FormFieldConfig(
          key: 'name',
          label: 'Nom complet',
          defaultValue: citizen.name,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'occupation',
          label: 'Profession',
          defaultValue: citizen.occupation,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'quote',
          label: 'Citation',
          type: FormFieldType.multiline,
          defaultValue: citizen.quote,
        ),
        FormFieldConfig(
          key: 'photoUrl',
          label: 'URL de la photo',
          defaultValue: citizen.photoUrl,
        ),
      ],
      isEditing: true,
      onSubmit: (values) => controller.updateExemplaryCitizen(
        citizen.copyWith(
          name: values['name'],
          occupation: values['occupation'],
          quote: values['quote'],
          photoUrl: values['photoUrl'],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce citoyen exemplaire ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteExemplaryCitizen(id);
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
