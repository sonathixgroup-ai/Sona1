// presentation/thix_sante/patient/patient_life_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/health_bottom_nav.dart';

class PatientLifePage extends StatefulWidget {
  const PatientLifePage({super.key});

  @override
  State<PatientLifePage> createState() => _PatientLifePageState();
}

class _PatientLifePageState extends State<PatientLifePage>
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
        title: const Text('Vie & Bien-être'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.pregnant_woman), text: 'Grossesse'),
            Tab(icon: Icon(Icons.family_restroom), text: 'Famille'),
            Tab(icon: Icon(Icons.self_improvement), text: 'Bien-être'),
            Tab(icon: Icon(Icons.share), text: 'Partage'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PregnancyTab(),
          _FamilyTab(),
          _WellnessTab(),
          _SecureSharingTab(),
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

// ===== Onglet Grossesse =====
class _PregnancyTab extends StatelessWidget {
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
                    Icon(Icons.pregnant_woman, color: Colors.pink, size: 32),
                    SizedBox(width: 12),
                    Text('Suivi de grossesse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Semaine actuelle : 12', style: TextStyle(fontSize: 20)),
                const Text('Date prévue d\'accouchement : 15/10/2024'),
                const SizedBox(height: 12),
                const LinearProgressIndicator(value: 0.3, backgroundColor: Colors.grey, color: Colors.pink),
                const SizedBox(height: 8),
                const Text('30% du parcours'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('Prise de poids', '+3.5 kg', Icons.monitor_weight),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard('Échographies', '2 réalisées', Icons.ultrasound),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.push('/sante/patient/pregnancy/new');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une mesure'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Historique des mesures', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ListTile(
          leading: const Icon(Icons.calendar_today, color: Colors.pink),
          title: const Text('Semaine 10'),
          subtitle: const Text('Poids : 61.0 kg • Tension : 120/80'),
          onTap: () {
            context.push('/sante/patient/pregnancy/1');
          },
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today, color: Colors.pink),
          title: const Text('Semaine 11'),
          subtitle: const Text('Poids : 61.8 kg • Tension : 122/82'),
          onTap: () {
            context.push('/sante/patient/pregnancy/2');
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Colors.pink),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ===== Onglet Famille =====
class _FamilyTab extends StatelessWidget {
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
                    Icon(Icons.family_restroom, color: Colors.orange, size: 32),
                    SizedBox(width: 12),
                    Text('Espace famille', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Gérez les dossiers de santé de vos proches.', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.push('/sante/patient/family/new');
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Ajouter un membre'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Membres de votre famille', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ListTile(
          leading: const CircleAvatar(child: Text('M')),
          title: const Text('Marie Dupont'),
          subtitle: const Text('Épouse • Dossier partagé'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            context.push('/sante/patient/family/1');
          },
        ),
        ListTile(
          leading: const CircleAvatar(child: Text('E')),
          title: const Text('Emma Dupont'),
          subtitle: const Text('Fille • Dossier partagé'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            context.push('/sante/patient/family/2');
          },
        ),
        ListTile(
          leading: const CircleAvatar(child: Text('L')),
          title: const Text('Lucas Dupont'),
          subtitle: const Text('Fils • Dossier partagé'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            context.push('/sante/patient/family/3');
          },
        ),
      ],
    );
  }
}

// ===== Onglet Bien-être =====
class _WellnessTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Programmes recommandés pour vous', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildProgramCard(
          title: 'Gestion du stress',
          subtitle: 'Méditation et respiration',
          progress: 0.4,
          icon: Icons.self_improvement,
          color: Colors.blue,
          programId: 'stress',
        ),
        _buildProgramCard(
          title: 'Arrêt du tabac',
          subtitle: 'Programme 30 jours',
          progress: 0.7,
          icon: Icons.smoke_free,
          color: Colors.green,
          programId: 'stop-smoking',
        ),
        _buildProgramCard(
          title: 'Nutrition équilibrée',
          subtitle: 'Menus et conseils',
          progress: 0.2,
          icon: Icons.restaurant,
          color: Colors.orange,
          programId: 'nutrition',
        ),
        _buildProgramCard(
          title: 'Activité physique',
          subtitle: 'Programme adapté à votre condition',
          progress: 0.5,
          icon: Icons.fitness_center,
          color: Colors.purple,
          programId: 'fitness',
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            // Voir tous les programmes
          },
          icon: const Icon(Icons.view_list),
          label: const Text('Voir tous les programmes'),
        ),
      ],
    );
  }

  Widget _buildProgramCard({
    required String title,
    required String subtitle,
    required double progress,
    required IconData icon,
    required Color color,
    required String programId,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/sante/patient/wellness/$programId');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      color: color,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== Onglet Partage sécurisé =====
class _SecureSharingTab extends StatelessWidget {
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
                    Icon(Icons.shield, color: Colors.green, size: 32),
                    SizedBox(width: 12),
                    Text('Partage sécurisé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Partagez votre dossier médical avec vos médecins ou vos proches de manière confidentielle.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.push('/sante/patient/sharing/new');
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Nouveau partage'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Partages actifs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ListTile(
          leading: const Icon(Icons.person, color: Colors.green),
          title: const Text('Dr. Dupont'),
          subtitle: const Text('Accès complet • Expire dans 30 jours'),
          trailing: const Chip(label: Text('Actif'), backgroundColor: Colors.green),
          onTap: () {
            context.push('/sante/patient/sharing/1');
          },
        ),
        ListTile(
          leading: const Icon(Icons.person, color: Colors.orange),
          title: const Text('Marie Dupont'),
          subtitle: const Text('Accès limité • En attente de validation'),
          trailing: const Chip(label: Text('En attente'), backgroundColor: Colors.orange),
          onTap: () {
            context.push('/sante/patient/sharing/2');
          },
        ),
        const SizedBox(height: 16),
        const Text('Historique des partages'),
        ListTile(
          leading: const Icon(Icons.history, color: Colors.grey),
          title: const Text('Partage avec Dr. Martin'),
          subtitle: const Text('Expiré le 01/02/2024'),
        ),
      ],
    );
  }
}
