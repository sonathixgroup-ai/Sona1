// lib/presentation/mon_pays/admin/sections/manage_news.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_provider.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/form_dialog.dart';
import '../../models/news_model.dart';
import '../../enums/news_type.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ManageNews extends ConsumerWidget {
  const ManageNews({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminControllerProvider);
    final controller = ref.read(adminControllerProvider.notifier);

    return DataTableWidget<News>(
      items: state.news,
      columns: const [
        DataColumnConfig(label: 'Titre'),
        DataColumnConfig(label: 'Catégorie'),
        DataColumnConfig(label: 'Date'),
      ],
      cellBuilder: (news) => [
        Text(
          news.title,
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _getCategoryColor(news.type),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getCategoryLabel(news.type),
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(news.date),
      ],
      onEdit: (news) => _showEditDialog(context, news, controller),
      onDelete: (news) => _confirmDelete(context, news.id, controller),
      isLoading: state.isLoading,
      emptyMessage: 'Aucune actualité enregistrée',
    );
  }

  Color _getCategoryColor(NewsType type) {
    switch (type) {
      case NewsType.official:
        return AppColors.primaryRed;
      case NewsType.communique:
        return AppColors.primaryBlue;
      case NewsType.national:
        return Colors.orange;
      case NewsType.international:
        return Colors.green;
    }
  }

  String _getCategoryLabel(NewsType type) {
    switch (type) {
      case NewsType.official:
        return 'OFFICIEL';
      case NewsType.communique:
        return 'COMMUNIQUÉ';
      case NewsType.national:
        return 'NATIONAL';
      case NewsType.international:
        return 'INTERNATIONAL';
    }
  }

  void _showAddDialog(BuildContext context, AdminController controller) {
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
          key: 'type',
          label: 'Catégorie',
          type: FormFieldType.dropdown,
          dropdownItems: NewsType.values.map((e) => e.toString().split('.').last).toList(),
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
        FormFieldConfig(
          key: 'imageUrl',
          label: 'URL de l\'image',
          hint: 'https://exemple.com/image.jpg',
        ),
        FormFieldConfig(
          key: 'author',
          label: 'Auteur',
          hint: 'Nom de l\'auteur',
        ),
      ],
      onSubmit: (values) => controller.addNews(
        News(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: values['title'],
          type: NewsType.values.firstWhere(
            (e) => e.toString().split('.').last == values['type'],
          ),
          date: values['date'],
          content: values['content'],
          imageUrl: values['imageUrl'],
          author: values['author'],
          views: 0,
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, News news, AdminController controller) {
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
          key: 'type',
          label: 'Catégorie',
          type: FormFieldType.dropdown,
          dropdownItems: NewsType.values.map((e) => e.toString().split('.').last).toList(),
          defaultValue: news.type.toString().split('.').last,
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
        FormFieldConfig(
          key: 'imageUrl',
          label: 'URL de l\'image',
          defaultValue: news.imageUrl,
        ),
        FormFieldConfig(
          key: 'author',
          label: 'Auteur',
          defaultValue: news.author,
        ),
      ],
      isEditing: true,
      onSubmit: (values) => controller.updateNews(
        news.copyWith(
          title: values['title'],
          type: NewsType.values.firstWhere(
            (e) => e.toString().split('.').last == values['type'],
          ),
          date: values['date'],
          content: values['content'],
          imageUrl: values['imageUrl'],
          author: values['author'],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, AdminController controller) {
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
