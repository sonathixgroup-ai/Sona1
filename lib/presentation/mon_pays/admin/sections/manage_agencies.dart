// lib/presentation/mon_pays/admin/sections/manage_agencies.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_provider.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/form_dialog.dart';
import '../../models/agency_model.dart';
import '../../enums/agency_type.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ManageAgencies extends ConsumerWidget {
  const ManageAgencies({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminControllerProvider);
    final controller = ref.read(adminControllerProvider.notifier);

    return DataTableWidget<Agency>(
      items: state.agencies,
      columns: const [
        DataColumnConfig(label: 'Nom'),
        DataColumnConfig(label: 'Type'),
      ],
      cellBuilder: (agency) => [
        Text(
          agency.name,
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(agency.type.toString().split('.').last),
      ],
      onEdit: (agency) => _showEditDialog(context, agency, controller),
      onDelete: (agency) => _confirmDelete(context, agency.id, controller),
      isLoading: state.isLoading,
      emptyMessage: 'Aucune agence enregistrée',
    );
  }

  void _showAddDialog(BuildContext context, AdminController controller) {
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
          key: 'type',
          label: 'Type',
          type: FormFieldType.dropdown,
          dropdownItems: AgencyType.values.map((e) => e.toString().split('.').last).toList(),
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
        FormFieldConfig(
          key: 'website',
          label: 'Site web',
          hint: 'https://exemple.com',
        ),
        FormFieldConfig(
          key: 'email',
          label: 'Email',
          hint: 'contact@exemple.com',
        ),
        FormFieldConfig(
          key: 'phone',
          label: 'Téléphone',
          hint: '+243 000 000 000',
        ),
      ],
      onSubmit: (values) => controller.addAgency(
        Agency(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: values['name'],
          type: AgencyType.values.firstWhere(
            (e) => e.toString().split('.').last == values['type'],
          ),
          description: values['description'],
          logoUrl: values['logoUrl'],
          website: values['website'],
          email: values['email'],
          phone: values['phone'],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Agency agency, AdminController controller) {
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
          key: 'type',
          label: 'Type',
          type: FormFieldType.dropdown,
          dropdownItems: AgencyType.values.map((e) => e.toString().split('.').last).toList(),
          defaultValue: agency.type.toString().split('.').last,
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
        FormFieldConfig(
          key: 'website',
          label: 'Site web',
          defaultValue: agency.website,
        ),
        FormFieldConfig(
          key: 'email',
          label: 'Email',
          defaultValue: agency.email,
        ),
        FormFieldConfig(
          key: 'phone',
          label: 'Téléphone',
          defaultValue: agency.phone,
        ),
      ],
      isEditing: true,
      onSubmit: (values) => controller.updateAgency(
        agency.copyWith(
          name: values['name'],
          type: AgencyType.values.firstWhere(
            (e) => e.toString().split('.').last == values['type'],
          ),
          description: values['description'],
          logoUrl: values['logoUrl'],
          website: values['website'],
          email: values['email'],
          phone: values['phone'],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, AdminController controller) {
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
