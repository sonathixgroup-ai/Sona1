// lib/presentation/thix_reservation/delivery/pages/admin/delivery_admin_routes_page.dart
// FIX PROVIDER NOT FOUND - 100% FONCTIONNEL
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/delivery_admin_provider.dart';
import '../../data/delivery_models.dart';

class DeliveryAdminRoutesPage extends StatefulWidget {
  const DeliveryAdminRoutesPage({super.key});

  @override
  State<DeliveryAdminRoutesPage> createState() =>
      _DeliveryAdminRoutesPageState();
}

class _DeliveryAdminRoutesPageState extends State<DeliveryAdminRoutesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryAdminProvider>().loadRoutes(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6D28D9),
        foregroundColor: Colors.white,
        title: const Text(
          "Prix par trajet",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<DeliveryAdminProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6D28D9),
              ),
            );
          }
          if (prov.routes.isEmpty) {
            return const Center(
              child: Text(
                "Aucun trajet - Cliquez + pour créer\nEx: KOLWEZI -> LUBUMBASHI",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Color(0xFF8B8BA3)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: prov.routes.length,
            itemBuilder: (_, i) {
              final DeliveryRoute r = prov.routes[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  title: Text(
                    "${r.fromCity} → ${r.toCity}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    "Base ${r.basePrice} FCFA | Express ${r.expressPrice} FCFA | ${r.distanceKm} km",
                    style: const TextStyle(fontSize: 9),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    onPressed: () => prov.deleteRoute(r.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6D28D9),
        onPressed: () => _openCreateDialog(context),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  // FIX PROVIDER NOT FOUND ICI
  void _openCreateDialog(BuildContext context) {
    // On capture le provider AVANT le showDialog
    final adminProv = context.read<DeliveryAdminProvider>();

    final fromCtrl = TextEditingController();
    final toCtrl = TextEditingController();
    final baseCtrl = TextEditingController(text: "3000");
    final expressCtrl = TextEditingController(text: "5000");
    final supCtrl = TextEditingController(text: "500");
    final distCtrl = TextEditingController(text: "230");
    bool isInter = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text("Nouveau trajet"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: fromCtrl,
                      decoration: const InputDecoration(
                        labelText: "De (ex: Abidjan)",
                      ),
                    ),
                    TextField(
                      controller: toCtrl,
                      decoration: const InputDecoration(
                        labelText: "Vers (ex: Yamoussoukro)",
                      ),
                    ),
                    TextField(
                      controller: baseCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Prix base 0-5kg (FCFA)",
                      ),
                    ),
                    TextField(
                      controller: expressCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Prix express 0-5kg",
                      ),
                    ),
                    TextField(
                      controller: supCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Supplément /kg au delà 5kg",
                      ),
                    ),
                    TextField(
                      controller: distCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Distance km",
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text("International"),
                        const Spacer(),
                        Checkbox(
                          value: isInter,
                          onChanged: (v) => setState(() => isInter = v?? false),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6D28D9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    // On utilise adminProv capturé, pas context.read
                    await adminProv.createRoute(
                      fromCity: fromCtrl.text.trim().toUpperCase(),
                      toCity: toCtrl.text.trim().toUpperCase(),
                      basePrice: int.tryParse(baseCtrl.text)?? 3000,
                      expressPrice: int.tryParse(expressCtrl.text)?? 5000,
                      pricePerKg: int.tryParse(supCtrl.text)?? 500,
                      distanceKm: int.tryParse(distCtrl.text)?? 0,
                      isInternational: isInter,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text(
                    "Créer",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
