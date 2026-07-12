// ============================================================
// FICHIER 18 : pages/provinces/provinces_page.dart
// ============================================================
// lib/presentation/mon_pays/pages/provinces/provinces_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/provinces_provider.dart';
import '../../cards/province_card.dart';

class ProvincesPage extends ConsumerStatefulWidget {
  const ProvincesPage({super.key});

  @override
  ConsumerState<ProvincesPage> createState() => _ProvincesPageState();
}

class _ProvincesPageState extends ConsumerState<ProvincesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRegion = 'Toutes';

  static const List<String> _regions = ['Toutes', 'Centre', 'Est', 'Ouest', 'Nord', 'Sud'];

  @override
  Widget build(BuildContext context) {
    final region = _selectedRegion == 'Toutes' ? null : _selectedRegion;
    final provincesAsync = ref.watch(provincesProvider(region));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provinces de la RDC'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // focus sur la recherche
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Rechercher une province...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedRegion,
                  items: _regions.map((r) {
                    return DropdownMenuItem(value: r, child: Text(r));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedRegion = value!);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: provincesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur : $err')),
        data: (provinces) {
          final query = _searchController.text.trim().toLowerCase();
          List<Province> filtered = provinces;
          if (query.isNotEmpty) {
            filtered = provinces.where((p) =>
                p.name.toLowerCase().contains(query) ||
                p.capital.toLowerCase().contains(query) ||
                p.code.toLowerCase().contains(query)
            ).toList();
          }
          if (filtered.isEmpty) {
            return const Center(child: Text('Aucune province trouvée.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final province = filtered[i];
              return ProvinceCard(
                province: province,
                onTap: () {
                  context.push('/mon-pays/provinces/${province.id}');
                },
              );
            },
          );
        },
      ),
    );
  }
}
