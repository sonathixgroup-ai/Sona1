import 'package:thix_id/models/market_product.dart';

/// Fallback content used when the Supabase tables are empty.
///
/// The screen still works 100% with Supabase; this list is only used for UI
/// preview in a fresh database.
class ThixMarketDemoData {
  static List<String> categories = const [
    'Tous',
    'Mode',
    'Électronique',
    'Maison',
    'Beauté',
    'Sports',
    'Auto',
    'Services',
  ];

  static List<MarketProduct> placeholderProducts = List.generate(
    10,
    (i) => MarketProduct(
      id: 'demo_$i',
      title: i.isEven ? 'Montre connectée' : 'Sneakers premium',
      price: i.isEven ? 75000 : 56000,
      oldPrice: i.isEven ? 100000 : 70000,
      discountPercent: i.isEven ? 25 : 20,
      rating: 4.6,
      ratingCount: 42,
      isFlash: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      currency: 'XOF',
      imageUrl: null,
      description: null,
      categoryId: null,
      storeId: null,
    ),
  );
}
