// lib/presentation/thix_reservation/bus/pages/client/bus_home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/bus_search_provider.dart';
import '../../providers/agency_dashboard_provider.dart';
import '../../widgets/client/bus_search_bar.dart';
import '../../widgets/client/popular_route_card.dart';
import '../agency/agency_entry_button.dart';

class BusHomePage extends StatefulWidget {
  const BusHomePage({super.key});
  @override
  State<BusHomePage> createState() => _BusHomePageState();
}

class _BusHomePageState extends State<BusHomePage> {
  @override
  void initState() {
    super.initState();
    // Précharge l'agence pour afficher le bouton si c'est un propriétaire
    Future.microtask(() => context.read<AgencyDashboardProvider>().init());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF0D47A1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.directions_bus, color: Colors.white, size: 20)),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('THIX RESERVATION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0A3D62))), Text('Réservez simplement, voyagez sereinement.', style: TextStyle(fontSize: 11, color: Colors.grey))]),
        ]),
        actions: [IconButton(onPressed: () {}, icon: Badge(count: 3, child: const Icon(Icons.notifications_outlined))), const SizedBox(width: 8)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Banner
          Container(height: 160, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)])), image: const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1570125909232-eb263c188f7e'), fit: BoxFit.cover, opacity: 0.3)), child: Stack(children: [Positioned(left: 20, top: 20, right: 120, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Bonjour, Michel 👋', style: TextStyle(color: Colors.white70, fontSize: 12)), const SizedBox(height: 6), const Text('Réservez votre bus\nen toute simplicité', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, height: 1.2)), const SizedBox(height: 12), ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0D47A1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('Réserver un bus'))]))])),
          
          const SizedBox(height: 16),
          const AgencyEntryButton(),

          const SizedBox(height: 8),
          BusSearchBar(onSearch: () => context.push('/thix-reservation/bus/search')),

          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Routes populaires', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), TextButton(onPressed: () {}, child: const Text('Voir tout'))]),
          SizedBox(height: 170, child: ListView(scrollDirection: Axis.horizontal, children: [
            PopularRouteCard(from: 'Abidjan', to: 'Yamoussoukro', dateLabel: '18 Mai • 08:00', price: '5.000 FCFA', imageUrl: 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a', onTap: () { context.read<BusSearchProvider>().setDeparture('Abidjan'); context.read<BusSearchProvider>().setArrival('Yamoussoukro'); context.push('/thix-reservation/bus/search'); }),
            PopularRouteCard(from: 'Abidjan', to: 'Bouaké', dateLabel: '18 Mai • 09:00', price: '6.000 FCFA', imageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96', onTap: () {}),
            PopularRouteCard(from: 'Abidjan', to: 'Korhogo', dateLabel: '18 Mai • 10:00', price: '7.000 FCFA', imageUrl: 'https://images.unsplash.com/photo-1449824913935-59a10b8d2000', onTap: () {}),
          ])),

          const SizedBox(height: 20),
          const Text('Nos bus pour votre confort', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: const [
            _Comfort(icon: Icons.airline_seat_recline_extra, label: 'Sièges\nconfortables'),
            _Comfort(icon: Icons.wifi, label: 'Wi-Fi\ngratuit'),
            _Comfort(icon: Icons.ac_unit, label: 'Climatisation'),
            _Comfort(icon: Icons.luggage, label: 'Bagages\nautorisés'),
            _Comfort(icon: Icons.verified_user, label: 'Sécurité\ngarantie'),
          ]),
          const SizedBox(height: 80),
        ]),
      ),
      bottomNavigationBar: BottomNavigationBar(currentIndex: 0, selectedItemColor: const Color(0xFF0D47A1), items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_outlined), label: 'Réservations'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle, size: 40, color: Color(0xFF0D47A1)), label: 'Réserver'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Favoris'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
      ]),
    );
  }
}

class _Comfort extends StatelessWidget {
  final IconData icon; final String label;
  const _Comfort({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFF0D47A1), size: 20)), const SizedBox(height: 6), Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey.shade700))]);
  }
}
