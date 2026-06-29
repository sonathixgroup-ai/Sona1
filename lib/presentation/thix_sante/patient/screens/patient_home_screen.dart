// 📁 lib/presentation/thix_sante/patient/screens/patient_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/stats_card.dart';
import '../widgets/quick_services.dart';
import '../widgets/health_tips_carousel.dart';
import '../widgets/upcoming_appointments.dart';
import '../widgets/recent_documents.dart';
import '../widgets/active_treatments.dart';
import '../widgets/health_score_widget.dart';
import '../widgets/emergency_contact_card.dart';

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: DashboardHeader()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StatsCard(),
                  const SizedBox(height: 20),
                  const QuickServices(),
                  const SizedBox(height: 20),
                  const HealthScoreWidget(),
                  const SizedBox(height: 20),
                  const UpcomingAppointments(),
                  const SizedBox(height: 20),
                  const RecentDocuments(),
                  const SizedBox(height: 20),
                  const ActiveTreatments(),
                  const SizedBox(height: 20),
                  const HealthTipsCarousel(),
                  const SizedBox(height: 20),
                  const EmergencyContactCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
