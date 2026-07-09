// lib/presentation/mon_pays/admin/sections/manage_laws.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../admin_controller.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/form_dialog.dart';
import '../../../models/law_model.dart';

class ManageLaws extends StatelessWidget {
  final AdminController controller;

  const ManageLaws({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return DataTableWidget<Law>(
        items: controller.laws,
        columns: const [
          DataColumnConfig(label: 'Titre'),
          DataColumnConfig(label: 'Contenu'),
        ],
        cellBuilder: (law) => [
          Text(
            law.title,
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            law.content ?? '-',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        onEdit: (law) => _showEditDialog(context, law),
        onDelete: (law) => _confirmDelete(context, law.id),
        isLoading: controller.isLoading,
        emptyMessage: 'Aucune loi enregistrée',
      );
    });
  }

  void _showAddDialog(BuildContext context) {
    FormDialog.show(
      context: context,
      title: 'Ajouter une loi',
      fields: [
        FormFieldConfig(
          key: 'title',
          label: 'Titre de la loi',
          hint: 'Ex: Constitution',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'content',
          label: 'Contenu',
          type: FormFieldType.multiline,
          hint: 'Contenu détaillé de la loi',
        ),
        FormFieldConfig(
          key: 'category',
          label: 'Catégorie',
          type: FormFieldType.dropdown,
          dropdownItems: [
            'Constitution',
            'Institutions',
            'Symboles Nationaux',
            'Codes et Lois',
            'Droits du Citoyen',
            'Devoirs du Citoyen',
            'Justice',
            'Administration',
          ],
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
      ],
      onSubmit: (values) => controller.addLaw(
        Law(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: values['title'],
          content: values['content'],
          category: values['category'],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Law law) {
    FormDialog.show(
      context: context,
      title: 'Modifier la loi',
      fields: [
        FormFieldConfig(
          key: 'title',
          label: 'Titre de la loi',
          defaultValue: law.title,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'content',
          label: 'Contenu',
          type: FormFieldType.multiline,
          defaultValue: law.content,
        ),
        FormFieldConfig(
          key: 'category',
          label: 'Catégorie',
          type: FormFieldType.dropdown,
          dropdownItems: [
            'Constitution',
            'Institutions',
            'Symboles Nationaux',
            'Codes et Lois',
            'Droits du Citoyen',
            'Devoirs du Citoyen',
            'Justice',
            'Administration',
          ],
          defaultValue: law.category,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
      ],
      isEditing: true,
      onSubmit: (values) => controller.updateLaw(
        law.copyWith(
          title: values['title'],
          content: values['content'],
          category: values['category'],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette loi ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteLaw(id);
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
