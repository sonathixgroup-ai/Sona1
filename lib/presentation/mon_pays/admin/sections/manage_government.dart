// lib/presentation/mon_pays/admin/sections/manage_government.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_provider.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/form_dialog.dart';
import '../../models/government_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ManageGovernment extends ConsumerWidget {
  const ManageGovernment({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminControllerProvider);
    final controller = ref.read(adminControllerProvider.notifier);

    return DataTableWidget<Government>(
      items: state.governments,
      columns: const [
        DataColumnConfig(label: 'Nom'),
        DataColumnConfig(label: 'Type'),
      ],
      cellBuilder: (gov) => [
        Text(
          gov.name,
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(gov.type ?? '-'),
      ],
      onEdit: (gov) => _showEditDialog(context, gov, controller),
      onDelete: (gov) => _confirmDelete(context, gov.id, controller),
      isLoading: state.isLoading,
      emptyMessage: 'Aucune entrée gouvernementale enregistrée',
    );
  }

  void _showAddDialog(BuildContext context, AdminController controller) {
    FormDialog.show(
      context: context,
      title: 'Ajouter une entrée gouvernementale',
      fields: [
        FormFieldConfig(
          key: 'name',
          label: 'Nom',
          hint: 'Ex: Gouvernement central',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'description',
          label: 'Description',
          type: FormFieldType.multiline,
          hint: 'Description...',
        ),
        FormFieldConfig(
          key: 'type',
          label: 'Type',
          hint: 'central, provincial, local',
        ),
        FormFieldConfig(
          key: 'logoUrl',
          label: 'URL du logo',
          hint: 'https://exemple.com/logo.png',
        ),
        FormFieldConfig(
          key: 'website',
          label: 'Site web',
          hint: 'https://exemple.com',
        ),
      ],
      onSubmit: (values) => controller.addGovernment(
        Government(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: values['name'],
          description: values['description'],
          type: values['type'],
          logoUrl: values['logoUrl'],
          website: values['website'],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Government gov, AdminController controller) {
    FormDialog.show(
      context: context,
      title: 'Modifier l\'entrée gouvernementale',
      fields: [
        FormFieldConfig(
          key: 'name',
          label: 'Nom',
          defaultValue: gov.name,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'description',
          label: 'Description',
          type: FormFieldType.multiline,
          defaultValue: gov.description,
        ),
        FormFieldConfig(
          key: 'type',
          label: 'Type',
          defaultValue: gov.type,
        ),
        FormFieldConfig(
          key: 'logoUrl',
          label: 'URL du logo',
          defaultValue: gov.logoUrl,
        ),
        FormFieldConfig(
          key: 'website',
          label: 'Site web',
          defaultValue: gov.website,
        ),
      ],
      isEditing: true,
      onSubmit: (values) => controller.updateGovernment(
        gov.copyWith(
          name: values['name'],
          description: values['description'],
          type: values['type'],
          logoUrl: values['logoUrl'],
          website: values['website'],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, AdminController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette entrée ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteGovernment(id);
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
