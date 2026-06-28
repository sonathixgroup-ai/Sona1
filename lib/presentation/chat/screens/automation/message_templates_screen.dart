import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/message_template_model.dart';
import '../../providers/automation_provider.dart';

class MessageTemplatesScreen extends ConsumerStatefulWidget {
  const MessageTemplatesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MessageTemplatesScreen> createState() =>
      _MessageTemplatesScreenState();
}

class _MessageTemplatesScreenState extends ConsumerState<MessageTemplatesScreen> {
  String _selectedCategory = 'Tous';
  final categories = ['Tous', 'Support', 'Ventes', 'Personnel', 'Professionnel'];

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(messageTemplatesProvider);
    final filteredTemplates = _selectedCategory == 'Tous'
        ? templates
        : templates.where((t) => t.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mod\u00e8les de Messages',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF5A67D8)),
            onPressed: () => _showTemplateDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: categories
                  .map((category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            setState(() => _selectedCategory = category);
                          },
                          selectedColor: const Color(0xFF5A67D8),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Templates list
          Expanded(
            child: filteredTemplates.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined,
                            size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun mod\u00e8le',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTemplates.length,
                    itemBuilder: (context, index) {
                      final template = filteredTemplates[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: IconButton(
                            icon: Icon(
                              template.isFavorite
                                  ? Icons.star
                                  : Icons.star_outline,
                              color: template.isFavorite
                                  ? Colors.orange
                                  : Colors.grey,
                            ),
                            onPressed: () => ref
                                .read(messageTemplatesProvider.notifier)
                                .toggleFavorite(template.id),
                          ),
                          title: Text(
                            template.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                template.content.length > 50
                                    ? '${template.content.substring(0, 50)}...'
                                    : template.content,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Utilis\u00e9 ${template.useCount} fois',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: const Text('Copier'),
                                onTap: () {
                                  ref
                                      .read(messageTemplatesProvider.notifier)
                                      .incrementUseCount(template.id);
                                },
                              ),
                              PopupMenuItem(
                                child: const Text('Modifier'),
                                onTap: () => _showTemplateDialog(
                                    context, ref, template),
                              ),
                              PopupMenuItem(
                                child: const Text('Supprimer'),
                                onTap: () => ref
                                    .read(messageTemplatesProvider.notifier)
                                    .deleteTemplate(template.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showTemplateDialog(BuildContext context, WidgetRef ref,
      [MessageTemplate? existingTemplate]) {
    final nameController =
        TextEditingController(text: existingTemplate?.name ?? '');
    final contentController =
        TextEditingController(text: existingTemplate?.content ?? '');
    String? selectedCategory = existingTemplate?.category;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existingTemplate != null
              ? 'Modifier le mod\u00e8le'
              : 'Cr\u00e9er un mod\u00e8le'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du mod\u00e8le',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Contenu',
                    border: OutlineInputBorder(),
                    hintText: 'Utilisez {variable} pour les espaces r\u00e9s\u00e9rv\u00e9s',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Aucune')),
                    ...[
                      'Support',
                      'Ventes',
                      'Personnel',
                      'Professionnel'
                    ]
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                  ],
                  onChanged: (value) => setState(() => selectedCategory = value),
                  decoration: const InputDecoration(
                    labelText: 'Cat\u00e9gorie',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                if (existingTemplate != null) {
                  ref
                      .read(messageTemplatesProvider.notifier)
                      .updateTemplate(
                        existingTemplate.id,
                        existingTemplate.copyWith(
                          name: nameController.text,
                          content: contentController.text,
                          category: selectedCategory,
                        ),
                      );
                } else {
                  ref.read(messageTemplatesProvider.notifier).addTemplate(
                        MessageTemplate(
                          id: DateTime.now().toString(),
                          userId: '',
                          name: nameController.text,
                          content: contentController.text,
                          category: selectedCategory,
                          createdAt: DateTime.now(),
                        ),
                      );
                }
                Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
