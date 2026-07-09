import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThixMoneyPage extends StatefulWidget {
  const ThixMoneyPage({super.key});

  @override
  State<ThixMoneyPage> createState() => _ThixMoneyPageState();
}

class _ThixMoneyPageState extends State<ThixMoneyPage> {
  int currentIndex = 2;

  // ============================================================
  // CHARTE THIX MONEY — Élite Institutionnel Bleu / Blanc
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
                      decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.menu_rounded, size: 20, color: navy),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'THIX ',
                                  style: GoogleFonts.poppins(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: darkText,
                                  ),
                                ),
                                TextSpan(
                                  text: 'MONEY',
                                  style: GoogleFonts.poppins(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'Gérez, épargnez, investissez sereinement.',
                            style: TextStyle(fontSize: 11, color: mutedText),
                          ),
                        ],
                      ),
                    ),
                    _iconWithBadge(Icons.notifications_none_rounded, badgeCount: 0),
                    const SizedBox(width: 10),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [navyDeep, primaryBlue]),
                        boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ========== SOLDE TOTAL ==========
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [navyDeep, navy, primaryBlue],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(color: primaryBlue.withOpacity(0.28), blurRadius: 22, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bonjour, Michel',
                            style: TextStyle(color: Colors.white70, fontSize: 13.5, fontWeight: FontWeight.w500),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(20)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility_rounded, size: 11, color: Colors.white70),
                                SizedBox(width: 4),
                                Text('Masquer', style: TextStyle(color: Colors.white70, fontSize: 9.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Solde total',
                        style: TextStyle(color: Colors.white70, fontSize: 11.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '0 FC',
                        style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '= 0,00 €',
                        style: TextStyle(color: Colors.white70, fontSize: 11.5),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _actionButton('Envoyer', Icons.north_east_rounded),
                          const SizedBox(width: 10),
                          _actionButton('Recevoir', Icons.add_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ========== MES COMPTES (grille 2x2) ==========
                const Text(
                  'Mes comptes',
                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: darkText),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: const [
                    _AccountCard(title: 'Compte principal', amount: '0 FC', note: 'Disponible', icon: Icons.account_balance_wallet_rounded),
                    _AccountCard(title: 'Épargne', amount: '0 FC', note: 'Disponible', icon: Icons.savings_rounded),
                    _AccountCard(title: 'Dollars (USD)', amount: '0 USD', note: '0 FC', icon: Icons.attach_money_rounded),
                    _AccountCard(title: 'Carte prépayée', amount: '0 FC', note: 'Disponible', icon: Icons.credit_card_rounded),
                  ],
                ),
                const SizedBox(height: 26),

                // ========== SERVICES FINANCIERS — grille icônes cadrées ==========
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Services financiers',
                      style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: darkText),
                    ),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: pureWhite,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(color: navyDeep.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.72,
                    children: const [
                      _ServiceIcon(icon: Icons.flash_on_rounded, label: 'Crédit', color: gold),
                      _ServiceIcon(icon: Icons.shield_rounded, label: 'Assurance', color: primaryBlue),
                      _ServiceIcon(icon: Icons.trending_up_rounded, label: 'Épargne', color: green),
                      _ServiceIcon(icon: Icons.currency_exchange_rounded, label: 'Change', color: navy),
                      _ServiceIcon(icon: Icons.store_rounded, label: 'Marchand', color: Color(0xFF7C4DFF)),
                      _ServiceIcon(icon: Icons.favorite_rounded, label: 'Don', color: red),
                      _ServiceIcon(icon: Icons.groups_rounded, label: 'Tontine', color: primaryBlue),
                      _ServiceIcon(icon: Icons.school_rounded, label: 'Éducation', color: gold),
                      _ServiceIcon(icon: Icons.public_rounded, label: 'Virement Int.', color: navy),
                      _ServiceIcon(icon: Icons.account_balance_rounded, label: 'Microfinance', color: green),
                      _ServiceIcon(icon: Icons.analytics_rounded, label: 'Planification', color: primaryBlue),
                      _ServiceIcon(icon: Icons.show_chart_rounded, label: 'Investir', color: Color(0xFF7C4DFF)),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                // ========== TRANSACTIONS RÉCENTES — vide (0) ==========
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transactions récentes',
                      style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: darkText),
                    ),
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: pureWhite,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(color: softBlue, shape: BoxShape.circle),
                        child: Icon(Icons.receipt_long_rounded, size: 28, color: navy.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucune transaction',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: darkText),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Vos opérations apparaîtront ici',
                        style: TextStyle(fontSize: 11.5, color: mutedText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ========== BANNIÈRE ÉPARGNE AUTOMATIQUE ==========
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [softBlue, Color(0xFFE3EDFF)]),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: pureWhite, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.savings_rounded, color: primaryBlue, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Épargnez automatiquement',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: darkText),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Mettez de l\'argent de côté sans y penser.',
                              style: TextStyle(fontSize: 10.5, color: mutedText),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [navyDeep, primaryBlue]),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: const Text('Activer', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)),
                      ),
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
            right: 2,
            top: 2,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(color: red, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _actionButton(String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 17),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
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
          _navItem(Icons.sync_alt_rounded, 'Transactions', 1),
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
          _navItem(Icons.credit_card_outlined, 'Cartes', 3),
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

// ========== COMPOSANTS UI ==========

class _AccountCard extends StatelessWidget {
  final String title;
  final String amount;
  final String note;
  final IconData icon;
  const _AccountCard({required this.title, required this.amount, required this.note, required this.icon});

  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE7EEFC);
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color softBlue = Color(0xFFEFF5FF);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: softBlue, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: navy),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: darkText)),
          const Spacer(),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: darkText)),
          const SizedBox(height: 3),
          Text(note, style: const TextStyle(fontSize: 9.5, color: mutedText)),
        ],
      ),
    );
  }
}

// ✅ Icônes de services — cadrées, avec petit texte dessous, comme la
// grille "Mes services" de la page d'accueil (screenshot de référence)
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
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
          ),
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
