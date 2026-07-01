// presentation/thix_sante/patient/details/patient_teleconsultation_jitsi_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class PatientTeleconsultationJitsiPage extends StatefulWidget {
  final String link;
  final String? doctorName;
  final String? appointmentId;

  const PatientTeleconsultationJitsiPage({
    super.key,
    required this.link,
    this.doctorName,
    this.appointmentId,
  });

  @override
  State<PatientTeleconsultationJitsiPage> createState() =>
      _PatientTeleconsultationJitsiPageState();
}

class _PatientTeleconsultationJitsiPageState
    extends State<PatientTeleconsultationJitsiPage> {
  bool _isConnecting = true;
  String _statusMessage = 'Connexion en cours...';

  @override
  void initState() {
    super.initState();
    _simulateConnection();
  }

  Future<void> _simulateConnection() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isConnecting = false;
      _statusMessage = 'Prêt à rejoindre';
    });
  }

  Future<void> _launchJitsi() async {
    final url = Uri.parse(widget.link);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir le lien Jitsi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.doctorName != null
              ? 'Téléconsultation avec ${widget.doctorName}'
              : 'Téléconsultation',
        ),
        backgroundColor: const Color(0xFF2563FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.video_call,
                  size: 48,
                  color: Color(0xFF2563FF),
                ),
              ),
              const SizedBox(height: 24),

              // Titre
              Text(
                widget.doctorName != null
                    ? 'Consultation avec ${widget.doctorName}'
                    : 'Consultation à distance',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),

              // Statut
              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: _isConnecting ? Colors.orange : Colors.green,
                ),
              ),
              const SizedBox(height: 16),

              // Lien
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.link,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),

              // Bouton Rejoindre
              if (!_isConnecting)
                ElevatedButton.icon(
                  onPressed: _launchJitsi,
                  icon: const Icon(Icons.video_call),
                  label: const Text('Rejoindre la consultation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(200, 50),
                  ),
                )
              else
                const CircularProgressIndicator(),

              const SizedBox(height: 16),

              // Bouton Annuler
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Annuler et quitter'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aide'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pour une consultation en toute sérénité :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Assurez-vous d\'avoir une bonne connexion Internet.'),
            Text('• Autorisez l\'accès à la caméra et au microphone.'),
            Text('• Choisissez un endroit calme et bien éclairé.'),
            Text('• Préparez vos questions à l\'avance.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
