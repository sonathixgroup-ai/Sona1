// presentation/thix_sante/patient/jitsi_teleconsultation_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Page de téléconsultation utilisant Jitsi Meet (via WebView ou lancement externe)
class JitsiTeleconsultationPage extends StatefulWidget {
  final String link;
  final String? doctorName;
  final String? appointmentId;

  const JitsiTeleconsultationPage({
    super.key,
    required this.link,
    this.doctorName,
    this.appointmentId,
  });

  @override
  State<JitsiTeleconsultationPage> createState() => _JitsiTeleconsultationPageState();
}

class _JitsiTeleconsultationPageState extends State<JitsiTeleconsultationPage> {
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
        const SnackBar(content: Text('Impossible d\'ouvrir le lien Jitsi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.doctorName != null ? 'Téléconsultation avec ${widget.doctorName}' : 'Téléconsultation'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam, size: 80, color: Colors.purple),
              const SizedBox(height: 20),
              Text(
                widget.doctorName != null ? 'Consultation avec ${widget.doctorName}' : 'Consultation à distance',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: _isConnecting ? Colors.orange : Colors.green,
                ),
              ),
              const SizedBox(height: 30),
              if (!_isConnecting)
                ElevatedButton.icon(
                  onPressed: _launchJitsi,
                  icon: const Icon(Icons.video_call),
                  label: const Text('Rejoindre la consultation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              else
                const CircularProgressIndicator(),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler et quitter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
