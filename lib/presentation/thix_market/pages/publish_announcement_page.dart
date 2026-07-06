import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/selling/publish_announcement_form.dart';

class PublishAnnouncementPage extends StatefulWidget {
  const PublishAnnouncementPage({super.key});

  @override
  State<PublishAnnouncementPage> createState() => _PublishAnnouncementPageState();
}

class _PublishAnnouncementPageState extends State<PublishAnnouncementPage> {
  String? _selectedShopId;
  bool _isLoadingShops = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadShops();
    });
  }

  Future<void> _loadShops() async {
    final shopProvider = context.read<ShopProvider>();
    await shopProvider.loadMyShops();
    setState(() {
      _isLoadingShops = false;
      if (shopProvider.myShops.isNotEmpty) {
        _selectedShopId = shopProvider.myShops.first['id'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = context.watch<ShopProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Publier une annonce',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoadingShops
          ? const Center(child: CircularProgressIndicator())
          : shopProvider.myShops.isEmpty
              ? _buildNoShopView()
              : _buildForm(shopProvider),
    );
  }

  Widget _buildNoShopView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Vous n\'avez pas encore de boutique',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez une boutique pour pouvoir publier des annonces',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/market/shop/create'),
              icon: const Icon(Icons.add),
              label: const Text('Créer une boutique'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(ShopProvider shopProvider) {
    final shops = shopProvider.myShops;

    return Column(
      children: [
        if (shops.length > 1)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Sélectionner une boutique',
                      border: InputBorder.none,
                    ),
                    value: _selectedShopId,
                    items: shops.map((shop) {
                      return DropdownMenuItem(
                        value: shop['id'],
                        child: Row(
                          children: [
                            if (shop['logo_url'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  shop['logo_url'],
                                  width: 24,
                                  height: 24,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.store, size: 16),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Text(shop['name'] ?? 'Boutique'),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedShopId = value;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
        if (_selectedShopId != null)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: PublishAnnouncementForm(
                shopId: _selectedShopId!,
                onSuccess: (response) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Annonce publiée avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.pop();
                },
              ),
            ),
          ),
      ],
    );
  }
}
