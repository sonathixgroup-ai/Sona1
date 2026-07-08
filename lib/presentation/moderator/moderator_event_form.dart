// lib/presentation/moderator/moderator_event_form.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/moderator_provider.dart';
import '../../models/event_model.dart';

class ModeratorEventForm extends StatefulWidget {
  final Event? event;
  const ModeratorEventForm({super.key, this.event});

  @override
  State<ModeratorEventForm> createState() => _ModeratorEventFormState();
}

class _ModeratorEventFormState extends State<ModeratorEventForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _cityController = TextEditingController();
  final _priceController = TextEditingController();
  final _capacityController = TextEditingController();
  String? _category = 'musique';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFree = false;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descController.text = widget.event!.description;
      _locationController.text = widget.event!.location;
      _cityController.text = widget.event!.city ?? '';
      _priceController.text = widget.event!.price.toString();
      _capacityController.text = widget.event!.capacity?.toString() ?? '';
      _category = widget.event!.category;
      _startDate = widget.event!.startDate;
      _endDate = widget.event!.endDate;
      _isFree = widget.event!.isFree;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une date de début')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<ModeratorProvider>();
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await provider.uploadImage(_imageFile!.path);
      }

      final data = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'category': _category!,
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
        'location': _locationController.text.trim(),
        'city': _cityController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0,
        'is_free': _isFree,
        'capacity': int.tryParse(_capacityController.text),
        'image_url': imageUrl,
      };

      if (widget.event != null) {
        await provider.updateEvent(widget.event!.id, data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Événement mis à jour'), backgroundColor: Colors.green),
        );
      } else {
        await provider.createEvent(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Événement créé'), backgroundColor: Colors.green),
        );
      }
      context.go('/moderator/events');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier l\'événement' : 'Créer un événement'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go('/moderator/events'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Titre
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titre', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 4,
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),

              // Catégorie
              DropdownButtonFormField<String>(
                value: _category,
                items: const [
                  DropdownMenuItem(value: 'musique', child: Text('Musique')),
                  DropdownMenuItem(value: 'conference', child: Text('Conférence')),
                  DropdownMenuItem(value: 'culture', child: Text('Culture')),
                  DropdownMenuItem(value: 'sport', child: Text('Sport')),
                  DropdownMenuItem(value: 'festival', child: Text('Festival')),
                  DropdownMenuItem(value: 'spectacle', child: Text('Spectacle')),
                  DropdownMenuItem(value: 'exposition', child: Text('Exposition')),
                ],
                onChanged: (v) => setState(() => _category = v),
                decoration: const InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              // Date et heure
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final dt = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (dt != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() {
                              _startDate = DateTime(dt.year, dt.month, dt.day, time.hour, time.minute);
                            });
                          }
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_startDate != null
                          ? DateFormat('dd/MM/yyyy HH:mm').format(_startDate!)
                          : 'Début'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[100]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final dt = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? _startDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (dt != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() {
                              _endDate = DateTime(dt.year, dt.month, dt.day, time.hour, time.minute);
                            });
                          }
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_endDate != null
                          ? DateFormat('dd/MM/yyyy HH:mm').format(_endDate!)
                          : 'Fin (option)'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[100]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Lieu
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Lieu', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),

              // Ville
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Ville', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              // Prix / Gratuit
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Prix (FCFA)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      enabled: !_isFree,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CheckboxListTile(
                      value: _isFree,
                      onChanged: (v) => setState(() => _isFree = v!),
                      title: const Text('Gratuit'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Capacité
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(labelText: 'Capacité totale', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),

              // Image
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: Text(_imageFile != null ? 'Image sélectionnée' : 'Choisir une image'),
                    ),
                  ),
                  if (_imageFile != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _imageFile = null),
                    ),
                ],
              ),
              if (_imageFile != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Image.file(_imageFile!, height: 100, fit: BoxFit.cover),
                ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF2D6CDF),
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('ENREGISTRER', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
