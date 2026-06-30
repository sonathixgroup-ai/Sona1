// presentation/thix_sante/patient/details/patient_chat_new_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PatientChatNewPage extends StatefulWidget {
  const PatientChatNewPage({super.key});

  @override
  State<PatientChatNewPage> createState() => _PatientChatNewPageState();
}

class _PatientChatNewPageState extends State<PatientChatNewPage> {
  final List<Map<String, String>> _contacts = [
    {'id': 'doc1', 'name': 'Dr. Dupont', 'role': 'Médecin', 'icon': '👨‍⚕️'},
    {'id': 'doc2', 'name': 'Dr. Martin', 'role': 'Cardiologue', 'icon': '👨‍⚕️'},
    {'id': 'pharm1', 'name': 'Pharmacie Centrale', 'role': 'Pharmacie', 'icon': '🏪'},
  ];

  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _contacts.where((c) =>
        c['name']!.toLowerCase().contains(_filter.toLowerCase()) ||
        c['role']!.toLowerCase().contains(_filter.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau message')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _filter = value),
              decoration: const InputDecoration(
                hintText: 'Rechercher un contact...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final contact = filtered[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: contact['role'] == 'Pharmacie' ? Colors.green : Colors.blue,
                      child: Text(contact['icon']!, style: const TextStyle(fontSize: 20)),
                    ),
                    title: Text(contact['name']!),
                    subtitle: Text(contact['role']!),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      context.push('/sante/patient/chat/${contact['id']}',
                          extra: contact['name']);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
