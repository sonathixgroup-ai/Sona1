// presentation/thix_sante/doctor/doctor_consult_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/health_bottom_nav.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/patient/jitsi_teleconsultation_page.dart'; // Réutilisation

class DoctorConsultPage extends StatefulWidget {
  const DoctorConsultPage({super.key});

  @override
  State<DoctorConsultPage> createState() => _DoctorConsultPageState();
}

class _DoctorConsultPageState extends State<DoctorConsultPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Données mockées pour l'agenda
  final List<Appointment> _appointments = [
    Appointment(
      id: 'a1',
      doctorId: 'doc1',
      doctorName: 'Dr. Dupont',
      patientId: 'p1',
      patientName: 'Michel L.',
      date: DateTime.now().add(const Duration(hours: 1)),
      type: AppointmentType.teleconsultation,
      status: AppointmentStatus.confirmed,
      teleconsultationLink: 'https://meet.jit.si/consult1',
    ),
    Appointment(
      id: 'a2',
      doctorId: 'doc1',
      doctorName: 'Dr. Dupont',
      patientId: 'p2',
      patientName: 'Sophie M.',
      date: DateTime.now().add(const Duration(hours: 3, minutes: 30)),
      type: AppointmentType.inPerson,
      status: AppointmentStatus.scheduled,
    ),
    Appointment(
      id: 'a3',
      doctorId: 'doc1',
      doctorName: 'Dr. Dupont',
      patientId: 'p3',
      patientName: 'Jean P.',
      date: DateTime.now().add(const Duration(days: 1, hours: 10)),
      type: AppointmentType.teleexpertise,
      status: AppointmentStatus.confirmed,
      teleconsultationLink: 'https://meet.jit.si/expertise1',
    ),
  ];

  // Demandes de téléexpertise
  final List<Map<String, dynamic>> _expertiseRequests = [
    {
      'id': 'e1',
      'doctorName': 'Dr. Martin',
      'specialty': 'Cardiologue',
      'patientName': 'Marie D.',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'En attente',
      'message': 'Demande d\'avis sur un ECG',
    },
    {
      'id': 'e2',
      'doctorName': 'Dr. Bernard',
      'specialty': 'Dermatologue',
      'patientName': 'Luc R.',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'status': 'Répondu',
      'message': 'Avis sur une lésion cutanée',
    },
  ];

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
        title: const Text('Consultations'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.videocam), text: 'Téléconsultation'),
            Tab(icon: Icon(Icons.medical_services), text: 'Téléexpertise'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Agenda'),
            Tab(icon: Icon(Icons.phone_android), text: 'Mobile terrain'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TeleconsultationTab(),
          _TeleexpertiseTab(expertiseRequests: _expertiseRequests),
          _AgendaTab(appointments: _appointments),
          const _MobileTerrainTab(),
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
            context.go('/sante/doctor/messages');
          } else if (index == 4) {
            context.go('/sante/doctor/profile');
          }
        },
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
                context.push('/sante/doctor/teleconsultation/new');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 1. ONGLET TÉLÉCONSULTATION (Jitsi)
// ============================================================
class _TeleconsultationTab extends StatelessWidget {
  const _TeleconsultationTab();

  @override
  Widget build(BuildContext context) {
    // Liste des téléconsultations à venir
    final consultations = [
      {
        'patientName': 'Michel L.',
        'date': DateTime.now().add(const Duration(hours: 1)),
        'link': 'https://meet.jit.si/consult1',
        'status': 'À venir',
      },
      {
        'patientName': 'Sophie M.',
        'date': DateTime.now().add(const Duration(hours: 4)),
        'link': 'https://meet.jit.si/consult2',
        'status': 'Planifiée',
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.videocam, size: 48, color: Colors.purple),
                SizedBox(height: 8),
                Text('Téléconsultation en direct', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Connectez-vous avec vos patients via Jitsi', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Consultations à venir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ...consultations.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person, color: Colors.white), backgroundColor: Colors.purple),
                title: Text(item['patientName'] as String),
                subtitle: Text('${(item['date'] as DateTime).hour}h${(item['date'] as DateTime).minute.toString().padLeft(2, '0')}'),
                trailing: ElevatedButton(
                  onPressed: () {
                    // Ouvrir la téléconsultation Jitsi
                    context.push('/sante/doctor/teleconsultation/jitsi', extra: item['link']);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                  child: const Text('Rejoindre'),
                ),
              ),
            )),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            // Nouvelle téléconsultation (créer un lien)
            context.push('/sante/doctor/teleconsultation/new');
          },
          icon: const Icon(Icons.add),
          label: const Text('Créer une téléconsultation'),
        ),
      ],
    );
  }
}

// ============================================================
// 2. ONGLET TÉLÉEXPERTISE
// ============================================================
class _TeleexpertiseTab extends StatelessWidget {
  final List<Map<String, dynamic>> expertiseRequests;
  const _TeleexpertiseTab({required this.expertiseRequests});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.medical_services, size: 48, color: Colors.orange),
                SizedBox(height: 8),
                Text('Téléexpertise', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Demandez ou répondez à des avis médicaux', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Demandes en attente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ...expertiseRequests.where((e) => e['status'] == 'En attente').map((req) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.question_answer), backgroundColor: Colors.orange),
                title: Text(req['doctorName'] as String),
                subtitle: Text('${req['patientName']} • ${req['specialty']}'),
                trailing: const Chip(label: Text('En attente'), backgroundColor: Colors.orange),
                onTap: () {
                  // Voir la demande
                  context.push('/sante/doctor/teleexpertise/${req['id']}');
                },
              ),
            )),
        const SizedBox(height: 16),
        const Text('Demandes répondues', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ...expertiseRequests.where((e) => e['status'] == 'Répondu').map((req) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.check_circle), backgroundColor: Colors.green),
                title: Text(req['doctorName'] as String),
                subtitle: Text('${req['patientName']} • ${req['specialty']}'),
                trailing: const Chip(label: Text('Répondu'), backgroundColor: Colors.green),
                onTap: () {
                  // Voir l'avis
                },
              ),
            )),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            // Nouvelle demande de téléexpertise
            context.push('/sante/doctor/teleexpertise/new');
          },
          icon: const Icon(Icons.add),
          label: const Text('Demander un avis'),
        ),
      ],
    );
  }
}

// ============================================================
// 3. ONGLET AGENDA
// ============================================================
class _AgendaTab extends StatelessWidget {
  final List<Appointment> appointments;
  const _AgendaTab({required this.appointments});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Agenda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Icon(Icons.calendar_today),
          ],
        ),
        const SizedBox(height: 16),
        // Mini calendrier simulé
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text('Calendrier (simulation)', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Rendez-vous du jour', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ...appointments.map((appt) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: appt.type == AppointmentType.teleconsultation ? Colors.purple : Colors.blue,
                  child: Icon(appt.type == AppointmentType.teleconsultation ? Icons.videocam : Icons.person, color: Colors.white),
                ),
                title: Text(appt.patientName ?? 'Patient'),
                subtitle: Text('${appt.date.hour}h${appt.date.minute.toString().padLeft(2, '0')} • ${appt.type.name}'),
                trailing: Chip(
                  label: Text(appt.status == AppointmentStatus.confirmed ? 'Confirmé' : 'Planifié'),
                  backgroundColor: appt.status == AppointmentStatus.confirmed ? Colors.green : Colors.orange,
                ),
                onTap: () {
                  context.push('/sante/doctor/appointment/${appt.id}', extra: appt);
                },
              ),
            )),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            // Nouveau créneau
            context.push('/sante/doctor/agenda/slots');
          },
          icon: const Icon(Icons.add),
          label: const Text('Gérer les créneaux'),
        ),
      ],
    );
  }
}

// ============================================================
// 4. ONGLET MOBILE TERRAIN
// ============================================================
class _MobileTerrainTab extends StatelessWidget {
  const _MobileTerrainTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.phone_android, size: 48, color: Colors.teal),
                SizedBox(height: 8),
                Text('Mobile Terrain', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Outils pour les déplacements et consultations hors cabinet'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildTerrainTile(
          icon: Icons.qr_code_scanner,
          title: 'Scan bracelet patient',
          subtitle: 'Identifier un patient rapidement',
          color: Colors.blue,
          onTap: () {
            context.push('/sante/doctor/terrain/scan');
          },
        ),
        _buildTerrainTile(
          icon: Icons.mic,
          title: 'Dictée vocale',
          subtitle: 'Prenez des notes médicales par voix',
          color: Colors.orange,
          onTap: () {
            context.push('/sante/doctor/terrain/dictation');
          },
        ),
        _buildTerrainTile(
          icon: Icons.offline_bolt,
          title: 'Mode hors ligne',
          subtitle: 'Accédez aux dossiers sans connexion',
          color: Colors.green,
          onTap: () {
            context.push('/sante/doctor/terrain/offline');
          },
        ),
        _buildTerrainTile(
          icon: Icons.camera_alt,
          title: 'Prise de photo',
          subtitle: 'Capturer des images de documents',
          color: Colors.purple,
          onTap: () {
            context.push('/sante/doctor/terrain/photo');
          },
        ),
        const SizedBox(height: 16),
        const Text('Derniers patients consultés sur le terrain', style: TextStyle(fontWeight: FontWeight.bold)),
        ListTile(
          leading: const CircleAvatar(child: Text('M')),
          title: const Text('Michel L.'),
          subtitle: const Text('Consultation à domicile - 10/03'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
        ListTile(
          leading: const CircleAvatar(child: Text('S')),
          title: const Text('Sophie M.'),
          subtitle: const Text('Téléconsultation mobile - 09/03'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ],
    );
  }

  Widget _buildTerrainTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
