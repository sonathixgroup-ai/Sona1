// presentation/thix_sante/patient/details/patient_vaccination_calendar_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientVaccinationCalendarPage extends StatefulWidget {
  const PatientVaccinationCalendarPage({super.key});

  @override
  State<PatientVaccinationCalendarPage> createState() =>
      _PatientVaccinationCalendarPageState();
}

class _PatientVaccinationCalendarPageState
    extends State<PatientVaccinationCalendarPage> {
  final HealthService _healthService = HealthService.instance;
  List<Vaccine> _vaccines = [];
  bool _isLoading = true;
  String? _error;

  // Date actuelle du calendrier
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  // Map des vaccins par date (pour un affichage rapide)
  Map<DateTime, List<Vaccine>> _vaccinesByDate = {};

  // Liste des dates du mois
  List<DateTime> _daysInMonth = [];

  @override
  void initState() {
    super.initState();
    _loadVaccines();
  }

  Future<void> _loadVaccines() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }
      final patientId = user.id;
      final vaccines = await _healthService.fetchVaccines(patientId);
      setState(() {
        _vaccines = vaccines;
        _buildVaccinesMap();
        _buildDaysInMonth();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _buildVaccinesMap() {
    _vaccinesByDate = {};
    for (final vaccine in _vaccines) {
      final dateKey = DateTime(
        vaccine.dateAdministered.year,
        vaccine.dateAdministered.month,
        vaccine.dateAdministered.day,
      );
      _vaccinesByDate.putIfAbsent(dateKey, () => []).add(vaccine);
    }
  }

  void _buildDaysInMonth() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final days = <DateTime>[];
    for (int i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }
    _daysInMonth = days;
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      _buildDaysInMonth();
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      _buildDaysInMonth();
    });
  }

  void _goToToday() {
    setState(() {
      _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
      _buildDaysInMonth();
    });
  }

  List<Vaccine> _getVaccinesForDate(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return _vaccinesByDate[key] ?? [];
  }

  List<Vaccine> _getVaccinesForMonth() {
    return _vaccines.where((v) {
      return v.dateAdministered.year == _currentMonth.year &&
          v.dateAdministered.month == _currentMonth.month;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier des vaccins'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVaccines,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push('/sante/patient/vaccine/new');
            },
            tooltip: 'Ajouter un vaccin',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Erreur : $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadVaccines,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _vaccines.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucun vaccin enregistré.\nAppuyez sur le bouton + pour en ajouter.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadVaccines,
                      child: Column(
                        children: [
                          // Calendrier
                          _buildCalendar(),
                          // Légende
                          _buildLegend(),
                          // Liste des vaccins du mois
                          Expanded(
                            child: _buildMonthVaccinesList(),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildCalendar() {
    final monthFormat = DateFormat('MMMM yyyy', 'fr_FR');
    final firstDayOfWeek = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final startOffset = firstDayOfWeek.weekday % 7; // 0 = Dimanche, 1 = Lundi

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête du mois
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                onPressed: _previousMonth,
              ),
              GestureDetector(
                onTap: _goToToday,
                child: Text(
                  monthFormat.format(_currentMonth),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
                onPressed: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Jours de la semaine
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _DayLabel('L'),
              _DayLabel('M'),
              _DayLabel('M'),
              _DayLabel('J'),
              _DayLabel('V'),
              _DayLabel('S'),
              _DayLabel('D'),
            ],
          ),
          const SizedBox(height: 4),
          // Grille des jours
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
            ),
            itemCount: startOffset + _daysInMonth.length,
            itemBuilder: (context, index) {
              if (index < startOffset) {
                return const SizedBox.shrink();
              }
              final dayIndex = index - startOffset;
              final date = _daysInMonth[dayIndex];
              final vaccines = _getVaccinesForDate(date);
              final isToday = date.day == DateTime.now().day &&
                  date.month == DateTime.now().month &&
                  date.year == DateTime.now().year;
              final isSelected = date.day == _selectedDate.day &&
                  date.month == _selectedDate.month &&
                  date.year == _selectedDate.year;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.2)
                        : isToday
                            ? Colors.blue.withOpacity(0.08)
                            : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday ? Colors.blue : Colors.black,
                        ),
                      ),
                      if (vaccines.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            vaccines.length.clamp(0, 3),
                            (i) => Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: _hasBooster(vaccines[i])
                                    ? Colors.orange
                                    : Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _hasBooster(Vaccine vaccine) {
    return vaccine.boosterDate != null &&
        vaccine.boosterDate!.isAfter(DateTime.now());
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text('Vaccin', style: TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text('Rappel', style: TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              // Naviguer vers la liste complète
              context.push('/sante/patient/vaccinations');
            },
            child: const Row(
              children: [
                Icon(Icons.list, size: 14, color: Colors.blue),
                SizedBox(width: 4),
                Text('Voir tout', style: TextStyle(fontSize: 11, color: Colors.blue)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthVaccinesList() {
    final monthVaccines = _getVaccinesForMonth();
    if (monthVaccines.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Aucun vaccin ce mois-ci.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: monthVaccines.length,
      itemBuilder: (context, index) {
        final vaccine = monthVaccines[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: vaccine.isBoosterDue ? Colors.orange : Colors.green,
              child: Icon(
                vaccine.isBoosterDue ? Icons.warning : Icons.check,
                color: Colors.white,
                size: 18,
              ),
            ),
            title: Text(
              vaccine.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Administré le ${_formatDate(vaccine.dateAdministered)}'
              '${vaccine.boosterDate != null ? ', rappel le ${_formatDate(vaccine.boosterDate!)}' : ''}',
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey[400],
            ),
            onTap: () {
              context.push('/sante/patient/vaccine/${vaccine.id}');
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _DayLabel extends StatelessWidget {
  final String label;

  const _DayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: Colors.grey[600],
      ),
    );
  }
}
