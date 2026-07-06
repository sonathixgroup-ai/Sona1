import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/live/create_live_form.dart';

class CreateLivePage extends StatefulWidget {
  const CreateLivePage({super.key});

  @override
  State<CreateLivePage> createState() => _CreateLivePageState();
}

class _CreateLivePageState extends State<CreateLivePage> {
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
      appBar: AppBar(
        title: const Text('Créer un live'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingShops
          ? const Center(child: CircularProgressIndicator())
          : shopProvider.myShops.isEmpty
              ? _buildNoShopView()
              : _buildForm(shopProvider),
    );
  }

  // ========== CORRECTION 1 : Icons.store_off → Icons.storefront ==========
  Widget _buildNoShopView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.storefront, size: 64, color: Colors.grey), // ✅
          const SizedBox(height: 16),
          const Text(
            'Vous n\'avez pas encore de boutique',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez une boutique pour pouvoir créer un live',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/market/shop/create');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Créer une boutique'),
          ),
        ],
      ),
    );
  }

  // ========== CORRECTION 2 : ajout de <String> pour DropdownMenuItem ==========
  Widget _buildForm(ShopProvider shopProvider) {
    final shops = shopProvider.myShops;

    return Column(
      children: [
        if (shops.length > 1)
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Sélectionner une boutique',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              value: _selectedShopId,
              items: shops.map<DropdownMenuItem<String>>((shop) {   // ✅
                return DropdownMenuItem<String>(                     // ✅
                  value: shop['id'],
                  child: Text(shop['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedShopId = value;
                });
              },
            ),
          ),
        if (_selectedShopId != null)
          Expanded(
            child: SingleChildScrollView(
              child: CreateLiveForm(shopId: _selectedShopId!),
            ),
          ),
      ],
    );
  }
}
