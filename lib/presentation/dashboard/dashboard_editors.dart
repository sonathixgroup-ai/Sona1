import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/thix_profile.dart';
import 'package:thix_id/presentation/common/parcours_form.dart';
import 'package:thix_id/presentation/common/upload_document_preview.dart';
import 'package:thix_id/services/document_service.dart';
import 'package:thix_id/services/profile_photo_service.dart';
import 'package:thix_id/services/profile_service.dart';
import 'package:thix_id/services/user_service.dart';
import 'package:thix_id/services/verification_status.dart';
import 'package:thix_id/services/platform_file_from_path_stub.dart' if (dart.library.io) 'package:thix_id/services/platform_file_from_path_io.dart';
import '../../theme.dart';

// ============================================================
// DASHBOARD_EDITORS.DART - TOUS LES BOTTOM SHEETS COMPLETS
// Production: chaque editor gère son state, son upload, sa validation
// ============================================================

String _truncate(String v, int max) {
  final s = v.trim();
  if (s.length <= max) return s;
  return '${s.substring(0, max).trim()}…';
}

// -------------------- PROFILE EDITOR COMPLET --------------------
class ProfileEditorSheet {
  static Future<void> show(
    BuildContext context, {
    required ThixProfile profile,
    required ProfileService profileService,
    required dynamic authUser,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileEditorBody(
        profile: profile,
        profileService: profileService,
        authUser: authUser,
      ),
    );
  }
}

class _ProfileEditorBody extends StatefulWidget {
  final ThixProfile profile;
  final ProfileService profileService;
  final dynamic authUser;

  const _ProfileEditorBody({
    required this.profile,
    required this.profileService,
    required this.authUser,
  });

  @override
  State<_ProfileEditorBody> createState() => _ProfileEditorBodyState();
}

class _ProfileEditorBodyState extends State<_ProfileEditorBody> {
  late final TextEditingController _nameC, _competenceC, _bioC, _countryOriginC;
  late final TextEditingController _contactPhoneC, _dobC, _pobC, _nationalityC;
  late final TextEditingController _maritalC, _genderC, _occupationC, _addressC;
  late final TextEditingController _emergencyNameC, _emergencyPhoneC, _emergencyRelationC, _thixChatC;
  
  late final TextEditingController _originProvinceC, _originTerritoryFreeC;
  late final TextEditingController _residenceCountryC, _residenceProvinceC, _residenceCityC;
  late final TextEditingController _residenceTerritoryFreeC, _residenceCommuneFreeC;

  final _originSectorC = TextEditingController();
  final _residenceQuarterC = TextEditingController();
  final _residenceAvenueC = TextEditingController();
  final _residenceNumberC = TextEditingController();
  final _heightC = TextEditingController();
  final _weightC = TextEditingController();
  final _bloodGroupC = TextEditingController();
  final _disabilityDescC = TextEditingController();
  final _nationalIdNumberC = TextEditingController();
  final _idDocTypeC = TextEditingController();
  final _idIssueDateC = TextEditingController();
  final _idExpiryDateC = TextEditingController();
  final _idIssuePlaceC = TextEditingController();

  late final TextEditingController _langAddC, _langLevelC;

  bool _hasDisability = false;
  PlatformFile? _idFront, _idBack, _idSelfie;
  String? _idFrontDocId, _idBackDocId, _idSelfieDocId;
  String? _idVerificationStatus;
  
  late List<Map<String, dynamic>> _languagesDetailed;
  late List<String> _languages;
  PlatformFile? _pickedPhoto;
  bool _saving = false;

  String? _originProvince, _originTerritory;
  String? _residenceCountry, _residenceProvince, _residenceTerritory, _residenceCity, _residenceCommune;

  final _photos = ProfilePhotoService();
  final _userService = UserService(Supabase.instance.client);
  final _docs = DocumentService();

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    final a = widget.authUser;

    _nameC = TextEditingController(text: (p.fullName ?? p.displayName).trim().isEmpty ? p.displayName : (p.fullName ?? p.displayName));
    _competenceC = TextEditingController(text: p.competence ?? '');
    _bioC = TextEditingController(text: p.bio ?? '');
    _countryOriginC = TextEditingController(text: p.countryOrOrigin ?? '');
    _contactPhoneC = TextEditingController(text: a.contactPhone ?? '');
    _dobC = TextEditingController(text: a.dateOfBirth ?? '');
    _pobC = TextEditingController(text: a.placeOfBirth ?? '');
    _nationalityC = TextEditingController(text: a.nationality ?? '');
    _maritalC = TextEditingController(text: a.maritalStatus ?? '');
    _genderC = TextEditingController(text: a.gender ?? '');
    _occupationC = TextEditingController(text: (a.profession ?? p.profession ?? p.occupation ?? a.occupation) ?? '');
    _addressC = TextEditingController(text: a.address ?? '');
    _emergencyNameC = TextEditingController(text: a.emergencyContactName ?? '');
    _emergencyPhoneC = TextEditingController(text: a.emergencyContactPhone ?? '');
    _emergencyRelationC = TextEditingController(text: a.emergencyContactRelation ?? '');
    _thixChatC = TextEditingController(text: p.thixChat ?? '');

    _originProvince = (p.originProvince ?? '').trim().isEmpty ? null : p.originProvince;
    _originTerritory = (p.originTerritory ?? '').trim().isEmpty ? null : p.originTerritory;
    _originProvinceC = TextEditingController(text: _originProvince ?? '');
    _originTerritoryFreeC = TextEditingController(text: _originTerritory ?? '');
    _originSectorC.text = p.originSector ?? '';

    _residenceCountry = (p.residenceCountry ?? '').trim().isEmpty ? null : p.residenceCountry;
    _residenceProvince = (p.residenceProvince ?? '').trim().isEmpty ? null : p.residenceProvince;
    _residenceTerritory = (p.residenceTerritory ?? '').trim().isEmpty ? null : p.residenceTerritory;
    _residenceCity = (p.residenceCity ?? '').trim().isEmpty ? null : p.residenceCity;
    _residenceCommune = (p.residenceCommune ?? '').trim().isEmpty ? null : p.residenceCommune;

    _residenceCountryC = TextEditingController(text: _residenceCountry ?? '');
    _residenceProvinceC = TextEditingController(text: _residenceProvince ?? '');
    _residenceCityC = TextEditingController(text: _residenceCity ?? '');
    _residenceTerritoryFreeC = TextEditingController(text: _residenceTerritory ?? '');
    _residenceCommuneFreeC = TextEditingController(text: _residenceCommune ?? '');

    _residenceQuarterC.text = p.residenceQuarter ?? '';
    _residenceAvenueC.text = p.residenceAvenue ?? '';
    _residenceNumberC.text = p.residenceNumber ?? '';

    _heightC.text = p.height ?? '';
    _weightC.text = p.weight ?? '';
    _bloodGroupC.text = p.bloodGroup ?? '';
    _hasDisability = p.hasPhysicalDisability ?? false;
    _disabilityDescC.text = p.physicalDisabilityDescription ?? '';

    _nationalIdNumberC.text = p.nationalIdNumber ?? '';
    _idDocTypeC.text = p.idDocumentType ?? '';
    _idIssueDateC.text = p.idDocumentIssueDate ?? '';
    _idExpiryDateC.text = p.idDocumentExpiryDate ?? '';
    _idIssuePlaceC.text = p.idDocumentIssuePlace ?? '';

    _idFrontDocId = p.idDocumentFrontDocId;
    _idBackDocId = p.idDocumentBackDocId;
    _idSelfieDocId = p.idDocumentSelfieDocId;
    _idVerificationStatus = p.idVerificationStatus;

    _languagesDetailed = [...p.languagesDetailed];
    _languages = [...p.languages];
    _langAddC = TextEditingController();
    _langLevelC = TextEditingController();
  }

  @override
  void dispose() {
    _nameC.dispose(); _competenceC.dispose(); _bioC.dispose(); _countryOriginC.dispose();
    _contactPhoneC.dispose(); _dobC.dispose(); _pobC.dispose(); _nationalityC.dispose();
    _maritalC.dispose(); _genderC.dispose(); _occupationC.dispose(); _addressC.dispose();
    _emergencyNameC.dispose(); _emergencyPhoneC.dispose(); _emergencyRelationC.dispose();
    _thixChatC.dispose(); _langAddC.dispose(); _langLevelC.dispose();
    _originProvinceC.dispose(); _originTerritoryFreeC.dispose(); _originSectorC.dispose();
    _residenceCountryC.dispose(); _residenceProvinceC.dispose(); _residenceCityC.dispose();
    _residenceTerritoryFreeC.dispose(); _residenceCommuneFreeC.dispose();
    _residenceQuarterC.dispose(); _residenceAvenueC.dispose(); _residenceNumberC.dispose();
    _heightC.dispose(); _weightC.dispose(); _bloodGroupC.dispose(); _disabilityDescC.dispose();
    _nationalIdNumberC.dispose(); _idDocTypeC.dispose(); _idIssueDateC.dispose();
    _idExpiryDateC.dispose(); _idIssuePlaceC.dispose();
    super.dispose();
  }

  Future<void> _pickIdFile(String kind) async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        withData: kIsWeb,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'pdf'],
      );
      if (res == null || res.files.isEmpty) return;
      
      final f = res.files.first;
      setState(() {
        if (kind == 'front') _idFront = f;
        if (kind == 'back') _idBack = f;
        if (kind == 'selfie') _idSelfie = f;
      });
    } catch (e) {
      debugPrint('pick id $e');
    }
  }

  Future<void> _uploadIdIfNeeded({required String uid, required String kind}) async {
    final PlatformFile? f = switch (kind) {
      'front' => _idFront,
      'back' => _idBack,
      'selfie' => _idSelfie,
      _ => null
    };
    
    if (f == null) return;
    
    final docId = 'NATIONAL_ID_${kind.toUpperCase()}';
    await _docs.uploadPickedFile(
      uid: uid,
      docId: docId,
      title: 'Identité nationale (${kind == 'front' ? 'Recto' : kind == 'back' ? 'Verso' : 'Selfie'})',
      file: f,
      docType: 'national_id',
    );
    
    setState(() {
      if (kind == 'front') _idFrontDocId = docId;
      if (kind == 'back') _idBackDocId = docId;
      if (kind == 'selfie') _idSelfieDocId = docId;
      _idVerificationStatus = 'pending';
    });
  }

  void _addLanguage() {
    final raw = _langAddC.text.trim();
    if (raw.isEmpty) return;
    
    final level = _langLevelC.text.trim();
    final parts = raw.split(RegExp(r'[,;/]+')).map((e) => e.trim()).where((e) => e.isNotEmpty);
    final existing = _languagesDetailed.map((e) => (e['name'] ?? '').toString().toLowerCase()).toSet();
    final next = [..._languagesDetailed];
    
    for (final p in parts) {
      if (existing.contains(p.toLowerCase())) continue;
      next.add({'name': p, if (level.isNotEmpty) 'level': level});
    }
    
    final flat = {..._languages, ...next.map((e) => (e['name'] ?? '').toString().trim()).where((e) => e.isNotEmpty)}.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      
    setState(() {
      _languagesDetailed = next;
      _languages = flat;
      _langAddC.clear();
      _langLevelC.clear();
    });
  }

  void _removeLanguage(String v) {
    setState(() {
      _languages = _languages.where((e) => e != v).toList();
      _languagesDetailed = _languagesDetailed.where((e) => (e['name'] ?? '').toString().trim() != v).toList();
    });
  }

  Future<void> _save() async {
    _originProvince = _originProvinceC.text.trim().isEmpty ? null : _originProvinceC.text.trim();
    _originTerritory = _originTerritoryFreeC.text.trim().isEmpty ? null : _originTerritoryFreeC.text.trim();
    _residenceCountry = _residenceCountryC.text.trim().isEmpty ? null : _residenceCountryC.text.trim();
    _residenceProvince = _residenceProvinceC.text.trim().isEmpty ? null : _residenceProvinceC.text.trim();
    _residenceTerritory = _residenceTerritoryFreeC.text.trim().isEmpty ? null : _residenceTerritoryFreeC.text.trim();
    _residenceCity = _residenceCityC.text.trim().isEmpty ? null : _residenceCityC.text.trim();
    _residenceCommune = _residenceCommuneFreeC.text.trim().isEmpty ? null : _residenceCommuneFreeC.text.trim();

    if (_nameC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nom requis.')));
      return;
    }
    
    setState(() => _saving = true);
    
    try {
      String? newPhotoUrl;
      if (_pickedPhoto != null) {
        newPhotoUrl = await _photos.uploadProfilePhoto(uid: widget.profile.userId, file: _pickedPhoto!);
      }
      
      await _uploadIdIfNeeded(uid: widget.profile.userId, kind: 'front');
      await _uploadIdIfNeeded(uid: widget.profile.userId, kind: 'back');
      await _uploadIdIfNeeded(uid: widget.profile.userId, kind: 'selfie');

      await _userService.updateProfile(
        uid: widget.profile.userId,
        displayName: _nameC.text.trim(),
        fullName: _nameC.text.trim(),
        competence: _competenceC.text,
        bio: _bioC.text,
        countryOrOrigin: _countryOriginC.text,
        contactPhone: _contactPhoneC.text,
        maritalStatus: _maritalC.text,
        gender: _genderC.text,
        profession: _occupationC.text,
        occupation: _occupationC.text,
        dateOfBirth: _dobC.text,
        placeOfBirth: _pobC.text,
        nationality: _nationalityC.text,
        address: _addressC.text,
        emergencyContactName: _emergencyNameC.text,
        emergencyContactPhone: _emergencyPhoneC.text,
        emergencyContactRelation: _emergencyRelationC.text,
        originProvince: _originProvince,
        originTerritory: _originTerritory,
        originSector: _originSectorC.text,
        residenceCountry: _residenceCountry,
        residenceProvince: _residenceProvince,
        residenceTerritory: _residenceTerritory,
        residenceCity: _residenceCity,
        residenceCommune: _residenceCommune,
        residenceQuarter: _residenceQuarterC.text,
        residenceAvenue: _residenceAvenueC.text,
        residenceNumber: _residenceNumberC.text,
        height: _heightC.text,
        weight: _weightC.text,
        bloodGroup: _bloodGroupC.text,
        hasPhysicalDisability: _hasDisability,
        physicalDisabilityDescription: _disabilityDescC.text,
        nationalIdNumber: _nationalIdNumberC.text,
        idDocumentType: _idDocTypeC.text,
        idDocumentIssueDate: _idIssueDateC.text,
        idDocumentExpiryDate: _idExpiryDateC.text,
        idDocumentIssuePlace: _idIssuePlaceC.text,
        idDocumentFrontDocId: _idFrontDocId,
        idDocumentBackDocId: _idBackDocId,
        idDocumentSelfieDocId: _idSelfieDocId,
        idVerificationStatus: _idVerificationStatus,
        thixChat: _thixChatC.text,
        languages: _languages,
        languagesDetailed: _languagesDetailed,
        photoUrl: newPhotoUrl,
      );

      final updated = widget.authUser.copyWith(
        displayName: _nameC.text.trim(),
        bio: _bioC.text.trim(),
        countryOrOrigin: _countryOriginC.text.trim(),
        occupation: _occupationC.text.trim(),
        profession: _occupationC.text.trim(),
        thixChat: _thixChatC.text.trim(),
        languages: _languages,
        photoUrl: newPhotoUrl ?? widget.authUser.photoUrl,
        contactPhone: _contactPhoneC.text.trim(),
        maritalStatus: _maritalC.text.trim(),
        gender: _genderC.text.trim(),
        dateOfBirth: _dobC.text.trim(),
        placeOfBirth: _pobC.text.trim(),
        nationality: _nationalityC.text.trim(),
        address: _addressC.text.trim(),
        emergencyContactName: _emergencyNameC.text.trim(),
        emergencyContactPhone: _emergencyPhoneC.text.trim(),
        emergencyContactRelation: _emergencyRelationC.text.trim(),
      );

      if (mounted) await context.read<AuthController>().updateCurrentUser(updated);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil mis à jour.')));
      context.pop();
    } catch (e) {
      debugPrint('save failed $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: kIsWeb);
      if (res == null || res.files.isEmpty) return;
      setState(() => _pickedPhoto = res.files.first);
    } catch (e) {
      debugPrint('pick photo $e');
    }
  }

  Widget _idSlot({required String kind, required String? docId, required String label, required IconData icon}) {
    if (docId == null || docId.trim().isEmpty) {
      return OutlinedButton.icon(
        onPressed: _saving ? null : () => _pickIdFile(kind),
        icon: Icon(icon),
        label: Text(label),
      );
    }
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: _docs.fetchLatestDocumentRowByDocId(uid: widget.profile.userId, docId: docId),
      builder: (context, snap) {
        final row = snap.data;
        final path = (row?['storage_path'] ?? '').toString().trim();
        final fileName = (row?['file_name'] ?? '').toString().trim();
        final mime = (row?['mime_type'] ?? '').toString().trim();
        
        if (path.isEmpty) {
          return OutlinedButton.icon(
            onPressed: _saving ? null : () => _pickIdFile(kind),
            icon: Icon(icon),
            label: Text('$label ✓'),
          );
        }
        
        return UploadDocumentPreview(
          bucketName: DocumentService.bucket,
          storagePath: path,
          fileName: fileName.isEmpty ? '$label${mime.toLowerCase().contains('pdf') ? '.pdf' : ''}' : fileName,
          mimeType: mime,
          label: label,
          onDelete: _saving ? null : () async {
            try {
              await _docs.deleteLatestDocumentByDocId(uid: widget.profile.userId, docId: docId);
              setState(() {
                if (kind == 'front') _idFrontDocId = null;
                if (kind == 'back') _idBackDocId = null;
                if (kind == 'selfie') _idSelfieDocId = null;
              });
            } catch (e) {
              debugPrint('delete $e');
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xl),
            topRight: Radius.circular(AppRadius.xl),
          ),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Modifier mon profil', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  IconButton(onPressed: _saving ? null : () => context.pop(), icon: const Icon(Icons.close_rounded))
                ],
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: LightModeColors.accent.withOpacity(0.65), width: 2),
                      image: DecorationImage(
                        image: _pickedPhoto != null
                            ? (kIsWeb ? MemoryImage(_pickedPhoto!.bytes!) : FileImage(fileFromPath(_pickedPhoto!.path!) as dynamic)) as ImageProvider
                            : ((widget.profile.photoUrl ?? '').trim().isNotEmpty
                                ? NetworkImage(widget.profile.photoUrl!.trim())
                                : const AssetImage('assets/images/African_businessman_in_suit_grayscale_1775573970767.jpg')),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _pickPhoto,
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: const Text('Changer la photo'),
                      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              TextField(controller: _nameC, decoration: InputDecoration(labelText: 'Nom complet', prefixIcon: const Icon(Icons.person_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _competenceC, maxLines: 2, decoration: InputDecoration(labelText: 'Compétences (résumé)', prefixIcon: const Icon(Icons.auto_awesome_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _countryOriginC, decoration: InputDecoration(labelText: 'Origines / Pays d\'origine', prefixIcon: const Icon(Icons.public_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _bioC, maxLines: 3, decoration: InputDecoration(labelText: 'Bio', prefixIcon: const Icon(Icons.psychology_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.translate_rounded, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Langues', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_languages.isEmpty)
                      Text('Aucune langue.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText))
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _languages.map((l) => InputChip(
                          label: Text(l, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          onDeleted: _saving ? null : () => _removeLanguage(l),
                          deleteIconColor: LightModeColors.error,
                        )).toList(),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _langAddC, enabled: !_saving, onSubmitted: (_) => _addLanguage(), decoration: InputDecoration(labelText: 'Ajouter langue', hintText: 'Français, Anglais', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                        const SizedBox(width: 8),
                        SizedBox(width: 80, child: TextField(controller: _langLevelC, decoration: InputDecoration(labelText: 'Niveau', hintText: 'B2', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saving ? null : _addLanguage,
                          style: ElevatedButton.styleFrom(backgroundColor: LightModeColors.accent),
                          child: const Text('Ajouter', style: TextStyle(color: Color(0xFF123B7A), fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              TextField(controller: _contactPhoneC, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Contact', prefixIcon: const Icon(Icons.call_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _dobC, decoration: InputDecoration(labelText: 'Date naissance YYYY-MM-DD', prefixIcon: const Icon(Icons.cake_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _pobC, decoration: InputDecoration(labelText: 'Lieu naissance', prefixIcon: const Icon(Icons.location_on_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _nationalityC, decoration: InputDecoration(labelText: 'Nationalité', prefixIcon: const Icon(Icons.flag_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _maritalC, decoration: InputDecoration(labelText: 'État civil', prefixIcon: const Icon(Icons.favorite_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _genderC, decoration: InputDecoration(labelText: 'Genre', prefixIcon: const Icon(Icons.wc_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _occupationC, decoration: InputDecoration(labelText: 'Profession', prefixIcon: const Icon(Icons.work_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _addressC, maxLines: 2, decoration: InputDecoration(labelText: 'Adresse', prefixIcon: const Icon(Icons.home_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              
              const SizedBox(height: 16),
              Text('Origine', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              TextField(controller: _originProvinceC, decoration: InputDecoration(labelText: 'Province origine', prefixIcon: const Icon(Icons.map_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _originTerritoryFreeC, decoration: InputDecoration(labelText: 'Territoire (optionnel)', prefixIcon: const Icon(Icons.place_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _originSectorC, decoration: InputDecoration(labelText: 'Secteur', prefixIcon: const Icon(Icons.account_tree_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              
              const SizedBox(height: 16),
              Text('Résidence actuelle', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              TextField(controller: _residenceCountryC, decoration: InputDecoration(labelText: 'Pays', prefixIcon: const Icon(Icons.public_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _residenceProvinceC, decoration: InputDecoration(labelText: 'Province', prefixIcon: const Icon(Icons.map_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _residenceTerritoryFreeC, decoration: InputDecoration(labelText: 'Territoire (optionnel)', prefixIcon: const Icon(Icons.place_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _residenceCityC, decoration: InputDecoration(labelText: 'Ville', prefixIcon: const Icon(Icons.location_city_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _residenceCommuneFreeC, decoration: InputDecoration(labelText: 'Commune', prefixIcon: const Icon(Icons.apartment_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _residenceQuarterC, decoration: InputDecoration(labelText: 'Quartier', prefixIcon: const Icon(Icons.streetview_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _residenceAvenueC, decoration: InputDecoration(labelText: 'Avenue', prefixIcon: const Icon(Icons.route_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _residenceNumberC, decoration: InputDecoration(labelText: 'Numéro', prefixIcon: const Icon(Icons.numbers_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                ],
              ),
              
              const SizedBox(height: 16),
              TextField(controller: _emergencyNameC, decoration: InputDecoration(labelText: 'Contact urgence — Nom', prefixIcon: const Icon(Icons.contact_emergency_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _emergencyPhoneC, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Contact urgence — Téléphone', prefixIcon: const Icon(Icons.call_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _emergencyRelationC, decoration: InputDecoration(labelText: 'Lien', hintText: 'Frère / Mère', prefixIcon: const Icon(Icons.family_restroom_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : () => EmergencyContactsEditorSheet.show(context, profile: widget.profile, profileService: widget.profileService),
                  icon: const Icon(Icons.group_add_rounded),
                  label: const Text('Ajouter un contact (multi)'),
                ),
              ),
              
              const SizedBox(height: 16),
              Text('Infos physiques', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: _heightC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Taille (cm)', prefixIcon: const Icon(Icons.height_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _weightC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Poids (kg)', prefixIcon: const Icon(Icons.monitor_weight_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: _bloodGroupC, decoration: InputDecoration(labelText: 'Groupe sanguin', hintText: 'A+, O-', prefixIcon: const Icon(Icons.bloodtype_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _hasDisability,
                onChanged: _saving ? null : (v) => setState(() => _hasDisability = v),
                title: const Text('Handicap physique'),
                subtitle: Text(_hasDisability ? 'Oui' : 'Non'),
                contentPadding: EdgeInsets.zero,
              ),
              if (_hasDisability)
                TextField(controller: _disabilityDescC, maxLines: 2, decoration: InputDecoration(labelText: 'Description', prefixIcon: const Icon(Icons.notes_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              
              const SizedBox(height: 16),
              Text('Identité nationale', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              TextField(controller: _nationalIdNumberC, decoration: InputDecoration(labelText: 'Numéro identité', prefixIcon: const Icon(Icons.badge_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _idDocTypeC, decoration: InputDecoration(labelText: 'Type document', hintText: 'Carte identité / Passeport', prefixIcon: const Icon(Icons.credit_card_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _idIssueDateC, decoration: InputDecoration(labelText: 'Date émission', hintText: 'YYYY-MM-DD', prefixIcon: const Icon(Icons.event_available_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _idExpiryDateC, decoration: InputDecoration(labelText: 'Date expiration', hintText: 'YYYY-MM-DD', prefixIcon: const Icon(Icons.event_busy_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: _idIssuePlaceC, decoration: InputDecoration(labelText: 'Lieu émission', prefixIcon: const Icon(Icons.place_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Pièces identité (photo/PDF)', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.orange.withOpacity(0.25)),
                          ),
                          child: Text(
                            (_idVerificationStatus ?? 'pending') == 'verified' ? 'Vérifié' : 'En attente',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _idSlot(kind: 'front', docId: _idFrontDocId, label: 'Recto', icon: Icons.photo_rounded)),
                        const SizedBox(width: 8),
                        Expanded(child: _idSlot(kind: 'back', docId: _idBackDocId, label: 'Verso', icon: Icons.photo_library_rounded)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(child: _idSlot(kind: 'selfie', docId: _idSelfieDocId, label: 'Selfie avec document', icon: Icons.face_rounded)),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              TextField(controller: _thixChatC, decoration: InputDecoration(labelText: 'THIX CHAT (@handle)', prefixIcon: const Icon(Icons.alternate_email_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 20),
              
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF123B7A)))
                      : const Icon(Icons.save_rounded, color: Color(0xFF123B7A)),
                  label: Text('SAUVEGARDER', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF123B7A), fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LightModeColors.accent,
                    foregroundColor: const Color(0xFF123B7A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- PARCOURS EDITOR --------------------
class ParcoursEditorSheet {
  static Future<void> show(BuildContext context, {required ThixProfile profile, required ProfileService profileService}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ParcoursEditorBody(profile: profile, profileService: profileService),
    );
  }
}

class _ParcoursEditorBody extends StatefulWidget {
  final ThixProfile profile;
  final ProfileService profileService;
  const _ParcoursEditorBody({required this.profile, required this.profileService});
  @override
  State<_ParcoursEditorBody> createState() => _ParcoursEditorBodyState();
}

class _ParcoursEditorBodyState extends State<_ParcoursEditorBody> {
  late final TextEditingController _bioC, _competenceC;
  late List<EducationEntryControllers> _education;
  late List<ExperienceEntryControllers> _experience;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bioC = TextEditingController(text: widget.profile.bio ?? '');
    _competenceC = TextEditingController(text: widget.profile.competence ?? '');
    
    final edu = widget.profile.education.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    final exp = widget.profile.experience.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    
    _education = edu.isEmpty ? [EducationEntryControllers()] : edu.map(EducationEntryControllers.fromMap).toList(growable: true);
    _experience = exp.isEmpty ? [ExperienceEntryControllers()] : exp.map(ExperienceEntryControllers.fromMap).toList(growable: true);
  }

  @override
  void dispose() {
    _bioC.dispose();
    _competenceC.dispose();
    for (final e in _education) e.dispose();
    for (final e in _experience) e.dispose();
    super.dispose();
  }

  String? _validate() {
    final bio = _bioC.text.trim();
    if (bio.isEmpty) return 'Bio requise.';
    if (bio.length < 40) return 'Bio trop courte (40 car min).';
    
    bool hasEdu = false;
    for (final e in _education) {
      final level = e.levelC.text.trim().toLowerCase();
      final inst = e.institutionC.text.trim();
      final city = e.cityC.text.trim();
      final degree = e.degreeC.text.trim();
      final start = e.startYearC.text.trim();
      final degreeReq = level.startsWith('sup') || level.startsWith('for');
      final ok = inst.isNotEmpty && city.isNotEmpty && start.isNotEmpty && (!degreeReq || degree.isNotEmpty);
      if (ok) {
        hasEdu = true;
        break;
      }
    }
    if (!hasEdu) return 'Ajoutez au moins 1 cursus.';
    
    bool hasExp = false;
    for (final e in _experience) {
      final company = e.companyC.text.trim();
      final city = e.cityC.text.trim();
      final title = e.titleC.text.trim();
      final missions = e.missionsC.text.trim();
      if (company.isNotEmpty && city.isNotEmpty && title.isNotEmpty && missions.isNotEmpty) {
        hasExp = true;
        break;
      }
    }
    if (!hasExp) return 'Ajoutez au moins 1 expérience.';
    
    return null;
  }

  Future<void> _save() async {
    final err = _validate();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    
    setState(() => _saving = true);
    try {
      final edu = _education.map((e) => e.toMap()).toList();
      final exp = _experience.map((e) => e.toMap()).toList();
      await widget.profileService.updateProfile(userId: widget.profile.userId, bio: _bioC.text.trim(), competence: _competenceC.text.trim(), education: edu, experience: exp);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parcours sauvegardé.')));
      context.pop();
    } catch (e) {
      debugPrint('Parcours save $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sauvegarde impossible.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mon parcours', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    IconButton(onPressed: _saving ? null : () => context.pop(), icon: const Icon(Icons.close_rounded))
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<ThixProfile?>(
                  stream: widget.profileService.streamMyProfile(widget.profile.userId),
                  builder: (context, snap) {
                    return ParcoursForm(
                      header: Text('Compétences', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                      bioC: _bioC,
                      competenceC: _competenceC,
                      education: _education,
                      experience: _experience,
                      enabled: !_saving,
                      onAddEducation: () => setState(() => _education.add(EducationEntryControllers())),
                      onRemoveEducation: (i) {
                        if (_education.length <= 1) return;
                        setState(() => _education.removeAt(i).dispose());
                      },
                      onAddExperience: () => setState(() => _experience.add(ExperienceEntryControllers())),
                      onRemoveExperience: (i) {
                        if (_experience.length <= 1) return;
                        setState(() => _experience.removeAt(i).dispose());
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF123B7A)))
                        : const Icon(Icons.save_rounded, color: Color(0xFF123B7A)),
                    label: Text('SAUVEGARDER', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF123B7A), fontWeight: FontWeight.w900)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LightModeColors.accent,
                      foregroundColor: const Color(0xFF123B7A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------- EXPERIENCE EDITOR --------------------
class ExperienceEditorSheet {
  static Future<void> show(BuildContext context, {required ThixProfile profile, required ProfileService profileService}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExperienceEditorBody(profile: profile, profileService: profileService),
    );
  }
}

class _ExperienceEditorBody extends StatefulWidget {
  final ThixProfile profile;
  final ProfileService profileService;
  const _ExperienceEditorBody({required this.profile, required this.profileService});
  @override
  State<_ExperienceEditorBody> createState() => _ExperienceEditorBodyState();
}

class _ExperienceEditorBodyState extends State<_ExperienceEditorBody> {
  final _titleC = TextEditingController();
  final _orgC = TextEditingController();
  final _dateC = TextEditingController();
  final _tasksC = TextEditingController();
  final _sectorC = TextEditingController();
  final _cityC = TextEditingController();
  List<EvidenceFileRef> _evidence = const [];
  final _docs = DocumentService();
  bool _saving = false;
  int? _editingIndex;

  @override
  void dispose() {
    _titleC.dispose(); _orgC.dispose(); _dateC.dispose(); _tasksC.dispose(); _sectorC.dispose(); _cityC.dispose();
    super.dispose();
  }

  void _loadForEdit(int index, Map<String, dynamic> entry) {
    final raw = (entry['evidence'] as List?) ?? [];
    final parsed = raw.map(EvidenceFileRef.tryParse).whereType<EvidenceFileRef>().toList();
    setState(() {
      _editingIndex = index;
      _titleC.text = (entry['title'] as String?) ?? '';
      _orgC.text = (entry['org'] as String?) ?? (entry['company'] as String?) ?? '';
      _dateC.text = (entry['date'] as String?) ?? (entry['period'] as String?) ?? '';
      _tasksC.text = (entry['tasks'] as String?) ?? (entry['missions'] as String?) ?? '';
      _sectorC.text = (entry['sector'] as String?) ?? '';
      _cityC.text = (entry['city'] as String?) ?? '';
      _evidence = parsed;
    });
  }

  void _reset() {
    setState(() {
      _editingIndex = null;
      _titleC.clear(); _orgC.clear(); _dateC.clear(); _tasksC.clear(); _sectorC.clear(); _cityC.clear();
      _evidence = const [];
    });
  }

  Future<void> _pickEvidence() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: kIsWeb,
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      );
      if (res == null || res.files.isEmpty) return;
      
      setState(() => _saving = true);
      final uid = widget.profile.userId;
      final uploaded = <EvidenceFileRef>[];
      
      for (final f in res.files) {
        final docId = 'CRED_EXP_${DateTime.now().millisecondsSinceEpoch}_${f.name}'.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_').toUpperCase();
        await _docs.uploadPickedFile(
          uid: uid,
          docId: docId,
          title: 'Pièce expérience: ${_titleC.text.trim().isEmpty ? f.name : _titleC.text.trim()}',
          file: f,
          docType: 'credential_experience',
        );
        uploaded.add(EvidenceFileRef(storagePathOrUrl: 'documents:$docId', label: f.name));
      }
      
      if (!mounted) return;
      setState(() => _evidence = [..._evidence, ...uploaded]);
    } catch (e) {
      debugPrint('pick evidence $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save(List<Map<String, dynamic>> existing) async {
    final title = _titleC.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Titre requis.')));
      return;
    }
    
    setState(() => _saving = true);
    try {
      final next = [...existing];
      final patch = {
        'title': title,
        'org': _orgC.text.trim(),
        'date': _dateC.text.trim(),
        'sector': _sectorC.text.trim(),
        'city': _cityC.text.trim(),
        if (_tasksC.text.trim().isNotEmpty) 'tasks': _tasksC.text.trim(),
        'verification_status': VerificationStatus.pending.value,
        'evidence': _evidence.map((e) => e.toJson()).toList(),
      };
      
      if (_editingIndex != null && _editingIndex! >= 0 && _editingIndex! < next.length) {
        next[_editingIndex!] = patch;
      } else {
        next.add(patch);
      }
      
      await widget.profileService.updateProfile(userId: widget.profile.userId, experience: next);
      if (!mounted) return;
      
      final wasEdit = _editingIndex != null;
      _reset();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(wasEdit ? 'Expérience mise à jour.' : 'Expérience ajoutée.')));
    } catch (e) {
      debugPrint('save exp $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(List<Map<String, dynamic>> existing, int index) async {
    if (index < 0 || index >= existing.length) return;
    setState(() => _saving = true);
    try {
      final next = [...existing]..removeAt(index);
      await widget.profileService.updateProfile(userId: widget.profile.userId, experience: next);
      if (!mounted) return;
      if (_editingIndex == index) _reset();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<ThixProfile?>(
          stream: widget.profileService.streamMyProfile(widget.profile.userId),
          builder: (context, snap) {
            final existing = (snap.data ?? widget.profile).experience;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_editingIndex == null ? 'Ajouter une expérience' : 'Modifier', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded))
                  ],
                ),
                if (existing.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Vos expériences', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        ...List.generate(existing.length, (i) {
                          final e = existing[i];
                          final title = (e['title'] as String?) ?? '—';
                          final org = (e['org'] as String?) ?? '';
                          final date = (e['date'] as String?) ?? '';
                          final selected = _editingIndex == i;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: selected ? LightModeColors.accent.withOpacity(0.12) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: selected ? LightModeColors.accent : Theme.of(context).dividerColor),
                            ),
                            child: ListTile(
                              dense: true,
                              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              subtitle: Text([org, date].where((v) => v.trim().isNotEmpty).join(' • '), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              onTap: _saving ? null : () => _loadForEdit(i, e),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: _saving ? null : () => _delete(existing, i),
                              ),
                            ),
                          );
                        })
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(controller: _titleC, decoration: InputDecoration(labelText: 'Titre', prefixIcon: const Icon(Icons.work_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 12),
                TextField(controller: _orgC, decoration: InputDecoration(labelText: 'Organisation', prefixIcon: const Icon(Icons.business_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _sectorC, decoration: InputDecoration(labelText: 'Secteur', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _cityC, decoration: InputDecoration(labelText: 'Ville', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: _dateC, decoration: InputDecoration(labelText: 'Période 2023-2025', prefixIcon: const Icon(Icons.calendar_today_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 12),
                TextField(controller: _tasksC, maxLines: 4, decoration: InputDecoration(labelText: 'Tâches / Responsabilités', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.attachment_rounded, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Pièces obtenues', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900))),
                          OutlinedButton.icon(onPressed: _saving ? null : _pickEvidence, icon: const Icon(Icons.upload_file_rounded), label: const Text('Ajouter'))
                        ],
                      ),
                      if (_evidence.isEmpty)
                        Text('Aucune pièce.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText))
                      else
                        ..._evidence.map((e) => Row(
                          children: [
                            const Icon(Icons.insert_drive_file_rounded, size: 18, color: LightModeColors.accent),
                            const SizedBox(width: 8),
                            Expanded(child: Text(e.label ?? 'Pièce', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                            IconButton(
                              onPressed: () => setState(() => _evidence = _evidence.where((x) => x != e).toList()),
                              icon: const Icon(Icons.close, color: Colors.red, size: 18),
                            ),
                          ],
                        ))
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : () => _save(existing),
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF123B7A)))
                        : const Icon(Icons.save_rounded, color: Color(0xFF123B7A)),
                    label: Text(_editingIndex == null ? 'AJOUTER' : 'METTRE À JOUR', style: const TextStyle(color: Color(0xFF123B7A), fontWeight: FontWeight.w900)),
                    style: ElevatedButton.styleFrom(backgroundColor: LightModeColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  ),
                ),
                if (_editingIndex != null)
                  TextButton.icon(onPressed: _reset, icon: const Icon(Icons.restart_alt_rounded), label: const Text('Annuler')),
              ],
            );
          },
        ),
      ),
    );
  }
}

// -------------------- SKILLS EDITOR --------------------
class SkillsEditorSheet {
  static Future<void> show(BuildContext context, {required ThixProfile profile, required ProfileService profileService}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SkillsEditorBody(profile: profile, profileService: profileService),
    );
  }
}

class _SkillsEditorBody extends StatefulWidget {
  final ThixProfile profile;
  final ProfileService profileService;
  const _SkillsEditorBody({required this.profile, required this.profileService});
  @override
  State<_SkillsEditorBody> createState() => _SkillsEditorBodyState();
}

class _SkillsEditorBodyState extends State<_SkillsEditorBody> {
  final _nameC = TextEditingController();
  final _detailsC = TextEditingController();
  String _level = 'Intermédiaire';
  bool _saving = false;
  int? _editingIndex;

  @override
  void dispose() {
    _nameC.dispose(); _detailsC.dispose();
    super.dispose();
  }

  void _load(int i, Map<String, dynamic> e) {
    setState(() {
      _editingIndex = i;
      _nameC.text = (e['name'] as String?) ?? '';
      _level = (e['level'] as String?) ?? 'Intermédiaire';
      _detailsC.text = (e['details'] as String?) ?? '';
    });
  }

  void _reset() {
    setState(() {
      _editingIndex = null;
      _nameC.clear();
      _level = 'Intermédiaire';
      _detailsC.clear();
    });
  }

  Future<void> _save(List<Map<String, dynamic>> existing) async {
    final name = _nameC.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nom requis.')));
      return;
    }
    
    setState(() => _saving = true);
    try {
      final next = [...existing];
      final patch = {'name': name, 'level': _level, if (_detailsC.text.trim().isNotEmpty) 'details': _detailsC.text.trim()};
      
      if (_editingIndex != null && _editingIndex! >= 0 && _editingIndex! < next.length) {
        next[_editingIndex!] = patch;
      } else {
        next.add(patch);
      }
      
      await widget.profileService.updateProfile(userId: widget.profile.userId, skills: next);
      if (!mounted) return;
      
      final wasEdit = _editingIndex != null;
      _reset();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(wasEdit ? 'Compétence mise à jour.' : 'Compétence ajoutée.')));
    } catch (e) {
      debugPrint('skills save $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(List<Map<String, dynamic>> existing, int index) async {
    if (index < 0 || index >= existing.length) return;
    setState(() => _saving = true);
    try {
      final next = [...existing]..removeAt(index);
      await widget.profileService.updateProfile(userId: widget.profile.userId, skills: next);
      if (_editingIndex == index) _reset();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<ThixProfile?>(
          stream: widget.profileService.streamMyProfile(widget.profile.userId),
          builder: (context, snap) {
            final existing = (snap.data ?? widget.profile).skills;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_editingIndex == null ? 'Ajouter compétence' : 'Modifier compétence', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded))
                  ],
                ),
                if (existing.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      children: List.generate(existing.length, (i) {
                        final e = existing[i];
                        final name = (e['name'] as String?) ?? '—';
                        final level = (e['level'] as String?) ?? '—';
                        final selected = _editingIndex == i;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: selected ? LightModeColors.accent.withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: selected ? LightModeColors.accent : Theme.of(context).dividerColor),
                          ),
                          child: ListTile(
                            dense: true,
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text(level, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            onTap: () => _load(i, e),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _delete(existing, i),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(controller: _nameC, decoration: InputDecoration(labelText: 'Compétence', prefixIcon: const Icon(Icons.psychology_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 12),
                TextField(controller: _detailsC, maxLines: 3, decoration: InputDecoration(labelText: 'Explication / Détails', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _level,
                  items: const [
                    DropdownMenuItem(value: 'Débutant', child: Text('Débutant')),
                    DropdownMenuItem(value: 'Intermédiaire', child: Text('Intermédiaire')),
                    DropdownMenuItem(value: 'Avancé', child: Text('Avancé')),
                    DropdownMenuItem(value: 'Expert', child: Text('Expert'))
                  ],
                  onChanged: (v) => setState(() => _level = v ?? 'Intermédiaire'),
                  decoration: InputDecoration(labelText: 'Niveau', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : () => _save(existing),
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF123B7A)))
                        : const Icon(Icons.save_rounded, color: Color(0xFF123B7A)),
                    label: Text(_editingIndex == null ? 'AJOUTER' : 'METTRE À JOUR', style: const TextStyle(color: Color(0xFF123B7A), fontWeight: FontWeight.w900)),
                    style: ElevatedButton.styleFrom(backgroundColor: LightModeColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  ),
                ),
                if (_editingIndex != null)
                  TextButton.icon(onPressed: _reset, icon: const Icon(Icons.restart_alt_rounded), label: const Text('Annuler')),
              ],
            );
          },
        ),
      ),
    );
  }
}

// -------------------- EMERGENCY CONTACTS EDITOR --------------------
class EmergencyContactsEditorSheet {
  static Future<void> show(BuildContext context, {required ThixProfile profile, required ProfileService profileService}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmergencyContactsEditorBody(profile: profile, profileService: profileService),
    );
  }
}

class _EmergencyContactsEditorBody extends StatefulWidget {
  final ThixProfile profile;
  final ProfileService profileService;
  const _EmergencyContactsEditorBody({required this.profile, required this.profileService});
  @override
  State<_EmergencyContactsEditorBody> createState() => _EmergencyContactsEditorBodyState();
}

class _EmergencyContactsEditorBodyState extends State<_EmergencyContactsEditorBody> {
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  final _relationC = TextEditingController();
  final _cityC = TextEditingController();
  bool _saving = false;
  int? _editingIndex;

  @override
  void dispose() {
    _nameC.dispose(); _phoneC.dispose(); _relationC.dispose(); _cityC.dispose();
    super.dispose();
  }

  void _load(int i, Map<String, dynamic> e) {
    setState(() {
      _editingIndex = i;
      _nameC.text = (e['name'] as String?) ?? '';
      _phoneC.text = (e['phone'] as String?) ?? (e['number'] as String?) ?? '';
      _relationC.text = (e['relation'] as String?) ?? '';
      _cityC.text = (e['city'] as String?) ?? '';
    });
  }

  void _reset() {
    setState(() {
      _editingIndex = null;
      _nameC.clear(); _phoneC.clear(); _relationC.clear(); _cityC.clear();
    });
  }

  Future<void> _save(List<Map<String, dynamic>> existing) async {
    final name = _nameC.text.trim();
    final phone = _phoneC.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nom et numéro requis.')));
      return;
    }
    
    setState(() => _saving = true);
    try {
      final next = [...existing];
      final patch = {'name': name, 'phone': phone, 'relation': _relationC.text.trim(), 'city': _cityC.text.trim()};
      
      if (_editingIndex != null && _editingIndex! >= 0 && _editingIndex! < next.length) {
        next[_editingIndex!] = patch;
      } else {
        next.add(patch);
      }
      
      await widget.profileService.updateProfile(userId: widget.profile.userId, emergencyContacts: next);
      if (!mounted) return;
      
      final wasEdit = _editingIndex != null;
      _reset();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(wasEdit ? 'Contact mis à jour.' : 'Contact ajouté.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(List<Map<String, dynamic>> existing, int index) async {
    if (index < 0 || index >= existing.length) return;
    setState(() => _saving = true);
    try {
      final next = [...existing]..removeAt(index);
      await widget.profileService.updateProfile(userId: widget.profile.userId, emergencyContacts: next);
      if (_editingIndex == index) _reset();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<ThixProfile?>(
          stream: widget.profileService.streamMyProfile(widget.profile.userId),
          builder: (context, snap) {
            final existing = (snap.data ?? widget.profile).emergencyContacts;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_editingIndex == null ? 'Ajouter contact' : 'Modifier contact', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded))
                  ],
                ),
                if (existing.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      children: List.generate(existing.length, (i) {
                        final e = existing[i];
                        final name = (e['name'] as String?) ?? '—';
                        final phone = (e['phone'] as String?) ?? '';
                        final selected = _editingIndex == i;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: selected ? LightModeColors.accent.withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: selected ? LightModeColors.accent : Theme.of(context).dividerColor),
                          ),
                          child: ListTile(
                            dense: true,
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text(phone, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            onTap: () => _load(i, e),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _delete(existing, i),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(controller: _nameC, decoration: InputDecoration(labelText: 'Nom', prefixIcon: const Icon(Icons.person_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 12),
                TextField(controller: _phoneC, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Numéro', prefixIcon: const Icon(Icons.call_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _relationC, decoration: InputDecoration(labelText: 'Relation', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _cityC, decoration: InputDecoration(labelText: 'Ville', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : () => _save(existing),
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF123B7A)))
                        : const Icon(Icons.save_rounded, color: Color(0xFF123B7A)),
                    label: Text(_editingIndex == null ? 'AJOUTER' : 'METTRE À JOUR', style: const TextStyle(color: Color(0xFF123B7A), fontWeight: FontWeight.w900)),
                    style: ElevatedButton.styleFrom(backgroundColor: LightModeColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  ),
                ),
                if (_editingIndex != null)
                  TextButton.icon(onPressed: _reset, icon: const Icon(Icons.restart_alt_rounded), label: const Text('Annuler')),
              ],
            );
          },
        ),
      ),
    );
  }
}
