// presentation/thix_sante/patient/details/patient_consent_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class PatientConsentPage extends StatefulWidget {
  final String? consentId;

  const PatientConsentPage({super.key, this.consentId});

  @override
  State<PatientConsentPage> createState() => _PatientConsentPageState();
}

class _PatientConsentPageState extends State<PatientConsentPage> {
  final SupabaseClient _supabase = SupabaseConfig.client;
  List<Consent> _consents = [];
  bool _isLoading = true;
  String? _error;
  Consent? _selectedConsent;

  @override
  void initState() {
    super.initState();
    _loadConsents();
  }

  Future<void> _loadConsents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer les consentements du patient
      final response = await _supabase
          .from('health_consents')
          .select('*')
          .eq('patient_id', user.id)
          .order('date', ascending: false);

      if (response is List) {
        _consents = response.map((data) => Consent.fromJson(data)).toList();
      }

      // Si un ID est fourni, on cherche le consentement correspondant
      if (widget.consentId != null) {
        final found = _consents.firstWhere(
          (c) => c.id == widget.consentId,
          orElse: () => throw Exception('Consentement introuvable'),
        );
        _selectedConsent = found;
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

  Future<void> _toggleConsent(Consent consent, bool newValue) async {
    try {
      await _supabase
          .from('health_consents')
          .update({'granted': newValue})
          .eq('id', consent.id);

      setState(() {
        final index = _consents.indexWhere((c) => c.id == consent.id);
        if (index != -1) {
          _consents[index] = Consent(
            id: consent.id,
            patientId: consent.patientId,
            type: consent.type,
            granted: newValue,
            date: consent.date,
            expiryDate: consent.expiryDate,
          );
        }
        if (_selectedConsent != null && _selectedConsent!.id == consent.id) {
          _selectedConsent = _consents[index];
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newValue
                ? 'Consentement accordé pour ${consent.type}'
                : 'Consentement révoqué pour ${consent.type}',
          ),
          backgroundColor: newValue ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mode détail (si un ID est fourni)
    if (widget.consentId != null && _selectedConsent != null) {
      return _buildDetailView();
    }

    // Sinon, mode liste
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consentements RGPD'),
        backgroundColor: const Color(0xFF2563FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConsents,
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
                        onPressed: _loadConsents,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _consents.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucun consentement enregistré.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadConsents,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _consents.length,
                        itemBuilder: (context, index) {
                          final consent = _consents[index];
                          return _ConsentCard(
                            consent: consent,
                            onTap: () {
                              context.push('/sante/patient/consent/${consent.id}');
                            },
                            onToggle: (value) => _toggleConsent(consent, value),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildDetailView() {
    final c = _selectedConsent!;
    return Scaffold(
      appBar: AppBar(
        title: Text('Détail consentement'),
        backgroundColor: const Color(0xFF2563FF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: c.granted ? Colors.green[50] : Colors.red[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      c.granted ? Icons.check_circle : Icons.cancel,
                      color: c.granted ? Colors.green : Colors.red,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.granted ? 'Consentement accordé' : 'Consentement révoqué',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: c.granted ? Colors.green : Colors.red,
                          ),
                        ),
                        Text(
                          'Modifié le ${_formatDate(c.date)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _infoRow('Type', c.type),
            _infoRow('Statut', c.granted ? 'Accepté' : 'Refusé'),
            _infoRow('Date', _formatDate(c.date)),
            if (c.expiryDate != null)
              _infoRow('Expiration', _formatDate(c.expiryDate!)),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Accorder ce consentement'),
              subtitle: Text(
                c.granted
                    ? 'Vous avez actuellement accepté ce consentement.'
                    : 'Vous avez actuellement refusé ce consentement.',
              ),
              value: c.granted,
              onChanged: (value) async {
                await _toggleConsent(c, value);
                setState(() {
                  _selectedConsent = c.copyWith(granted: value);
                });
              },
              activeColor: const Color(0xFF2563FF),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non définie';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _ConsentCard extends StatelessWidget {
  final Consent consent;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  const _ConsentCard({
    required this.consent,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                consent.granted ? Icons.check_circle : Icons.cancel,
                color: consent.granted ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      consent.type,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${consent.granted ? 'Accepté' : 'Refusé'} le ${_formatDate(consent.date)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: consent.granted,
                onChanged: onToggle,
                activeColor: const Color(0xFF2563FF),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
