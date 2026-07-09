// lib/presentation/mon_pays/admin/sections/manage_wanted.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../admin_controller.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/form_dialog.dart';
import '../../../models/wanted_person_model.dart';

class ManageWanted extends StatelessWidget {
  final AdminController controller;

  const ManageWanted({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return DataTableWidget<WantedPerson>(
        items: controller.wantedPersons,
        columns: const [
          DataColumnConfig(label: 'Nom'),
          DataColumnConfig(label: 'Alias'),
          DataColumnConfig(label: 'Type'),
          DataColumnConfig(label: 'Province'),
        ],
        cellBuilder: (person) => [
          Text(
            person.name,
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(person.alias ?? '-'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: person.type == WantedType.dangerous
                  ? AppColors.primaryRed
                  : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              person.type == WantedType.dangerous ? '🚨' : '🔍',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
          Text(person.province),
        ],
        onEdit: (person) => _showEditDialog(context, person),
        onDelete: (person) => _confirmDelete(context, person.id),
        isLoading: controller.isLoading,
        emptyMessage: 'Aucune personne recherchée enregistrée',
      );
    });
  }

  void _showAddDialog(BuildContext context) {
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
          key: 'type',
          label: 'Type',
          type: FormFieldType.dropdown,
          dropdownItems: ['dangerous', 'missing'],
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
      ],
      onSubmit: (values) => controller.addWantedPerson(
        WantedPerson(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: values['name'],
          alias: values['alias'],
          type: values['type'] == 'dangerous' ? WantedType.dangerous : WantedType.missing,
          reason: values['reason'],
          province: values['province'],
          date: values['date'],
          alertLevel: int.parse(values['alertLevel']),
          photoUrl: values['photoUrl'],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WantedPerson person) {
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
          key: 'type',
          label: 'Type',
          type: FormFieldType.dropdown,
          dropdownItems: ['dangerous', 'missing'],
          defaultValue: person.type == WantedType.dangerous ? 'dangerous' : 'missing',
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
      ],
      isEditing: true,
      onSubmit: (values) => controller.updateWantedPerson(
        person.copyWith(
          name: values['name'],
          alias: values['alias'],
          type: values['type'] == 'dangerous' ? WantedType.dangerous : WantedType.missing,
          reason: values['reason'],
          province: values['province'],
          date: values['date'],
          alertLevel: int.parse(values['alertLevel']),
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
