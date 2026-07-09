// lib/presentation/mon_pays/admin/sections/manage_consultations.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../admin_controller.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/form_dialog.dart';
import '../../../models/consultation_model.dart';

class ManageConsultations extends StatelessWidget {
  final AdminController controller;

  const ManageConsultations({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return DataTableWidget<Consultation>(
        items: controller.consultations,
        columns: const [
          DataColumnConfig(label: 'Titre'),
          DataColumnConfig(label: 'Date début'),
          DataColumnConfig(label: 'Date fin'),
          DataColumnConfig(label: 'Statut'),
        ],
        cellBuilder: (consultation) => [
          Text(
            consultation.title,
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(consultation.startDate),
          Text(consultation.endDate),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: consultation.isActive ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              consultation.isActive ? 'Active' : 'Fermée',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        onEdit: (consultation) => _showEditDialog(context, consultation),
        onDelete: (consultation) => _confirmDelete(context, consultation.id),
        isLoading: controller.isLoading,
        emptyMessage: 'Aucune consultation enregistrée',
      );
    });
  }

  void _showAddDialog(BuildContext context) {
    FormDialog.show(
      context: context,
      title: 'Ajouter une consultation',
      fields: [
        FormFieldConfig(
          key: 'title',
          label: 'Titre',
          hint: 'Titre de la consultation',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'description',
          label: 'Description',
          type: FormFieldType.multiline,
          hint: 'Description détaillée',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'startDate',
          label: 'Date de début',
          type: FormFieldType.date,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'endDate',
          label: 'Date de fin',
          type: FormFieldType.date,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'isActive',
          label: 'Statut',
          type: FormFieldType.dropdown,
          dropdownItems: ['Active', 'Fermée'],
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'link',
          label: 'Lien de participation',
          hint: 'https://exemple.com/consultation',
        ),
      ],
      onSubmit: (values) => controller.addConsultation(
        Consultation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: values['title'],
          description: values['description'],
          startDate: values['startDate'],
          endDate: values['endDate'],
          isActive: values['isActive'] == 'Active',
          link: values['link'],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Consultation consultation) {
    FormDialog.show(
      context: context,
      title: 'Modifier la consultation',
      fields: [
        FormFieldConfig(
          key: 'title',
          label: 'Titre',
          defaultValue: consultation.title,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'description',
          label: 'Description',
          type: FormFieldType.multiline,
          defaultValue: consultation.description,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'startDate',
          label: 'Date de début',
          type: FormFieldType.date,
          defaultValue: consultation.startDate,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'endDate',
          label: 'Date de fin',
          type: FormFieldType.date,
          defaultValue: consultation.endDate,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'isActive',
          label: 'Statut',
          type: FormFieldType.dropdown,
          dropdownItems: ['Active', 'Fermée'],
          defaultValue: consultation.isActive ? 'Active' : 'Fermée',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'link',
          label: 'Lien de participation',
          defaultValue: consultation.link,
        ),
      ],
      isEditing: true,
      onSubmit: (values) => controller.updateConsultation(
        consultation.copyWith(
          title: values['title'],
          description: values['description'],
          startDate: values['startDate'],
          endDate: values['endDate'],
          isActive: values['isActive'] == 'Active',
          link: values['link'],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette consultation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteConsultation(id);
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
