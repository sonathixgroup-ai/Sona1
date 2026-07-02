// presentation/chat/group_waiting_room/waiting_room_screen.dart
import 'package:flutter/material.dart';

class WaitingRoomScreen extends StatelessWidget {
  const WaitingRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Salle d\'attente')),
      body: const Center(child: Text('Gestion des demandes d\'adhésion (à implémenter)')),
    );
  }
}
