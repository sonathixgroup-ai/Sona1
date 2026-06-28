import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workflow_rule_model.dart';
import '../../providers/automation_provider.dart';

class WorkflowRulesScreen extends ConsumerStatefulWidget {
  const WorkflowRulesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WorkflowRulesScreen> createState() =>
      _WorkflowRulesScreenState();
}

class _WorkflowRulesScreenState extends ConsumerState<WorkflowRulesScreen> {
  @override
  Widget build(BuildContext context) {
    final workflowRules = ref.watch(workflowRulesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Flux de Travail',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF5A67D8)),
            onPressed: () => _showWorkflowDialog(context, ref),
          ),
        ],
      ),
      body: workflowRules.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.workflow, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune r\u00e8gle de flux',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            )
          : ReorderableListView(
              padding: const EdgeInsets.all(16),
              children: workflowRules
                  .map((rule) => Container(
                        key: ValueKey(rule.id),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.drag_handle,
                            color: Colors.grey,
                          ),
                          title: Text(
                            rule.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Condition: ${rule.trigger.type.name}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                              Text(
                                'Actions: ${rule.actions.length}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: Text(rule.isEnabled
                                    ? 'D\u00e9sactiver'
                                    : 'Activer'),
                                onTap: () => ref
                                    .read(workflowRulesProvider.notifier)
                                    .toggleWorkflowRule(rule.id),
                              ),
                              PopupMenuItem(
                                child: const Text('Modifier'),
                                onTap: () =>
                                    _showWorkflowDialog(context, ref, rule),
                              ),
                              PopupMenuItem(
                                child: const Text('Supprimer'),
                                onTap: () => ref
                                    .read(workflowRulesProvider.notifier)
                                    .deleteWorkflowRule(rule.id),
                              ),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
              onReorder: (oldIndex, newIndex) => ref
                  .read(workflowRulesProvider.notifier)
                  .reorderRules(oldIndex, newIndex),
            ),
    );
  }

  void _showWorkflowDialog(BuildContext context, WidgetRef ref,
      [WorkflowRule? existingRule]) {
    final nameController =
        TextEditingController(text: existingRule?.name ?? '');
    final descriptionController =
        TextEditingController(text: existingRule?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existingRule != null
              ? 'Modifier la r\u00e8gle'
              : 'Cr\u00e9er une r\u00e8gle de flux'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la r\u00e8gle',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text(
                  'D\u00e9clencheur:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                DropdownButtonFormField<WorkflowTriggerType>(
                  items: WorkflowTriggerType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.name),
                          ))
                      .toList(),
                  onChanged: (value) {},
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Actions:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                ...WorkflowActionType.values
                    .take(3)
                    .map((action) => CheckboxListTile(
                          value: false,
                          onChanged: (value) {},
                          title: Text(action.name),
                        ))
                    .toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
