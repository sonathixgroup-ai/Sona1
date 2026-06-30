// presentation/thix_sante/doctor/doctor_connect_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/health_bottom_nav.dart';

class DoctorConnectPage extends StatefulWidget {
  const DoctorConnectPage({super.key});

  @override
  State<DoctorConnectPage> createState() => _DoctorConnectPageState();
}

class _DoctorConnectPageState extends State<DoctorConnectPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _messages = [
    {
      'id': 'm1',
      'sender': 'Dr. Martin',
      'role': 'Doctor',
      'lastMessage': 'Pouvez-vous vérifier ce dossier ?',
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'unread': true,
    },
    {
      'id': 'm2',
      'sender': 'Michel L.',
      'role': 'Patient',
      'lastMessage': 'Merci pour la prescription.',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'unread': false,
    },
    {
      'id': 'm3',
      'sender': 'Pharmacie Centrale',
      'role': 'Pharmacy',
      'lastMessage': 'L\'ordonnance est prête.',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'unread': false,
    },
  ];

  final List<Map<String, dynamic>> _patientAlerts = [
    {
      'patientName': 'Jean P.',
      'risk': 'Élevé',
      'message': 'Tension artérielle anormalement haute (160/95)',
      'date': DateTime.now().subtract(const Duration(hours: 1)),
      'critical': true,
    },
    {
      'patientName': 'Marie D.',
      'risk': 'Modéré',
      'message': 'Non-observance du traitement antihypertenseur',
      'date': DateTime.now().subtract(const Duration(hours: 3)),
      'critical': false,
    },
    {
      'patientName': 'Luc R.',
      'risk': 'Faible',
      'message': 'Consultation de suivi recommandée',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'critical': false,
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
            Tab(icon: Icon(Icons.notifications_active), text: 'Alertes patients'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Rechercher dans les messages
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MessagingTab(messages: _messages),
          _AlertsTab(patientAlerts: _patientAlerts),
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
            context.go('/sante/doctor/connect');
          } else if (index == 4) {
            context.go('/sante/doctor/profile');
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            context.push('/sante/doctor/messages/new');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Alertes marquées comme lues')),
            );
          }
        },
        child: Icon(_tabController.index == 0 ? Icons.edit : Icons.done_all),
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
              leading: const Icon(Icons.person_add, color: Colors.blue),
              title: const Text('Nouveau patient'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/doctor/patient/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt, color: Colors.green),
              title: const Text('Nouvelle prescription'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/doctor/prescription/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.purple),
              title: const Text('Téléconsultation'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/doctor/teleconsult');
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
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Conversations récentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...messages.map((msg) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getColorForRole(msg['role'] as String),
                  child: Text((msg['sender'] as String)[0], style: const TextStyle(color: Colors.white)),
                ),
                title: Text(msg['sender'] as String,
                    style: TextStyle(fontWeight: (msg['unread'] as bool) ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text(msg['lastMessage'] as String, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatDate(msg['date'] as DateTime), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (msg['unread'] as bool)
                      const SizedBox(height: 4),
                    if (msg['unread'] as bool)
                      const CircleAvatar(radius: 5, backgroundColor: Colors.blue),
                  ],
                ),
                onTap: () {
                  context.push('/sante/doctor/messages/${msg['id']}', extra: msg['sender']);
                },
              ),
            )),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            context.push('/sante/doctor/messages/new');
          },
          icon: const Icon(Icons.edit),
          label: const Text('Nouveau message'),
        ),
      ],
    );
  }

  Color _getColorForRole(String role) {
    switch (role) {
      case 'Patient':
        return Colors.blue;
      case 'Doctor':
        return Colors.purple;
      case 'Pharmacy':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return 'Aujourd\'hui';
    } else if (date.day == now.day - 1) {
      return 'Hier';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}

// ----- Onglet Alertes patients -----
class _AlertsTab extends StatelessWidget {
  final List<Map<String, dynamic>> patientAlerts;
  const _AlertsTab({required this.patientAlerts});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Alertes en temps réel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...patientAlerts.map((alert) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: (alert['critical'] as bool) ? Colors.red : Colors.orange,
                  child: Icon((alert['critical'] as bool) ? Icons.crisis_alert : Icons.warning, color: Colors.white),
                ),
                title: Text(alert['patientName'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(alert['message'] as String),
                trailing: Chip(
                  label: Text(alert['risk'] as String),
                  backgroundColor: _getRiskColor(alert['risk'] as String),
                ),
                onTap: () {
                  context.push('/sante/doctor/alert/${alert['patientName']}');
                },
              ),
            )),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            context.push('/sante/doctor/alerts');
          },
          icon: const Icon(Icons.view_list),
          label: const Text('Toutes les alertes'),
        ),
      ],
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'Élevé':
        return Colors.red;
      case 'Modéré':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}
