// presentation/thix_sante/pharmacy/pharmacy_connect_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/health_bottom_nav.dart';

class PharmacyConnectPage extends StatefulWidget {
  const PharmacyConnectPage({super.key});

  @override
  State<PharmacyConnectPage> createState() => _PharmacyConnectPageState();
}

class _PharmacyConnectPageState extends State<PharmacyConnectPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _messages = [
    {
      'id': 'm1',
      'sender': 'Dr. Dupont',
      'role': 'Doctor',
      'lastMessage': 'Confirmez-vous la disponibilité ?',
      'date': 'Aujourd\'hui',
      'unread': true,
    },
    {
      'id': 'm2',
      'sender': 'Michel L.',
      'role': 'Patient',
      'lastMessage': 'Merci pour la préparation.',
      'date': 'Hier',
      'unread': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat), text: 'Messagerie'),
            Tab(icon: Icon(Icons.store), text: 'Profil pharmacie'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MessagingTab(messages: _messages),
          const _PharmacyProfileTab(),
        ],
      ),
      bottomNavigationBar: HealthBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            context.go('/sante');
          } else if (index == 2) {
            _showQuickAction(context);
          } else if (index == 3) {
            context.go('/sante/pharmacy/connect');
          } else if (index == 4) {
            context.go('/sante/pharmacy/profile');
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            context.push('/sante/pharmacy/chat/new');
          } else {
            // Éditer profil
          }
        },
        child: Icon(_tabController.index == 0 ? Icons.edit : Icons.settings),
      ),
    );
  }

  void _showQuickAction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.add_shopping_cart, color: Colors.blue),
              title: const Text('Nouvelle commande'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/pharmacy/order/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.verified, color: Colors.green),
              title: const Text('Valider ordonnance'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/pharmacy/prescription/p1');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ----- Onglet Messagerie -----
class _MessagingTab extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  const _MessagingTab({required this.messages});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('Conversations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...messages.map((msg) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: msg['role'] == 'Doctor' ? Colors.blue : Colors.green,
                  child: Text((msg['sender'] as String)[0], style: const TextStyle(color: Colors.white)),
                ),
                title: Text(msg['sender'] as String,
                    style: TextStyle(fontWeight: (msg['unread'] as bool) ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text(msg['lastMessage'] as String),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(msg['date'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (msg['unread'] as bool)
                      const CircleAvatar(radius: 5, backgroundColor: Colors.blue),
                  ],
                ),
                onTap: () {
                  context.push('/sante/pharmacy/chat/${msg['id']}', extra: msg['sender']);
                },
              ),
            )),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => context.push('/sante/pharmacy/chat/new'),
          icon: const Icon(Icons.edit),
          label: const Text('Nouveau message'),
        ),
      ],
    );
  }
}

// ----- Onglet Profil pharmacie -----
class _PharmacyProfileTab extends StatelessWidget {
  const _PharmacyProfileTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.green,
            child: Icon(Icons.local_pharmacy, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text('Pharmacie Centrale', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('1 Rue de la Santé, 75001 Paris', style: TextStyle(color: Colors.grey)),
          const Text('Tél : 01 23 45 67 89', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Informations légales', style: TextStyle(fontWeight: FontWeight.bold)),
          const ListTile(
            leading: Icon(Icons.business),
            title: Text('SIRET : 12345678900012'),
          ),
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Pharmacien titulaire : Dr. Bernard'),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Éditer le profil
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Modification profil (simulé)')),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Modifier le profil'),
          ),
        ],
      ),
    );
  }
}
