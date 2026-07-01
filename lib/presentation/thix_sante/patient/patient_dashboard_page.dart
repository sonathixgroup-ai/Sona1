import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// GARDE TES IMPORTS EXISTANTS
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

  int currentIndex = 0;

  final List<_ServiceItem> quickServices = [
    _ServiceItem(
      title: 'Rendez-vous',
      icon: Icons.calendar_month_rounded,
      color: Color(0xFF2563FF),
      route: '/appointments',
    ),
    _ServiceItem(
      title: 'Consultation',
      icon: Icons.medical_services_rounded,
      color: Color(0xFF0EA5E9),
      route: '/consultation',
    ),
    _ServiceItem(
      title: 'Examens',
      icon: Icons.science_rounded,
      color: Color(0xFF7C3AED),
      route: '/exams',
    ),
    _ServiceItem(
      title: 'Ordonnances',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF4F46E5),
      route: '/prescriptions',
    ),
    _ServiceItem(
      title: 'Urgences',
      icon: Icons.favorite_rounded,
      color: Color(0xFFE11D48),
      route: '/emergency',
    ),
    _ServiceItem(
      title: 'Plus',
      icon: Icons.more_horiz_rounded,
      color: Color(0xFF64748B),
      route: '/more',
    ),
  ];

  final List<_HealthCardData> summary = [
    _HealthCardData(
      title: 'Consultations',
      value: '12',
      subtitle: 'Cette année',
      icon: Icons.calendar_today_rounded,
      color: Color(0xFF2563FF),
    ),
    _HealthCardData(
      title: 'Examens',
      value: '7',
      subtitle: 'Complétés',
      icon: Icons.science_rounded,
      color: Color(0xFF10B981),
    ),
    _HealthCardData(
      title: 'Médicaments',
      value: '3',
      subtitle: 'En cours',
      icon: Icons.medication_rounded,
      color: Color(0xFF8B5CF6),
    ),
    _HealthCardData(
      title: 'Rendez-vous',
      value: '2',
      subtitle: 'À venir',
      icon: Icons.access_time_rounded,
      color: Color(0xFFF97316),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,

      floatingActionButton: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2563FF),
              Color(0xFF00D2C8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563FF).withOpacity(.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: _showQuickActions,
          child: const Icon(
            Icons.add_rounded,
            size: 34,
            color: Colors.white,
          ),
        ),
      ),

      bottomNavigationBar: _buildBottomBar(),

      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            // =================================================
            // APP BAR
            // =================================================

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                child: Row(
                  children: [

                    _topButton(
                      icon: Icons.menu_rounded,
                      onTap: () {},
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Row(
                        children: [

                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF2563FF),
                                  Color(0xFF00D2C8),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.health_and_safety_rounded,
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
                                  fontWeight: FontWeight.w800,
                                  fontSize: 21,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),

                              Text(
                                'Votre santé, notre priorité.',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Stack(
                      children: [

                        _topButton(
                          icon: Icons.notifications_none_rounded,
                          onTap: () {},
                        ),

                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF10B981),
                            ),
                            child: Center(
                              child: Text(
                                '3',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 10),

                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        image: const DecorationImage(
                          image: AssetImage(
                            'assets/images/doctor.jpg',
                          ),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =================================================
            // HERO
            // =================================================

            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  height: 270,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2563FF),
                        Color(0xFF00D2C8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563FF)
                            .withOpacity(.25),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [

                      Positioned(
                        right: -30,
                        top: -10,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                Colors.white.withOpacity(.08),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    'Bonjour, Michel 👋',
                                    style:
                                        GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.w500,
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  Text(
                                    'Votre santé\nentre de bonnes mains',
                                    style:
                                        GoogleFonts.poppins(
                                      height: 1.15,
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight:
                                          FontWeight.w800,
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  Text(
                                    'Consultez, suivez et prenez soin\n'
                                    'de votre santé au quotidien.',
                                    style:
                                        GoogleFonts.poppins(
                                      color: Colors.white
                                          .withOpacity(.92),
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),

                                  const Spacer(),

                                  GestureDetector(
                                    onTap: () {},
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(
                                              18),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 8,
                                          sigmaY: 8,
                                        ),
                                        child: Container(
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            horizontal: 18,
                                            vertical: 14,
                                          ),
                                          decoration:
                                              BoxDecoration(
                                            color: Colors.white,
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

                                              Container(
                                                width: 36,
                                                height: 36,
                                                decoration:
                                                    BoxDecoration(
                                                  color:
                                                      const Color(
                                                          0xFF2563FF),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12),
                                                ),
                                                child:
                                                    const Icon(
                                                  Icons
                                                      .folder_open_rounded,
                                                  color: Colors
                                                      .white,
                                                  size: 18,
                                                ),
                                              ),

                                              const SizedBox(
                                                  width: 12),

                                              Text(
                                                'Dossier de santé',
                                                style:
                                                    GoogleFonts
                                                        .poppins(
                                                  color:
                                                      const Color(
                                                          0xFF0F172A),
                                                  fontWeight:
                                                      FontWeight
                                                          .w700,
                                                  fontSize: 14,
                                                ),
                                              ),

                                              const SizedBox(
                                                  width: 8),

                                              const Icon(
                                                Icons
                                                    .arrow_forward_ios_rounded,
                                                size: 14,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Image.asset(
                                'assets/images/doctor.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // =================================================
            // QUICK SERVICES
            // =================================================

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 18,
                ),
                child: Row(
                  children: quickServices.map((e) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          margin:
                              const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(.04),
                                blurRadius: 12,
                                offset:
                                    const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [

                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: e.color
                                      .withOpacity(.12),
                                  borderRadius:
                                      BorderRadius
                                          .circular(16),
                                ),
                                child: Icon(
                                  e.icon,
                                  color: e.color,
                                  size: 24,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                e.title,
                                textAlign:
                                    TextAlign.center,
                                style:
                                    GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w600,
                                  color:
                                      const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // =================================================
            // SECTION TITLE
            // =================================================

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    20, 26, 20, 14),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [

                    Text(
                      'Résumé de santé',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),

                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Voir tout',
                        style: GoogleFonts.poppins(
                          color:
                              const Color(0xFF2563FF),
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =================================================
            // HEALTH SUMMARY
            // =================================================

            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverGrid(
                delegate:
                    SliverChildBuilderDelegate(
                  (context, index) {
                    final item = summary[index];

                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(
                                    .04),
                            blurRadius: 14,
                            offset:
                                const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: item.color
                                  .withOpacity(.12),
                              borderRadius:
                                  BorderRadius
                                      .circular(16),
                            ),
                            child: Icon(
                              item.icon,
                              color: item.color,
                              size: 24,
                            ),
                          ),

                          const Spacer(),

                          Text(
                            item.title,
                            style:
                                GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  item.color,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            item.value,
                            style:
                                GoogleFonts.poppins(
                              fontSize: 34,
                              fontWeight:
                                  FontWeight.w800,
                              color:
                                  const Color(
                                      0xFF0F172A),
                            ),
                          ),

                          Text(
                            item.subtitle,
                            style:
                                GoogleFonts.poppins(
                              fontSize: 12,
                              color:
                                  Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: summary.length,
                ),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: .92,
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 24,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      elevation: 25,
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 10,
      child: SizedBox(
        height: 78,
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceAround,
          children: [

            _navItem(
              index: 0,
              icon: Icons.home_rounded,
              label: 'Accueil',
            ),

            _navItem(
              index: 1,
              icon: Icons.favorite_border_rounded,
              label: 'Santé',
            ),

            const SizedBox(width: 40),

            _navItem(
              index: 2,
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Messages',
            ),

            _navItem(
              index: 3,
              icon: Icons.person_outline_rounded,
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          currentIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [

          AnimatedContainer(
            duration:
                const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF2563FF)
                      .withOpacity(.12)
                  : Colors.transparent,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: selected
                  ? const Color(0xFF2563FF)
                  : Colors.grey.shade500,
              size: 24,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected
                  ? const Color(0xFF2563FF)
                  : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(34),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 24),

              _sheetTile(
                icon: Icons.calendar_month_rounded,
                title: 'Prendre rendez-vous',
                color: const Color(0xFF2563FF),
              ),

              _sheetTile(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Scanner ordonnance',
                color: const Color(0xFF8B5CF6),
              ),

              _sheetTile(
                icon: Icons.smart_toy_rounded,
                title: 'Assistant IA',
                color: const Color(0xFF10B981),
              ),

              _sheetTile(
                icon: Icons.local_hospital_rounded,
                title: 'Urgence médicale',
                color: const Color(0xFFE11D48),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetTile({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(vertical: 6),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color.withOpacity(.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          icon,
          color: color,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
      ),
      onTap: () {},
    );
  }
}

// ============================================================
// MODELS
// ============================================================

class _ServiceItem {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  _ServiceItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _HealthCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  _HealthCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
