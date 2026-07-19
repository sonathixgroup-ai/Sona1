// lib/presentation/thix_event/admin/pages/events/event_create_edit_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thix_id/models/event_model.dart';

import '../../providers/admin_event_provider.dart';
import '../../services/admin_event_service.dart';
import '../../widgets/admin_app_bar.dart';
import '../../core/admin_guards.dart';

class EventCreateEditPage extends StatefulWidget {
  final Event? eventToEdit;
  const EventCreateEditPage({super.key, this.eventToEdit});

  @override
  State<EventCreateEditPage> createState() => _EventCreateEditPageState();
}

class _EventCreateEditPageState extends State<EventCreateEditPage> {
  // Couleur THIX Violette
  static const Color appViolet = Color(0xFF6B3CE2);

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl, _descCtrl, _locationCtrl, _addressCtrl, _cityCtrl;
  late TextEditingController _priceCtrl, _capacityCtrl, _subCategoryCtrl;
  late TextEditingController _organizerNameCtrl, _contactPhoneCtrl, _contactEmailCtrl;
  
  late String _category, _currency, _status;
  late DateTime _startDate;
  DateTime? _endDate;
  bool _isFree = false;
  bool _isSaving = false;

  // Nouvelle variable pour la section de publication
  String _publishSection = 'upcoming';

  Uint8List? _pickedImageBytes;
  Uint8List? _pickedBannerBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final e = widget.eventToEdit;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _locationCtrl = TextEditingController(text: e?.location ?? '');
    _addressCtrl = TextEditingController(text: e?.address ?? '');
    _cityCtrl = TextEditingController(text: e?.city ?? 'Dar es Salaam, Tanzanie');
    _priceCtrl = TextEditingController(text: e?.price.toString() ?? '0');
    _capacityCtrl = TextEditingController(text: e?.capacity?.toString() ?? '100');
    _subCategoryCtrl = TextEditingController(text: e?.subCategory ?? '');
    _organizerNameCtrl = TextEditingController(text: e?.organizerName ?? '');
    _contactPhoneCtrl = TextEditingController(text: e?.contactPhone ?? '');
    _contactEmailCtrl = TextEditingController(text: e?.contactEmail ?? '');
    
    _category = e?.category ?? 'concert';
    _currency = e?.priceCurrency ?? 'FC'; 
    _status = e?.status ?? 'upcoming';
    _startDate = e?.startDate ?? DateTime.now().add(const Duration(days: 7));
    _endDate = e?.endDate;
    _isFree = e?.isFree ?? false;
    
    // Initialisation de la section de publication
    if (e?.isFeatured == true) {
      _publishSection = 'featured';
    } else {
      // TODO: Si vous ajoutez e?.isRecommended dans le futur, gérez-le ici.
      _publishSection = 'upcoming';
    }
  }

  Future<void> _pickImage(bool isBanner) async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null) {
      final bytes = await x.readAsBytes();
      setState(() => isBanner ? _pickedBannerBytes = bytes : _pickedImageBytes = bytes);
    }
  }

  // Fonction combinée pour choisir la Date ET l'Heure
  Future<DateTime?> _pickDateTime(DateTime initialDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => _buildTheme(child),
    );

    if (date == null) return null; // Annulé

    if (!mounted) return date;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      builder: (context, child) => _buildTheme(child),
    );

    if (time == null) return date; // A choisi la date mais annulé l'heure

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // Applique le thème Violet THIX aux sélecteurs
  Widget _buildTheme(Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: appViolet, 
          onPrimary: Colors.white,
          onSurface: Colors.black87,
        ),
      ),
      child: child!,
    );
  }

  Future<void> _save() async {
    final role = await AdminGuard.getCurrentRole();
    if (!AdminGuard.canWrite(role)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lecture seule')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final service = context.read<AdminEventService>();
      final provider = context.read<AdminEventProvider>();

      final capacity = int.tryParse(_capacityCtrl.text);

      bool isFeatured = _publishSection == 'featured';
      // bool isRecommended = _publishSection == 'recommended'; // À décommenter si ajouté au modèle Event

      final event = Event(
        id: widget.eventToEdit?.id ?? '',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        subCategory: _subCategoryCtrl.text.trim().isEmpty ? null : _subCategoryCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        price: _isFree ? 0 : double.tryParse(_priceCtrl.text) ?? 0,
        priceCurrency: _currency,
        isFree: _isFree,
        capacity: capacity,
        remainingTickets: widget.eventToEdit == null ? capacity : widget.eventToEdit?.remainingTickets,
        isFeatured: isFeatured,
         isRecommended: isRecommended, // Ajoutez ceci dans votre constructeur Event si vous gérez les recommandations
        status: _status,
        organizerName: _organizerNameCtrl.text.trim().isEmpty ? null : _organizerNameCtrl.text.trim(),
        contactPhone: _contactPhoneCtrl.text.trim().isEmpty ? null : _contactPhoneCtrl.text.trim(),
        contactEmail: _contactEmailCtrl.text.trim().isEmpty ? null : _contactEmailCtrl.text.trim(),
        viewsCount: widget.eventToEdit?.viewsCount ?? 0,
        likesCount: widget.eventToEdit?.likesCount ?? 0,
        sharesCount: widget.eventToEdit?.sharesCount ?? 0,
        createdAt: widget.eventToEdit?.createdAt ?? DateTime.now(),
        imageUrl: widget.eventToEdit?.imageUrl,
        bannerUrl: widget.eventToEdit?.bannerUrl,
      );

      await service.upsertEvent(event, imageBytes: _pickedImageBytes, bannerBytes: _pickedBannerBytes);
      await provider.loadEvents(refresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Événement enregistré', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Format d'affichage de la date et l'heure
  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} à ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AdminAppBar(title: widget.eventToEdit == null ? 'Créer Event' : 'Modifier Event'),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: appViolet, // Changé en Violet
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isSaving
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(
                  widget.eventToEdit == null ? 'CRÉER L\'ÉVÉNEMENT' : 'ENREGISTRER',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Expanded(child: _imagePicker('Cover', _pickedImageBytes, widget.eventToEdit?.imageUrl, () => _pickImage(false))),
              const SizedBox(width: 12),
              Expanded(child: _imagePicker('Banner', _pickedBannerBytes, widget.eventToEdit?.bannerUrl, () => _pickImage(true))),
            ]),
            const SizedBox(height: 20),
            
            _field(_titleCtrl, 'Titre événement *', validator: (v) => v!.isEmpty ? 'Requis' : null),
            const SizedBox(height: 12),
            _field(_descCtrl, 'Description *', maxLines: 4, validator: (v) => v!.length < 10 ? 'Min 10 car' : null),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _category,
                  decoration: _deco('Catégorie'),
                  items: ['concert', 'conférence', 'sport', 'festival', 'théâtre', 'autre'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _field(_subCategoryCtrl, 'Sous-catégorie')),
            ]),
            
            const SizedBox(height: 20),
            const Text('Date & Heure', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final dt = await _pickDateTime(_startDate);
                    if (dt != null) setState(() => _startDate = dt);
                  },
                  child: InputDecorator(
                    decoration: _deco('Début'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDateTime(_startDate), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const Icon(Icons.access_time, size: 16, color: appViolet),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final dt = await _pickDateTime(_endDate ?? _startDate);
                    if (dt != null) setState(() => _endDate = dt);
                  },
                  child: InputDecorator(
                    decoration: _deco('Fin (Optionnel)'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_endDate == null ? 'Ajouter' : _formatDateTime(_endDate!), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const Icon(Icons.access_time, size: 16, color: appViolet),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
            
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _field(_cityCtrl, 'Ville *', validator: (v) => v!.isEmpty ? 'Requis' : null)),
              const SizedBox(width: 12),
              Expanded(child: _field(_locationCtrl, 'Lieu (ex: Stade) *', validator: (v) => v!.isEmpty ? 'Requis' : null)),
            ]),
            const SizedBox(height: 12),
            _field(_addressCtrl, 'Adresse complète'),
            
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _field(_organizerNameCtrl, 'Organisateur')),
              const SizedBox(width: 12),
              Expanded(child: _field(_contactPhoneCtrl, 'Téléphone', keyboard: TextInputType.phone)),
            ]),
            const SizedBox(height: 12),
            _field(_contactEmailCtrl, 'Email de contact', keyboard: TextInputType.emailAddress),
            
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _field(_priceCtrl, 'Prix', enabled: !_isFree, keyboard: TextInputType.number)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _currency,
                items: ['FC', 'USD', 'EUR'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _currency = v!),
              ),
              const SizedBox(width: 8),
              Row(children: [
                Checkbox(value: _isFree, activeColor: appViolet, onChanged: (v) => setState(() => _isFree = v!)),
                const Text('Gratuit', style: TextStyle(fontSize: 12))
              ]),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_capacityCtrl, 'Capacité totale', keyboard: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _status,
                  decoration: _deco('Statut'),
                  items: ['upcoming', 'ongoing', 'completed', 'cancelled'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _status = v!),
                ),
              ),
            ]),
            
            const SizedBox(height: 20),
            const Text('Où afficher cet événement ?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _publishSection,
              decoration: _deco('Visibilité de l\'événement'),
              items: const [
                DropdownMenuItem(
                  value: 'upcoming', 
                  child: Text('Prochains événements (Par défaut)', style: TextStyle(fontSize: 13))
                ),
                DropdownMenuItem(
                  value: 'recommended', 
                  child: Text('Événements Recommandés', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13))
                ),
                DropdownMenuItem(
                  value: 'featured', 
                  child: Text('À la Une (Bannière)', style: TextStyle(color: appViolet, fontWeight: FontWeight.bold, fontSize: 13))
                ),
              ],
              onChanged: (v) => setState(() => _publishSection = v!),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _imagePicker(String label, Uint8List? bytes, String? url, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: appViolet.withOpacity(0.3), width: 1.5),
        ),
        child: bytes != null
            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(bytes, fit: BoxFit.cover))
            : url != null
                ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(url, fit: BoxFit.cover))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo, color: appViolet),
                      const SizedBox(height: 6),
                      Text(label, style: const TextStyle(fontSize: 11, color: appViolet, fontWeight: FontWeight.w600)),
                    ],
                  ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1, bool enabled = true, TextInputType? keyboard, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: validator,
      decoration: _deco(label),
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE7EEFC))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: appViolet, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
