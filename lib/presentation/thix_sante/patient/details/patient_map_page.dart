// presentation/thix_sante/patient/details/patient_map_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';
import 'package:thix_id/supabase/supabase_config.dart';

enum MapCategory { pharmacies, hospitals, emergencies }

class PatientMapPage extends StatefulWidget {
  final String type; // 'pharmacies', 'hospitals', 'emergencies'

  const PatientMapPage({super.key, required this.type});

  @override
  State<PatientMapPage> createState() => _PatientMapPageState();
}

class _PatientMapPageState extends State<PatientMapPage> {
  final HealthService _healthService = HealthService.instance;
  final _mapController = MapController();

  bool _isLoading = true;
  bool _hasLocation = false;
  String? _error;
  LatLng? _currentLocation;

  List<Pharmacy> _pharmacies = [];
  List<Pharmacy> _hospitals = [];
  List<Pharmacy> _emergencies = [];

  MapCategory _selectedCategory = MapCategory.pharmacies;
  bool _showList = true;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categoryFromString(widget.type);
    _initLocation();
  }

  MapCategory _categoryFromString(String type) {
    switch (type) {
      case 'pharmacies':
        return MapCategory.pharmacies;
      case 'hospitals':
        return MapCategory.hospitals;
      case 'emergencies':
        return MapCategory.emergencies;
      default:
        return MapCategory.pharmacies;
    }
  }

  Future<void> _initLocation() async {
    try {
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Permission de localisation refusée.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'La localisation est désactivée. Activez-la dans les paramètres.';
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _hasLocation = true;
      });
      await _loadPlaces();
    } catch (e) {
      setState(() {
        _error = 'Erreur de localisation : $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPlaces() async {
    if (_currentLocation == null) return;

    setState(() => _isLoading = true);

    try {
      // Charger les pharmacies
      final pharmacies = await _healthService.findNearbyPharmacies(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );
      setState(() {
        _pharmacies = pharmacies;
      });

      // Charger les hôpitaux (depuis la même table avec type='hospital' ou table dédiée)
      // On suppose qu'il y a une table health_hospitals
      final hospitalsData = await SupabaseConfig.client
          .from('health_hospitals')
          .select('*')
          .limit(50);
      if (hospitalsData is List) {
        _hospitals = hospitalsData
            .map((e) => Pharmacy(
                  id: e['id'],
                  name: e['name'] ?? 'Hôpital',
                  address: e['address'] ?? '',
                  phone: e['phone'],
                  latitude: (e['latitude'] as num?)?.toDouble(),
                  longitude: (e['longitude'] as num?)?.toDouble(),
                  isOpen: e['is_open'] ?? true,
                ))
            .toList();
      }

      // Urgences = hôpitaux avec service d'urgence (ou on filtre)
      _emergencies = _hospitals.where((h) => h.isOpen).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur de chargement des lieux : $e';
        _isLoading = false;
      });
    }
  }

  List<Pharmacy> get _currentPlaces {
    switch (_selectedCategory) {
      case MapCategory.pharmacies:
        return _pharmacies;
      case MapCategory.hospitals:
        return _hospitals;
      case MapCategory.emergencies:
        return _emergencies;
    }
  }

  String get _categoryTitle {
    switch (_selectedCategory) {
      case MapCategory.pharmacies:
        return 'Pharmacies';
      case MapCategory.hospitals:
        return 'Hôpitaux';
      case MapCategory.emergencies:
        return 'Urgences';
    }
  }

  IconData get _categoryIcon {
    switch (_selectedCategory) {
      case MapCategory.pharmacies:
        return Icons.local_pharmacy;
      case MapCategory.hospitals:
        return Icons.local_hospital;
      case MapCategory.emergencies:
        return Icons.emergency;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_categoryTitle),
        actions: [
          IconButton(
            icon: Icon(_showList ? Icons.map : Icons.list),
            onPressed: () => setState(() => _showList = !_showList),
            tooltip: _showList ? 'Voir la carte' : 'Voir la liste',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlaces,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(_error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _initLocation,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : !_hasLocation
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Localisation en cours...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // Filtres (catégories)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              _CategoryChip(
                                label: 'Pharmacies',
                                icon: Icons.local_pharmacy,
                                selected: _selectedCategory == MapCategory.pharmacies,
                                onTap: () => setState(() => _selectedCategory = MapCategory.pharmacies),
                              ),
                              const SizedBox(width: 8),
                              _CategoryChip(
                                label: 'Hôpitaux',
                                icon: Icons.local_hospital,
                                selected: _selectedCategory == MapCategory.hospitals,
                                onTap: () => setState(() => _selectedCategory = MapCategory.hospitals),
                              ),
                              const SizedBox(width: 8),
                              _CategoryChip(
                                label: 'Urgences',
                                icon: Icons.emergency,
                                selected: _selectedCategory == MapCategory.emergencies,
                                onTap: () => setState(() => _selectedCategory = MapCategory.emergencies),
                              ),
                            ],
                          ),
                        ),
                        // Carte + liste
                        Expanded(
                          child: Stack(
                            children: [
                              // Carte
                              if (_showList)
                                _buildMap()
                              else
                                _buildList(),
                              // Bouton retour à la position
                              Positioned(
                                bottom: 20,
                                right: 20,
                                child: FloatingActionButton.small(
                                  onPressed: () {
                                    if (_currentLocation != null) {
                                      _mapController.move(_currentLocation!, 14);
                                    }
                                  },
                                  child: const Icon(Icons.my_location),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildMap() {
    if (_currentLocation == null) return const SizedBox.shrink();

    final markers = _currentPlaces.map((place) {
      if (place.latitude == null || place.longitude == null) return null;
      return Marker(
        point: LatLng(place.latitude!, place.longitude!),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            // Afficher les infos du lieu
            _showPlaceDetails(place);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _categoryIcon,
              size: 22,
              color: const Color(0xFF2563FF),
            ),
          ),
        ),
      );
    }).whereType<Marker>().toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLocation!,
        initialZoom: 14,
        minZoom: 8,
        maxZoom: 18,
        onTap: (_, __) => setState(() {}), // pour fermer les popups
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.thix_id',
        ),
        MarkerLayer(markers: markers),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () {},
            ),
          ],
        ),
        // Marqueur de position actuelle
        MarkerLayer(
          markers: [
            Marker(
              point: _currentLocation!,
              width: 20,
              height: 20,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF2563FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildList() {
    final places = _currentPlaces;
    if (places.isEmpty) {
      return const Center(
        child: Text('Aucun établissement trouvé à proximité.'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: places.length,
      itemBuilder: (context, index) {
        final place = places[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(_categoryIcon, color: const Color(0xFF2563FF)),
            title: Text(place.name),
            subtitle: Text(place.address),
            trailing: place.isOpen
                ? const Chip(
                    label: Text('Ouvert'),
                    backgroundColor: Colors.green,
                  )
                : const Chip(
                    label: Text('Fermé'),
                    backgroundColor: Colors.grey,
                  ),
            onTap: () => _showPlaceDetails(place),
          ),
        );
      },
    );
  }

  void _showPlaceDetails(Pharmacy place) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_categoryIcon, color: const Color(0xFF2563FF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      place.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(place.address),
              if (place.phone != null) Text('📞 ${place.phone}'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(place.isOpen ? 'Ouvert' : 'Fermé'),
                    backgroundColor: place.isOpen ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  if (place.latitude != null && place.longitude != null)
                    OutlinedButton(
                      onPressed: () {
                        // Ouvrir Google Maps pour l'itinéraire
                        // TODO: implémenter l'ouverture de Google Maps
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Itinéraire à implémenter'),
                          ),
                        );
                      },
                      child: const Text('Itinéraire'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFF2563FF).withOpacity(0.2),
      checkmarkColor: const Color(0xFF2563FF),
    );
  }
}
