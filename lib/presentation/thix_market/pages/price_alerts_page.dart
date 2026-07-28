// lib/presentation/thix_market/pages/price_alerts_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/market_providers.dart';

// ============================================================
// CHARTE GRAPHIQUE
// ============================================================
class _MarketColors {
  static const red = Color(0xFFD81E2C);
  static const gold = Color(0xFFF0A93B);
  static const lightBg = Color(0xFFF7F7FA);
  static const pureWhite = Color(0xFFFFFFFF);
  static const darkText = Color(0xFF1A1A1A);
  static const mutedText = Color(0xFF8A8A8F);
  static const cardBorder = Color(0xFFF0F0F0);
  static const successGreen = Color(0xFF00B074);
  static const creamBg = Color(0xFFFCEFDA);
}

// ============================================================
// PROVIDER
// ============================================================
final priceAlertsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.read(supabaseClientProvider);
  final uid = db.auth.currentUser?.id;
  
  if (uid == null) return [];
  
  final res = await db.from('price_alerts')
      .select('id, target_price, product_id, products(title, image_url, price, currency, shop:shops(name))')
      .eq('user_id', uid)
      .order('created_at', ascending: false);
      
  List<Map<String, dynamic>> list = [];
  
  for (final alert in (res as List)) {
    final prodRaw = alert['products'];
    Map<String, dynamic> prod = {};
    if (prodRaw is Map) prod = Map<String, dynamic>.from(prodRaw);
    
    final shopRaw = prod['shop'];
    Map<String, dynamic> shop = {};
    if (shopRaw is Map) shop = Map<String, dynamic>.from(shopRaw);
    
    list.add({
      'id': alert['id'].toString(),
      'product_id': alert['product_id'].toString(),
      'title': prod['title'] != null ? prod['title'].toString() : 'Produit inconnu',
      'image_url': prod['image_url'] != null ? prod['image_url'].toString() : '',
      'shop_name': shop['name'] != null ? shop['name'].toString() : 'Boutique',
      'current_price': prod['price'] ?? 0,
      'target_price': alert['target_price'] ?? 0,
      'currency': prod['currency'] != null ? prod['currency'].toString() : 'FC',
    });
  }
  
  return list;
});

// ============================================================
// PAGE ALERTE DE PRIX
// ============================================================
class PriceAlertsPage extends ConsumerWidget {
  const PriceAlertsPage({super.key});

  Future<void> deleteAlert(WidgetRef ref, BuildContext context, String id) async {
    try {
      final db = ref.read(supabaseClientProvider);
      await db.from('price_alerts').delete().eq('id', id);
      ref.invalidate(priceAlertsProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerte supprimée'), backgroundColor: _MarketColors.successGreen)
        );
      }
    } catch (e) { 
      debugPrint('Error deleting alert: $e'); 
    }
  }

  @override 
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAlerts = ref.watch(priceAlertsProvider);
    
    return Scaffold(
      backgroundColor: _MarketColors.lightBg,
      appBar: AppBar(
        backgroundColor: _MarketColors.pureWhite, 
        elevation: 0, 
        centerTitle: true, 
        iconTheme: const IconThemeData(color: _MarketColors.darkText), 
        title: const Text(
          'Mes Alertes de Prix', 
          style: TextStyle(color: _MarketColors.darkText, fontWeight: FontWeight.w900, fontSize: 18)
        ), 
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1), 
          child: Container(color: _MarketColors.cardBorder, height: 1)
        )
      ),
      body: asyncAlerts.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _MarketColors.red)),
        error: (error, _) => Center(child: Text('Erreur : $error')),
        data: (alerts) {
          if (alerts.isEmpty) return _empty(context);
          
          return RefreshIndicator(
            color: _MarketColors.red, 
            onRefresh: () async { 
              ref.invalidate(priceAlertsProvider); 
            }, 
            child: ListView.separated(
              padding: const EdgeInsets.all(16), 
              itemCount: alerts.length, 
              separatorBuilder: (ctx, index) => const SizedBox(height: 12), 
              itemBuilder: (ctx, index) => _card(context, ref, alerts[index])
            )
          );
        },
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32), 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Container(
              padding: const EdgeInsets.all(24), 
              decoration: const BoxDecoration(color: _MarketColors.creamBg, shape: BoxShape.circle), 
              child: const Icon(Icons.notifications_active_outlined, size: 64, color: _MarketColors.gold)
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucune alerte de prix', 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _MarketColors.darkText)
            ),
            const SizedBox(height: 8),
            const Text(
              'Cherchez un produit et cliquez sur la cloche pour créer une alerte.', 
              textAlign: TextAlign.center, 
              style: TextStyle(fontSize: 13, color: _MarketColors.mutedText, height: 1.4)
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/market/home'), 
              style: ElevatedButton.styleFrom(
                backgroundColor: _MarketColors.red, 
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), 
                elevation: 0
              ), 
              child: const Text('Explorer le marché', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))
            ),
          ]
        )
      )
    );
  }

  Widget _card(BuildContext context, WidgetRef ref, Map<String, dynamic> alert) {
    double current = 0;
    double target = 0;
    
    try { 
      current = (alert['current_price'] as num).toDouble(); 
    } catch (_) { 
      current = double.tryParse(alert['current_price'].toString()) ?? 0; 
    }
    
    try { 
      target = (alert['target_price'] as num).toDouble(); 
    } catch (_) { 
      target = double.tryParse(alert['target_price'].toString()) ?? 0; 
    }
    
    String currency = alert['currency'].toString();
    bool reached = current <= target;
    
    return Dismissible(
      key: Key(alert['id'].toString()), 
      direction: DismissDirection.endToStart, 
      background: Container(
        alignment: Alignment.centerRight, 
        padding: const EdgeInsets.only(right: 20), 
        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(16)), 
        child: const Icon(Icons.delete_outline, color: Colors.red)
      ), 
      onDismissed: (_) => deleteAlert(ref, context, alert['id'].toString()), 
      child: GestureDetector(
        onTap: () => context.push('/market/product/${alert['product_id']}'), 
        child: Container(
          decoration: BoxDecoration(
            color: _MarketColors.pureWhite, 
            borderRadius: BorderRadius.circular(16), 
            border: Border.all(
              color: reached ? _MarketColors.successGreen.withOpacity(0.3) : _MarketColors.cardBorder, 
              width: reached ? 1.5 : 1
            ), 
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03), 
                blurRadius: 10, 
                offset: const Offset(0, 4)
              )
            ]
          ), 
          child: Padding(
            padding: const EdgeInsets.all(12), 
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12), 
                  child: Container(
                    width: 80, height: 80, 
                    color: _MarketColors.lightBg, 
                    child: alert['image_url'].toString().isEmpty
                        ? const Icon(Icons.image_not_supported_outlined, color: _MarketColors.mutedText) 
                        : Image.network(
                            alert['image_url'].toString(), 
                            fit: BoxFit.cover, 
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                            },
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported_outlined, color: _MarketColors.mutedText),
                          )
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Text(
                        alert['title'].toString(), 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis, 
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _MarketColors.darkText)
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded, size: 12, color: _MarketColors.mutedText), 
                          const SizedBox(width: 4), 
                          Text(alert['shop_name'].toString(), style: const TextStyle(fontSize: 11, color: _MarketColors.mutedText))
                        ]
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                        crossAxisAlignment: CrossAxisAlignment.end, 
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start, 
                            children: [
                              const Text('Prix ciblé', style: TextStyle(fontSize: 9, color: _MarketColors.mutedText)), 
                              Text('${target.toInt()} $currency', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))
                            ]
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end, 
                            children: [
                              const Text('Prix actuel', style: TextStyle(fontSize: 9, color: _MarketColors.mutedText)), 
                              Text(
                                '${current.toInt()} $currency', 
                                style: TextStyle(
                                  fontWeight: FontWeight.w900, 
                                  fontSize: 16, 
                                  color: reached ? _MarketColors.successGreen : _MarketColors.red
                                )
                              )
                            ]
                          ),
                        ]
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity, 
                        padding: const EdgeInsets.symmetric(vertical: 6), 
                        decoration: BoxDecoration(
                          color: reached ? _MarketColors.successGreen.withOpacity(0.1) : _MarketColors.gold.withOpacity(0.15), 
                          borderRadius: BorderRadius.circular(8)
                        ), 
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center, 
                          children: [
                            Icon(
                              reached ? Icons.check_circle_outline : Icons.schedule, 
                              size: 14, 
                              color: reached ? _MarketColors.successGreen : _MarketColors.gold
                            ), 
                            const SizedBox(width: 6), 
                            Text(
                              reached ? 'Objectif atteint!' : 'En surveillance...', 
                              style: TextStyle(
                                fontSize: 10, 
                                fontWeight: FontWeight.bold, 
                                color: reached ? _MarketColors.successGreen : _MarketColors.gold
                              )
                            )
                          ]
                        )
                      ),
                    ]
                  )
                ),
              ]
            )
          )
        )
      )
    );
  }
}
