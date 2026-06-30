import 'package:flutter/material.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';

class AppointmentDetailPage extends StatelessWidget {
  final Appointment appointment;
  const AppointmentDetailPage({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail du rendez-vous')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Médecin : ${appointment.doctorName}'),
            Text('Spécialité : ${appointment.doctorSpecialty ?? 'Généraliste'}'),
            Text('Date : ${appointment.formattedDate}'),
            Text('Statut : ${appointment.status.name}'),
            Text('Type : ${appointment.type.name}'),
            if (appointment.notes != null) Text('Notes : ${appointment.notes}'),
          ],
        ),
      ),
    );
  }
}
