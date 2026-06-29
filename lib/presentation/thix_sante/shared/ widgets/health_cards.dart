// presentation/thix_sante/shared/widgets/health_cards.dart
import 'package:flutter/material.dart';
import 'package:thix_id/presentation/thix_sante/thix_role.dart';
import 'package:thix_id/presentation/thix_sante/health_constants.dart';

/// Carte générique pour afficher une statistique (ex: nombre de consultations)
class HealthStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const HealthStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? HealthConstants.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          constraints: const BoxConstraints(minHeight: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: cardColor),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte pour un service rapide (ex: "Consulter un médecin")
class HealthServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const HealthServiceCard({
    super.key,
    required this.title,
    required this.icon,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? HealthConstants.primaryColor;
    return ListTile(
      leading: Icon(icon, color: cardColor),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

/// Carte pour un article de santé
class HealthArticleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final int readTime; // en minutes
  final VoidCallback onTap;

  const HealthArticleCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.readTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.article),
                ),
              )
            : const Icon(Icons.article, size: 40),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$subtitle • $readTime min de lecture',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Carte de résumé de santé (utilisée sur le dashboard patient)
class HealthSummaryCard extends StatelessWidget {
  final int consultations;
  final int exams;
  final int medications;
  final int appointments;

  const HealthSummaryCard({
    super.key,
    required this.consultations,
    required this.exams,
    required this.medications,
    required this.appointments,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatColumn(label: 'Consultations', value: consultations.toString(), icon: Icons.medical_services),
            _StatColumn(label: 'Examens', value: exams.toString(), icon: Icons.science),
            _StatColumn(label: 'Médicaments', value: medications.toString(), icon: Icons.medication),
            _StatColumn(label: 'Rendez-vous', value: appointments.toString(), icon: Icons.calendar_today),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatColumn({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: HealthConstants.primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Carte pour afficher les prochains rendez-vous
class UpcomingAppointmentCard extends StatelessWidget {
  final String doctorName;
  final String specialty;
  final DateTime date;
  final VoidCallback onTap;

  const UpcomingAppointmentCard({
    super.key,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = date.difference(now);
    final isToday = diff.inDays == 0;
    final isTomorrow = diff.inDays == 1;
    final days = diff.inDays;

    String dayLabel;
    if (isToday) {
      dayLabel = "Aujourd'hui";
    } else if (isTomorrow) {
      dayLabel = 'Demain';
    } else if (days < 7) {
      dayLabel = 'Dans $days jours';
    } else {
      dayLabel = 'Le ${date.day}/${date.month}/${date.year}';
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: HealthConstants.primaryColor,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(doctorName),
        subtitle: Text('$specialty • $dayLabel à ${date.hour}h${date.minute.toString().padLeft(2, '0')}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
