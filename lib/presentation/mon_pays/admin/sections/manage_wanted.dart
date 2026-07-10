// lib/presentation/mon_pays/admin/sections/manage_wanted.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_provider.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/form_dialog.dart';
import '../../models/wanted_person_model.dart';
import '../../enums/wanted_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ManageWanted extends ConsumerWidget {
  const ManageWanted({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminControllerProvider);
    final controller = ref.read(adminControllerProvider.notifier);

    return DataTableWidget<WantedPerson>(
      items: state.wantedPersons,
      columns: const [
        DataColumnConfig(label: 'Nom'),
        DataColumnConfig(label: 'Statut'),
        DataColumnConfig(label: 'Province'),
        DataColumnConfig(label: 'Niveau'),
      ],
      cellBuilder: (person) => [
        Text(
          person.name,
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: person.status == WantedStatus.dangerous
                ? AppColors.primaryRed
                : Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            person.status.toString().split('.').last,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(person.province),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getAlertColor(person.alertLevel),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${person.alertLevel}',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
      onEdit: (person) => _showEditDialog(context, person, controller),
      onDelete: (person) => _confirmDelete(context, person.id, controller),
      isLoading: state.isLoading,
      emptyMessage: 'Aucune personne recherchée enregistrée',
    );
  }

  Color _getAlertColor(int level) {
    if (level >= 4) return Colors.red;
    if (level >= 2) return Colors.orange;
    return Colors.yellow.shade700;
  }

  void _showAddDialog(BuildContext context, AdminController controller) {
    FormDialog.show(
      context: context,
      title: 'Ajouter une personne recherchée',
      fields: [
        FormFieldConfig(
          key: 'name',
          label: 'Nom complet',
          hint: 'Ex: Jean Dupont',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'alias',
          label: 'Alias (surnom)',
          hint: 'Ex: "Le Jaguar"',
        ),
        FormFieldConfig(
          key: 'status',
          label: 'Statut',
          type: FormFieldType.dropdown,
          dropdownItems: WantedStatus.values.map((e) => e.toString().split('.').last).toList(),
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'reason',
          label: 'Motif',
          hint: 'Motif de la recherche',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'province',
          label: 'Province',
          hint: 'Ex: Kinshasa',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'date',
          label: 'Date de signalement',
          type: FormFieldType.date,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'alertLevel',
          label: 'Niveau d\'alerte (1-5)',
          type: FormFieldType.number,
          hint: 'Ex: 3',
          validator: (v) {
            if (v == null || v.isEmpty) return 'Requis';
            final level = int.tryParse(v);
            if (level == null || level < 1 || level > 5) {
              return 'Doit être entre 1 et 5';
            }
            return null;
          },
        ),
        FormFieldConfig(
          key: 'photoUrl',
          label: 'URL de la photo',
          hint: 'https://exemple.com/photo.jpg',
        ),
        FormFieldConfig(
          key: 'description',
          label: 'Description',
          type: FormFieldType.multiline,
          hint: 'Description détaillée',
        ),
      ],
      onSubmit: (values) => controller.addWantedPerson(
        WantedPerson(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: values['name'],
          alias: values['alias'],
          status: WantedStatus.values.firstWhere(
            (e) => e.toString().split('.').last == values['status'],
          ),
          reason: values['reason'],
          province: values['province'],
          date: values['date'],
          alertLevel: int.parse(values['alertLevel']),
          photoUrl: values['photoUrl'],
          description: values['description'],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WantedPerson person, AdminController controller) {
    FormDialog.show(
      context: context,
      title: 'Modifier la personne recherchée',
      fields: [
        FormFieldConfig(
          key: 'name',
          label: 'Nom complet',
          defaultValue: person.name,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'alias',
          label: 'Alias (surnom)',
          defaultValue: person.alias,
        ),
        FormFieldConfig(
          key: 'status',
          label: 'Statut',
          type: FormFieldType.dropdown,
          dropdownItems: WantedStatus.values.map((e) => e.toString().split('.').last).toList(),
          defaultValue: person.status.toString().split('.').last,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'reason',
          label: 'Motif',
          defaultValue: person.reason,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'province',
          label: 'Province',
          defaultValue: person.province,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'date',
          label: 'Date de signalement',
          type: FormFieldType.date,
          defaultValue: person.date,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'alertLevel',
          label: 'Niveau d\'alerte (1-5)',
          type: FormFieldType.number,
          defaultValue: person.alertLevel.toString(),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Requis';
            final level = int.tryParse(v);
            if (level == null || level < 1 || level > 5) {
              return 'Doit être entre 1 et 5';
            }
            return null;
          },
        ),
        FormFieldConfig(
          key: 'photoUrl',
          label: 'URL de la photo',
          defaultValue: person.photoUrl,
        ),
        FormFieldConfig(
          key: 'description',
          label: 'Description',
          type: FormFieldType.multiline,
          defaultValue: person.description,
        ),
      ],
      isEditing: true,
      onSubmit: (values) => controller.updateWantedPerson(
        person.copyWith(
          name: values['name'],
          alias: values['alias'],
          status: WantedStatus.values.firstWhere(
            (e) => e.toString().split('.').last == values['status'],
          ),
          reason: values['reason'],
          province: values['province'],
          date: values['date'],
          alertLevel: int.parse(values['alertLevel']),
          photoUrl: values['photoUrl'],
          description: values['description'],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, AdminController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette personne ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteWantedPerson(id);
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
