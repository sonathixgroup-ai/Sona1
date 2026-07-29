// lib/presentation/thix_market/widgets/selling/publish_announcement_form.dart
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

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
  static const thixRed = Color(0xFFD81E2C);
  static const darkText = Color(0xFF1A1D29);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _brandController = TextEditingController();
  final _customCityController = TextEditingController();
  final _warrantyController = TextEditingController();
  final _shippingCostController = TextEditingController();

  List<XFile> _selectedImages = [];
  final Map<String, Uint8List> _imageBytesCache = {};

  String? _category;
  String? _condition;
  String? _shippingType;
  String? _currency = 'CDF';
  String? _city;
  String _placement = 'normal'; // Par défaut 'normal'
  DateTime? _flashEndTime;
  bool _freeShipping = false;
  bool _isService = false;
  bool _isLoading = false;
  bool _isUploading = false;

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

  final List<Map<String, String>> _currencies = [
    {'id': 'USD', 'name': 'USD (\$)'},
    {'id': 'CDF', 'name': 'CDF (FC)'},
  ];

  final List<String> _cities = [
    'Kinshasa', 'Lubumbashi', 'Mbuji-Mayi', 'Kananga', 'Kisangani',
    'Bukavu', 'Goma', 'Matadi', 'Kolwezi', 'Likasi', 'Autre',
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
    _customCityController.dispose();
    _warrantyController.dispose();
    _shippingCostController.dispose();
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
        if (mounted) setState(() => _currentPosition = position);
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
    _warrantyController.text = (data['warranty_months'] ?? '').toString();
    _shippingCostController.text = (data['shipping_cost'] ?? '').toString();
    _category = data['category'];
    _condition = data['condition'];
    _shippingType = data['shipping_type'];
    _currency = data['currency'] ?? 'CDF';
    _freeShipping = data['free_shipping'] ?? false;
    _isService = data['is_service'] ?? false;

    if (data['expires_at'] != null) {
      _flashEndTime = DateTime.tryParse(data['expires_at']);
    }

    final existingCity = data['city'] as String?;
    if (existingCity != null && _cities.contains(existingCity)) {
      _city = existingCity;
    } else if (existingCity != null && existingCity.isNotEmpty) {
      _city = 'Autre';
      _customCityController.text = existingCity;
    }

    if (data['is_flash_sale'] == true) {
      _placement = 'flash_sale';
    } else if (data['is_featured'] == true) {
      _placement = 'recommended';
    } else {
      _placement = 'normal';
    }
  }

  Future<void> _pickImages() async {
    final List<XFile>? images = await _picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (images != null && images.isNotEmpty) {
      for (final img in images) {
        try {
          _imageBytesCache[img.path] = await img.readAsBytes();
        } catch (e) {
          debugPrint('❌ Erreur lecture image ${img.path}: $e');
        }
      }
      setState(() {
        _selectedImages = images;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      final removed = _selectedImages.removeAt(index);
      _imageBytesCache.remove(removed.path);
    });
  }

  String _getExtensionFromMime(String? mimeType) {
    if (mimeType == null) return 'jpg';
    switch (mimeType) {
      case 'image/jpeg': return 'jpg';
      case 'image/png': return 'png';
      case 'image/gif': return 'gif';
      case 'image/webp': return 'webp';
      case 'image/heic': return 'heic';
      case 'image/bmp': return 'bmp';
      case 'image/tiff': return 'tiff';
      default: return 'jpg';
    }
  }

  String _getContentTypeFromExt(String ext) {
    switch (ext) {
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'webp': return 'image/webp';
      case 'heic': return 'image/heic';
      case 'bmp': return 'image/bmp';
      case 'tiff': case 'tif': return 'image/tiff';
      case 'svg': return 'image/svg+xml';
      default: return 'image/jpeg';
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> urls = [];
    setState(() => _isUploading = true);
    try {
      for (final image in _selectedImages) {
        final bytes = _imageBytesCache[image.path] ?? await image.readAsBytes();
        String? mimeType = image.mimeType;
        if (mimeType == null) {
          final ext = image.path.split('.').last.toLowerCase();
          mimeType = _getContentTypeFromExt(ext);
        }
        final ext = _getExtensionFromMime(mimeType);
        final fileName = '${const Uuid().v4()}.$ext';
        final filePath = 'products/$fileName';

        await Supabase.instance.client.storage.from('product_images').uploadBinary(
              filePath, bytes,
              fileOptions: FileOptions(contentType: mimeType, cacheControl: '3600', upsert: false),
            );

        final publicUrl = Supabase.instance.client.storage.from('product_images').getPublicUrl(filePath);
        urls.add(publicUrl);
      }
    } finally {
      setState(() => _isUploading = false);
    }
    return urls;
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: thixRed, onPrimary: Colors.white)),
        child: child!,
      ),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: thixRed, onPrimary: Colors.white)),
          child: child!,
        ),
      );

      if (time != null) {
        setState(() {
          _flashEndTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  String? _resolveCity() {
    if (_city == 'Autre') {
      final custom = _customCityController.text.trim();
      return custom.isEmpty ? null : custom;
    }
    return _city;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImages.isEmpty && widget.editAnnouncement == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajoutez au moins une image'), backgroundColor: thixRed));
      return;
    }
    
    final resolvedCity = _resolveCity();
    if (resolvedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Précisez la ville de publication'), backgroundColor: thixRed));
      return;
    }

    if (_placement == 'flash_sale' && _flashEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez définir une date de fin pour la vente flash.'), backgroundColor: thixRed));
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
        'discount_price': _discountPriceController.text.isNotEmpty ? double.parse(_discountPriceController.text) : null,
        'stock': int.parse(_stockController.text),
        'brand': _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        'category': _category,
        'condition': _condition,
        'shipping_type': _shippingType,
        'free_shipping': _freeShipping,
        'is_service': _isService,
        'currency': _currency,
        'city': resolvedCity,
        'is_flash_sale': _placement == 'flash_sale',
        'is_featured': _placement == 'recommended',
        'expires_at': _placement == 'flash_sale' ? _flashEndTime?.toIso8601String() : null,
        'images': imageUrls,
        'image_url': imageUrls.isNotEmpty ? imageUrls.first : null,
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
        'updated_at': DateTime.now().toIso8601String(),
        'warranty_months': _warrantyController.text.isNotEmpty ? int.parse(_warrantyController.text) : null,
        'shipping_cost': _shippingCostController.text.isNotEmpty ? double.parse(_shippingCostController.text) : null,
      };

      if (widget.editAnnouncement != null) {
        await Supabase.instance.client.from('products').update(productData).eq('id', widget.editAnnouncement!['id']);
      } else {
        productData['created_at'] = DateTime.now().toIso8601String();
        productData['status'] = 'active';
        final response = await Supabase.instance.client.from('products').insert(productData).select().single();
        widget.onSuccess?.call(response);
      }
    } catch (e) {
      debugPrint('Error submitting form: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: thixRed));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── PLACEMENT (Standard, Hero, Flash) ───
          const Text('Placement de l\'annonce', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: darkText)),
          const SizedBox(height: 12),
          _buildPlacementOption('normal', 'Annonce Standard', 'Affichage classique dans le flux de la marketplace', Icons.view_agenda_rounded),
          const SizedBox(height: 8),
          _buildPlacementOption('recommended', 'Hero Banner', 'Bannière principale tout en haut de l\'accueil', Icons.branding_watermark_rounded),
          const SizedBox(height: 8),
          _buildPlacementOption('flash_sale', 'Vente Flash', 'Mise en avant avec un compte à rebours', Icons.bolt_rounded),
          const SizedBox(height: 16),

          // ─── GESTION DU TEMPS (Si Vente Flash) ───
          if (_placement == 'flash_sale') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.withOpacity(0.3))),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.timer_outlined, color: Colors.white, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Fin de la vente flash', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.deepOrange)),
                        const SizedBox(height: 2),
                        Text(_flashEndTime == null ? 'Aucune date définie' : DateFormat('dd MMM yyyy à HH:mm', 'fr_FR').format(_flashEndTime!), style: TextStyle(color: _flashEndTime == null ? Colors.grey : darkText, fontSize: 14, fontWeight: _flashEndTime == null ? FontWeight.normal : FontWeight.bold)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDateTime,
                    style: TextButton.styleFrom(foregroundColor: Colors.deepOrange),
                    child: const Text('Définir'),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          const Divider(height: 32),

          // ─── PHOTOS DU PRODUIT ───
          const Text('Photos du produit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: darkText)),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length + 1,
              itemBuilder: (context, index) {
                if (index == _selectedImages.length) {
                  return GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: thixRed.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: thixRed.withOpacity(0.3), width: 1.5, style: BorderStyle.solid),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded, size: 28, color: thixRed),
                          SizedBox(height: 6),
                          Text('Ajouter', style: TextStyle(fontSize: 12, color: thixRed, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                }

                final image = _selectedImages[index];
                final bytes = _imageBytesCache[image.path];

                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey[100]),
                      child: bytes != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(bytes, width: 100, height: 100, fit: BoxFit.cover))
                          : const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: thixRed))),
                    ),
                    Positioned(
                      top: 4, right: 16,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // ─── CHAMPS TEXTES ───
          _buildTextField(controller: _titleController, label: 'Titre de l\'annonce', isRequired: true),
          const SizedBox(height: 16),
          _buildTextField(controller: _descriptionController, label: 'Description détaillée', maxLines: 4, isRequired: true),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(child: _buildTextField(controller: _priceController, label: 'Prix', isRequired: true, type: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(controller: _discountPriceController, label: 'Prix promo', type: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _currency,
            decoration: _inputDecoration('Devise'),
            items: _currencies.map((cur) => DropdownMenuItem(value: cur['id'], child: Text(cur['name']!))).toList(),
            onChanged: (v) => setState(() => _currency = v),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _buildTextField(controller: _stockController, label: 'Stock disponible', isRequired: true, type: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(controller: _brandController, label: 'Marque (Opt.)')),
            ],
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _category,
            decoration: _inputDecoration('Catégorie *'),
            items: _categories.map((cat) => DropdownMenuItem(value: cat['id'], child: Text(cat['name']!))).toList(),
            onChanged: (v) => setState(() => _category = v),
            validator: (v) => v == null ? 'Champ requis' : null,
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _condition,
            decoration: _inputDecoration('État *'),
            items: _conditions.map((cond) => DropdownMenuItem(value: cond['id'], child: Text(cond['name']!))).toList(),
            onChanged: (v) => setState(() => _condition = v),
            validator: (v) => v == null ? 'Champ requis' : null,
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _city,
            decoration: _inputDecoration('Ville de publication *'),
            items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _city = v),
            validator: (v) => v == null ? 'Champ requis' : null,
          ),
          if (_city == 'Autre') ...[
            const SizedBox(height: 8),
            _buildTextField(controller: _customCityController, label: 'Précisez la ville', isRequired: true),
          ],
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _shippingType,
            decoration: _inputDecoration('Type de livraison *'),
            items: _shippingTypes.map((type) => DropdownMenuItem(value: type['id'], child: Text(type['name']!))).toList(),
            onChanged: (v) => setState(() => _shippingType = v),
            validator: (v) => v == null ? 'Champ requis' : null,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _buildTextField(controller: _shippingCostController, label: 'Frais de livraison', type: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(controller: _warrantyController, label: 'Garantie (mois)', type: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 12),

          // ─── TOGGLES ───
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Livraison gratuite', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  value: _freeShipping,
                  onChanged: (v) => setState(() => _freeShipping = v),
                  activeColor: thixRed,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Ceci est un service', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Sélectionnez ceci s\'il s\'agit d\'une réservation.', style: TextStyle(fontSize: 12)),
                  value: _isService,
                  onChanged: (v) => setState(() => _isService = v),
                  activeColor: thixRed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ─── BOUTON SUBMIT ───
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (_isLoading || _isUploading) ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: thixRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading || _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(widget.editAnnouncement != null ? 'Mettre à jour' : 'Publier l\'annonce', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS HELPERS POUR LE DESIGN ---

  Widget _buildPlacementOption(String value, String title, String subtitle, IconData icon) {
    final isSelected = _placement == value;
    return InkWell(
      onTap: () => setState(() => _placement = value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? thixRed.withOpacity(0.05) : Colors.white,
          border: Border.all(color: isSelected ? thixRed : Colors.grey.shade200, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? thixRed : Colors.grey.shade400, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: isSelected ? thixRed : darkText)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _placement,
              activeColor: thixRed,
              onChanged: (v) => setState(() => _placement = v!),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, int maxLines = 1, bool isRequired = false, TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: type,
      validator: isRequired ? (v) => v == null || v.trim().isEmpty ? 'Requis' : null : null,
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: thixRed, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1)),
    );
  }
}
