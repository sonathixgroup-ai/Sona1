// 📁 lib/presentation/thix_sante/doctor/screens/doctor_schedule_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/widgets/calendar_widget.dart';
import '../../../common/widgets/section_title.dart';
import '../../../common/widgets/pill_badge.dart';

class DoctorScheduleScreen extends ConsumerStatefulWidget {
  const DoctorScheduleScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends ConsumerState<DoctorScheduleScreen> {
  DateTime _selectedDay = DateTime.now();

  final Map<DateTime, List> _events = {
    DateTime(2024, 12, 18): ['14h30 - Michel Dupont', '16h00 - Sophie Martin'],
    DateTime(2024, 12, 19): ['09h30 - Lucas Bernard'],
  };

  @override
  Widget build(BuildContext context) {
    final dayEvents = _events[_selectedDay] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon agenda'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomCalendarWidget(
              onDaySelected: (day) => setState(() => _selectedDay = day),
              events: _events,
              selectedDay: _selectedDay,
            ),
            const SizedBox(height: 20),
            SectionTitle(
              title: 'Consultations du ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
              showDivider: false,
            ),
            const SizedBox(height: 8),
            if (dayEvents.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Aucune consultation ce jour', style: TextStyle(fontSize: 12)),
                ),
              )
            else
              ...dayEvents.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person, size: 20, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(e, style: const TextStyle(fontSize: 13)),
                    ),
                    PillBadge(text: 'À venir', color: Colors.green),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }
}
