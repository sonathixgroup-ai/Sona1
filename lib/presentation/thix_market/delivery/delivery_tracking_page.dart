import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'delivery_provider.dart';

class DeliveryTrackingPage extends StatefulWidget {
  final String orderId;

  const DeliveryTrackingPage({super.key, required this.orderId});

  @override
  State<DeliveryTrackingPage> createState() => _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState extends State<DeliveryTrackingPage> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  LatLng? _currentLocation;
  LatLng? _destinationLocation;

  // ─── Couleurs de la marque THIX ───
  static const Color thixOrange = Color(0xFFE5592F);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryProvider>().trackDelivery(widget.orderId);
    });
  }

  void _updateMap(DeliveryProvider provider) {
    final tracking = provider.currentTracking;
    if (tracking == null) return;

    final driverLat = tracking['driver']?['current_lat'] as double?;
    final driverLng = tracking['driver']?['current_lng'] as double?;
    final destLat = tracking['dest_latitude'] as double?;
    final destLng = tracking['dest_longitude'] as double?;

    if (driverLat != null && driverLng != null) {
      _currentLocation = LatLng(driverLat, driverLng);
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange), // Marqueur Orange THIX
          infoWindow: const InfoWindow(title: 'Votre livreur'),
        ),
      );
    }

    if (destLat != null && destLng != null) {
      _destinationLocation = LatLng(destLat, destLng);
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Lieu de livraison'),
        ),
      );
    }

    if (_currentLocation != null) {
      _mapController.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation!, 15));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true, // La carte passe sous l'AppBar
      appBar: AppBar(
        title: const Text(
          'Suivi de commande',
          style: TextStyle(fontWeight: FontWeight.w800, color: darkText),
        ),
        backgroundColor: Colors.white.withOpacity(0.9), // Effet translucide
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkText),
      ),
      body: Consumer<DeliveryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingTracking) {
            return const Center(child: CircularProgressIndicator(color: thixOrange));
          }

          final tracking = provider.currentTracking;
          if (tracking == null) {
            return _buildEmptyState();
          }

          return Stack(
            children: [
              // 1. La Carte en arrière-plan (prend tout l'écran)
              Positioned.fill(
                child: GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _updateMap(provider);
                  },
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(-4.322447, 15.307045), // Kinshasa par défaut
                    zoom: 13,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false, // On désactive pour un look plus épuré
                ),
              ),

              // 2. Le Panneau d'informations en bas (effet bottom sheet persistant)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      // Petite barre de glissement (drag handle visuel)
                      Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Informations du livreur (si disponible)
                      if (tracking['driver'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildDriverCard(tracking['driver']),
                        ),
                      
                      if (tracking['driver'] != null)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Divider(height: 1),
                        ),

                      // Frise chronologique (Timeline)
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: _buildStatusTimeline(tracking),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── CARTE DU LIVREUR (DESIGN PREMIUM) ───
  Widget _buildDriverCard(Map<String, dynamic> driver) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: thixOrange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: thixOrange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: thixOrange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: thixOrange, size: 28),
          ),
          const SizedBox(width: 16),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: darkText),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.directions_car_rounded, size: 14, color: mutedText),
                    const SizedBox(width: 4),
                    Text(
                      driver['vehicle'] as String? ?? 'Véhicule THIX',
                      style: TextStyle(fontSize: 13, color: mutedText, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bouton d'appel
          Container(
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.phone_rounded, color: Colors.white),
              onPressed: () {
                // TODO: Ajouter la logique pour lancer l'appel téléphonique (url_launcher)
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── TIMELINE DE STATUT (FRISE CHRONOLOGIQUE) ───
  Widget _buildStatusTimeline(Map<String, dynamic> tracking) {
    final statuses = [
      {'key': 'preparing', 'label': 'Commande confirmée', 'desc': 'Votre commande est en cours de préparation', 'icon': Icons.inventory_2_rounded},
      {'key': 'picked_up', 'label': 'Colis récupéré', 'desc': 'Le livreur a récupéré votre commande', 'icon': Icons.storefront_rounded},
      {'key': 'in_transit', 'label': 'En route', 'desc': 'Votre commande est en chemin', 'icon': Icons.local_shipping_rounded},
      {'key': 'out_for_delivery', 'label': 'En approche', 'desc': 'Le livreur est proche de chez vous', 'icon': Icons.location_on_rounded},
      {'key': 'delivered', 'label': 'Livré', 'desc': 'Commande remise avec succès', 'icon': Icons.check_circle_rounded},
    ];

    final currentStatus = tracking['status'] as String? ?? 'preparing';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Détails de la livraison',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: darkText),
        ),
        const SizedBox(height: 24),
        ...List.generate(statuses.length, (index) {
          final status = statuses[index];
          final statusKey = status['key'] as String;
          final isCompleted = _isStatusCompleted(currentStatus, statusKey);
          final isCurrent = currentStatus == statusKey;
          final isLast = index == statuses.length - 1;

          return _buildTimelineItem(
            status: status,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            isLast: isLast,
          );
        }),
      ],
    );
  }

  Widget _buildTimelineItem({
    required Map<String, dynamic> status,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    final activeColor = isCompleted ? Colors.green : (isCurrent ? thixOrange : Colors.grey[300]!);
    final iconColor = (isCompleted || isCurrent) ? Colors.white : Colors.grey[500]!;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Colonne de gauche : Icône + Ligne verticale
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
                boxShadow: isCurrent ? [
                  BoxShadow(color: thixOrange.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))
                ] : [],
              ),
              child: Icon(status['icon'] as IconData, color: iconColor, size: 20),
            ),
            if (!isLast)
              Container(
                width: 3,
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Colonne de droite : Textes
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status['label'] as String,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 16,
                    color: (isCompleted || isCurrent) ? darkText : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status['desc'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: isCurrent ? mutedText : Colors.grey[400],
                    height: 1.3,
                  ),
                ),
                if (!isLast) const SizedBox(height: 24), // Espace compensatoire pour la ligne
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Suivi indisponible', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkText)),
          const SizedBox(height: 8),
          Text('Les informations de suivi pour cette\ncommande ne sont pas encore prêtes.', textAlign: TextAlign.center, style: TextStyle(color: mutedText)),
        ],
      ),
    );
  }

  bool _isStatusCompleted(String current, String statusKey) {
    const order = ['preparing', 'picked_up', 'in_transit', 'out_for_delivery', 'delivered'];
    final currentIndex = order.indexOf(current);
    final statusIndex = order.indexOf(statusKey);
    return statusIndex < currentIndex;
  }
}
