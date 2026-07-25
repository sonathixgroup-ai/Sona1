import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/thix_profile.dart';
import 'package:thix_id/services/document_service.dart';
import 'package:thix_id/services/profile_photo_service.dart';
import 'package:thix_id/services/profile_service.dart';
import 'package:thix_id/services/user_service.dart';
import 'package:thix_id/services/platform_file_from_path_stub.dart' if (dart.library.io) 'package:thix_id/services/platform_file_from_path_io.dart';
import '../../theme.dart';

// ============================================================
// CONSTANTES DESIGN & CHARTE GRAPHIQUE
// ============================================================
const _blue = Color(0xFF0D2CC1);
const _blueDark = Color(0xFF0A1E8A);
const _bgLight = Color(0xFFF5F6FB);

InputDecoration _inputDecor(String label, IconData icon, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, color: Colors.black54, size: 20),
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

class _EditorSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _EditorSectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: _blue),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: _blueDark)),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE0E0E0)),
          child,
        ],
      ),
    );
  }
}

// ============================================================
// PROFILE EDITOR COMPLET (IDENTITÉ, ORIGINE, RÉSIDENCE, NAT ID)
// ============================================================
class ProfileEditorSheet {
  static Future<void> show(BuildContext context, {required ThixProfile profile, required ProfileService profileService, required dynamic authUser}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileEditorBody(profile: profile, profileService: profileService, authUser: authUser),
    );
  }
}

class _ProfileEditorBody extends StatefulWidget {
  final ThixProfile profile;
  final ProfileService profileService;
  final dynamic authUser;

  const _ProfileEditorBody({required this.profile, required this.profileService, required this.authUser});

  @override
  State<_ProfileEditorBody> createState() => _ProfileEditorBodyState();
}

class _ProfileEditorBodyState extends State<_ProfileEditorBody> {
  final ValueNotifier<bool> _saving = ValueNotifier(false);

  // Déclaration de TOUS les contrôleurs
  late final TextEditingController _nameC, _competenceC, _bioC, _countryOriginC;
  late final TextEditingController _contactPhoneC, _dobC, _pobC, _nationalityC;
  late final TextEditingController _maritalC, _genderC, _occupationC, _addressC;
  late final TextEditingController _fatherNameC, _motherNameC, _thixChatC;
  
  late final TextEditingController _originProvinceC, _originTerritoryC, _originSectorC;
  late final TextEditingController _residenceCountryC, _residenceProvinceC, _residenceCityC;
  late final TextEditingController _residenceTerritoryC, _residenceCommuneC;
  late final TextEditingController _residenceQuarterC, _residenceAvenueC, _residenceNumberC;

  late final TextEditingController _heightC, _weightC, _bloodGroupC, _disabilityDescC;
  late final TextEditingController _nationalIdNumberC, _idDocTypeC, _idIssueDateC, _idExpiryDateC, _idIssuePlaceC;

  bool _hasDisability = false;
  PlatformFile? _idFront, _idBack, _idSelfie;
  String? _idFrontDocId, _idBackDocId, _idSelfieDocId;
  String? _idVerificationStatus;
  
  PlatformFile? _pickedPhoto;

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
    _contactPhoneC = TextEditingController(text: p.contactPhone ?? a.contactPhone ?? '');
    _dobC = TextEditingController(text: p.dateOfBirth ?? a.dateOfBirth ?? '');
    _pobC = TextEditingController(text: p.placeOfBirth ?? a.placeOfBirth ?? '');
    _nationalityC = TextEditingController(text: p.nationality ?? a.nationality ?? '');
    _maritalC = TextEditingController(text: p.maritalStatus ?? a.maritalStatus ?? '');
    _genderC = TextEditingController(text: p.gender ?? a.gender ?? '');
    _occupationC = TextEditingController(text: (p.profession ?? p.occupation ?? a.profession ?? a.occupation) ?? '');
    _addressC = TextEditingController(text: p.address ?? a.address ?? '');
    _fatherNameC = TextEditingController(text: p.fatherName ?? a.fatherName ?? '');
    _motherNameC = TextEditingController(text: p.motherName ?? a.motherName ?? '');
    _thixChatC = TextEditingController(text: p.thixChat ?? '');

    _originProvinceC = TextEditingController(text: p.originProvince ?? '');
    _originTerritoryC = TextEditingController(text: p.originTerritory ?? '');
    _originSectorC = TextEditingController(text: p.originSector ?? '');

    _residenceCountryC = TextEditingController(text: p.residenceCountry ?? '');
    _residenceProvinceC = TextEditingController(text: p.residenceProvince ?? '');
    _residenceCityC = TextEditingController(text: p.residenceCity ?? '');
    _residenceTerritoryC = TextEditingController(text: p.residenceTerritory ?? '');
    _residenceCommuneC = TextEditingController(text: p.residenceCommune ?? '');
    _residenceQuarterC = TextEditingController(text: p.residenceQuarter ?? '');
    _residenceAvenueC = TextEditingController(text: p.residenceAvenue ?? '');
    _residenceNumberC = TextEditingController(text: p.residenceNumber ?? '');

    _heightC = TextEditingController(text: p.height ?? '');
    _weightC = TextEditingController(text: p.weight ?? '');
    _bloodGroupC = TextEditingController(text: p.bloodGroup ?? '');
    _hasDisability = p.hasPhysicalDisability ?? false;
    _disabilityDescC = TextEditingController(text: p.physicalDisabilityDescription ?? '');

    _nationalIdNumberC = TextEditingController(text: p.nationalIdNumber ?? '');
    _idDocTypeC = TextEditingController(text: p.idDocumentType ?? '');
    _idIssueDateC = TextEditingController(text: p.idDocumentIssueDate ?? '');
    _idExpiryDateC = TextEditingController(text: p.idDocumentExpiryDate ?? '');
    _idIssuePlaceC = TextEditingController(text: p.idDocumentIssuePlace ?? '');

    _idFrontDocId = p.idDocumentFrontDocId;
    _idBackDocId = p.idDocumentBackDocId;
    _idSelfieDocId = p.idDocumentSelfieDocId;
    _idVerificationStatus = p.idVerificationStatus;
  }

  Future<void> _pickIdFile(String kind) async {
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.custom, withData: kIsWeb, allowedExtensions: const ['png', 'jpg', 'jpeg', 'pdf']);
      if (res == null || res.files.isEmpty) return;
      setState(() {
        if (kind == 'front') _idFront = res.files.first;
        if (kind == 'back') _idBack = res.files.first;
        if (kind == 'selfie') _idSelfie = res.files.first;
      });
    } catch (e) {
      debugPrint('pick id error: $e');
    }
  }

  Future<void> _uploadIdIfNeeded({required String uid, required String kind}) async {
    final PlatformFile? f = kind == 'front' ? _idFront : (kind == 'back' ? _idBack : _idSelfie);
    if (f == null) return;
    
    final docId = 'NATIONAL_ID_${kind.toUpperCase()}';
    await _docs.uploadPickedFile(
      uid: uid,
      docId: docId,
      title: 'Identité nationale (${kind == 'front' ? 'Recto' : kind == 'back' ? 'Verso' : 'Selfie'})',
      file: f,
      docType: 'national_id',
    );
    
    if (kind == 'front') _idFrontDocId = docId;
    if (kind == 'back') _idBackDocId = docId;
    if (kind == 'selfie') _idSelfieDocId = docId;
    _idVerificationStatus = 'pending';
  }

  Future<void> _save() async {
    if (_nameC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le nom complet est requis.')));
      return;
    }
    
    _saving.value = true;
    try {
      String? newPhotoUrl;
      if (_pickedPhoto != null) {
        newPhotoUrl = await _photos.uploadProfilePhoto(uid: widget.profile.userId, file: _pickedPhoto!);
      }
      
      await _uploadIdIfNeeded(uid: widget.profile.userId, kind: 'front');
      await _uploadIdIfNeeded(uid: widget.profile.userId, kind: 'back');
      await _uploadIdIfNeeded(uid: widget.profile.userId, kind: 'selfie');

      // Le script SQL BLOC 1 doit avoir été exécuté pour que cette sauvegarde fonctionne.
      await _userService.updateProfile(
        uid: widget.profile.userId,
        displayName: _nameC.text.trim(),
        fullName: _nameC.text.trim(),
        competence: _competenceC.text.trim(),
        bio: _bioC.text.trim(),
        countryOrOrigin: _countryOriginC.text.trim(),
        contactPhone: _contactPhoneC.text.trim(),
        maritalStatus: _maritalC.text.trim(),
        gender: _genderC.text.trim(),
        profession: _occupationC.text.trim(),
        occupation: _occupationC.text.trim(),
        dateOfBirth: _dobC.text.trim(),
        placeOfBirth: _pobC.text.trim(),
        nationality: _nationalityC.text.trim(),
        address: _addressC.text.trim(),
        fatherName: _fatherNameC.text.trim(),
        motherName: _motherNameC.text.trim(),
        originProvince: _originProvinceC.text.trim(),
        originTerritory: _originTerritoryC.text.trim(),
        originSector: _originSectorC.text.trim(),
        residenceCountry: _residenceCountryC.text.trim(),
        residenceProvince: _residenceProvinceC.text.trim(),
        residenceTerritory: _residenceTerritoryC.text.trim(),
        residenceCity: _residenceCityC.text.trim(),
        residenceCommune: _residenceCommuneC.text.trim(),
        residenceQuarter: _residenceQuarterC.text.trim(),
        residenceAvenue: _residenceAvenueC.text.trim(),
        residenceNumber: _residenceNumberC.text.trim(),
        height: _heightC.text.trim(),
        weight: _weightC.text.trim(),
        bloodGroup: _bloodGroupC.text.trim(),
        hasPhysicalDisability: _hasDisability,
        physicalDisabilityDescription: _disabilityDescC.text.trim(),
        nationalIdNumber: _nationalIdNumberC.text.trim(),
        idDocumentType: _idDocTypeC.text.trim(),
        idDocumentIssueDate: _idIssueDateC.text.trim(),
        idDocumentExpiryDate: _idExpiryDateC.text.trim(),
        idDocumentIssuePlace: _idIssuePlaceC.text.trim(),
        idDocumentFrontDocId: _idFrontDocId,
        idDocumentBackDocId: _idBackDocId,
        idDocumentSelfieDocId: _idSelfieDocId,
        idVerificationStatus: _idVerificationStatus,
        thixChat: _thixChatC.text.trim(),
        photoUrl: newPhotoUrl,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil mis à jour avec succès.')));
      context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur (Assurez-vous que le script SQL a été exécuté) : $e')));
    } finally {
      _saving.value = false;
    }
  }

  Widget _idSlot({required String kind, required String? docId, required String label, required IconData icon}) {
    final pickedFile = kind == 'front' ? _idFront : (kind == 'back' ? _idBack : _idSelfie);
    
    if (pickedFile != null) {
      return OutlinedButton.icon(
        onPressed: _saving.value ? null : () => _pickIdFile(kind),
        icon: const Icon(Icons.cloud_upload_rounded, color: Colors.orange),
        label: Text('Prêt à envoyer', style: TextStyle(color: Colors.orange.shade800, fontSize: 11)),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange)),
      );
    }

    if (docId == null || docId.trim().isEmpty) {
      return OutlinedButton.icon(
        onPressed: _saving.value ? null : () => _pickIdFile(kind),
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 12)),
      );
    }
    
    return OutlinedButton.icon(
      onPressed: _saving.value ? null : () => _pickIdFile(kind),
      icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
      label: Text('$label ✓', style: const TextStyle(color: Colors.green, fontSize: 12)),
      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: _bgLight,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Modifier mon profil', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _blueDark)),
                  ValueListenableBuilder<bool>(
                    valueListenable: _saving,
                    builder: (ctx, isSaving, _) => IconButton(
                      onPressed: isSaving ? null : () => context.pop(), 
                      icon: const Icon(Icons.close_rounded)
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo de profil
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _pickedPhoto != null
                                ? (kIsWeb ? MemoryImage(_pickedPhoto!.bytes!) : FileImage(fileFromPath(_pickedPhoto!.path!) as dynamic)) as ImageProvider
                                : ((widget.profile.photoUrl ?? '').isNotEmpty ? NetworkImage(widget.profile.photoUrl!) : null),
                            child: _pickedPhoto == null && (widget.profile.photoUrl ?? '').isEmpty ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: ValueListenableBuilder<bool>(
                              valueListenable: _saving,
                              builder: (ctx, isSaving, _) => InkWell(
                                onTap: isSaving ? null : () async {
                                  final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: kIsWeb);
                                  if (res != null && res.files.isNotEmpty) setState(() => _pickedPhoto = res.files.first);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: _blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 1: PROFIL & BIO
                    _EditorSectionCard(
                      title: 'Profil Professionnel & Bio',
                      icon: Icons.person_rounded,
                      child: Column(children: [
                        TextField(controller: _nameC, decoration: _inputDecor('Nom complet', Icons.badge_rounded)),
                        const SizedBox(height: 12),
                        TextField(controller: _occupationC, decoration: _inputDecor('Profession / Poste', Icons.work_rounded)),
                        const SizedBox(height: 12),
                        TextField(controller: _bioC, maxLines: 3, decoration: _inputDecor('Biographie', Icons.history_edu_rounded)),
                        const SizedBox(height: 12),
                        TextField(controller: _competenceC, maxLines: 2, decoration: _inputDecor('Résumé des compétences', Icons.psychology_rounded)),
                        const SizedBox(height: 12),
                        TextField(controller: _thixChatC, decoration: _inputDecor('THIX CHAT (@handle)', Icons.alternate_email_rounded)),
                      ]),
                    ),

                    // SECTION 2: IDENTITÉ CIVILE
                    _EditorSectionCard(
                      title: 'Identité Civile',
                      icon: Icons.assignment_ind_rounded,
                      child: Column(children: [
                        TextField(controller: _dobC, decoration: _inputDecor('Date de naissance', Icons.cake_rounded, hint: 'YYYY-MM-DD')),
                        const SizedBox(height: 12),
                        TextField(controller: _pobC, decoration: _inputDecor('Lieu de naissance', Icons.place_rounded)),
                        const SizedBox(height: 12),
                        TextField(controller: _nationalityC, decoration: _inputDecor('Nationalité', Icons.flag_rounded)),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: TextField(controller: _genderC, decoration: _inputDecor('Genre', Icons.wc_rounded))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: _maritalC, decoration: _inputDecor('État civil', Icons.favorite_rounded))),
                        ]),
                        const SizedBox(height: 12),
                        TextField(controller: _addressC, decoration: _inputDecor('Adresse physique', Icons.home_rounded)),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: TextField(controller: _fatherNameC, decoration: _inputDecor('Nom du père', Icons.man_rounded))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: _motherNameC, decoration: _inputDecor('Nom de la mère', Icons.woman_rounded))),
                        ]),
                        const SizedBox(height: 12),
                        TextField(controller: _contactPhoneC, keyboardType: TextInputType.phone, decoration: _inputDecor('Téléphone', Icons.call_rounded)),
                      ]),
                    ),

                    // SECTION 3: ORIGINE
                    _EditorSectionCard(
                      title: 'Origine',
                      icon: Icons.map_rounded,
                      child: Column(children: [
                        TextField(controller: _originProvinceC, decoration: _inputDecor('Province d\'origine', Icons.location_on_rounded)),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: TextField(controller: _originTerritoryC, decoration: _inputDecor('Territoire', Icons.terrain_rounded))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: _originSectorC, decoration: _inputDecor('Secteur', Icons.account_tree_rounded))),
                        ]),
                      ]),
                    ),

                    // SECTION 4: RÉSIDENCE ACTUELLE
                    _EditorSectionCard(
                      title: 'Résidence Actuelle',
                      icon: Icons.home_work_rounded,
                      child: Column(children: [
                        TextField(controller: _residenceCountryC, decoration: _inputDecor('Pays', Icons.public_rounded)),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: TextField(controller: _residenceProvinceC, decoration: _inputDecor('Province', Icons.map_outlined))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: _residenceTerritoryC, decoration: _inputDecor('Territoire', Icons.terrain_outlined))),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: TextField(controller: _residenceCityC, decoration: _inputDecor('Ville', Icons.location_city_rounded))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: _residenceCommuneC, decoration: _inputDecor('Commune', Icons.apartment_rounded))),
                        ]),
                        const SizedBox(height: 12),
                        TextField(controller: _residenceQuarterC, decoration: _inputDecor('Quartier', Icons.streetview_rounded)),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: TextField(controller: _residenceAvenueC, decoration: _inputDecor('Avenue', Icons.route_rounded))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: _residenceNumberC, decoration: _inputDecor('Numéro', Icons.numbers_rounded))),
                        ]),
                      ]),
                    ),

                    // SECTION 5: INFOS PHYSIQUES
                    _EditorSectionCard(
                      title: 'Informations Physiques',
                      icon: Icons.monitor_weight_rounded,
                      child: Column(children: [
                        Row(children: [
                          Expanded(child: TextField(controller: _heightC, keyboardType: TextInputType.number, decoration: _inputDecor('Taille (cm)', Icons.height_rounded))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: _weightC, keyboardType: TextInputType.number, decoration: _inputDecor('Poids (kg)', Icons.scale_rounded))),
                        ]),
                        const SizedBox(height: 12),
                        TextField(controller: _bloodGroupC, decoration: _inputDecor('Groupe sanguin', Icons.bloodtype_rounded, hint: 'A+, O-')),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          value: _hasDisability,
                          activeColor: _blue,
                          onChanged: (v) => setState(() => _hasDisability = v),
                          title: const Text('Handicap physique', style: TextStyle(fontSize: 14)),
                        ),
                        if (_hasDisability)
                          TextField(controller: _disabilityDescC, maxLines: 2, decoration: _inputDecor('Description du handicap', Icons.accessible_forward_rounded)),
                      ]),
                    ),

                    // SECTION 6: IDENTITÉ NATIONALE
                    _EditorSectionCard(
                      title: 'Identité Nationale (Vérification)',
                      icon: Icons.admin_panel_settings_rounded,
                      child: Column(children: [
                        TextField(controller: _nationalIdNumberC, decoration: _inputDecor('Numéro de la pièce', Icons.numbers_rounded)),
                        const SizedBox(height: 12),
                        TextField(controller: _idDocTypeC, decoration: _inputDecor('Type de pièce', Icons.credit_card_rounded, hint: 'Carte d\'identité, Passeport')),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: TextField(controller: _idIssueDateC, decoration: _inputDecor('Émission', Icons.event_available_rounded, hint: 'YYYY-MM-DD'))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: _idExpiryDateC, decoration: _inputDecor('Expiration', Icons.event_busy_rounded, hint: 'YYYY-MM-DD'))),
                        ]),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                          child: Column(children: [
                            const Text('Photos du document officiel', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(child: _idSlot(kind: 'front', docId: _idFrontDocId, label: 'Recto', icon: Icons.front_hand_rounded)),
                              const SizedBox(width: 8),
                              Expanded(child: _idSlot(kind: 'back', docId: _idBackDocId, label: 'Verso', icon: Icons.branding_watermark_rounded)),
                            ]),
                            const SizedBox(height: 8),
                            _idSlot(kind: 'selfie', docId: _idSelfieDocId, label: 'Selfie avec la pièce', icon: Icons.face_rounded),
                          ]),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: ValueListenableBuilder<bool>(
                valueListenable: _saving,
                builder: (ctx, isSaving, _) => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: isSaving ? null : _save,
                    style: FilledButton.styleFrom(backgroundColor: _blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                    child: isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('ENREGISTRER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gestionnaire Universel d'Upload Multiple Web/Mobile
class _MultiFileUploadCard extends StatelessWidget {
  final List<EvidenceFileRef> existingEvidences;
  final List<PlatformFile> newFiles;
  final bool isSaving;
  final VoidCallback onPickFiles;
  final Function(PlatformFile) onRemoveNew;
  final Function(EvidenceFileRef) onRemoveExisting;

  const _MultiFileUploadCard({
    required this.existingEvidences,
    required this.newFiles,
    required this.isSaving,
    required this.onPickFiles,
    required this.onRemoveNew,
    required this.onRemoveExisting,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Documents & Photos (Preuves)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              OutlinedButton.icon(
                onPressed: isSaving ? null : onPickFiles,
                icon: const Icon(Icons.upload_file_rounded, size: 16),
                label: const Text('Ajouter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _blue,
                  side: const BorderSide(color: _blue),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(0, 32),
                ),
              )
            ],
          ),
          if (existingEvidences.isEmpty && newFiles.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Aucun document chargé.', style: TextStyle(color: Colors.black54, fontSize: 12)),
            ),
          const SizedBox(height: 8),
          ...existingEvidences.map((e) => _buildFileRow(label: e.label ?? 'Document', isNew: false, onRemove: () => onRemoveExisting(e))),
          ...newFiles.map((f) => _buildFileRow(label: f.name, isNew: true, onRemove: () => onRemoveNew(f))),
        ],
      ),
    );
  }

  Widget _buildFileRow({required String label, required bool isNew, required VoidCallback onRemove}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(isNew ? Icons.cloud_upload_rounded : Icons.verified_rounded, size: 16, color: isNew ? Colors.orange : Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.red, size: 16),
            onPressed: isSaving ? null : onRemove,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EDUCATION / CURSUS & FORMATIONS EDITOR (AVEC UPLOAD MULTIPLE)
// ============================================================
class EducationEditorSheet {
  static Future<void> show(BuildContext context, {required ThixProfile profile, required ProfileService profileService}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EducationEditorBody(profile: profile, profileService: profileService),
    );
  }
}

class _EducationEditorBody extends StatefulWidget {
  final ThixProfile profile;
  final ProfileService profileService;
  const _EducationEditorBody({required this.profile, required this.profileService});
  @override
  State<_EducationEditorBody> createState() => _EducationEditorBodyState();
}

class _EducationEditorBodyState extends State<_EducationEditorBody> {
  final ValueNotifier<bool> _saving = ValueNotifier(false);
  
  final _institutionC = TextEditingController();
  final _degreeC = TextEditingController();
  final _cityC = TextEditingController();
  final _startDateC = TextEditingController();
  final _endDateC = TextEditingController();
  final _descriptionC = TextEditingController();
  
  List<EvidenceFileRef> _existingEvidences = [];
  List<PlatformFile> _newFiles = [];
  
  int? _editingIndex;
  late List<Map<String, dynamic>> _localEducation;

  final _docs = DocumentService();

  @override
  void initState() {
    super.initState();
    _localEducation = List<Map<String, dynamic>>.from(widget.profile.education);
  }

  void _load(int index, Map<String, dynamic> entry) {
    setState(() {
      _editingIndex = index;
      _institutionC.text = (entry['institution'] ?? entry['school'] ?? '') as String;
      _degreeC.text = (entry['degree'] ?? entry['title'] ?? '') as String;
      _cityC.text = (entry['city'] ?? '') as String;
      _startDateC.text = (entry['startYear'] ?? entry['start_date'] ?? '') as String;
      _endDateC.text = (entry['endYear'] ?? entry['end_date'] ?? '') as String;
      _descriptionC.text = (entry['description'] ?? '') as String;
      
      final rawEv = (entry['evidence'] as List?) ?? [];
      _existingEvidences = rawEv.map(EvidenceFileRef.tryParse).whereType<EvidenceFileRef>().toList();
      _newFiles = [];
    });
  }

  void _reset() {
    setState(() {
      _editingIndex = null;
      _institutionC.clear(); _degreeC.clear(); _cityC.clear();
      _startDateC.clear(); _endDateC.clear(); _descriptionC.clear();
      _existingEvidences = [];
      _newFiles = [];
    });
  }

  Future<void> _pickFiles() async {
    final res = await FilePicker.platform.pickFiles(allowMultiple: true, withData: kIsWeb, type: FileType.custom, allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg']);
    if (res != null && res.files.isNotEmpty) {
      setState(() => _newFiles.addAll(res.files));
    }
  }

  Future<void> _save() async {
    if (_institutionC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('L\'établissement est requis.')));
      return;
    }
    
    _saving.value = true;
    try {
      final uid = widget.profile.userId;
      final uploadedEvidences = <EvidenceFileRef>[..._existingEvidences];
      
      // Upload des nouveaux fichiers
      for (final f in _newFiles) {
        final docId = 'EDU_${DateTime.now().millisecondsSinceEpoch}_${f.name}'.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_').toUpperCase();
        await _docs.uploadPickedFile(uid: uid, docId: docId, title: 'Preuve Cursus/Formation: ${f.name}', file: f, docType: 'credential_education');
        uploadedEvidences.add(EvidenceFileRef(storagePathOrUrl: 'documents:$docId', label: f.name));
      }

      final patch = {
        'institution': _institutionC.text.trim(),
        'degree': _degreeC.text.trim(),
        'city': _cityC.text.trim(),
        'startYear': _startDateC.text.trim(),
        'endYear': _endDateC.text.trim(),
        'description': _descriptionC.text.trim(),
        'evidence': uploadedEvidences.map((e) => e.toJson()).toList(),
      };

      if (_editingIndex != null) {
        _localEducation[_editingIndex!] = patch;
      } else {
        _localEducation.insert(0, patch); // Ajout au début
      }

      // Mise à jour optimiste + Backend
      await widget.profileService.updateProfile(userId: uid, education: _localEducation);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parcours scolaire mis à jour.')));
      _reset();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      _saving.value = false;
    }
  }

  Future<void> _delete(int index) async {
    _saving.value = true;
    try {
      _localEducation.removeAt(index);
      await widget.profileService.updateProfile(userId: widget.profile.userId, education: _localEducation);
      if (_editingIndex == index) _reset();
      setState((){}); // Refresh list
    } finally {
      _saving.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: _bgLight, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cursus & Formations', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _blueDark)),
                  ValueListenableBuilder<bool>(
                    valueListenable: _saving,
                    builder: (ctx, isSaving, _) => IconButton(onPressed: isSaving ? null : () => context.pop(), icon: const Icon(Icons.close_rounded)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_localEducation.isNotEmpty) ...[
                      const Text('Vos parcours enregistrés', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(height: 8),
                      ...List.generate(_localEducation.length, (i) {
                        final e = _localEducation[i];
                        final isEditing = _editingIndex == i;
                        return Card(
                          elevation: 0,
                          color: isEditing ? _blue.withOpacity(0.05) : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEditing ? _blue : Colors.black12)),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(e['institution'] ?? 'Établissement inconnu', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text('${e['degree'] ?? ''} - ${e['startYear'] ?? ''}'),
                            trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _delete(i)),
                            onTap: () => _load(i, e),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],

                    _EditorSectionCard(
                      title: _editingIndex == null ? 'Ajouter une formation' : 'Modifier la formation',
                      icon: Icons.school_rounded,
                      child: Column(children: [
                        TextField(controller: _institutionC, decoration: _inputDecor('Établissement / École', Icons.account_balance_rounded)),
                        const SizedBox(height: 12),
                        TextField(controller: _degreeC, decoration: _inputDecor('Diplôme / Titre obtenu', Icons.workspace_premium_rounded)),
                        const SizedBox(height: 12),
                        TextField(controller: _cityC, decoration: _inputDecor('Ville', Icons.location_city_rounded)),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: TextField(controller: _startDateC, decoration: _inputDecor('Début (Année)', Icons.date_range_rounded))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: _endDateC, decoration: _inputDecor('Fin (Année)', Icons.event_available_rounded))),
                        ]),
                        const SizedBox(height: 12),
                        TextField(controller: _descriptionC, maxLines: 3, decoration: _inputDecor('Description (optionnel)', Icons.notes_rounded)),
                        const SizedBox(height: 16),
                        
                        ValueListenableBuilder<bool>(
                          valueListenable: _saving,
                          builder: (ctx, isSaving, _) => _MultiFileUploadCard(
                            isSaving: isSaving,
                            existingEvidences: _existingEvidences,
                            newFiles: _newFiles,
                            onPickFiles: _pickFiles,
                            onRemoveNew: (f) => setState(() => _newFiles.remove(f)),
                            onRemoveExisting: (e) => setState(() => _existingEvidences.remove(e)),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  if (_editingIndex != null) ...[
                    OutlinedButton(onPressed: _reset, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('ANNULER')),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _saving,
                      builder: (ctx, isSaving, _) => SizedBox(
                        height: 50,
                        child: FilledButton(
                          onPressed: isSaving ? null : _save,
                          style: FilledButton.styleFrom(backgroundColor: _blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                          child: isSaving 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(_editingIndex == null ? 'AJOUTER CE PARCOURS' : 'METTRE À JOUR', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        ),
                      ),
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
}

// ============================================================
// EXPERIENCE EDITOR (AVEC UPLOAD MULTIPLE)
// ============================================================
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
  final ValueNotifier<bool> _saving = ValueNotifier(false);
  final _titleC = TextEditingController();
  final _orgC = TextEditingController();
  final _dateC = TextEditingController();
  final _tasksC = TextEditingController();
  final _sectorC = TextEditingController();
  final _cityC = TextEditingController();
  
  List<EvidenceFileRef> _existingEvidences = [];
  List<PlatformFile> _newFiles = [];
  int? _editingIndex;
  late List<Map<String, dynamic>> _localExperience;
  final _docs = DocumentService();

  @override
  void initState() {
    super.initState();
    _localExperience = List<Map<String, dynamic>>.from(widget.profile.experience);
  }

  void _load(int index, Map<String, dynamic> entry) {
    setState(() {
      _editingIndex = index;
      _titleC.text = (entry['title'] as String?) ?? '';
      _orgC.text = (entry['org'] as String?) ?? (entry['company'] as String?) ?? '';
      _dateC.text = (entry['date'] as String?) ?? (entry['period'] as String?) ?? '';
      _tasksC.text = (entry['tasks'] as String?) ?? (entry['missions'] as String?) ?? '';
      _sectorC.text = (entry['sector'] as String?) ?? '';
      _cityC.text = (entry['city'] as String?) ?? '';
      
      final rawEv = (entry['evidence'] as List?) ?? [];
      _existingEvidences = rawEv.map(EvidenceFileRef.tryParse).whereType<EvidenceFileRef>().toList();
      _newFiles = [];
    });
  }

  void _reset() {
    setState(() {
      _editingIndex = null;
      _titleC.clear(); _orgC.clear(); _dateC.clear(); _tasksC.clear(); _sectorC.clear(); _cityC.clear();
      _existingEvidences = [];
      _newFiles = [];
    });
  }

  Future<void> _pickFiles() async {
    final res = await FilePicker.platform.pickFiles(allowMultiple: true, withData: kIsWeb, type: FileType.custom, allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg']);
    if (res != null && res.files.isNotEmpty) setState(() => _newFiles.addAll(res.files));
  }

  Future<void> _save() async {
    if (_titleC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le titre du poste est requis.')));
      return;
    }
    
    _saving.value = true;
    try {
      final uid = widget.profile.userId;
      final uploadedEvidences = <EvidenceFileRef>[..._existingEvidences];
      
      for (final f in _newFiles) {
        final docId = 'EXP_${DateTime.now().millisecondsSinceEpoch}_${f.name}'.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_').toUpperCase();
        await _docs.uploadPickedFile(uid: uid, docId: docId, title: 'Preuve Expérience: ${f.name}', file: f, docType: 'credential_experience');
        uploadedEvidences.add(EvidenceFileRef(storagePathOrUrl: 'documents:$docId', label: f.name));
      }

      final patch = {
        'title': _titleC.text.trim(),
        'org': _orgC.text.trim(),
        'date': _dateC.text.trim(),
        'sector': _sectorC.text.trim(),
        'city': _cityC.text.trim(),
        if (_tasksC.text.trim().isNotEmpty) 'tasks': _tasksC.text.trim(),
        'evidence': uploadedEvidences.map((e) => e.toJson()).toList(),
      };

      if (_editingIndex != null) {
        _localExperience[_editingIndex!] = patch;
      } else {
        _localExperience.insert(0, patch);
      }

      await widget.profileService.updateProfile(userId: uid, experience: _localExperience);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expérience mise à jour.')));
      _reset();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      _saving.value = false;
    }
  }

  Future<void> _delete(int index) async {
    _saving.value = true;
    try {
      _localExperience.removeAt(index);
      await widget.profileService.updateProfile(userId: widget.profile.userId, experience: _localExperience);
      if (_editingIndex == index) _reset();
      setState((){});
    } finally {
      _saving.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: _bgLight, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Expériences Pro', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _blueDark)),
                  ValueListenableBuilder<bool>(
                    valueListenable: _saving,
                    builder: (ctx, isSaving, _) => IconButton(onPressed: isSaving ? null : () => context.pop(), icon: const Icon(Icons.close_rounded)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_localExperience.isNotEmpty) ...[
                      const Text('Vos expériences enregistrées', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(height: 8),
                      ...List.generate(_localExperience.length, (i) {
                        final e = _localExperience[i];
                        final isEditing = _editingIndex == i;
                        return Card(
                          elevation: 0,
                          color: isEditing ? _blue.withOpacity(0.05) : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEditing ? _blue : Colors.black12)),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(e['title'] ?? 'Poste', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text('${e['org'] ?? ''} - ${e['date'] ?? ''}'),
                            trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _delete(i)),
                            onTap: () => _load(i, e),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],

                    _EditorSectionCard(
                      title: _editingIndex == null ? 'Ajouter une expérience' : 'Modifier l\'expérience',
                      icon: Icons.work_history_rounded,
                      child: Column(children: [
                        TextField(controller: _titleC, decoration: _inputDecor('Titre du poste', Icons.badge_rounded)),
                        const SizedBox(height: 12),
                        TextField(controller: _orgC, decoration: _inputDecor('Entreprise / Organisation', Icons.business_rounded)),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: TextField(controller: _sectorC, decoration: _inputDecor('Secteur', Icons.category_rounded))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: _cityC, decoration: _inputDecor('Ville', Icons.location_city_rounded))),
                        ]),
                        const SizedBox(height: 12),
                        TextField(controller: _dateC, decoration: _inputDecor('Période (ex: 2021-2023)', Icons.date_range_rounded)),
                        const SizedBox(height: 12),
                        TextField(controller: _tasksC, maxLines: 4, decoration: _inputDecor('Missions et réalisations', Icons.format_list_bulleted_rounded)),
                        const SizedBox(height: 16),
                        
                        ValueListenableBuilder<bool>(
                          valueListenable: _saving,
                          builder: (ctx, isSaving, _) => _MultiFileUploadCard(
                            isSaving: isSaving,
                            existingEvidences: _existingEvidences,
                            newFiles: _newFiles,
                            onPickFiles: _pickFiles,
                            onRemoveNew: (f) => setState(() => _newFiles.remove(f)),
                            onRemoveExisting: (e) => setState(() => _existingEvidences.remove(e)),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  if (_editingIndex != null) ...[
                    OutlinedButton(onPressed: _reset, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('ANNULER')),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _saving,
                      builder: (ctx, isSaving, _) => SizedBox(
                        height: 50,
                        child: FilledButton(
                          onPressed: isSaving ? null : _save,
                          style: FilledButton.styleFrom(backgroundColor: _blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                          child: isSaving 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(_editingIndex == null ? 'AJOUTER L\'EXPÉRIENCE' : 'METTRE À JOUR', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        ),
                      ),
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
}
