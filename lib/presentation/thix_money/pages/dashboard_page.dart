// ============================================================
// GRILLE DES 12 SERVICES
// ============================================================
class _PremiumServiceGrid extends StatelessWidget {
  const _PremiumServiceGrid();

  @override
  Widget build(BuildContext context) {
    // Les routes inexistantes ont été remplacées par ''
    final services = [
      _ServiceItem('Crédit\ninstantané', Icons.flash_on_rounded, [const Color(0xFF2D6CDF), const Color(0xFF123B7A)], AppRoutes.thixMoneyLoans),
      _ServiceItem('Assurance', Icons.security_rounded, [const Color(0xFF1FA97F), const Color(0xFF0E6B4E)], ''), // Suspendu
      _ServiceItem('Épargne\nplanifiée', Icons.savings_rounded, [_Palette.gold, _Palette.goldDark], AppRoutes.thixMoneySavings),
      _ServiceItem('Change', Icons.currency_exchange_rounded, [const Color(0xFF9B59B6), const Color(0xFF5E3370)], ''), // Suspendu
      _ServiceItem('Marchand', Icons.storefront_rounded, [const Color(0xFFE0743C), const Color(0xFF9C4A22)], ''), // Suspendu
      _ServiceItem('Don &\nContributions', Icons.volunteer_activism_rounded, [const Color(0xFFE0507A), const Color(0xFF9C2E4E)], ''), // Suspendu
      _ServiceItem('Ma Tontine', Icons.groups_rounded, [const Color(0xFF2DA6DF), const Color(0xFF12557A)], AppRoutes.thixMoneyTontines),
      _ServiceItem('Éducation', Icons.school_rounded, [const Color(0xFF3CB4E3), const Color(0xFF1D6F8C)], ''), // Suspendu
      _ServiceItem('Virement\ninternational', Icons.public_rounded, [_Palette.navy, _Palette.navyDeep], ''), // Suspendu
      _ServiceItem('Microfinance', Icons.account_balance_rounded, [const Color(0xFF4CAF50), const Color(0xFF2E6B30)], ''), // Suspendu
      _ServiceItem('Investissement', Icons.trending_up_rounded, [_Palette.gold, const Color(0xFF8A6420)], AppRoutes.thixMoneyInvestments),
      _ServiceItem('Planification', Icons.calendar_month_rounded, [_Palette.blue, const Color(0xFF1A3D8C)], ''), // Suspendu
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 10,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, index) {
          final s = services[index];
          return GestureDetector(
            onTap: () {
              // Vérification : on ne redirige que si la route n'est pas vide
              if (s.route.isNotEmpty) {
                context.push(s.route);
              }
            },
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: s.gradient),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: s.gradient.last.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Icon(s.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 6),
                Text(
                  s.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 10.5, color: _Palette.navyDeep, fontWeight: FontWeight.w600, height: 1.15),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
