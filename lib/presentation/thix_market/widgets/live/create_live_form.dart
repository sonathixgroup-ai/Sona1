import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class CreateLiveForm extends StatefulWidget {
  final String shopId;
  final Function(Map<String, dynamic>)? onSuccess;

  const CreateLiveForm({super.key, required this.shopId, this.onSuccess});

  @override
  State<CreateLiveForm> createState() => _CreateLiveFormState();
}

class _CreateLiveFormState extends State<CreateLiveForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  File? _thumbnail;
  List<String> _selectedProductIds = [];
  bool _hasAuction = false;
  double _startingPrice = 0;
  DateTime? _auctionEndTime;
  bool _isLoading = false;
  
  List<Map<String, dynamic>> _availableProducts = [];
  bool _loadingProducts = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _loadingProducts = true);
    
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select('id, title, price, image_url')
          .eq('shop_id', widget.shopId)
          .eq('status', 'active');
      
      setState(() {
        _availableProducts = List<Map<String, dynamic>>.from(response);
        _loadingProducts = false;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      setState(() => _loadingProducts = false);
    }
  }

  Future<void> _pickThumbnail() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (image != null) {
      setState(() => _thumbnail = File(image.path));
    }
  }

  Future<String?> _uploadThumbnail() async {
    if (_thumbnail == null) return null;
    
    final fileExt = _thumbnail!.path.split('.').last;
    final fileName = '${const Uuid().v4()}.$fileExt';
    final filePath = 'live_thumbnails/$fileName';
    
    await Supabase.instance.client.storage
        .from('live_images')
        .upload(filePath, _thumbnail!);
    
    return Supabase.instance.client.storage
        .from('live_images')
        .getPublicUrl(filePath);
  }

  Future<void> _createLive() async {
    if (!_formKey.currentState!.validate()) return;
    if (_thumbnail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter une miniature')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final thumbnailUrl = await _uploadThumbnail();
      
      final channelName = 'live_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create Agora token (simplified, use Edge Function in production)
      final tokenResponse = await Supabase.instance.client
          .functions
          .invoke('generate-rtc-token', body: {'channelName': channelName});
      
      final liveData = {
        'shop_id': widget.shopId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'thumbnail_url': thumbnailUrl,
        'channel_name': channelName,
        'token': tokenResponse.data['token'],
        'products': _selectedProductIds,
        'has_auction': _hasAuction,
        'starting_price': _hasAuction ? _startingPrice : null,
        'auction_end_time': _hasAuction ? _auctionEndTime?.toIso8601String() : null,
        'status': 'scheduled',
        'scheduled_start': DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };
      
      final response = await Supabase.instance.client
          .from('lives')
          .insert(liveData)
          .select()
          .single();
      
      widget.onSuccess?.call(response);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live programmé avec succès')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error creating live: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
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
            // Thumbnail
            const Text('Miniature *', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickThumbnail,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _thumbnail != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_thumbnail!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('Ajouter une miniature', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            const Text('Titre *', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Ex: Vente flash mode été',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 12),
            
            // Description
            const Text('Description', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Décrivez votre live...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            
            // Products
            const Text('Produits à présenter', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            _loadingProducts
                ? const Center(child: CircularProgressIndicator())
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableProducts.map((product) {
                      final isSelected = _selectedProductIds.contains(product['id']);
                      return FilterChip(
                        label: Text(product['title'], maxLines: 1),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedProductIds.add(product['id']);
                            } else {
                              _selectedProductIds.remove(product['id']);
                            }
                          });
                        },
                        selectedColor: const Color(0xFFE5592F).withOpacity(0.1),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 16),
            
            // Auction toggle
            SwitchListTile(
              title: const Text('Activer les enchères'),
              value: _hasAuction,
              onChanged: (value) => setState(() => _hasAuction = value),
              activeColor: const Color(0xFFE5592F),
              contentPadding: EdgeInsets.zero,
            ),
            
            if (_hasAuction) ...[
              const SizedBox(height: 12),
              const Text('Prix de départ *', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: 'FCFA',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (v) => _startingPrice = double.tryParse(v) ?? 0,
              ),
              const SizedBox(height: 12),
              const Text('Fin des enchères', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              ListTile(
                title: Text(_auctionEndTime != null
                    ? '${_auctionEndTime!.day}/${_auctionEndTime!.month}/${_auctionEndTime!.year} ${_auctionEndTime!.hour}:${_auctionEndTime!.minute}'
                    : 'Sélectionner une date'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now().add(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: 18, minute: 0),
                    );
                    if (time != null) {
                      setState(() {
                        _auctionEndTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                      });
                    }
                  }
                },
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Create button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createLive,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5592F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    : const Text('Programmer le live', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
