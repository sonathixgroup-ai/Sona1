// lib/presentation/admin/pages/admin_events_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../providers/event_provider.dart';
import '../../../services/event_service.dart';
import 'admin_events_dashboard.dart';  // Même dossier

class AdminEventsPage extends StatelessWidget {
  final String role;
  
  const AdminEventsPage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EventProvider(EventService(Supabase.instance.client)),
      child: const AdminEventsDashboard(),
    );
  }
}
