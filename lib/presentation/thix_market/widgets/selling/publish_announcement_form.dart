import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';

class PublishAnnouncementForm extends StatefulWidget {
  final String? shopId;
  final Map<String, dynamic>? editAnnouncement;
  final Function(Map<String, dynamic>)? onSuccess;

  const PublishAnnouncementForm({
    super.key,
    required this.shopId,
    this.editAnnouncement,
    this.onSuccess,
  });

  @override
  State<PublishAnnouncementForm> createState() => _PublishAnnouncementFormState();
}

class _PublishAnnouncementFormState extends State<PublishAnnouncementForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _brandController = TextEditingController();
  
  List<File> _selectedImages = [];
  String? _category;
  String? _condition;
  String? _shippingType;
  bool _freeShipping = false;
  bool _isService = false;
  bool _isLoading = false;
  
  Position? _currentPosition;

  final List<Map<String, String>> _categories = [
    {'id': 'fashion', 'name': 'Mode & Accessoires'},
    {'id': 'electronics', 'name': 'Électronique'},
    {'id': 'home', 'name': 'Maison & Jardin'},
    {'id': 'services', 'name': 'Services'},
    {'id': 'vehicles', 'name': 'Véhicules'},
    {'id': 'realestate', 'name': 'Immobilier'},
    {'id': 'food', 'name': 'Alimentation'},
    {'id': 'beauty', 'name': 'Beauté & Bien-être'},
    {'id': 'sports', 'name': 'Sports & Loisirs'},
  ];

  final List<Map<String, String>> _conditions = [
    {'id': 'new', 'name': 'Neuf'},
    {'id': 'like_new', 'name': 'Comme neuf'},
    {'id': 'good', 'name': 'Bon état'},
    {'id': 'fair', 'name': 'État correct'},
  ];

  final List<Map<String, String>> _shippingTypes = [
    {'id': 'delivery', 'name': 'Livraison'},
    {'id': 'pickup', 'name': 'Retrait en magasin'},
    {'id': 'both', 'name': 'Les deux'},
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    if (widget.editAnnouncement != null) {
      _loadEditData();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _stockController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      try {
        Position position = await Geolocator.getCurrentPosition();
        setState(() => _currentPosition = position);
      } catch (e) {
        debugPrint('Error getting location: $e');
      }
    }
  }

  void _loadEditData() {
    final data = widget.editAnnouncement!;
    _titleController.text = data['title'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    _priceController.text = (data['price'] ?? 0).toString();
    _discountPriceController.text = (data['discount_price'] ?? '').toString();
    _stockController.text = (data['stock'] ?? 0).toString();
    _brandController.text = data['brand'] ?? '';
    _category = data['category'];
    _condition = data['condition'];
    _shippingType = data['shipping_type'];
    _freeShipping = data['free_shipping'] ?? false;
    _isService = data['is_service'] ?? false;
  }

  Future<void> _pickImages() async {
    final List<XFile>? images = await _picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (images != null) {
      setState(() {
        _selectedImages = images.map((x) => File(x.path)).toList();
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages() async {
    List<String> urls = [];
    for (File image in _selectedImages) {
      try {
        final fileExt = image.path.split('.').last;
        final fileName = '${const Uuid().v4()}.$fileExt';
        final filePath = 'products/$fileName';
        
        await Supabase.instance.client.storage
            .from('product_images')
            .upload(filePath, image);
        
        final publicUrl = Supabase.instance.client.storage
            .from('product_images')
            .getPublicUrl(filePath);
        
        urls.add(publicUrl);
      } catch (e) {
        debugPrint('Error uploading image: $e');
      }
    }
    return urls;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty && widget.editAnnouncement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins une image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages();
      } else if (widget.editAnnouncement != null) {
        imageUrls = List<String>.from(widget.editAnnouncement!['images'] ?? []);
      }

      final productData = {
        'shop_id': widget.shopId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'discount_price': _discountPriceController.text.isNotEmpty
            ? double.parse(_discountPriceController.text)
            : null,
        'stock': int.parse(_stockController.text),
        'brand': _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        'category': _category,
        'condition': _condition,
        'shipping_type': _shippingType,
        'free_shipping': _freeShipping,
        'is_service': _isService,
        'images': imageUrls,
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (widget.editAnnouncement != null) {
        // Update existing
        await Supabase.instance.client
            .from('products')
            .update(productData)
            .eq('id', widget.editAnnouncement!['id']);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Annonce mise à jour')),
        );
      } else {
        // Create new
        productData['created_at'] = DateTime.now().toIso8601String();
        productData['status'] = 'active';
        
        final response = await Supabase.instance.client
            .from('products')
            .insert(productData)
            .select()
            .single();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Annonce publiée avec succès')),
        );
        
        widget.onSuccess?.call(response);
      }
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error submitting form: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images
            const Text(
              'Photos du produit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length + 1,
                itemBuilder: (context, index) {
                  if (index == _selectedImages.length) {
                    return GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 30),
                            SizedBox(height: 4),
                            Text('Ajouter', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  }
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(_selectedImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Titre
            const Text('Titre *', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Ex: iPhone 13 Pro - Très bon état',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 12),

            // Description
            const Text('Description *', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Décrivez votre produit en détail...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 12),

            // Prix
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Prix *', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0',
                          suffixText: 'FCFA',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Prix promo', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _discountPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Optionnel',
                          suffixText: 'FCFA',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stock
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quantité *', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Stock disponible',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Marque', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _brandController,
                        decoration: InputDecoration(
                          hintText: 'Ex: Apple, Samsung...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Catégorie
            const Text('Catégorie *', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem(value: cat['id'], child: Text(cat['name']!));
              }).toList(),
              onChanged: (v) => setState(() => _category = v),
              validator: (v) => v == null ? 'Champ requis' : null,
            ),
            const SizedBox(height: 12),

            // État
            const Text('État *', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _condition,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _conditions.map((cond) {
                return DropdownMenuItem(value: cond['id'], child: Text(cond['name']!));
              }).toList(),
              onChanged: (v) => setState(() => _condition = v),
              validator: (v) => v == null ? 'Champ requis' : null,
            ),
            const SizedBox(height: 12),

            // Livraison
            const Text('Type de livraison *', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _shippingType,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _shippingTypes.map((type) {
                return DropdownMenuItem(value: type['id'], child: Text(type['name']!));
              }).toList(),
              onChanged: (v) => setState(() => _shippingType = v),
              validator: (v) => v == null ? 'Champ requis' : null,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Livraison gratuite'),
              value: _freeShipping,
              onChanged: (v) => setState(() => _freeShipping = v),
              activeColor: const Color(0xFFE5592F),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Ceci est un service (réservation)'),
              value: _isService,
              onChanged: (v) => setState(() => _isService = v),
              activeColor: const Color(0xFFE5592F),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5592F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    : const Text('Publier', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
