// ================================================================
// CHEMIN: lib/presentation/thix_reservation/delivery/pages/admin/delivery_admin_routes_page.dart
// ROLE: ADMIN FIXE PRIX PAR TRAJET - CRUD delivery_routes
// C'est ici que tu crées Abidjan->Yakro = 3000F
// Le client verra ce prix automatiquement sur Home
// SCALABLE: Form validation + cache invalidé auto
// ================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/delivery_admin_provider.dart';
import '../../widgets/delivery_admin_widgets.dart';

class DeliveryAdminRoutesPage extends StatefulWidget {
  const DeliveryAdminRoutesPage({super.key});

  @override
  State<DeliveryAdminRoutesPage> createState() => _DeliveryAdminRoutesPageState();
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
      appBar: AppBar(title: const Text("Prix par trajet"), backgroundColor: const Color(0xFF6D28D9), foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6D28D9),
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<DeliveryAdminProvider>(
        builder: (context, prov, _) {
          if (prov.routes.isEmpty) return const Center(child: Text("Aucun trajet, crée le premier"));

          // Liste scalable avec builder
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prov.routes.length,
            itemBuilder: (context, i) {
              final route = prov.routes[i];
              return AdminRouteCard(
                route: route,
                onEdit: () => _showEditDialog(context, route),
                onDelete: () async {
                  final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text("Supprimer?"), content: Text("${route.fromCity} → ${route.toCity}"), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Non")), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Oui"))]));
                  if (confirm == true) await prov.deleteRoute(route.id);
                },
              );
            },
          );
        },
      ),
    );
  }

  // --- DIALOG CREATE TRAJET ---
  void _showCreateDialog(BuildContext context) {
    final fromCtrl = TextEditingController();
    final toCtrl = TextEditingController();
    final baseCtrl = TextEditingController(text: "3000");
    final expressCtrl = TextEditingController(text: "5000");
    final perKgCtrl = TextEditingController(text: "500");
    final distCtrl = TextEditingController(text: "100");
    bool isInter = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          title: const Text("Nouveau trajet"),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: fromCtrl, decoration: const InputDecoration(labelText: "De (ex: Abidjan)")),
              TextField(controller: toCtrl, decoration: const InputDecoration(labelText: "Vers (ex: Yamoussoukro)")),
              TextField(controller: baseCtrl, decoration: const InputDecoration(labelText: "Prix base 0-5kg (FCFA)"), keyboardType: TextInputType.number),
              TextField(controller: expressCtrl, decoration: const InputDecoration(labelText: "Prix express 0-5kg"), keyboardType: TextInputType.number),
              TextField(controller: perKgCtrl, decoration: const InputDecoration(labelText: "Supplément /kg au delà 5kg"), keyboardType: TextInputType.number),
              TextField(controller: distCtrl, decoration: const InputDecoration(labelText: "Distance km"), keyboardType: TextInputType.number),
              CheckboxListTile(title: const Text("International"), value: isInter, onChanged: (v) => setS(() => isInter = v!)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6D28D9)),
              onPressed: () async {
                try {
                  await context.read<DeliveryAdminProvider>().createRoute(
                        fromCity: fromCtrl.text,
                        toCity: toCtrl.text,
                        basePrice: int.parse(baseCtrl.text),
                        expressPrice: int.parse(expressCtrl.text),
                        pricePerKg: int.parse(perKgCtrl.text),
                        distanceKm: int.parse(distCtrl.text),
                        isInternational: isInter,
                      );
                  if (context.mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trajet créé ✅")));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
                }
              },
              child: const Text("Créer", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, dynamic route) {
    final baseCtrl = TextEditingController(text: route.basePrice.toString());
    final expressCtrl = TextEditingController(text: route.expressPrice.toString());
    final perKgCtrl = TextEditingController(text: route.pricePerKg.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Modifier ${route.fromCity} → ${route.toCity}"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: baseCtrl, decoration: const InputDecoration(labelText: "Base"), keyboardType: TextInputType.number),
          TextField(controller: expressCtrl, decoration: const InputDecoration(labelText: "Express"), keyboardType: TextInputType.number),
          TextField(controller: perKgCtrl, decoration: const InputDecoration(labelText: "Par kg"), keyboardType: TextInputType.number),
        ]),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await context.read<DeliveryAdminProvider>().updateRoute(id: route.id, basePrice: int.parse(baseCtrl.text), expressPrice: int.parse(expressCtrl.text), pricePerKg: int.parse(perKgCtrl.text));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Sauver"),
          )
        ],
      ),
    );
  }
}
