// lib/presentation/mon_pays/admin/sections/manage_citizens.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_provider.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/form_dialog.dart';
import '../../models/citizen_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ManageCitizens extends ConsumerWidget {
  const ManageCitizens({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminControllerProvider);
    final controller = ref.read(adminControllerProvider.notifier);

    return DataTableWidget<ExemplaryCitizen>(
      items: state.exemplaryCitizens,
      columns: const [
        DataColumnConfig(label: 'Nom'),
        DataColumnConfig(label: 'Profession'),
        DataColumnConfig(label: 'Score'),
      ],
      cellBuilder: (citizen) => [
        Text(
          citizen.name,
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(citizen.occupation),
        Text(citizen.score?.toString() ?? '-'),
      ],
      onEdit: (citizen) => _showEditDialog(context, citizen, controller),
      onDelete: (citizen) => _confirmDelete(context, citizen.id, controller),
      isLoading: state.isLoading,
      emptyMessage: 'Aucun citoyen exemplaire enregistré',
    );
  }

  void _showAddDialog(BuildContext context, AdminController controller) {
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
        FormFieldConfig(
          key: 'city',
          label: 'Ville',
          hint: 'Ex: Kinshasa',
        ),
        FormFieldConfig(
          key: 'score',
          label: 'Score de confiance',
          type: FormFieldType.number,
          hint: 'Ex: 98',
        ),
      ],
      onSubmit: (values) => controller.addExemplaryCitizen(
        ExemplaryCitizen(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: values['name'],
          occupation: values['occupation'],
          quote: values['quote'],
          photoUrl: values['photoUrl'],
          city: values['city'],
          score: values['score'] != null ? int.tryParse(values['score']) : null,
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, ExemplaryCitizen citizen, AdminController controller) {
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
        FormFieldConfig(
          key: 'city',
          label: 'Ville',
          defaultValue: citizen.city,
        ),
        FormFieldConfig(
          key: 'score',
          label: 'Score de confiance',
          type: FormFieldType.number,
          defaultValue: citizen.score?.toString(),
        ),
      ],
      isEditing: true,
      onSubmit: (values) => controller.updateExemplaryCitizen(
        citizen.copyWith(
          name: values['name'],
          occupation: values['occupation'],
          quote: values['quote'],
          photoUrl: values['photoUrl'],
          city: values['city'],
          score: values['score'] != null ? int.tryParse(values['score']) : null,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, AdminController controller) {
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
