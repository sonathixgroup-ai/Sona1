// presentation/thix_sante/patient/details/patient_insurance_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/supabase/supabase_config.dart';

// Modèle local pour une offre d'assurance
class InsuranceOffer {
  final String id;
  final String title;
  final String description;
  final String coverage;
  final double monthlyPrice;
  final double annualPrice;
  final List<String> benefits;
  final bool isPopular;

  InsuranceOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.coverage,
    required this.monthlyPrice,
    required this.annualPrice,
    this.benefits = const [],
    this.isPopular = false,
  });

  factory InsuranceOffer.fromJson(Map<String, dynamic> json) {
    return InsuranceOffer(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      coverage: json['coverage'] as String,
      monthlyPrice: (json['monthly_price'] as num).toDouble(),
      annualPrice: (json['annual_price'] as num).toDouble(),
      benefits: (json['benefits'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isPopular: json['is_popular'] as bool? ?? false,
    );
  }
}

class PatientInsurancePage extends StatefulWidget {
  const PatientInsurancePage({super.key});

  @override
  State<PatientInsurancePage> createState() => _PatientInsurancePageState();
}

class _PatientInsurancePageState extends State<PatientInsurancePage> {
  final SupabaseClient _supabase = SupabaseConfig.client;
  List<InsuranceOffer> _offers = [];
  bool _isLoading = true;
  String? _error;
  bool _hasInsurance = false;
  String _currentInsurance = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer les offres d'assurance depuis Supabase (si la table existe)
      // Sinon, utiliser des offres par défaut
      try {
        final response = await _supabase
            .from('health_insurance_offers')
            .select('*')
            .order('monthly_price', ascending: true);

        if (response is List && response.isNotEmpty) {
          _offers = response.map((data) => InsuranceOffer.fromJson(data)).toList();
        } else {
          _offers = _getDefaultOffers();
        }
      } catch (_) {
        // Table probablement inexistante, utiliser les offres par défaut
        _offers = _getDefaultOffers();
      }

      // Vérifier si le patient a déjà une assurance
      // Dans la vraie vie, on aurait une table patient_insurance
      // On simule : on vérifie si une entrée existe dans patient_profiles -> insurance_id
      try {
        final profile = await _supabase
            .from('patient_profiles')
            .select('insurance_id, insurance_name')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null && profile['insurance_id'] != null) {
          _hasInsurance = true;
          _currentInsurance = profile['insurance_name'] ?? 'Assurance en cours';
        }
      } catch (_) {
        // Si la table n'existe pas, on simule
        _hasInsurance = false;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<InsuranceOffer> _getDefaultOffers() {
    return [
      InsuranceOffer(
        id: 'basic',
        title: 'Offre Essentielle',
        description: 'Protection de base pour les consultations courantes.',
        coverage: 'Consultations généralistes, examens de routine, médicaments remboursables.',
        monthlyPrice: 15.99,
        annualPrice: 179.00,
        benefits: [
          'Consultations chez le médecin traitant',
          'Examens de biologie courants',
          'Médicaments remboursables',
          'Accès à la téléconsultation',
        ],
        isPopular: false,
      ),
      InsuranceOffer(
        id: 'standard',
        title: 'Offre Confort',
        description: 'Couverture élargie pour une tranquillité d\'esprit.',
        coverage: 'Consultations spécialisées, hospitalisation, optique, dentaire.',
        monthlyPrice: 29.99,
        annualPrice: 329.00,
        benefits: [
          'Tout de l\'offre Essentielle',
          'Consultations chez les spécialistes (cardiologue, dermatologue, etc.)',
          'Hospitalisation avec forfait journalier',
          'Optique (montures et verres) jusqu\'à 150€',
          'Soins dentaires de base',
          'Assistance 24/7',
        ],
        isPopular: true,
      ),
      InsuranceOffer(
        id: 'premium',
        title: 'Offre Premium',
        description: 'La protection complète pour toute la famille.',
        coverage: 'Couverture intégrale avec des plafonds élevés, médecine douce, etc.',
        monthlyPrice: 49.99,
        annualPrice: 549.00,
        benefits: [
          'Tout de l\'offre Confort',
          'Optique jusqu\'à 300€',
          'Soins dentaires étendus (prothèses, implants)',
          'Médecines douces (ostéopathie, acupuncture)',
          'Forfait hospitalisation premium',
          'Protection juridique',
          'Application mobile dédiée',
        ],
        isPopular: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assurance santé'),
        backgroundColor: const Color(0xFF2563FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
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
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête avec statut
                        _buildStatusCard(),
                        const SizedBox(height: 20),

                        // Offres disponibles
                        const Text(
                          'Nos offres',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._offers.map((offer) => _buildOfferCard(offer)),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: _hasInsurance ? Colors.green[50] : Colors.blue[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _hasInsurance ? Icons.check_circle : Icons.shield,
              color: _hasInsurance ? Colors.green : Colors.blue,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasInsurance
                        ? 'Vous êtes couvert(e)'
                        : 'Protégez votre santé',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _hasInsurance ? Colors.green : Colors.blue,
                    ),
                  ),
                  Text(
                    _hasInsurance
                        ? 'Assurance : $_currentInsurance'
                        : 'Souscrivez à une assurance santé dès maintenant.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            if (!_hasInsurance)
              ElevatedButton(
                onPressed: () {
                  // Faire défiler vers la première offre
                  // ou ouvrir un dialogue de souscription
                  _showSubscriptionDialog(null);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563FF),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Souscrire'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(InsuranceOffer offer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: offer.isPopular
            ? const BorderSide(color: Color(0xFF2563FF), width: 2)
            : BorderSide.none,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (offer.isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Populaire',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  offer.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  offer.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Couverture : ${offer.coverage}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${offer.monthlyPrice.toStringAsFixed(2)} €/mois',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563FF),
                          ),
                        ),
                        Text(
                          'ou ${offer.annualPrice.toStringAsFixed(2)} €/an',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => _showSubscriptionDialog(offer),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: offer.isPopular
                            ? const Color(0xFF2563FF)
                            : Colors.grey[200],
                        foregroundColor: offer.isPopular
                            ? Colors.white
                            : Colors.black,
                      ),
                      child: Text(
                        _hasInsurance ? 'Changer' : 'Souscrire',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (offer.benefits.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Avantages inclus :',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...offer.benefits.map(
                        (b) => Row(
                          children: [
                            const Icon(Icons.check_circle,
                                size: 16, color: Colors.green),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                b,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog(InsuranceOffer? offer) {
    final selectedOffer = offer ?? _offers.firstWhere((o) => o.isPopular, orElse: () => _offers.first);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Souscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous êtes sur le point de souscrire à l\'offre "${selectedOffer.title}".',
            ),
            const SizedBox(height: 8),
            Text(
              'Prix : ${selectedOffer.monthlyPrice.toStringAsFixed(2)} € / mois',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Voulez-vous continuer ?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Simuler la souscription
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Souscription en cours de traitement...'),
                  backgroundColor: Colors.green,
                ),
              );
              // Mettre à jour l'état local
              setState(() {
                _hasInsurance = true;
                _currentInsurance = selectedOffer.title;
              });
              // Dans une vraie app, on appellerait une méthode du service
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
