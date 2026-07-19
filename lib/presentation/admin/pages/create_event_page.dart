// lib/presentation/admin/pages/create_event_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../../../providers/event_provider.dart';
import '../../../models/event_model.dart';

class CreateEventPage extends StatefulWidget {
  final Event? event;

  const CreateEventPage({super.key, this.event});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  // Couleur principale THIX
  static const Color appViolet = Color(0xFF6B3CE2);
  static const Color textDark = Color(0xFF1A1A2E);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _capacityController = TextEditingController();
  
  String _selectedCategory = 'musique';
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _startTime = TimeOfDay.now();
  bool _isFree = false;
  
  // Section de publication (Au lieu d'un simple switch)
  String _publishSection = 'upcoming'; 

  String? _imageUrl;
  Uint8List? _imageBytes;
  String? _imageFileName;
  bool _isLoading = false;

  final List<Map<String, String>> _categories = [
    {'value': 'musique', 'label': 'Musique & Concerts'},
    {'value': 'conference', 'label': 'Conférences & Séminaires'},
    {'value': 'culture', 'label': 'Culture & Art'},
    {'value': 'sport', 'label': 'Sport & Loisirs'},
    {'value': 'festival', 'label': 'Festivals & Soirées'},
    {'value': 'spectacle', 'label': 'Spectacles'},
    {'value': 'exposition', 'label': 'Expositions'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description;
      _locationController.text = widget.event!.location;
      _cityController.text = widget.event!.city ?? '';
      _addressController.text = widget.event!.address ?? '';
      _selectedCategory = widget.event!.category;
      _startDate = widget.event!.startDate;
      _startTime = TimeOfDay.fromDateTime(widget.event!.startDate);
      _isFree = widget.event!.isFree;
      _imageUrl = widget.event!.imageUrl;
      
      // Déterminer la section de publication
      if (widget.event!.isFeatured) {
        _publishSection = 'featured';
      } else {
        // Si vous avez ajouté isRecommended au modèle plus tard, on pourrait l'assigner ici.
        // Pour l'instant on garde 'upcoming' par défaut si pas featured.
        _publishSection = 'upcoming'; 
      }

      if (!_isFree) {
        _priceController.text = widget.event!.price.toStringAsFixed(0);
      }
      if (widget.event!.capacity != null) {
        _capacityController.text = widget.event!.capacity.toString();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, 
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _imageBytes = result.files.first.bytes;
          _imageFileName = result.files.first.name;
        });
      }
    } catch (e) {
      _showError('Erreur lors de la sélection de l\'image');
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: appViolet, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: textDark, // Body text color
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: appViolet, 
              onPrimary: Colors.white,
              onSurface: textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _startTime = time);
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageBytes == null || _imageFileName == null) return _imageUrl;
    
    final provider = context.read<EventProvider>();
    return await provider.uploadImage(_imageBytes!, _imageFileName!);
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final uploadedImageUrl = await _uploadImage();
      
      final startDateTime = DateTime(
        _startDate.year, _startDate.month, _startDate.day,
        _startTime.hour, _startTime.minute,
      );
      
      final provider = context.read<EventProvider>();
      
      // Conversion de la section en booléens pour la base de données
      bool isFeatured = _publishSection == 'featured';
      bool isRecommended = _publishSection == 'recommended';

      final eventData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'start_date': startDateTime.toIso8601String(),
        'location': _locationController.text.trim(),
        'city': _cityController.text.trim(),
        'address': _addressController.text.trim(),
        'price': _isFree ? 0 : double.parse(_priceController.text.trim()),
        'is_free': _isFree,
        'capacity': _capacityController.text.trim().isEmpty ? null : int.parse(_capacityController.text.trim()),
        'image_url': uploadedImageUrl,
        'is_featured': isFeatured,
        'is_recommended': isRecommended, // Assurez-vous que cette colonne existe en DB !
      };
      
      if (widget.event != null) {
        await provider.updateEvent(widget.event!.id, eventData);
        _showSuccess('Événement modifié avec succès');
      } else {
        await provider.createEvent(
          title: eventData['title'] as String,
          description: eventData['description'] as String,
          category: eventData['category'] as String,
          startDate: startDateTime,
          location: eventData['location'] as String,
          city: eventData['city'] as String,
          address: eventData['address'] as String,
          price: eventData['price'] as double,
          isFree: eventData['is_free'] as bool,
          capacity: eventData['capacity'] as int?,
          imageUrl: uploadedImageUrl,
          isFeatured: isFeatured,
          // Note : Le provider createEvent devra peut-être être mis à jour 
          // pour accepter isRecommended si vous l'utilisez dans la fonction.
        );
        _showSuccess('Événement créé avec succès');
      }
      
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showError('Erreur: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.event != null ? 'Modifier l\'événement' : 'Nouvel événement',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textDark),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveEvent,
            child: Text(
              widget.event != null ? 'MODIFIER' : 'CRÉER',
              style: const TextStyle(color: appViolet, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: appViolet))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImageSection(),
                    const SizedBox(height: 24),
                    
                    const Text('Informations générales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Titre de l\'événement',
                        hintText: 'Nom accrocheur...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: appViolet, width: 2)),
                      ),
                      validator: (v) => v?.trim().isEmpty == true ? 'Titre requis' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Description complète...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: appViolet, width: 2)),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => v?.trim().isEmpty == true ? 'Description requise' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Catégorie',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: appViolet, width: 2)),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat['value'],
                          child: Text(cat['label']!, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                    ),
                    
                    const SizedBox(height: 32),
                    const Text('Date & Heure', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateTimeButton(
                            icon: Icons.calendar_today,
                            label: 'Date',
                            value: '${_startDate.day.toString().padLeft(2, '0')}/${_startDate.month.toString().padLeft(2, '0')}/${_startDate.year}',
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateTimeButton(
                            icon: Icons.access_time_filled,
                            label: 'Heure',
                            value: '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                            onTap: _pickTime,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    const Text('Lieu de l\'événement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Nom du lieu (Ex: Palais des Congrès)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: appViolet, width: 2)),
                      ),
                      validator: (v) => v?.trim().isEmpty == true ? 'Lieu requis' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: InputDecoration(
                              labelText: 'Ville',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: appViolet, width: 2)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText: 'Adresse',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: appViolet, width: 2)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    const Text('Billetterie & Visibilité', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SwitchListTile(
                        value: _isFree,
                        onChanged: (v) => setState(() => _isFree = v),
                        title: const Text('Événement 100% gratuit', style: TextStyle(fontWeight: FontWeight.w500)),
                        activeColor: appViolet,
                      ),
                    ),
                    if (!_isFree) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Prix du billet standard',
                          suffixText: 'FC',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: appViolet, width: 2)),
                        ),
                        validator: (v) => v?.trim().isEmpty == true ? 'Prix requis' : null,
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _capacityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Capacité totale',
                        hintText: 'Ex: 500 (Laisser vide si illimité)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: appViolet, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // SECTION DE PUBLICATION
                    DropdownButtonFormField<String>(
                      value: _publishSection,
                      decoration: InputDecoration(
                        labelText: 'Où afficher cet événement ?',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: appViolet, width: 2)),
                        filled: true,
                        fillColor: appViolet.withOpacity(0.05),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'upcoming', 
                          child: Text('Prochains événements (Par défaut)')
                        ),
                        DropdownMenuItem(
                          value: 'recommended', 
                          child: Text('Événements Recommandés', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))
                        ),
                        DropdownMenuItem(
                          value: 'featured', 
                          child: Text('À la Une (Bannière Défilante)', style: TextStyle(color: appViolet, fontWeight: FontWeight.bold))
                        ),
                      ],
                      onChanged: (v) => setState(() => _publishSection = v!),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // Widget personnalisé pour rendre la sélection de la date/heure plus attractive
  Widget _buildDateTimeButton({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: appViolet),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Affiche de l\'événement', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: appViolet.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: appViolet.withOpacity(0.3), width: 2, style: BorderStyle.solid),
            ),
            child: _imageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity),
                  )
                : _imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(_imageUrl!, fit: BoxFit.cover, width: double.infinity),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                            child: const Icon(Icons.add_a_photo, size: 32, color: appViolet),
                          ),
                          const SizedBox(height: 12),
                          const Text('Ajouter une affiche', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: appViolet)),
                          const SizedBox(height: 4),
                          Text('Format 16:9 recommandé', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
          ),
        ),
        if (_imageBytes != null || _imageUrl != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() {
                _imageBytes = null;
                _imageFileName = null;
                _imageUrl = null;
              }),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Retirer l\'image'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ),
      ],
    );
  }
}
