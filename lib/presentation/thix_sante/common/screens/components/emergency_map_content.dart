// 📁 lib/presentation/thix_sante/common/screens/_components/emergency_map_content.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../services/location/map_service.dart';
import '../../widgets/gradient_button.dart';

class EmergencyMapContent extends ConsumerStatefulWidget {
  const EmergencyMapContent({Key? key}) : super(key: key);

  @override
  ConsumerState<EmergencyMapContent> createState() => _EmergencyMapContentState();
}

class _EmergencyMapContentState extends ConsumerState<EmergencyMapContent> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _currentLocation;
  bool _isLoading = true;
  String _selectedType = 'all';

  final List<String> _filterTypes = ['all', 'hospital', 'pharmacy', 'clinic'];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final location = await MapService.getCurrentLocation();
    if (location != null && mounted) {
      setState(() {
        _currentLocation = LatLng(location.latitude, location.longitude);
        _isLoading = false;
      });
      _loadNearbyPlaces();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNearbyPlaces() async {
    if (_currentLocation == null) return;
    final places = await MapService.getNearbyEmergency(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      type: _selectedType,
    );
    setState(() {
      _markers.clear();
      for (final place in places) {
        _markers.add(
          Marker(
            markerId: MarkerId(place['id']),
            position: LatLng(place['lat'], place['lng']),
            infoWindow: InfoWindow(
              title: place['name'],
              snippet: place['address'],
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              place['type'] == 'hospital' ? BitmapDescriptor.hueRed :
              place['type'] == 'pharmacy' ? BitmapDescriptor.hueGreen :
              BitmapDescriptor.hueBlue,
            ),
          ),
        );
      }
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation!, 14));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentLocation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('Position non disponible', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            GradientButton(
              text: 'Réessayer',
              onPressed: _getCurrentLocation,
              width: 150,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Filtres
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: _filterTypes.map((type) {
              final isSelected = _selectedType == type;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedType = type);
                  _loadNearbyPlaces();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    type == 'all' ? 'Tous' : (type == 'hospital' ? 'Hôpitaux' : (type == 'pharmacy' ? 'Pharmacies' : 'Cliniques')),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Carte
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation!,
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
          ),
        ),
        // Bouton d'urgence
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            children: [
              Expanded(
                child: GradientButton(
                  text: '🚨 Appeler le 15',
                  onPressed: () => MapService.callEmergency(),
                  gradient: const LinearGradient(colors: [Colors.red, Colors.redAccent]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
