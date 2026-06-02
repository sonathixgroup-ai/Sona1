import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThixMoneyPage extends StatefulWidget {
  const ThixMoneyPage({super.key});

  @override
  State<ThixMoneyPage> createState() => _ThixMoneyPageState();
}

class _ThixMoneyPageState extends State<ThixMoneyPage> {
  int currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF5F7FB),
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
                    const Icon(Icons.menu_rounded, size: 28, color: Color(0xFF111827)),
                    const SizedBox(width: 14),
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
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                TextSpan(
                                  text: 'MONEY',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF2563FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'Gérez, épargnez, investissez sereinement.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    _iconWithBadge(Icons.notifications_none_rounded, badgeCount: 3),
                    const SizedBox(width: 10),
                    const CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage('https://i.pravatar.cc/300'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ========== SOLDE TOTAL ==========
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF020B56), Color(0xFF001B8D)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bonjour, Michel',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Solde total',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '1.250.000 FC',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '= 1.902,45 €',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _actionButton('Envoyer', Icons.north_east, const Color(0xFF2563FF)),
                          const SizedBox(width: 12),
                          _actionButton('Recevoir', Icons.add, const Color(0xFF16A34A)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ========== MES COMPTES (grille 2x2) ==========
                const Text(
                  'Mes comptes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
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
                    _AccountCard(title: 'Compte principal', amount: '1.250.000 FC', note: 'Disponible'),
                    _AccountCard(title: 'Épargne', amount: '750.000 FC', note: 'Disponible'),
                    _AccountCard(title: 'Dollars (USD)', amount: '320.000 USD', note: '192.000 FC'),
                    _AccountCard(title: 'Carte prépayée', amount: '85.000 FC', note: 'Disponible'),
                  ],
                ),
                const SizedBox(height: 24),

                // ========== SERVICES FINANCIERS ==========
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Services financiers',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'Voir tout >',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: const [
                    _ServiceTile(icon: Icons.flash_on, title: 'Crédit instantané', subtitle: 'Obtenez un crédit rapidement'),
                    _ServiceTile(icon: Icons.shield, title: 'Assurance', subtitle: 'Protégez-vous et vos biens'),
                    _ServiceTile(icon: Icons.trending_up, title: 'Épargne planifiée', subtitle: 'Atteignez vos objectifs'),
                    _ServiceTile(icon: Icons.currency_exchange, title: 'Change', subtitle: 'Achetez et vendez des devises'),
                    _ServiceTile(icon: Icons.store, title: 'Marchand', subtitle: 'Gérez vos encaissements'),
                    _ServiceTile(icon: Icons.favorite, title: 'Don & Contributions', subtitle: 'Soutenez des causes'),
                    _ServiceTile(icon: Icons.group, title: 'Ma Tontine', subtitle: 'Épargnez et recevez à votre tour'),
                    _ServiceTile(icon: Icons.school, title: 'Éducation', subtitle: 'Financez les études facilement'),
                    _ServiceTile(icon: Icons.public, title: 'Virement international', subtitle: 'Envoyez et recevez partout'),
                    _ServiceTile(icon: Icons.account_balance, title: 'Microfinance', subtitle: 'Financements adaptés'),
                    _ServiceTile(icon: Icons.analytics, title: 'Planification financière', subtitle: 'Planifiez votre avenir'),
                    _ServiceTile(icon: Icons.show_chart, title: 'Investissement', subtitle: 'Faites fructifier votre argent'),
                    _ServiceTile(icon: Icons.group_add, title: 'Épargne groupe', subtitle: 'Épargnez en groupe'),
                  ],
                ),
                const SizedBox(height: 24),

                // ========== TRANSACTIONS RÉCENTES ==========
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Transactions récentes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'Voir tout >',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _TransactionItem(
                  title: 'Transfert à Paul N.',
                  amount: '-50.000 FC',
                  date: "Aujourd'hui, 09:35",
                  status: 'Réussi',
                  statusColor: Colors.green,
                ),
                const _TransactionItem(
                  title: 'Dépôt via MoMo',
                  amount: '+100.000 FC',
                  date: "Aujourd'hui, 08:20",
                  status: 'Réussi',
                  statusColor: Colors.green,
                ),
                const _TransactionItem(
                  title: 'Paiement factures SENELEC',
                  amount: '-25.000 FC',
                  date: 'Hier, 19:15',
                  status: 'Réussi',
                  statusColor: Colors.green,
                ),
                const _TransactionItem(
                  title: 'Achat chez Super U',
                  amount: '-15.500 FC',
                  date: 'Hier, 16:42',
                  status: 'Réussi',
                  statusColor: Colors.green,
                ),
                const SizedBox(height: 24),

                // ========== BANNIÈRE ÉPARGNE AUTOMATIQUE ==========
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.savings, color: Colors.blue, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Épargnez automatiquement',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Mettez de l\'argent de côté sans y penser et atteignez vos objectifs plus vite.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Commencez >'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
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
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
          ),
          child: Icon(icon, size: 22, color: const Color(0xFF1E293B)),
        ),
        if (badgeCount > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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

  Widget _actionButton(String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
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
              gradient: const LinearGradient(colors: [Color(0xFF2563FF), Color(0xFF0047FF)]),
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.35), blurRadius: 18)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.qr_code_scanner, color: Colors.white, size: 26),
                SizedBox(height: 2),
                Text('Scanner QR', style: TextStyle(fontSize: 9, color: Colors.white)),
              ],
            ),
          ),
          _navItem(Icons.credit_card_outlined, 'Cartes', 3),
          _navItem(Icons.person_outline, 'Profil', 4),
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
          Icon(icon, size: 22, color: active ? const Color(0xFF2563FF) : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: active ? const Color(0xFF2563FF) : Colors.grey),
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
  const _AccountCard({required this.title, required this.amount, required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A))),
          const Spacer(),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(note, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ServiceTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 16, color: Colors.blue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF0F172A))),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 14, color: Colors.grey),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String title;
  final String amount;
  final String date;
  final String status;
  final Color statusColor;
  const _TransactionItem({required this.title, required this.amount, required this.date, required this.status, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4)],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.swap_horiz, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: amount.startsWith('+') ? Colors.green : Colors.redAccent)),
              const SizedBox(height: 4),
              Text(status, style: TextStyle(fontSize: 10, color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }
}
