import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin_provider.dart';

class AdminPromotionsPage extends StatefulWidget {
  const AdminPromotionsPage({super.key});

  @override
  State<AdminPromotionsPage> createState() => _AdminPromotionsPageState();
}

class _AdminPromotionsPageState extends State<AdminPromotionsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _discountController = TextEditingController();
  String _discountType = 'percentage';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadPromotions();
      context.read<AdminProvider>().loadBanners();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Promotions'),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(tabs: [
            Tab(text: 'Codes promo'),
            Tab(text: 'Bannières'),
          ]),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddPromotionDialog(context),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildPromotionsTab(),
            _buildBannersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionsTab() {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.promotions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.promotions.isEmpty) {
          return const Center(child: Text('Aucune promotion'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.promotions.length,
          itemBuilder: (context, index) {
            final promo = provider.promotions[index];
            return Card(
              child: ListTile(
                title: Text(promo['name']),
                subtitle: Text('Code: ${promo['code']} - ${promo['discount_value']}${promo['discount_type'] == 'percentage' ? '%' : ' FCFA'}'),
                trailing: Switch(
                  value: promo['is_active'] ?? false,
                  onChanged: (value) => provider.updatePromotionStatus(promo['id'], value),
                  activeColor: const Color(0xFFE5592F),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBannersTab() {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.banners.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.banners.length,
          itemBuilder: (context, index) {
            final banner = provider.banners[index];
            return Card(
              child: ListTile(
                leading: Image.network(banner['image_url'], width: 60, height: 60, fit: BoxFit.cover),
                title: Text(banner['title'] ?? 'Bannière'),
                subtitle: Text('Ordre: ${banner['sort_order']}'),
                trailing: Switch(
                  value: banner['is_active'] ?? false,
                  onChanged: (value) => provider.updateBannerStatus(banner['id'], value),
                  activeColor: const Color(0xFFE5592F),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddPromotionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle promotion'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nom'), validator: (v) => v!.isEmpty ? 'Requis' : null),
              TextFormField(controller: _codeController, decoration: const InputDecoration(labelText: 'Code promo'), validator: (v) => v!.isEmpty ? 'Requis' : null),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _discountController, decoration: const InputDecoration(labelText: 'Valeur'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _discountType,
                    items: const [
                      DropdownMenuItem(value: 'percentage', child: Text('%')),
                      DropdownMenuItem(value: 'fixed', child: Text('FCFA')),
                    ],
                    onChanged: (v) => setState(() => _discountType = v!),
                  ),
                ],
              ),
              ListTile(title: Text('Début: ${_startDate.toString().substring(0, 10)}'), trailing: const Icon(Icons.calendar_today), onTap: () async {
                final date = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (date != null) setState(() => _startDate = date);
              }),
              ListTile(title: Text('Fin: ${_endDate.toString().substring(0, 10)}'), trailing: const Icon(Icons.calendar_today), onTap: () async {
                final date = await showDatePicker(context: context, initialDate: _endDate, firstDate: _startDate, lastDate: DateTime.now().add(const Duration(days: 365)));
                if (date != null) setState(() => _endDate = date);
              }),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                context.read<AdminProvider>().createPromotion({
                  'name': _nameController.text,
                  'code': _codeController.text,
                  'discount_value': double.parse(_discountController.text),
                  'discount_type': _discountType,
                  'start_date': _startDate.toIso8601String(),
                  'end_date': _endDate.toIso8601String(),
                  'is_active': true,
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5592F)),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}
