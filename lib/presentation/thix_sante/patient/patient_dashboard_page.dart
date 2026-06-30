// presentation/thix_sante/patient/patient_dashboard_page.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/health_constants.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/emergency_button.dart';
import 'package:thix_id/presentation/thix_sante/thix_role.dart';

class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});

  @override
  State<PatientDashboardPage> createState() =>
      _PatientDashboardPageState();
}

class _PatientDashboardPageState
    extends State<PatientDashboardPage> {
  final HealthService _healthService = HealthService.instance;

  bool _isLoading = true;

  HealthSummary? _summary;

  List<Appointment> _upcomingAppointments = [];
  List<Medication> _currentMedications = [];
  List<HealthArticle> _articles = [];

  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final user = AuthController.instance.currentUser;

      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final patientId = user.id;

      final summary =
          await _healthService.fetchHealthSummary(patientId);

      final appointments =
          await _healthService.fetchUpcomingAppointments(
        patientId,
      );

      final medications =
          await _healthService.fetchMedications(
        patientId,
        activeOnly: true,
      );

      final articles =
          await _healthService.fetchHealthArticles(limit: 4);

      final alerts =
          await _healthService.fetchHealthAlerts(patientId);

      setState(() {
        _summary = summary;
        _upcomingAppointments = appointments;
        _currentMedications = medications;
        _articles = articles;
        _unreadNotifications = alerts.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      child: Scaffold(
        backgroundColor: HealthUI.background,

        floatingActionButton: FloatingActionButton(
          elevation: 6,
          backgroundColor: HealthUI.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () => _showQuickActions(context),
        ),

        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerDocked,

        bottomNavigationBar: _BottomNav(
          currentIndex: 0,
          onTap: (index) {
            if (index == 1) {
              context.go('/sante/patient/health');
            } else if (index == 3) {
              context.go('/sante/patient/messages');
            } else if (index == 4) {
              context.go('/sante/patient/profile');
            }
          },
        ),

        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: CustomScrollView(
                    physics:
                        const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(
                            18,
                            18,
                            18,
                            12,
                          ),
                          child: _TopBar(
                            unreadCount:
                                _unreadNotifications,
                            onNotificationTap: () {
                              context.push(
                                '/sante/patient/notifications',
                              );
                            },
                            onMenuTap: () {
                              _openRoleSwitchSheet(
                                context,
                              );
                            },
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 18,
                          ),
                          child: _HeroCard(
                            onTap: () {
                              context.push(
                                '/sante/patient/profile',
                              );
                            },
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(
                            top: 18,
                            left: 14,
                            right: 14,
                          ),
                          child: _QuickActions(
                            items: [
                              _ActionItem(
                                label:
                                    'Rendez-vous',
                                icon:
                                    Icons.calendar_month,
                                color:
                                    const Color(
                                      0xFF2563FF,
                                    ),
                                onTap: () {
                                  context.push(
                                    '/sante/patient/appointments',
                                  );
                                },
                              ),
                              _ActionItem(
                                label:
                                    'Consultation',
                                icon:
                                    Icons.video_call,
                                color:
                                    const Color(
                                      0xFF00B894,
                                    ),
                                onTap: () {},
                              ),
                              _ActionItem(
                                label: 'Examens',
                                icon: Icons.science,
                                color:
                                    Colors.purple,
                                onTap: () {},
                              ),
                              _ActionItem(
                                label:
                                    'Ordonnances',
                                icon: Icons.receipt,
                                color:
                                    Colors.orange,
                                onTap: () {},
                              ),
                              _ActionItem(
                                label: 'Urgences',
                                icon:
                                    Icons.favorite,
                                color: Colors.red,
                                onTap: () {},
                              ),
                              _ActionItem(
                                label: 'Plus',
                                icon:
                                    Icons.more_horiz,
                                color:
                                    Colors.blueGrey,
                                onTap: () {
                                  _showQuickActions(
                                    context,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      SliverPadding(
                        padding:
                            const EdgeInsets.all(18),
                        sliver: SliverList(
                          delegate:
                              SliverChildListDelegate(
                            [
                              const SizedBox(
                                height: 14,
                              ),

                              if (_summary != null)
                                _SummarySection(
                                  summary: _summary!,
                                ),

                              const SizedBox(
                                height: 22,
                              ),

                              _SectionTitle(
                                title:
                                    'Services santé',
                                action: 'Voir tout',
                              ),

                              const SizedBox(
                                height: 14,
                              ),

                              _HealthServicesGrid(),

                              const SizedBox(
                                height: 22,
                              ),

                              _SectionTitle(
                                title:
                                    'Services rapides',
                                action: 'Voir tout',
                              ),

                              const SizedBox(
                                height: 12,
                              ),

                              _QuickServices(),

                              const SizedBox(
                                height: 22,
                              ),

                              _InsuranceCard(
                                title: 'Assurance santé',
                                subtitle: 'Bénéficiez d\'une couverture complète adaptée à vos besoins.',
                                icon: Icons.shield,
                              ),

                              const SizedBox(height: 18),

                              _InsuranceCard(
                                title: 'Assurance',
                                subtitle: 'Protégez-vous et vos proches avec nos solutions.',
                                icon: Icons.security,
                              ),

                              const SizedBox(
                                height: 22,
                              ),

                              if (_articles.isNotEmpty)
                                _ArticlesSection(
                                  articles: _articles,
                                ),

                              // ===== BOUTON URGENCE AJOUTÉ =====
                              const SizedBox(height: 18),
                              const EmergencyButton(),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BottomSheetTile(
                  icon: Icons.calendar_today,
                  title:
                      'Prendre un rendez-vous',
                  color: HealthUI.primary,
                ),
                _BottomSheetTile(
                  icon: Icons.camera_alt,
                  title:
                      'Scanner une ordonnance',
                  color: Colors.purple,
                ),
                _BottomSheetTile(
                  icon: Icons.chat,
                  title: 'Assistant IA',
                  color: Colors.green,
                ),
                _BottomSheetTile(
                  icon: Icons.health_and_safety,
                  title: 'Urgence',
                  color: Colors.red,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openRoleSwitchSheet(
    BuildContext context,
  ) async {
    final selected =
        await showModalBottomSheet<ThixRole>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) {
        return const _RoleSwitchSheet(
          currentRole: ThixRole.patient,
        );
      },
    );

    if (selected == null) return;

    await _selectRoleAndNavigate(
      context,
      selected,
    );
  }

  Future<void> _selectRoleAndNavigate(
    BuildContext context,
    ThixRole role,
  ) async {
    try {
      ThixRoleController.instance
          .selectRole(role, manual: true);

      try {
        await Supabase.instance.client.auth
            .updateUser(
          UserAttributes(
            data: {
              'thix_role': role.name,
            },
          ),
        );
      } catch (e) {
        debugPrint(e.toString());
      }

      if (!context.mounted) return;

      switch (role) {
        case ThixRole.patient:
          context.go(
              '/sante/patient/dashboard');
          break;

        case ThixRole.doctor:
          context.go(
              '/sante/doctor/dashboard');
          break;

        case ThixRole.pharmacy:
          context.go(
              '/sante/pharmacy/dashboard');
          break;
      }
    } catch (_) {}
  }
}

class HealthUI {
  static const primary = Color(0xFF2563FF);

  static const secondary = Color(0xFF00C2A8);

  static const background = Color(0xFFF7F8FC);

  static const card = Colors.white;

  static const shadow = [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 18,
      offset: Offset(0, 10),
    ),
  ];
}

class _TopBar extends StatelessWidget {
  final int unreadCount;

  final VoidCallback onNotificationTap;

  final VoidCallback onMenuTap;

  const _TopBar({
    required this.unreadCount,
    required this.onNotificationTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthController.instance.currentUser;

    final photo =
        (user?.photoUrl ?? '').trim();

    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.menu,
          onTap: onMenuTap,
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(14),
                  gradient:
                      const LinearGradient(
                    colors: [
                      Color(0xFF2563FF),
                      Color(0xFF00D2C8),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),

              const SizedBox(width: 12),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'THIX SANTÉ',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Votre santé, notre priorité',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Stack(
          clipBehavior: Clip.none,
          children: [
            _CircleIconButton(
              icon:
                  Icons.notifications_none,
              onTap: onNotificationTap,
            ),
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 12),

        CircleAvatar(
          radius: 22,
          backgroundImage: photo.isNotEmpty
              ? NetworkImage(photo)
              : null,
          child: photo.isEmpty
              ? const Icon(Icons.person)
              : null,
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;

  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(16),
          boxShadow: HealthUI.shadow,
        ),
        child: Icon(
          icon,
          size: 22,
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onTap;

  const _HeroCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthController.instance.currentUser;

    final firstName =
        (user?.displayName ?? '')
            .split(' ')
            .first;

    return Container(
      height: 230,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2563FF),
            Color(0xFF00D2C8),
          ],
        ),
        boxShadow: HealthUI.shadow,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white
                    .withOpacity(0.08),
              ),
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      Text(
                        'Bonjour, $firstName 👋',
                        style:
                            GoogleFonts.poppins(
                          color:
                              Colors.white,
                          fontSize: 16,
                          fontWeight:
                              FontWeight
                                  .w500,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        'Votre santé\nentre de bonnes mains',
                        style:
                            GoogleFonts.poppins(
                          color:
                              Colors.white,
                          fontSize: 30,
                          height: 1.1,
                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      Text(
                        'Consultez, suivez et prenez soin de votre santé au quotidien.',
                        style:
                            GoogleFonts.poppins(
                          color: Colors.white
                              .withOpacity(
                                  0.9),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      GestureDetector(
                        onTap: onTap,
                        child: Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,
                            borderRadius:
                                BorderRadius
                                    .circular(
                                        18),
                          ),
                          child: Row(
                            mainAxisSize:
                                MainAxisSize
                                    .min,
                            children: [
                              const Icon(
                                Icons.folder,
                                size: 18,
                                color:
                                    HealthUI
                                        .primary,
                              ),
                              const SizedBox(
                                  width: 10),
                              Text(
                                'Dossier de santé',
                                style:
                                    GoogleFonts
                                        .poppins(
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                  color:
                                      HealthUI
                                          .primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                const CircleAvatar(
                  radius: 48,
                  backgroundColor:
                      Colors.white24,
                  child: Icon(
                    Icons.medical_services,
                    size: 42,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem {
  final String label;

  final IconData icon;

  final Color color;

  final VoidCallback onTap;

  _ActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _QuickActions extends StatelessWidget {
  final List<_ActionItem> items;

  const _QuickActions({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics:
          const BouncingScrollPhysics(),
      child: Row(
        children: items.map((item) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 4,
            ),
            child: GestureDetector(
              onTap: item.onTap,
              child: Container(
                width: 78,
                padding:
                    const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                          18),
                  boxShadow: HealthUI.shadow,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration:
                          BoxDecoration(
                        borderRadius:
                            BorderRadius
                                .circular(12),
                        color: item.color
                            .withOpacity(0.1),
                      ),
                      child: Icon(
                        item.icon,
                        size: 18,
                        color: item.color,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      item.label,
                      textAlign:
                          TextAlign.center,
                      style:
                          GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final HealthSummary summary;

  const _SummarySection({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionTitle(
          title: 'Résumé de santé',
          action: 'Voir tout',
        ),

        const SizedBox(height: 14),

        GridView.count(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _SummaryCard(
              title: 'Consultations',
              value:
                  summary.consultationsThisYear
                      .toString(),
              icon: Icons.calendar_today,
              color: Colors.blue,
            ),
            _SummaryCard(
              title: 'Examens',
              value: summary.examsCompleted
                  .toString(),
              icon: Icons.science,
              color: Colors.green,
            ),
            _SummaryCard(
              title: 'Médicaments',
              value: summary
                  .activeMedications
                  .toString(),
              icon: Icons.medication,
              color: Colors.purple,
            ),
            _SummaryCard(
              title: 'Rendez-vous',
              value: summary
                  .upcomingAppointments
                  .toString(),
              icon: Icons.access_time,
              color: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;

  final String value;

  final IconData icon;

  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: HealthUI.shadow,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              Icon(
                icon,
                color: color,
                size: 18,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  final String? action;

  const _SectionTitle({
    required this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (action != null)
          Text(
            action!,
            style: GoogleFonts.poppins(
              color: HealthUI.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _HealthServicesGrid
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final services = [
      (
        'Santé enfants',
        'Suivez la santé',
        Icons.child_care
      ),
      (
        'Vaccination',
        'Consultez vaccins',
        Icons.vaccines
      ),
      (
        'Grossesse',
        'Suivi pas à pas',
        Icons.pregnant_woman
      ),
      (
        'Assurance',
        'Protection santé',
        Icons.shield
      ),
      (
        'Assistance',
        'Solutions adaptées',
        Icons.security
      ),
      (
        'Plus',
        'Tous les services',
        Icons.more_horiz
      ),
    ];

    return GridView.builder(
      itemCount: services.length,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.38,
      ),
      itemBuilder: (_, index) {
        final item = services[index];

        return Container(
          padding:
              const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(22),
            boxShadow: HealthUI.shadow,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                          14),
                  color: HealthUI.primary
                      .withOpacity(0.1),
                ),
                child: Icon(
                  item.$3,
                  size: 20,
                  color: HealthUI.primary,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                item.$1,
                style: GoogleFonts.poppins(
                  fontWeight:
                      FontWeight.w700,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                item.$2,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickServices
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final services = [
      (
        'Consulter médecin',
        Icons.medical_services
      ),
      ('Dossier médical', Icons.folder),
      ('Résultats', Icons.science),
      ('Ordonnances', Icons.receipt),
      ('Hôpitaux', Icons.local_hospital),
      ('Médicaments', Icons.medication),
      // === AJOUT : Pharmacies proches & Urgences proches ===
      ('Pharmacies proches', Icons.local_pharmacy),
      ('Urgences proches', Icons.emergency),
    ];

    return Column(
      children: services.map((item) {
        return Container(
          margin:
              const EdgeInsets.only(
            bottom: 12,
          ),
          padding:
              const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(20),
            boxShadow: HealthUI.shadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                          14),
                  color: HealthUI.primary
                      .withOpacity(0.1),
                ),
                child: Icon(
                  item.$2,
                  color: HealthUI.primary,
                  size: 20,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  item.$1,
                  style:
                      GoogleFonts.poppins(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ===== NOUVEAU WIDGET : InsuranceCard réutilisable =====
class _InsuranceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _InsuranceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEAF4FF),
            Color(0xFFF4FFFC),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                      18),
            ),
            child: Icon(
              icon,
              color: HealthUI.primary,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      GoogleFonts.poppins(
                    fontWeight:
                        FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style:
                      GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticlesSection
    extends StatelessWidget {
  final List<HealthArticle> articles;

  const _ArticlesSection({
    required this.articles,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionTitle(
          title: 'Pour vous',
          action: 'Voir tout',
        ),

        const SizedBox(height: 14),

        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: articles.length,
            itemBuilder: (_, index) {
              final article =
                  articles[index];

              return Container(
                width: 240,
                margin:
                    const EdgeInsets.only(
                  right: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                          24),
                  image:
                      article.imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(
                                article
                                    .imageUrl!,
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                  color: Colors.white,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                            24),
                    gradient:
                        LinearGradient(
                      begin:
                          Alignment.topCenter,
                      end: Alignment
                          .bottomCenter,
                      colors: [
                        Colors.black
                            .withOpacity(
                                0.05),
                        Colors.black
                            .withOpacity(
                                0.55),
                      ],
                    ),
                  ),
                  padding:
                      const EdgeInsets.all(
                          18),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    mainAxisAlignment:
                        MainAxisAlignment
                            .end,
                    children: [
                      Text(
                        article.title,
                        maxLines: 2,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            GoogleFonts
                                .poppins(
                          color:
                              Colors.white,
                          fontWeight:
                              FontWeight
                                  .w700,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        article.readTime ??
                            '',
                        style:
                            GoogleFonts
                                .poppins(
                          color: Colors
                              .white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BottomSheetTile
    extends StatelessWidget {
  final IconData icon;

  final String title;

  final Color color;

  const _BottomSheetTile({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        vertical: 6,
      ),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: color,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;

  final Function(int) onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 78,
      elevation: 20,
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 10,
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceAround,
        children: [
          _NavItem(
            icon: Icons.home,
            label: 'Accueil',
            selected:
                currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon:
                Icons.favorite_border,
            label: 'Santé',
            selected:
                currentIndex == 1,
            onTap: () => onTap(1),
          ),

          const SizedBox(width: 30),

          _NavItem(
            icon:
                Icons.chat_bubble_outline,
            label: 'Messages',
            selected:
                currentIndex == 3,
            onTap: () => onTap(3),
          ),
          _NavItem(
            icon: Icons.person_outline,
            label: 'Profil',
            selected:
                currentIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;

  final String label;

  final bool selected;

  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 22,
            color: selected
                ? HealthUI.primary
                : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: selected
                  ? HealthUI.primary
                  : Colors.grey,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleSwitchSheet
    extends StatelessWidget {
  final ThixRole currentRole;

  const _RoleSwitchSheet({
    required this.currentRole,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.all(20),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Text(
            'Changer de rôle',
            style:
                GoogleFonts.poppins(
              fontWeight:
                  FontWeight.w800,
              fontSize: 22,
            ),
          ),

          const SizedBox(height: 20),

          for (final role
              in ThixRoleController
                  .availableRoles)
            GestureDetector(
              onTap: () {
                context.pop(role);
              },
              child: Container(
                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                padding:
                    const EdgeInsets.all(
                        16),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius
                          .circular(
                              22),
                  boxShadow:
                      HealthUI.shadow,
                ),
                child: Row(
                  children: [
                    Icon(
                      role.icon,
                      color:
                          role.accent,
                    ),
                    const SizedBox(
                        width: 14),
                    Expanded(
                      child: Text(
                        role.label,
                        style:
                            GoogleFonts
                                .poppins(
                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
                      ),
                    ),
                    if (role ==
                        currentRole)
                      const Icon(
                        Icons
                            .check_circle,
                        color:
                            Colors.green,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
