// presentation/thix_sante/pharmacy/pharmacy_orders_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/health_bottom_nav.dart';

class PharmacyOrdersPage extends StatefulWidget {
  const PharmacyOrdersPage({super.key});

  @override
  State<PharmacyOrdersPage> createState() => _PharmacyOrdersPageState();
}

class _PharmacyOrdersPageState extends State<PharmacyOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HealthService _service = HealthService.instance;
  
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _pendingPrescriptions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');
      final pharmacyId = user.id;

      // Charger les commandes réelles
      final orders = await _service.fetchPharmacyRecentOrders(pharmacyId, limit: 20);
      
      // Simuler des ordonnances en attente (à connecter à une vraie table)
      // Dans la vraie vie, on aurait une table health_prescriptions avec pharmacy_id
      _pendingPrescriptions = [
        {'id': 'pres1', 'patient': 'Marie D.', 'doctor': 'Dr. Dupont', 'date': '10/03'},
        {'id': 'pres2', 'patient': 'Luc R.', 'doctor': 'Dr. Martin', 'date': '09/03'},
      ];

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
          title: const Text('Commandes'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.orange.shade800,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.orange.shade700,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange,
            tabs: const [
              Tab(icon: Icon(Icons.receipt), text: 'Commandes'),
              Tab(icon: Icon(Icons.verified), text: 'Validation'),
              Tab(icon: Icon(Icons.payment), text: 'Dispensation'),
              Tab(icon: Icon(Icons.local_shipping), text: 'Livraisons'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        Text('Erreur : $_error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrdersTab(),
                      _buildValidationTab(),
                      _buildDispensationTab(),
                      _buildDeliveryTab(),
                    ],
                  ),
        bottomNavigationBar: HealthBottomNav(
          currentIndex: 1,
          onTap: (index) {
            if (index == 0) context.go('/sante');
            if (index == 2) context.go('/sante/pharmacy/connect');
            if (index == 3) context.go('/sante/pharmacy/connect');
            if (index == 4) context.go('/sante/pharmacy/profile');
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.orange,
          onPressed: () => context.push('/sante/pharmacy/order/new'),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_orders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aucune commande pour le moment.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final o = _orders[index];
        final id = (o['id'] ?? '').toString();
        final patient = (o['patient_name'] ?? o['patient'] ?? '').toString();
        final meds = o['meds_count'] ?? o['meds'] ?? '';
        final status = (o['status'] ?? '').toString();

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
                backgroundColor: _getStatusColor(status).withOpacity(0.15),
                child: Text(
                  patient.isNotEmpty ? patient.substring(0, 1).toUpperCase() : '?',
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      id.isNotEmpty ? 'Commande #${id.substring(0, 4)}' : 'Commande',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      patient.isNotEmpty ? 'Patient : $patient' : 'Patient inconnu',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (meds.toString().isNotEmpty)
                      Text(
                        '$meds médicaments',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.isNotEmpty ? status : 'En attente',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildValidationTab() {
    if (_pendingPrescriptions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aucune ordonnance à valider.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _pendingPrescriptions.length,
      itemBuilder: (context, index) {
        final p = _pendingPrescriptions[index];
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
              const CircleAvatar(
                backgroundColor: Colors.orange,
                child: Icon(Icons.receipt, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ordonnance du ${p['date']}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Dr. ${p['doctor']} • ${p['patient']}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ordonnance validée (simulé)'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ordonnance rejetée (simulé)'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDispensationTab() {
    final dispensations = [
      {'patient': 'Michel L.', 'medications': 'Paracétamol, Amoxicilline', 'status': 'À dispenser'},
      {'patient': 'Sophie M.', 'medications': 'Ibuprofène', 'status': 'Dispensé'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: dispensations.length,
      itemBuilder: (context, index) {
        final item = dispensations[index];
        final isDispensed = item['status'] == 'Dispensé';
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
                backgroundColor: isDispensed ? Colors.green : Colors.orange,
                child: Text(
                  (item['patient'] as String).substring(0, 1),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['patient'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      item['medications'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDispensed ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['status'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDispensed ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveryTab() {
    final deliveries = [
      {'patient': 'Jean P.', 'address': '12 Rue de Paris', 'status': 'En cours'},
      {'patient': 'Marie D.', 'address': '5 Avenue des Fleurs', 'status': 'Livrée'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: deliveries.length,
      itemBuilder: (context, index) {
        final item = deliveries[index];
        final isDelivered = item['status'] == 'Livrée';
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
              Icon(
                isDelivered ? Icons.check_circle : Icons.local_shipping,
                color: isDelivered ? Colors.green : Colors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['patient'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      item['address'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDelivered ? Colors.green.withOpacity(0.15) : Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['status'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDelivered ? Colors.green : Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'En attente':
        return Colors.orange;
      case 'Validée':
        return Colors.green;
      case 'Préparée':
        return Colors.blue;
      case 'Livrée':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
