import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'delivery_provider.dart';

class PickupPointsPage extends StatefulWidget {
  final Function(Map<String, dynamic>)? onPointSelected;

  const PickupPointsPage({super.key, this.onPointSelected});

  @override
  State<PickupPointsPage> createState() => _PickupPointsPageState();
}

class _PickupPointsPageState extends State<PickupPointsPage> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DeliveryProvider>();
      provider.loadNearbyPickupPoints();
      _setUserLocation(provider);
    });
  }

  void _setUserLocation(DeliveryProvider provider) {
    if (provider.currentPosition != null) {
      _userLocation = LatLng(provider.currentPosition!.latitude, provider.currentPosition!.longitude);
      _addUserMarker();
      _mapController.animateCamera(CameraUpdate.newLatLngZoom(_userLocation!, 12));
    }
  }

  void _addUserMarker() {
    if (_userLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: _userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Votre position'),
        ),
      );
    }
  }

  void _addPickupMarkers(List<Map<String, dynamic>> points) {
    for (var point in points) {
      final lat = point['latitude'] as double;
      final lng = point['longitude'] as double;
      _markers.add(
        Marker(
          markerId: MarkerId(point['id']),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: point['name'],
            snippet: point['address'],
          ),
          onTap: () => _showPointDetails(point),
        ),
      );
    }
    setState(() {});
  }

  void _showPointDetails(Map<String, dynamic> point) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(point['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(point['address']),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.access_time, size: 16), const SizedBox(width: 4), Text(point['opening_hours'] ?? '8h - 18h')]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onPointSelected?.call(point);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5592F)),
                child: const Text('Sélectionner ce point relais'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Points relais THIX'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<DeliveryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingPickupPoints) {
            return const Center(child: CircularProgressIndicator());
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (provider.pickupPoints.isNotEmpty && _markers.length <= 1) {
              _addPickupMarkers(provider.pickupPoints);
            }
          });

          return Stack(
            children: [
              GoogleMap(
                onMapCreated: (controller) => _mapController = controller,
                initialCameraPosition: CameraPosition(
                  target: _userLocation ?? const LatLng(5.359952, -4.008256),
                  zoom: 12,
                ),
                markers: _markers,
                myLocationEnabled: true,
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const Text('Points relais à proximité', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...provider.pickupPoints.take(3).map((point) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.store, color: Color(0xFFE5592F)),
                          title: Text(point['name']),
                          subtitle: Text('${(point['distance_km'] as num?)?.toStringAsFixed(1)} km'),
                          trailing: IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => _showPointDetails(point),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
