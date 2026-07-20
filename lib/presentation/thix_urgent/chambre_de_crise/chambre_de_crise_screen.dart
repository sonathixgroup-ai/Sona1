// lib/presentation/thix_urgent/chambre_de_crise/chambre_de_crise_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/urgent_controller.dart';
import 'widgets/live_map_card.dart';
import 'widgets/live_audio_wave.dart';
import 'widgets/photo_strip_live.dart';
import 'widgets/transcription_live.dart';
import 'widgets/guardian_actions.dart';

class ChambreDeCriseScreen extends StatefulWidget {
  final String criseId;
  final EmergencyType type;
  const ChambreDeCriseScreen({super.key, required this.criseId, required this.type});

  @override
  State<ChambreDeCriseScreen> createState() => _ChambreDeCriseScreenState();
}

class _ChambreDeCriseScreenState extends State<ChambreDeCriseScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE11D48),
        title: Text('CHAMBRE DE CRISE - ${widget.type.name.toUpperCase()} • ${widget.criseId.substring(0, 8)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        actions: [
          Container(margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.black.withOpacity(0.25), borderRadius: BorderRadius.circular(20)), child: const Row(children: [Icon(Icons.circle, color: Colors.white, size: 8), SizedBox(width: 4), Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900))])),
        ],
      ),
      body: Consumer<UrgentController>(
        builder: (_, ctrl, __) => ListView(
          padding: const EdgeInsets.all(14),
          children: [
            LiveMapCard(criseId: widget.criseId),
            const SizedBox(height: 12),
            const LiveAudioWave(),
            const SizedBox(height: 12),
            const PhotoStripLive(),
            const SizedBox(height: 12),
            const TranscriptionLive(),
            const SizedBox(height: 12),
            GuardianActions(criseId: widget.criseId, type: widget.type),
            const SizedBox(height: 20),
            // Pagination pour les gardiens en écoute (scale)
            Text('Gardiens connectés: ${ctrl.permissionCtrl.location ? "3 en ligne" : "Connexion..."}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
