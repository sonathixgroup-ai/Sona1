import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ============================================================
// CHARTE GRAPHIQUE THIX MARKET (Identique à l'accueil)
// ============================================================
class _MarketColors {
  static const Color red = Color(0xFFD81E2C);
  static const Color gold = Color(0xFFF0A93B);
  static const Color lightBg = Color(0xFFF7F7FA);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color mutedText = Color(0xFF8A8A8F);
  static const Color cardBorder = Color(0xFFF0F0F0);
  static const Color successGreen = Color(0xFF00B074);
  static const Color creamBg = Color(0xFFFCEFDA);
}

class PriceAlertsPage extends StatefulWidget {
  const PriceAlertsPage({super.key});

  @override
  State<PriceAlertsPage> createState() => _PriceAlertsPageState();
}

class _PriceAlertsPageState extends State<PriceAlertsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

    // ============================================================
  // LOGIQUE DE DONNÉES (100% SUPABASE)
  // ============================================================
  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      
      if (userId == null) {
        setState(() {
          _alerts = [];
          _isLoading = false;
        });
        return;
      }

      // Requête Supabase : on récupère l'alerte + les infos du produit + la boutique
      final response = await Supabase.instance.client
          .from('price_alerts')
          .select('''
            id,
            target_price,
            product_id,
            products (
              title,
              image_url,
              price,
              currency,
              shop:shops(name)
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // On formate la réponse pour l'interface
      final List<Map<String, dynamic>> formattedAlerts = (response as List).map((alert) {
        final product = alert['products'] as Map<String, dynamic>? ?? {};
        final shop = product['shop'] as Map<String, dynamic>? ?? {};
        
        return {
          'id': alert['id'].toString(),
          'product_id': alert['product_id'].toString(),
          'title': product['title'] ?? 'Produit inconnu',
          'image_url': product['image_url'] ?? '',
          'shop_name': shop['name'] ?? 'Boutique',
          'current_price': product['price'] ?? 0,
          'target_price': alert['target_price'] ?? 0,
          'currency': product['currency'] ?? 'FC',
        };
      }).toList();

      setState(() {
        _alerts = formattedAlerts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur Supabase (Alertes) : $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de charger vos alertes'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteAlert(String alertId) async {
    try {
      await Supabase.instance.client
          .from('price_alerts')
          .delete()
          .eq('id', alertId);
          
      setState(() {
        _alerts.removeWhere((alert) => alert['id'] == alertId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerte supprimée'), backgroundColor: _MarketColors.successGreen),
        );
      }
    } catch (e) {
      debugPrint('Erreur suppression alerte : $e');
    }
  }

    

  // ============================================================
  // INTERFACE UTILISATEUR
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _MarketColors.lightBg,
      appBar: AppBar(
        backgroundColor: _MarketColors.pureWhite,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _MarketColors.darkText),
        title: const Text(
          'Mes Alertes de Prix',
          style: TextStyle(
            color: _MarketColors.darkText,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _MarketColors.cardBorder, height: 1),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _MarketColors.red),
      );
    }

    if (_alerts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: _MarketColors.red,
      onRefresh: _loadAlerts,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _alerts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildAlertCard(_alerts[index]);
        },
      ),
    );
  }

  // ============================================================
  // ÉTAT VIDE (Aucune alerte)
  // ============================================================
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _MarketColors.creamBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                size: 64,
                color: _MarketColors.gold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucune alerte de prix',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _MarketColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vous ne surveillez le prix d\'aucun produit pour le moment. Cherchez un produit et cliquez sur la cloche pour créer une alerte.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _MarketColors.mutedText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/market/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _MarketColors.red,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Explorer le marché',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CARTE D'ALERTE INDIVIDUELLE
  // ============================================================
  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final currentPrice = (alert['current_price'] as num).toDouble();
    final targetPrice = (alert['target_price'] as num).toDouble();
    final currency = alert['currency'] as String;
    
    // Déterminer si l'objectif est atteint
    final isTargetReached = currentPrice <= targetPrice;

    return Dismissible(
      key: Key(alert['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (direction) => _deleteAlert(alert['id']),
      child: GestureDetector(
        onTap: () => context.push('/market/product/${alert['product_id']}'),
        child: Container(
          decoration: BoxDecoration(
            color: _MarketColors.pureWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTargetReached ? _MarketColors.successGreen.withOpacity(0.3) : _MarketColors.cardBorder,
              width: isTargetReached ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image du produit
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: _MarketColors.lightBg,
                    child: CachedNetworkImage(
                      imageUrl: alert['image_url'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      errorWidget: (context, url, error) => const Icon(Icons.image_not_supported_outlined, color: _MarketColors.mutedText),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Détails
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert['title'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _MarketColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded, size: 12, color: _MarketColors.mutedText),
                          const SizedBox(width: 4),
                          Text(
                            alert['shop_name'],
                            style: const TextStyle(fontSize: 11, color: _MarketColors.mutedText),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Zone des prix
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Prix ciblé', style: TextStyle(fontSize: 9, color: _MarketColors.mutedText)),
                              Text(
                                '${targetPrice.toInt()} $currency',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: _MarketColors.darkText),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Prix actuel', style: TextStyle(fontSize: 9, color: _MarketColors.mutedText)),
                              Text(
                                '${currentPrice.toInt()} $currency',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: isTargetReached ? _MarketColors.successGreen : _MarketColors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Statut visuel
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isTargetReached 
                              ? _MarketColors.successGreen.withOpacity(0.1) 
                              : _MarketColors.gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isTargetReached ? Icons.check_circle_outline : Icons.schedule,
                              size: 14,
                              color: isTargetReached ? _MarketColors.successGreen : _MarketColors.gold,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isTargetReached ? 'Objectif atteint !' : 'En surveillance...',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isTargetReached ? _MarketColors.successGreen : _MarketColors.gold,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
