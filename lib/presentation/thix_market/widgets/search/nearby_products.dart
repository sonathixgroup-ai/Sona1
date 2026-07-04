import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NearbyProducts extends StatefulWidget {
  final Function(Map<String, dynamic>)? onProductTap;
  final double? radiusKm;

  const NearbyProducts({
    super.key,
    this.onProductTap,
    this.radiusKm = 10,
  });

  @override
  State<NearbyProducts> createState() => _NearbyProductsState();
}

class _NearbyProductsState extends State<NearbyProducts> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  Position? _currentPosition;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkLocationAndLoad();
  }

  Future<void> _checkLocationAndLoad() async {
    await _checkLocationPermission();
    if (_hasLocationPermission) {
      await _getCurrentLocation();
      await _loadNearbyProducts();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = 'Autorisation de localisation refusée';
          _hasLocationPermission = false;
        });
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMessage = 'Les autorisations de localisation sont désactivées de façon permanente';
        _hasLocationPermission = false;
      });
      return;
    }
    
    setState(() => _hasLocationPermission = true);
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _currentPosition = position);
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() => _errorMessage = 'Impossible d\'obtenir votre position');
    }
  }

  Future<void> _loadNearbyProducts() async {
    if (_currentPosition == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final response = await Supabase.instance.client
          .rpc('nearby_products', params: {
            'lat': _currentPosition!.latitude,
            'lng': _currentPosition!.longitude,
            'radius_km': widget.radiusKm,
            'limit': 20,
          });
      
      if (mounted) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading nearby products: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur lors du chargement des produits';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingShimmer();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (!_hasLocationPermission) {
      return _buildPermissionDenied();
    }

    if (_products.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec distance
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: Color(0xFFE5592F)),
              const SizedBox(width: 4),
              Text(
                'À moins de ${widget.radiusKm} km',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _loadNearbyProducts(),
                child: const Text('Actualiser'),
              ),
            ],
          ),
        ),
        
        // Liste des produits
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              return _buildProductCard(_products[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () => widget.onProductTap?.call(product),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: product['image_url'],
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 150,
                  color: Colors.grey[200],
                ),
              ),
            ),
            
            // Infos
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 10, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product['distance_km'].toStringAsFixed(1),
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product['price'].toInt()} FCFA',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE5592F),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              SizedBox(width: 80, height: 20, child: ColoredBox(color: Colors.grey)),
            ],
          ),
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 4,
            itemBuilder: (context, index) => Container(
              width: 180,
              margin: const EdgeInsets.only(right: 12),
              color: Colors.grey[200],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _checkLocationAndLoad,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5592F),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          const Text(
            'Activez la localisation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Pour voir les produits près de chez vous',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _checkLocationAndLoad,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5592F),
            ),
            child: const Text('Autoriser'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_searching, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          const Text(
            'Aucun produit à proximité',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Essayez d\'élargir votre recherche',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
