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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryProvider>().trackDelivery(widget.orderId);
    });
  }

  void _updateMap(provider) {
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Livreur'),
        ),
      );
    }

    if (destLat != null && destLng != null) {
      _destinationLocation = LatLng(destLat, destLng);
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      );
    }

    if (_currentLocation != null) {
      _mapController.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation!, 14));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Suivi de livraison'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<DeliveryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingTracking) {
            return const Center(child: CircularProgressIndicator());
          }

          final tracking = provider.currentTracking;
          if (tracking == null) {
            return const Center(child: Text('Aucune information de suivi'));
          }

          return Column(
            children: [
              // Carte
              Expanded(
                flex: 2,
                child: GoogleMap(
                  onMapCreated: (controller) => _mapController = controller,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(5.359952, -4.008256), // Abidjan
                    zoom: 12,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: (_) => _updateMap(provider),
                ),
              ),
              // Timeline statut
              Expanded(
                child: _buildStatusTimeline(tracking),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusTimeline(Map<String, dynamic> tracking) {
    final statuses = [
      {'key': 'preparing', 'label': 'Préparation', 'icon': Icons.inventory},
      {'key': 'picked_up', 'label': 'Récupéré', 'icon': Icons.check_circle},
      {'key': 'in_transit', 'label': 'En transit', 'icon': Icons.local_shipping},
      {'key': 'out_for_delivery', 'label': 'En livraison', 'icon': Icons.delivery_dining},
      {'key': 'delivered', 'label': 'Livré', 'icon': Icons.home},
    ];

    final currentStatus = tracking['status'];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Statut de la livraison', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: statuses.length,
              itemBuilder: (context, index) {
                final status = statuses[index];
                final isCompleted = _isStatusCompleted(currentStatus, status['key']);
                final isCurrent = currentStatus == status['key'];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.withOpacity(0.1)
                          : isCurrent
                              ? const Color(0xFFE5592F).withOpacity(0.1)
                              : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      status['icon'],
                      color: isCompleted
                          ? Colors.green
                          : isCurrent
                              ? const Color(0xFFE5592F)
                              : Colors.grey,
                    ),
                  ),
                  title: Text(
                    status['label'],
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted
                          ? Colors.green
                          : isCurrent
                              ? const Color(0xFFE5592F)
                              : Colors.grey[700],
                    ),
                  ),
                  trailing: isCompleted
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                      : null,
                );
              },
            ),
          ),
          // Infos livreur
          if (tracking['driver'] != null)
            Card(
              margin: const EdgeInsets.only(top: 16),
              child: ListTile(
                leading: const Icon(Icons.person, color: Color(0xFFE5592F)),
                title: Text(tracking['driver']['name']),
                subtitle: Text(tracking['driver']['phone'] ?? ''),
                trailing: Text(tracking['driver']['vehicle'] ?? '', style: const TextStyle(fontSize: 12)),
              ),
            ),
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
