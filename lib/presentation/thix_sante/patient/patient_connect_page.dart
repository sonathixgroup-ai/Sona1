// presentation/thix_sante/patient/patient_connect_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/health_bottom_nav.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/emergency_button.dart';

class PatientConnectPage extends StatefulWidget {
  const PatientConnectPage({super.key});

  @override
  State<PatientConnectPage> createState() => _PatientConnectPageState();
}

class _PatientConnectPageState extends State<PatientConnectPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Communication & Alertes'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.chat), text: 'Messagerie'),
            Tab(icon: Icon(Icons.smart_toy), text: 'IA'),
            Tab(icon: Icon(Icons.notifications_active), text: 'Alertes'),
            Tab(icon: Icon(Icons.map), text: 'Carte'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MessagingTab(),
          _AIAssistantTab(),
          _AlertsTab(),
          _MapTab(),
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
            context.go('/sante/patient/messages');
          } else if (index == 4) {
            context.go('/sante/patient/profile');
          }
        },
      ),
    );
  }

  void _showQuickAction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: const Text('Prendre un rendez-vous'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/patient/appointment/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.purple),
              title: const Text('Scanner une ordonnance'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/patient/scan');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.teal),
              title: const Text('Consulter l\'assistant IA'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/patient/ia');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ===== Onglet Messagerie =====
class _MessagingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Conversations récentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildConversationTile(
          name: 'Dr. Dupont',
          lastMessage: 'Votre rendez-vous est confirmé.',
          date: 'Aujourd\'hui',
          unread: true,
          onTap: () => context.push('/sante/patient/chat/doc1', extra: 'Dr. Dupont'),
        ),
        _buildConversationTile(
          name: 'Pharmacie Centrale',
          lastMessage: 'Votre ordonnance est prête.',
          date: 'Hier',
          unread: false,
          onTap: () => context.push('/sante/patient/chat/pharm1', extra: 'Pharmacie Centrale'),
        ),
        _buildConversationTile(
          name: 'Assistant IA',
          lastMessage: 'Basé sur vos symptômes, je vous conseille...',
          date: 'Hier',
          unread: true,
          onTap: () => context.push('/sante/patient/ia'),
        ),
        _buildConversationTile(
          name: 'Dr. Martin',
          lastMessage: 'N\'oubliez pas votre prise de sang demain.',
          date: 'Il y a 2 jours',
          unread: false,
          onTap: () => context.push('/sante/patient/chat/doc2', extra: 'Dr. Martin'),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            context.push('/sante/patient/chat/new');
          },
          icon: const Icon(Icons.edit),
          label: const Text('Nouveau message'),
        ),
      ],
    );
  }

  Widget _buildConversationTile({
    required String name,
    required String lastMessage,
    required String date,
    required bool unread,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: unread ? Colors.blue : Colors.grey,
          child: Text(name[0], style: const TextStyle(color: Colors.white)),
        ),
        title: Text(name, style: TextStyle(fontWeight: unread ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (unread)
              const SizedBox(height: 4),
            if (unread)
              const CircleAvatar(radius: 6, backgroundColor: Colors.blue),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

// ===== Onglet Assistant IA =====
class _AIAssistantTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.smart_toy, color: Colors.teal, size: 32),
                    SizedBox(width: 12),
                    Text('Assistant santé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Posez vos questions sur votre santé, vos traitements ou vos symptômes. L\'IA vous répond en toute confidentialité.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Posez votre question...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.teal),
                        onPressed: () {
                          // Simuler une réponse IA
                          context.push('/sante/patient/ia');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Suggestions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSuggestionChip(context, 'Que faire en cas de grippe?'),
            _buildSuggestionChip(context, 'Mes résultats de prise de sang'),
            _buildSuggestionChip(context, 'Posologie paracétamol'),
            _buildSuggestionChip(context, 'Gérer mon stress'),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Historique des conversations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ListTile(
          title: const Text('Symptômes de la grippe'),
          subtitle: const Text('Il y a 2 jours'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            context.push('/sante/patient/ia/history/1');
          },
        ),
        ListTile(
          title: const Text('Vaccin COVID-19'),
          subtitle: const Text('Il y a 5 jours'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            context.push('/sante/patient/ia/history/2');
          },
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(BuildContext context, String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        context.push('/sante/patient/ia');
      },
      backgroundColor: Colors.teal.withOpacity(0.1),
      avatar: const Icon(Icons.chat, size: 16, color: Colors.teal),
    );
  }
}

// ===== Onglet Alertes sanitaires =====
class _AlertsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const EmergencyButton(),
        const SizedBox(height: 16),
        const Text('Alertes récentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildAlertCard(
          title: 'Épidémie de grippe',
          description: 'La grippe saisonnière est en hausse. Pensez à vous faire vacciner.',
          severity: 'warning',
          date: 'Aujourd\'hui',
          onTap: () => context.push('/sante/patient/alert/1'),
        ),
        _buildAlertCard(
          title: 'Rappel vaccination COVID-19',
          description: 'Vous êtes éligible pour une dose de rappel.',
          severity: 'info',
          date: 'Hier',
          onTap: () => context.push('/sante/patient/alert/2'),
        ),
        _buildAlertCard(
          title: 'Rappel médicament',
          description: 'Votre paracétamol est presque épuisé.',
          severity: 'critical',
          date: 'Il y a 2 jours',
          onTap: () => context.push('/sante/patient/alert/3'),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            context.push('/sante/patient/alerts');
          },
          icon: const Icon(Icons.view_list),
          label: const Text('Voir toutes les alertes'),
        ),
      ],
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String description,
    required String severity,
    required String date,
    required VoidCallback onTap,
  }) {
    Color color;
    IconData icon;
    switch (severity) {
      case 'critical':
        color = Colors.red;
        icon = Icons.crisis_alert;
        break;
      case 'warning':
        color = Colors.orange;
        icon = Icons.warning_amber;
        break;
      default:
        color = Colors.blue;
        icon = Icons.info_outline;
    }
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$description • $date'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// ===== Onglet Carte urgences/pharmacies =====
class _MapTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.map, color: Colors.blue, size: 32),
                    SizedBox(width: 12),
                    Text('À proximité', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Trouvez les services de santé les plus proches de chez vous.'),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on, size: 48, color: Colors.blue),
                          SizedBox(height: 8),
                          Text('Carte interactive', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('(Simulation)', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildServiceCard(
                        title: 'Pharmacies',
                        icon: Icons.local_pharmacy,
                        color: Colors.green,
                        onTap: () => context.push('/sante/patient/map/pharmacies'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildServiceCard(
                        title: 'Hôpitaux',
                        icon: Icons.local_hospital,
                        color: Colors.blue,
                        onTap: () => context.push('/sante/patient/map/hospitals'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildServiceCard(
                        title: 'Urgences',
                        icon: Icons.emergency,
                        color: Colors.red,
                        onTap: () => context.push('/sante/patient/map/emergencies'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Services à proximité', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ListTile(
          leading: const Icon(Icons.local_pharmacy, color: Colors.green),
          title: const Text('Pharmacie Centrale'),
          subtitle: const Text('1 Rue de la Santé • Ouverte'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => context.push('/sante/patient/map/pharmacy/1'),
        ),
        ListTile(
          leading: const Icon(Icons.local_hospital, color: Colors.blue),
          title: const Text('Hôpital Saint-Joseph'),
          subtitle: const Text('10 Avenue des Fleurs • Urgences 24/7'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => context.push('/sante/patient/map/hospital/1'),
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
