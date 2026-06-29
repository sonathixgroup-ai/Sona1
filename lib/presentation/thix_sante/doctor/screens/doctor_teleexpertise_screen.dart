// 📁 lib/presentation/thix_sante/doctor/screens/doctor_teleexpertise_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/teleexpertise_request_card.dart';
import '../../../common/widgets/section_title.dart';
import '../../../common/widgets/empty_state.dart';

class DoctorTeleexpertiseScreen extends ConsumerStatefulWidget {
  const DoctorTeleexpertiseScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DoctorTeleexpertiseScreen> createState() => _DoctorTeleexpertiseScreenState();
}

class _DoctorTeleexpertiseScreenState extends ConsumerState<DoctorTeleexpertiseScreen> {
  final List<Map<String, dynamic>> _requests = [
    {'patientName': 'Emma Dubois', 'description': 'Éruption cutanée sur le bras depuis 3 jours', 'date': '17/12/2024', 'image': null},
    {'patientName': 'Thomas Leroy', 'description': 'Douleur thoracique à l\'effort', 'date': '16/12/2024', 'image': null},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Téléexpertise'),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: () {}),
        ],
      ),
      body: _requests.isEmpty
          ? const EmptyStateWidget(
              title: 'Aucune demande',
              subtitle: 'Les demandes de téléexpertise apparaîtront ici',
              icon: Icons.medical_services_outlined,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nouvelles demandes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ..._requests.map((r) => TeleexpertiseRequestCard(
                    patientName: r['patientName']!,
                    description: r['description']!,
                    date: r['date']!,
                    onAccept: () {
                      setState(() {
                        _requests.remove(r);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Demande acceptée'), backgroundColor: Colors.green),
                      );
                    },
                    onDecline: () {
                      setState(() {
                        _requests.remove(r);
                      });
                    },
                  )),
                ],
              ),
            ),
    );
  }
}
