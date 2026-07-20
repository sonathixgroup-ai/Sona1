// lib/presentation/thix_urgent/thix_urgent_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/urgent_controller.dart';
import 'widgets/central/breathing_red_button.dart';
import 'widgets/header/personne_recherche_card.dart';
import 'widgets/actions/green_action_grid.dart';
import 'widgets/footer/chambre_de_crise_button.dart';
import 'widgets/central/emergency_timer_widget.dart';

class ThixUrgentScreen extends StatefulWidget {
  const ThixUrgentScreen({super.key});
  @override State<ThixUrgentScreen> createState() => _ThixUrgentScreenState();
}

class _ThixUrgentScreenState extends State<ThixUrgentScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    Future.microtask(() => context.read<UrgentController>().init(context));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text('THIX URGENT • SÉCURISÉ', style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900, color: Colors.white54)),
      ),
      body: Consumer<UrgentController>(
        builder: (_, ctrl, __) {
          return RefreshIndicator(
            onRefresh: () => ctrl.loadHistory(refresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const PersonneRechercheCard(),
                  const SizedBox(height: 8),
                  EmergencyTimerWidget(isActive: ctrl.isAlertActive),
                  const SizedBox(height: 20),
                  BreathingRedButton(isActive: ctrl.isAlertActive, pulseController: _pulse, onLongPress: () => ctrl.triggerAlert(context)),
                  const SizedBox(height: 16),
                  if (ctrl.isLoading) const CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
                  Text(ctrl.isAlertActive? '🔴 ALERTE EN COURS - THIX CHAT LIVE' : 'Maintiens 2s le bouton rouge pour alerter', style: TextStyle(color: ctrl.isAlertActive? Colors.red : Colors.white54, fontSize: 11, fontWeight: ctrl.isAlertActive? FontWeight.w800 : FontWeight.w400)),
                  if (ctrl.error!= null) Padding(padding: const EdgeInsets.all(8), child: Text(ctrl.error!, style: const TextStyle(color: Colors.redAccent, fontSize: 10))),
                  const SizedBox(height: 30),
                  const GreenActionGrid(),
                  const SizedBox(height: 16),
                  const ChambreDeCriseButton(),
                  const SizedBox(height: 24),
                  // Historique paginé scalable
                  if (ctrl.alertHistory.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ctrl.alertHistory.length + (ctrl.hasMoreHistory? 1 : 0),
                      itemBuilder: (c, i) {
                        if (i == ctrl.alertHistory.length) {
                          return TextButton(onPressed: () => ctrl.loadHistory(), child: const Text('Charger plus...', style: TextStyle(fontSize: 10)));
                        }
                        final a = ctrl.alertHistory[i];
                        return ListTile(dense: true, title: Text('${a['type']} - ${a['id']}', style: const TextStyle(color: Colors.white54, fontSize: 11)), subtitle: Text('${a['created_at']}', style: const TextStyle(color: Colors.white24, fontSize: 9)));
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
