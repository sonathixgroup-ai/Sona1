import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThixMoneyPage extends StatefulWidget {
  const ThixMoneyPage({super.key});

  @override
  State<ThixMoneyPage> createState() => _ThixMoneyPageState();
}

class _ThixMoneyPageState extends State<ThixMoneyPage> {
  int currentIndex = 2;
  bool _balanceVisible = true;

  // ============================================================
  // CHARTE THIX MONEY
  // ============================================================
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color softBlue = Color(0xFFEFF5FF);
  static const Color background = Color(0xFFF7FAFF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);
  static const Color border = Color(0xFFE7EEFC);
  static const Color gold = Color(0xFFE3B23C);
  static const Color green = Color(0xFF059669);
  static const Color red = Color(0xFFE5484D);
  static const Color purple = Color(0xFF7C4DFF);
  static const Color orange = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: background,
      bottomNavigationBar: _bottomNavigation(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ========== EN-TÊTE ==========
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(color: pureWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                      child: const Icon(Icons.menu_rounded, size: 20, color: navy),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [navyDeep, primaryBlue]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('T', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'THIX ',
                                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: darkText),
                                ),
                                TextSpan(
                                  text: 'MONEY',
                                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: primaryBlue),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'Votre argent, votre liberté',
                            style: TextStyle(fontSize: 10.5, color: mutedText),
                          ),
                        ],
                      ),
                    ),
                    _iconWithBadge(Icons.notifications_none_rounded, badgeCount: 3),
                    const SizedBox(width: 10),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: border, width: 1.5),
                        image: const DecorationImage(
                          image: NetworkImage('https://i.pravatar.cc/300'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ========== SOLDE DISPONIBLE ==========
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [navyDeep, navy],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(color: navyDeep.withOpacity(0.30), blurRadius: 22, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Watermark T
                      Positioned(
                        right: -10,
                        top: -10,
                        child: Opacity(
                          opacity: 0.06,
                          child: Text(
                            'T',
                            style: GoogleFonts.poppins(fontSize: 140, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Solde disponible',
                                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => setState(() => _balanceVisible = !_balanceVisible),
                                    child: Icon(
                                      _balanceVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                      size: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(Icons.wifi_rounded, color: Colors.white54, size: 20),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _balanceVisible ? '12 500 000' : '••• ••• •••',
                                style: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              const Text('FCFA', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _balanceVisible ? '≈ 20 500 USD' : '≈ •••• USD',
                            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white.withOpacity(0.22)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.history_rounded, size: 15, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text('Historique', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.22),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: gold.withOpacity(0.5)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('VISA', style: GoogleFonts.poppins(color: gold, fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                                    const SizedBox(width: 10),
                                    Text('THIX ID', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ========== ACTIONS RAPIDES ==========
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: pureWhite,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: border),
                    boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _quickAction(Icons.send_rounded, 'Envoyer'),
                      _quickAction(Icons.add_rounded, 'Recharger'),
                      _quickAction(Icons.qr_code_scanner_rounded, 'Scanner'),
                      _quickAction(Icons.savings_rounded, 'Retrait'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ========== STATISTIQUES ==========
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: pureWhite,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: border),
                    boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _statItem(Icons.account_balance_wallet_rounded, green, 'Épargne', '2 500 000', 'FCFA', true)),
                      _statDivider(),
                      Expanded(child: _statItem(Icons.show_chart_rounded, purple, 'Investissements', '750 000', 'FCFA', true)),
                      _statDivider(),
                      Expanded(child: _statItem(Icons.attach_money_rounded, orange, 'Crédits', '1 200 000', 'FCFA', true)),
                      _statDivider(),
                      Expanded(child: _statItem(Icons.groups_rounded, primaryBlue, 'Tontines', '5', 'actives', false)),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                // ========== SERVICES FINANCIERS ==========
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Services financiers', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: darkText)),
                    Row(
                      children: const [
                        Text('Voir tout', style: TextStyle(color: primaryBlue, fontSize: 11.5, fontWeight: FontWeight.w700)),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, size: 14, color: primaryBlue),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.82,
                  children: const [
                    _ServiceIcon(icon: Icons.flash_on_rounded, label: 'Crédit instantané', color: green),
                    _ServiceIcon(icon: Icons.shield_rounded, label: 'Assurance', color: primaryBlue),
                    _ServiceIcon(icon: Icons.track_changes_rounded, label: 'Épargne planifiée', color: red),
                    _ServiceIcon(icon: Icons.currency_exchange_rounded, label: 'Change', color: green),
                    _ServiceIcon(icon: Icons.storefront_rounded, label: 'Marchand', color: purple),
                    _ServiceIcon(icon: Icons.volunteer_activism_rounded, label: 'Don & Contributions', color: red),
                    _ServiceIcon(icon: Icons.groups_rounded, label: 'Ma Tontine', color: primaryBlue),
                    _ServiceIcon(icon: Icons.school_rounded, label: 'Éducation', color: purple),
                    _ServiceIcon(icon: Icons.public_rounded, label: 'Virement international', color: primaryBlue),
                    _ServiceIcon(icon: Icons.account_balance_rounded, label: 'Microfinance', color: green),
                    _ServiceIcon(icon: Icons.trending_up_rounded, label: 'Investissement', color: orange),
                    _ServiceIcon(icon: Icons.assignment_rounded, label: 'Planification financière', color: purple),
                  ],
                ),
                const SizedBox(height: 22),

                // ========== BANNIÈRES PROMO — ligne 1 ==========
                Row(
                  children: [
                    Expanded(
                      child: _CreditBanner(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AiBanner(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ========== BANNIÈRES PROMO — ligne 2 ==========
                Row(
                  children: [
                    Expanded(child: _CashbackBanner()),
                    const SizedBox(width: 12),
                    Expanded(child: _TransferBanner()),
                  ],
                ),
                const SizedBox(height: 26),

                // ========== MES TONTINES ==========
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mes tontines', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: darkText)),
                    Row(
                      children: const [
                        Text('Voir tout', style: TextStyle(color: primaryBlue, fontSize: 11.5, fontWeight: FontWeight.w700)),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, size: 14, color: primaryBlue),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 128,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: const [
                      _TontineCard(icon: Icons.groups_rounded, iconColor: green, title: 'Tontine Business', percent: 0.78, members: '7/10 membres'),
                      SizedBox(width: 12),
                      _TontineCard(icon: Icons.family_restroom_rounded, iconColor: orange, title: 'Tontine Famille', percent: 0.52, members: '5/10 membres'),
                      SizedBox(width: 12),
                      _TontineCard(icon: Icons.home_rounded, iconColor: purple, title: 'Projet Maison', percent: 0.33, members: '4/10 membres'),
                      SizedBox(width: 12),
                      _TontineCard(icon: Icons.savings_rounded, iconColor: gold, title: 'Épargne École', percent: 0.48, members: '4/10 membres'),
                    ],
                  ),
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS PRIVÉS
  // ============================================================

  Widget _iconWithBadge(IconData icon, {int badgeCount = 0}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: pureWhite,
            shape: BoxShape.circle,
            border: Border.all(color: border),
            boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.04), blurRadius: 8)],
          ),
          child: Icon(icon, size: 20, color: navy),
        ),
        if (badgeCount > 0)
          Positioned(
            right: 1,
            top: 1,
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(color: red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
              child: Center(
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _quickAction(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [navyDeep, primaryBlue]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: darkText)),
      ],
    );
  }

  Widget _statDivider() => Container(width: 1, height: 40, color: border);

  Widget _statItem(IconData icon, Color color, String label, String value, String unit, bool showTrend) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 10.5, color: mutedText, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: darkText)),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(unit, style: const TextStyle(fontSize: 9.5, color: mutedText)),
            if (showTrend) ...[
              const SizedBox(width: 4),
              Icon(Icons.trending_up_rounded, size: 12, color: color),
            ],
          ],
        ),
      ],
    );
  }

  Widget _bottomNavigation() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.10), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_rounded, 'Accueil', 0),
          _navItem(Icons.description_rounded, 'Transactions', 1),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [navyDeep, primaryBlue]),
              boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24),
                SizedBox(height: 2),
                Text('Scanner', style: TextStyle(fontSize: 8.5, color: Colors.white)),
              ],
            ),
          ),
          _navItem(Icons.apps_rounded, 'Services', 3),
          _navItem(Icons.person_outline_rounded, 'Profil', 4),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final active = currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => currentIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 21, color: active ? primaryBlue : mutedText),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 9.5, color: active ? primaryBlue : mutedText, fontWeight: active ? FontWeight.w700 : FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ========== ICÔNE DE SERVICE ==========
class _ServiceIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ServiceIcon({required this.icon, required this.label, required this.color});

  static const Color darkText = Color(0xFF10192E);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(18)),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: darkText, height: 1.15),
        ),
      ],
    );
  }
}

// ========== BANNIÈRE CRÉDIT INSTANTANÉ ==========
class _CreditBanner extends StatelessWidget {
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color gold = Color(0xFFE3B23C);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 152,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [navyDeep, navy], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(6)),
            child: const Text('CRÉDIT INSTANTANÉ', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
          ),
          const Spacer(),
          const Text('Besoin d\'argent ?', style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          const Text('Jusqu\'à 5 000 000 FCFA', style: TextStyle(color: Colors.white70, fontSize: 10.5)),
          const SizedBox(height: 10),
          Row(
            children: const [
              Text('Demander', style: TextStyle(color: gold, fontSize: 11.5, fontWeight: FontWeight.w800)),
              SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 14, color: gold),
            ],
          ),
        ],
      ),
    );
  }
}

// ========== BANNIÈRE THIX AI ==========
class _AiBanner extends StatelessWidget {
  static const Color darkText = Color(0xFF10192E);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color green = Color(0xFF059669);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 152,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [green.withOpacity(0.12), green.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: green.withOpacity(0.16), borderRadius: BorderRadius.circular(6)),
                child: Text('THIX AI', style: TextStyle(color: green, fontSize: 8, fontWeight: FontWeight.w800)),
              ),
              const Spacer(),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: green, shape: BoxShape.circle),
                child: const Icon(Icons.smart_toy_rounded, size: 14, color: Colors.white),
              ),
            ],
          ),
          const Spacer(),
          const Text('Vous pouvez épargner', style: TextStyle(color: darkText, fontSize: 12.5, fontWeight: FontWeight.w800, height: 1.2)),
          const Text('150 000 FCFA ce mois.', style: TextStyle(color: darkText, fontSize: 12.5, fontWeight: FontWeight.w800, height: 1.2)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Voir plus', style: TextStyle(color: green, fontSize: 11.5, fontWeight: FontWeight.w800)),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 14, color: green),
            ],
          ),
        ],
      ),
    );
  }
}

// ========== BANNIÈRE CASHBACK ==========
class _CashbackBanner extends StatelessWidget {
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);
  static const Color purple = Color(0xFF7C4DFF);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 122,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [purple.withOpacity(0.12), purple.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Cashback 10%', style: TextStyle(color: darkText, fontSize: 13.5, fontWeight: FontWeight.w800)),
              ),
              Icon(Icons.card_giftcard_rounded, color: purple, size: 22),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Paiement chez partenaires', style: TextStyle(color: mutedText, fontSize: 10)),
          const Spacer(),
          Row(
            children: [
              Text('Utiliser', style: TextStyle(color: purple, fontSize: 11.5, fontWeight: FontWeight.w800)),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 14, color: purple),
            ],
          ),
        ],
      ),
    );
  }
}

// ========== BANNIÈRE VIREMENT INTERNATIONAL ==========
class _TransferBanner extends StatelessWidget {
  static const Color darkText = Color(0xFF10192E);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color gold = Color(0xFFE3B23C);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 122,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [gold.withOpacity(0.16), gold.withOpacity(0.06)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Envoyez de l\'argent\npartout dans le monde', style: TextStyle(color: darkText, fontSize: 11.5, fontWeight: FontWeight.w800, height: 1.2)),
              ),
              Icon(Icons.public_rounded, color: primaryBlue, size: 24),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Text('Envoyer', style: TextStyle(color: primaryBlue, fontSize: 11.5, fontWeight: FontWeight.w800)),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 14, color: primaryBlue),
            ],
          ),
        ],
      ),
    );
  }
}

// ========== CARTE TONTINE ==========
class _TontineCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final double percent;
  final String members;

  const _TontineCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.percent,
    required this.members,
  });

  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE7EEFC);
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);
  static const Color primaryBlue = Color(0xFF2D6CDF);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: iconColor.withOpacity(0.14), borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: darkText), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('${(percent * 100).round()}%', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: darkText)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(value: percent, backgroundColor: border, color: iconColor, minHeight: 6),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(members, style: const TextStyle(fontSize: 9.5, color: mutedText)),
              Text('Voir', style: TextStyle(fontSize: 9.5, color: primaryBlue, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}
