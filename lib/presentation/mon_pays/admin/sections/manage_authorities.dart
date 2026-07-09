// lib/presentation/mon_pays/admin/sections/manage_authorities.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../admin_controller.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/form_dialog.dart';
import '../../../models/authority_model.dart';

class ManageAuthorities extends StatelessWidget {
  final AdminController controller;

  const ManageAuthorities({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return DataTableWidget<Authority>(
        items: controller.authorities,
        columns: const [
          DataColumnConfig(label: 'Nom'),
          DataColumnConfig(label: 'Fonction'),
          DataColumnConfig(label: 'Parti'),
        ],
        cellBuilder: (authority) => [
          Text(
            authority.name,
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(authority.title),
          Text(authority.party ?? '-'),
        ],
        onEdit: (authority) => _showEditDialog(context, authority),
        onDelete: (authority) => _confirmDelete(context, authority.id),
        isLoading: controller.isLoading,
        emptyMessage: 'Aucune autorité enregistrée',
      );
    });
  }

  void _showAddDialog(BuildContext context) {
    FormDialog.show(
      context: context,
      title: 'Ajouter une autorité',
      fields: [
        FormFieldConfig(
          key: 'name',
          label: 'Nom complet',
          hint: 'Ex: Félix-A. Tshisekedi',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'title',
          label: 'Fonction',
          hint: 'Ex: Président de la République',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'party',
          label: 'Parti politique',
          hint: 'Ex: UDPS',
        ),
        FormFieldConfig(
          key: 'biography',
          label: 'Biographie',
          type: FormFieldType.multiline,
          hint: 'Courte biographie...',
        ),
        FormFieldConfig(
          key: 'photoUrl',
          label: 'URL de la photo',
          hint: 'https://exemple.com/photo.jpg',
        ),
      ],
      onSubmit: (values) => controller.addAuthority(
        Authority(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: values['name'],
          title: values['title'],
          party: values['party'],
          biography: values['biography'],
          photoUrl: values['photoUrl'],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Authority authority) {
    FormDialog.show(
      context: context,
      title: 'Modifier l\'autorité',
      fields: [
        FormFieldConfig(
          key: 'name',
          label: 'Nom complet',
          defaultValue: authority.name,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'title',
          label: 'Fonction',
          defaultValue: authority.title,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'party',
          label: 'Parti politique',
          defaultValue: authority.party,
        ),
        FormFieldConfig(
          key: 'biography',
          label: 'Biographie',
          type: FormFieldType.multiline,
          defaultValue: authority.biography,
        ),
        FormFieldConfig(
          key: 'photoUrl',
          label: 'URL de la photo',
          defaultValue: authority.photoUrl,
        ),
      ],
      isEditing: true,
      onSubmit: (values) => controller.updateAuthority(
        authority.copyWith(
          name: values['name'],
          title: values['title'],
          party: values['party'],
          biography: values['biography'],
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
        content: const Text('Voulez-vous vraiment supprimer cette autorité ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteAuthority(id); 
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
