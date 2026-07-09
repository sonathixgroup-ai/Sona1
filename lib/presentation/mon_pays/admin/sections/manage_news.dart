// lib/presentation/mon_pays/admin/sections/manage_news.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../admin_controller.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/form_dialog.dart';
import '../../../models/news_model.dart';

class ManageNews extends StatelessWidget {
  final AdminController controller;

  const ManageNews({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return DataTableWidget<News>(
        items: controller.news,
        columns: const [
          DataColumnConfig(label: 'Titre'),
          DataColumnConfig(label: 'Catégorie'),
          DataColumnConfig(label: 'Date'),
        ],
        cellBuilder: (news) => [
          Text(
            news.title,
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getCategoryColor(news.category),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              news.category,
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(news.date),
        ],
        onEdit: (news) => _showEditDialog(context, news),
        onDelete: (news) => _confirmDelete(context, news.id),
        isLoading: controller.isLoading,
        emptyMessage: 'Aucune actualité enregistrée',
      );
    });
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'OFFICIEL':
        return AppColors.primaryRed;
      case 'COMMUNIQUÉ':
        return AppColors.primaryBlue;
      case 'NATIONAL':
        return Colors.orange;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showAddDialog(BuildContext context) {
    FormDialog.show(
      context: context,
      title: 'Ajouter une actualité',
      fields: [
        FormFieldConfig(
          key: 'title',
          label: 'Titre',
          hint: 'Titre de l\'actualité',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'category',
          label: 'Catégorie',
          type: FormFieldType.dropdown,
          dropdownItems: ['OFFICIEL', 'COMMUNIQUÉ', 'NATIONAL'],
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'date',
          label: 'Date',
          type: FormFieldType.date,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'content',
          label: 'Contenu',
          type: FormFieldType.multiline,
          hint: 'Contenu détaillé de l\'actualité',
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
      ],
      onSubmit: (values) => controller.addNews(
        News(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: values['title'],
          category: values['category'],
          date: values['date'],
          content: values['content'],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, News news) {
    FormDialog.show(
      context: context,
      title: 'Modifier l\'actualité',
      fields: [
        FormFieldConfig(
          key: 'title',
          label: 'Titre',
          defaultValue: news.title,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'category',
          label: 'Catégorie',
          type: FormFieldType.dropdown,
          dropdownItems: ['OFFICIEL', 'COMMUNIQUÉ', 'NATIONAL'],
          defaultValue: news.category,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'date',
          label: 'Date',
          type: FormFieldType.date,
          defaultValue: news.date,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
        FormFieldConfig(
          key: 'content',
          label: 'Contenu',
          type: FormFieldType.multiline,
          defaultValue: news.content,
          validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        ),
      ],
      isEditing: true,
      onSubmit: (values) => controller.updateNews(
        news.copyWith(
          title: values['title'],
          category: values['category'],
          date: values['date'],
          content: values['content'],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette actualité ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteNews(id);
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
