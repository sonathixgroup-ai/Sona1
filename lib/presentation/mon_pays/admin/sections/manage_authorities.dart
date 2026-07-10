// lib/presentation/mon_pays/admin/sections/manage_authorities.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_provider.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/form_dialog.dart';
import '../../models/authority_model.dart';
import '../../enums/authority_type.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ManageAuthorities extends ConsumerWidget {
  const ManageAuthorities({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminControllerProvider);
    final controller = ref.read(adminControllerProvider.notifier);

    return DataTableWidget<Authority>(
      items: state.authorities,
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
      onEdit: (authority) => _showEditDialog(context, authority, controller),
      onDelete: (authority) => _confirmDelete(context, authority.id, controller),
      isLoading: state.isLoading,
      emptyMessage: 'Aucune autorité enregistrée',
    );
  }

  void _showAddDialog(BuildContext context, AdminController controller) {
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
          key: 'type',
          label: 'Type',
          type: FormFieldType.dropdown,
          dropdownItems: AuthorityType.values.map((e) => e.toString().split('.').last).toList(),
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
        FormFieldConfig(
          key: 'startDate',
          label: 'Date de début',
          type: FormFieldType.date,
        ),
        FormFieldConfig(
          key: 'endDate',
          label: 'Date de fin',
          type: FormFieldType.date,
        ),
      ],
      onSubmit: (values) => controller.addAuthority(
        Authority(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: values['name'],
          title: values['title'],
          type: AuthorityType.values.firstWhere(
            (e) => e.toString().split('.').last == values['type'],
          ),
          party: values['party'],
          biography: values['biography'],
          photoUrl: values['photoUrl'],
          startDate: values['startDate'],
          endDate: values['endDate'],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Authority authority, AdminController controller) {
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
          key: 'type',
          label: 'Type',
          type: FormFieldType.dropdown,
          dropdownItems: AuthorityType.values.map((e) => e.toString().split('.').last).toList(),
          defaultValue: authority.type.toString().split('.').last,
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
        FormFieldConfig(
          key: 'startDate',
          label: 'Date de début',
          type: FormFieldType.date,
          defaultValue: authority.startDate,
        ),
        FormFieldConfig(
          key: 'endDate',
          label: 'Date de fin',
          type: FormFieldType.date,
          defaultValue: authority.endDate,
        ),
      ],
      isEditing: true,
      onSubmit: (values) => controller.updateAuthority(
        authority.copyWith(
          name: values['name'],
          title: values['title'],
          type: AuthorityType.values.firstWhere(
            (e) => e.toString().split('.').last == values['type'],
          ),
          party: values['party'],
          biography: values['biography'],
          photoUrl: values['photoUrl'],
          startDate: values['startDate'],
          endDate: values['endDate'],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, AdminController controller) {
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
