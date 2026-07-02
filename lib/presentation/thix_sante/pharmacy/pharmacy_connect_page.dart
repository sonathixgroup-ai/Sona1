// presentation/thix_sante/pharmacy/pharmacy_connect_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thix_id/auth/auth_controller.dart';
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
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: const Text('Communication'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.orange.shade800,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.orange.shade700,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange,
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
            if (index == 0) context.go('/sante');
            if (index == 2) context.go('/sante/pharmacy/orders');
            if (index == 3) context.go('/sante/pharmacy/connect');
            if (index == 4) context.go('/sante/pharmacy/profile');
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.orange,
          onPressed: () => context.push('/sante/pharmacy/chat/new'),
          child: const Icon(Icons.edit, color: Colors.white),
        ),
      ),
    );
  }
}

class _MessagingTab extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  const _MessagingTab({required this.messages});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ...messages.map((msg) {
          final isUnread = msg['unread'] as bool? ?? false;
          final isDoctor = msg['role'] == 'Doctor';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isDoctor ? Colors.blue : Colors.green,
                  child: Text(
                    (msg['sender'] as String).substring(0, 1),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg['sender'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      Text(
                        msg['lastMessage'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      msg['date'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (isUnread)
                      const SizedBox(height: 4),
                    if (isUnread)
                      const CircleAvatar(
                        radius: 5,
                        backgroundColor: Colors.blue,
                      ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => context.push('/sante/pharmacy/chat/new'),
          icon: const Icon(Icons.edit),
          label: const Text('Nouveau message'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }
}

class _PharmacyProfileTab extends StatelessWidget {
  const _PharmacyProfileTab();

  @override
  Widget build(BuildContext context) {
    final user = AuthController.instance.currentUser;
    final name = user?.displayName ?? 'Pharmacie';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.orange,
            child: Icon(
              Icons.local_pharmacy,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            '1 Rue de la Santé, 75001 Paris',
            style: TextStyle(color: Colors.grey),
          ),
          const Text(
            'Tél : 01 23 45 67 89',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Informations légales',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Modification profil à implémenter'),
                ),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Modifier le profil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
