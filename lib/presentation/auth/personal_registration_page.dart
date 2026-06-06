import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/auth/auth_manager.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/presentation/common/parcours_form.dart';
import 'package:thix_id/services/document_service.dart';
import 'package:thix_id/services/firestore_user_service.dart';
import 'package:thix_id/theme.dart';
import 'package:thix_id/presentation/common/date_picker_field.dart';
import 'package:thix_id/services/profile_photo_service.dart';
import 'package:thix_id/services/platform_file_from_path_stub.dart'
    if (dart.library.io) 'package:thix_id/services/platform_file_from_path_io.dart';

// ... (les classes FormSectionHeader, InputField, StepIndicator, PremiumCard restent inchangées) ...

class PersonalRegistrationPage extends StatefulWidget {
  final int initialStep;
  const PersonalRegistrationPage({super.key, this.initialStep = 1});

  @override
  State<PersonalRegistrationPage> createState() => _PersonalRegistrationPageState();
}

class _PersonalRegistrationPageState extends State<PersonalRegistrationPage> {
  final _firestoreUsers = FirestoreUserService();
  final _docs = DocumentService();
  final _photos = ProfilePhotoService();

  int _step = 1;

  @override
  void initState() {
    super.initState();
    final s = widget.initialStep;
    _step = s < 1 ? 1 : (s > 4 ? 4 : s);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final me = context.read<AuthController>().currentUser;
      if (me == null) return;
      if (_thixChatC.text.trim().isEmpty && (me.thixChat).trim().isNotEmpty) {
        _thixChatC.text = me.thixChat;
      }
    });
  }

  // Step 1: profile + credentials
  final _nameC = TextEditingController();
  final _emailOrPhoneC = TextEditingController();
  final _passwordC = TextEditingController();
  final _confirmC = TextEditingController();

  final _countryOriginC = TextEditingController();
  final _contactPhoneC = TextEditingController();
  final _dobC = TextEditingController();
  final _placeBirthC = TextEditingController();
  final _nationalityC = TextEditingController();
  final _maritalStatusC = TextEditingController();
  final _genderC = TextEditingController();
  final _occupationC = TextEditingController();
  final _addressC = TextEditingController();
  final _fatherNameC = TextEditingController();
  final _motherNameC = TextEditingController();

  // Structured origin & residence (Step 1)
  final _originProvinceC = TextEditingController();
  final _originTerritoryC = TextEditingController();
  final _originSectorC = TextEditingController();

  final _residenceCountryC = TextEditingController(text: 'RDC');
  final _residenceProvinceC = TextEditingController();
  final _residenceTerritoryC = TextEditingController();
  final _residenceCityC = TextEditingController();
  final _residenceCommuneC = TextEditingController();
  final _residenceQuarterC = TextEditingController();
  final _residenceAvenueC = TextEditingController();
  final _residenceNumberC = TextEditingController();

  // Emergency contacts (multi-add)
  final List<_EmergencyContactControllers> _emergencyContacts = [_EmergencyContactControllers()];

  // Step 2: parcours
  final _bioC = TextEditingController();
  final _competenceC = TextEditingController();

  // Physical / identity (Step 1)
  final _heightC = TextEditingController();
  final _weightC = TextEditingController();
  final _bloodGroupC = TextEditingController();
  bool _hasDisability = false;
  final _disabilityDescC = TextEditingController();
  final _nationalIdC = TextEditingController();
  final _idDocTypeC = TextEditingController();
  final _idIssueDateC = TextEditingController();
  final _idExpiryDateC = TextEditingController();
  final _idIssuePlaceC = TextEditingController();

  // Step 4: final - THIX CHAT (modifiable)
  final _thixChatC = TextEditingController();

  final List<EducationEntryControllers> _education = [EducationEntryControllers()];
  final List<ExperienceEntryControllers> _experience = [ExperienceEntryControllers()];

  bool _rememberMe = true;
  bool _isLoading = false;
  PlatformFile? _pickedPhoto;
  PhoneAuthSession? _phoneSession;
  final List<_PendingRegistrationDoc> _pendingDocs = [];

  @override
  void dispose() {
    _nameC.dispose();
    _emailOrPhoneC.dispose();
    _passwordC.dispose();
    _confirmC.dispose();
    _countryOriginC.dispose();
    _contactPhoneC.dispose();
    _dobC.dispose();
    _placeBirthC.dispose();
    _nationalityC.dispose();
    _maritalStatusC.dispose();
    _genderC.dispose();
    _occupationC.dispose();
    _addressC.dispose();
    _fatherNameC.dispose();
    _motherNameC.dispose();
    _originProvinceC.dispose();
    _originTerritoryC.dispose();
    _originSectorC.dispose();
    _residenceCountryC.dispose();
    _residenceProvinceC.dispose();
    _residenceTerritoryC.dispose();
    _residenceCityC.dispose();
    _residenceCommuneC.dispose();
    _residenceQuarterC.dispose();
    _residenceAvenueC.dispose();
    _residenceNumberC.dispose();
    for (final c in _emergencyContacts) {
      c.dispose();
    }
    _bioC.dispose();
    _competenceC.dispose();
    _heightC.dispose();
    _weightC.dispose();
    _bloodGroupC.dispose();
    _disabilityDescC.dispose();
    _nationalIdC.dispose();
    _idDocTypeC.dispose();
    _idIssueDateC.dispose();
    _idExpiryDateC.dispose();
    _idIssuePlaceC.dispose();
    _thixChatC.dispose();
    for (final e in _education) e.dispose();
    for (final e in _experience) e.dispose();
    super.dispose();
  }

  bool get _hasAnyDoc => _pendingDocs.isNotEmpty;

  bool _looksLikePhone(String s) => RegExp(r'^\+?[0-9][0-9\s\-]{7,}$').hasMatch(s.trim());
  bool _looksLikeEmail(String s) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim());

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  bool _hasSupabaseSession() => Supabase.instance.client.auth.currentSession != null;

  void _handleUnauthedWrite() {
    if (!mounted) return;
    _snack('Session expirée. Connectez-vous pour continuer.');
    context.go(AppRoutes.login);
  }

  String _rawSupabaseError(Object e) {
    if (e is PostgrestException) return 'PostgrestException: ${e.message} (code: ${e.code})';
    return e.toString();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final current = DateTime.tryParse(_dobC.text.trim());
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 110),
      lastDate: DateTime(now.year - 10),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: LightModeColors.accent)), child: child!),
    );
    if (picked == null) return;
    final v = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() => _dobC.text = v);
  }

  /// Validates step 1 (profile + credentials) without creating the account.
  bool _validateStep1() {
    final name = _nameC.text.trim();
    final id = _emailOrPhoneC.text.trim();
    final pass = _passwordC.text;
    final confirm = _confirmC.text;

    if (name.isEmpty) {
      _snack('Nom complet requis.');
      return false;
    }
    if (id.isEmpty) {
      _snack('Email ou téléphone requis.');
      return false;
    }
    if (!_looksLikeEmail(id) && !_looksLikePhone(id)) {
      _snack('Email ou téléphone invalide.');
      return false;
    }
    if (pass.trim().length < 8 && !_looksLikePhone(id)) {
      _snack('Mot de passe: minimum 8 caractères.');
      return false;
    }
    if (!_looksLikePhone(id) && pass != confirm) {
      _snack('Les mots de passe ne correspondent pas.');
      return false;
    }

    if (_countryOriginC.text.trim().isEmpty) {
      _snack('Origines / Pays d\'origine requis.');
      return false;
    }
    if (_contactPhoneC.text.trim().isEmpty) {
      _snack('Téléphone de contact requis.');
      return false;
    }
    if (_dobC.text.trim().isEmpty) {
      _snack('Date de naissance requise.');
      return false;
    }
    if (_placeBirthC.text.trim().isEmpty) {
      _snack('Lieu de naissance requis.');
      return false;
    }
    if (_nationalityC.text.trim().isEmpty) {
      _snack('Nationalité requise.');
      return false;
    }
    if (_genderC.text.trim().isEmpty) {
      _snack('Genre requis.');
      return false;
    }
    if (_maritalStatusC.text.trim().isEmpty) {
      _snack('Statut matrimonial requis.');
      return false;
    }
    if (_occupationC.text.trim().isEmpty) {
      _snack('Profession / Occupation requise.');
      return false;
    }
    if (_addressC.text.trim().isEmpty) {
      _snack('Résidence / Adresse requise.');
      return false;
    }
    if (_fatherNameC.text.trim().isEmpty || _motherNameC.text.trim().isEmpty) {
      _snack('Nom du père et de la mère requis.');
      return false;
    }
    if (_originProvinceC.text.trim().isEmpty) {
      _snack('Province d\'origine requise.');
      return false;
    }
    if (_originSectorC.text.trim().isEmpty) {
      _snack('Secteur d\'origine requis.');
      return false;
    }
    if (_residenceCountryC.text.trim().isEmpty) {
      _snack('Pays de résidence requis.');
      return false;
    }
    if (_residenceProvinceC.text.trim().isEmpty) {
      _snack('Province de résidence requise.');
      return false;
    }
    if (_residenceCityC.text.trim().isEmpty) {
      _snack('Ville de résidence requise.');
      return false;
    }
    if (_residenceCommuneC.text.trim().isEmpty) {
      _snack('Commune de résidence requise.');
      return false;
    }

    final primary = _emergencyContacts.isEmpty ? null : _emergencyContacts.first;
    if (primary == null || primary.nameC.text.trim().isEmpty || primary.phoneC.text.trim().isEmpty) {
      _snack('Contact d\'urgence (nom + téléphone) requis.');
      return false;
    }
    if (primary.relationC.text.trim().isEmpty) {
      _snack('Relation du contact d\'urgence requise (ex: frère, mère, ami).');
      return false;
    }
    return true;
  }

  Map<String, dynamic> _buildStep1ProfilePatch() {
    final contacts = _emergencyContacts
        .map((e) => e.toMap())
        .where((m) => (m['name'] as String).trim().isNotEmpty || (m['phone'] as String).trim().isNotEmpty)
        .toList(growable: false);
    final primary = contacts.isNotEmpty ? contacts.first : null;
    final addr = _addressC.text.trim().isNotEmpty
        ? _addressC.text.trim()
        : [
            _residenceCityC.text.trim(),
            _residenceQuarterC.text.trim(),
            _residenceAvenueC.text.trim().isEmpty ? '' : 'Av. ${_residenceAvenueC.text.trim()}',
            _residenceNumberC.text.trim().isEmpty ? '' : 'N° ${_residenceNumberC.text.trim()}',
          ].where((e) => e.trim().isNotEmpty).join(', ');

    return {
      'full_name': _nameC.text.trim(),
      'display_name': _nameC.text.trim(),
      'country_or_origin': _countryOriginC.text.trim(),
      'contact_phone': _contactPhoneC.text.trim(),
      'date_of_birth': _dobC.text.trim(),
      'place_of_birth': _placeBirthC.text.trim(),
      'nationality': _nationalityC.text.trim(),
      'marital_status': _maritalStatusC.text.trim(),
      'gender': _genderC.text.trim(),
      'occupation': _occupationC.text.trim(),
      'address': addr,
      'father_name': _fatherNameC.text.trim(),
      'mother_name': _motherNameC.text.trim(),
      'emergency_contact_name': primary?['name'] ?? '',
      'emergency_contact_phone': primary?['phone'] ?? '',
      'emergency_contact_relation': primary?['relation'] ?? '',
      'origin_province': _originProvinceC.text.trim(),
      'origin_territory': _originTerritoryC.text.trim(),
      'origin_sector': _originSectorC.text.trim(),
      'residence_country': _residenceCountryC.text.trim(),
      'residence_province': _residenceProvinceC.text.trim(),
      'residence_territory': _residenceTerritoryC.text.trim(),
      'residence_city': _residenceCityC.text.trim(),
      'residence_commune': _residenceCommuneC.text.trim(),
      'residence_quarter': _residenceQuarterC.text.trim(),
      'residence_avenue': _residenceAvenueC.text.trim(),
      'residence_number': _residenceNumberC.text.trim(),
      'emergency_contacts': contacts,
      'height': _heightC.text.trim(),
      'weight': _weightC.text.trim(),
      'blood_group': _bloodGroupC.text.trim(),
      'has_physical_disability': _hasDisability,
      'physical_disability_description': _disabilityDescC.text.trim(),
      'national_id_number': _nationalIdC.text.trim(),
      'id_document_type': _idDocTypeC.text.trim(),
      'id_document_issue_date': _idIssueDateC.text.trim(),
      'id_document_expiry_date': _idExpiryDateC.text.trim(),
      'id_document_issue_place': _idIssuePlaceC.text.trim(),
      'registration_status': 'draft_step1',
    };
  }

  Future<void> _saveStep1AndEnsureAccount() async {
    if (_isLoading) return;
    if (!_validateStep1()) return;

    final auth = context.read<AuthController>();
    final draft = _buildStep1ProfilePatch();

    setState(() => _isLoading = true);
    try {
      if (auth.currentUser == null) {
        final name = _nameC.text.trim();
        final id = _emailOrPhoneC.text.trim();
        final pass = _passwordC.text;

        if (_looksLikePhone(id) && !id.contains('@')) {
          if (kIsWeb) {
            _snack('Inscription par SMS non disponible dans la Preview web. Utilisez un email ou testez sur Android/iOS.');
            return;
          }
          if (_phoneSession == null) {
            _phoneSession = await auth.startPhoneAuth(phoneNumber: id);
            if (!mounted) return;
            _snack('SMS envoyé. Entrez le code dans “Mot de passe” puis validez.');
            return;
          }
          await auth.confirmPhoneCode(session: _phoneSession!, smsCode: pass, displayName: name, accountType: AccountType.personal);
        } else {
          await auth.registerPersonal(email: id, password: pass, displayName: name, rememberMe: _rememberMe, profileDraft: draft);
        }
      }

      final me = auth.currentUser;
      if (me == null) throw Exception('Session utilisateur introuvable.');
      if (!_hasSupabaseSession()) {
        _handleUnauthedWrite();
        return;
      }

      // Persist step1 to Supabase.
      await _firestoreUsers.updateProfile(
        uid: me.id,
        displayName: _nameC.text.trim(),
        fullName: _nameC.text.trim(),
        countryOrOrigin: _countryOriginC.text.trim(),
        contactPhone: _contactPhoneC.text.trim(),
        dateOfBirth: _dobC.text.trim(),
        placeOfBirth: _placeBirthC.text.trim(),
        nationality: _nationalityC.text.trim(),
        maritalStatus: _maritalStatusC.text.trim(),
        gender: _genderC.text.trim(),
        occupation: _occupationC.text.trim(),
        address: (draft['address'] as String?) ?? _addressC.text.trim(),
        fatherName: _fatherNameC.text.trim(),
        motherName: _motherNameC.text.trim(),
        emergencyContactName: (draft['emergency_contact_name'] as String?) ?? '',
        emergencyContactPhone: (draft['emergency_contact_phone'] as String?) ?? '',
        emergencyContactRelation: (draft['emergency_contact_relation'] as String?) ?? '',
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
        emergencyContacts: (draft['emergency_contacts'] as List).cast<Map<String, dynamic>>(),
        height: _heightC.text.trim(),
        weight: _weightC.text.trim(),
        bloodGroup: _bloodGroupC.text.trim(),
        hasPhysicalDisability: _hasDisability,
        physicalDisabilityDescription: _disabilityDescC.text.trim(),
        nationalIdNumber: _nationalIdC.text.trim(),
        idDocumentType: _idDocTypeC.text.trim(),
        idDocumentIssueDate: _idIssueDateC.text.trim(),
        idDocumentExpiryDate: _idExpiryDateC.text.trim(),
        idDocumentIssuePlace: _idIssuePlaceC.text.trim(),
        registrationStatus: 'draft_step1',
      );

      if (_pickedPhoto != null) {
        final url = await _photos.uploadProfilePhoto(uid: me.id, file: _pickedPhoto!);
        await _firestoreUsers.updateProfile(uid: me.id, photoUrl: url);
      }
    } catch (e) {
      debugPrint('PersonalReg: save step1 failed err=$e');
      if (!mounted) return;
      _snack(_rawSupabaseError(e));
      rethrow;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ CORRECTION 1 : _pickPhoto avec FilePicker.platform
  Future<void> _pickPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: kIsWeb,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      setState(() => _pickedPhoto = result.files.first);
    } catch (e) {
      debugPrint('PersonalReg: pick photo failed err=$e');
      if (!mounted) return;
      _snack('Sélection image impossible.');
    }
  }

  ImageProvider? _photoPreview() {
    final f = _pickedPhoto;
    if (f == null) return null;
    if (kIsWeb) {
      final bytes = f.bytes;
      if (bytes == null) return null;
      return MemoryImage(bytes);
    }
    final path = f.path;
    if (path == null) return null;
    return FileImage(fileFromPath(path) as dynamic);
  }

  Future<void> _next() async {
    if (_isLoading) return;
    if (_step == 1) {
      try {
        await _saveStep1AndEnsureAccount();
      } catch (_) {
        return;
      }
      if (!mounted) return;
      if (context.read<AuthController>().currentUser == null) return;
      setState(() => _step = 2);
      return;
    }
    if (_step == 2) {
      final parcoursError = _validateParcours();
      if (parcoursError != null) {
        _snack(parcoursError);
        return;
      }

      final me = context.read<AuthController>().currentUser;
      if (me == null) {
        _snack('Session expirée.');
        setState(() => _step = 1);
        return;
      }
      if (!_hasSupabaseSession()) {
        _handleUnauthedWrite();
        return;
      }

      setState(() => _isLoading = true);
      try {
        await _firestoreUsers.updateProfile(
          uid: me.id,
          bio: _bioC.text.trim(),
          competence: _competenceC.text.trim(),
          education: _education.map((e) => e.toMap()).toList(growable: false),
          experience: _experience.map((e) => e.toMap()).toList(growable: false),
          registrationStatus: 'draft_step2',
        );
      } catch (e) {
        debugPrint('PersonalReg: save step2 failed uid=${me.id} err=$e');
        if (!mounted) return;
        _snack(_rawSupabaseError(e));
        return;
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }

      if (!mounted) return;
      setState(() => _step = 3);
      return;
    }
    if (_step == 3) {
      if (!_hasAnyDoc) {
        _snack('Ajoutez au moins un document avant de continuer.');
        return;
      }

      final me = context.read<AuthController>().currentUser;
      if (me == null) {
        _snack('Compte non disponible après inscription.');
        return;
      }
      if (!_hasSupabaseSession()) {
        _handleUnauthedWrite();
        return;
      }

      setState(() => _isLoading = true);
      try {
        // ✅ CORRECTION 2 : utiliser `me.id` au lieu de `uid` non défini
        final thixId = await _firestoreUsers.ensureThixId(uid: me.id);
        final suggested = _suggestChatFromName(_nameC.text.trim());
        final claimed = await _firestoreUsers.ensureThixChat(uid: me.id, desired: _thixChatC.text.trim().isEmpty ? suggested : _thixChatC.text);
        _thixChatC.text = claimed;
        await _firestoreUsers.updateProfile(uid: me.id, registrationStatus: 'identifiers_ready', thixChat: claimed);
        debugPrint('PersonalReg: identifiers prepared uid=${me.id} thixId=$thixId thixChat=$claimed');
      } catch (e) {
        debugPrint('PersonalReg: identifiers prepare failed uid=${me.id} err=$e');
        if (!mounted) return;
        final msg = e.toString();
        if (msg.contains('Not authenticated') || msg.toLowerCase().contains('jwt') || msg.contains('42501')) {
          _handleUnauthedWrite();
          return;
        }
        _snack(_rawSupabaseError(e));
        return;
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }

      if (!mounted) return;
      setState(() => _step = 4);
      return;
    }
    if (_step == 4) {
      await _proceedToPayment();
      return;
    }
  }

  void _back() {
    if (_isLoading) return;
    if (_step <= 1) {
      context.popOrGo(AppRoutes.home);
      return;
    }
    setState(() => _step -= 1);
  }

  String _suggestChatFromName(String name) {
    final base = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList().isEmpty
        ? 'user'
        : name.trim().split(RegExp(r'\s+')).first;
    final cleaned = base.toLowerCase().replaceAll(RegExp(r'[^a-z0-9._]'), '');
    final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(9);
    final candidate = '@${cleaned.isEmpty ? 'user' : cleaned}${suffix.padLeft(4, '0')}';
    return candidate.length > 21 ? candidate.substring(0, 21) : candidate;
  }

  String? _validateParcours() {
    final bio = _bioC.text.trim();
    if (bio.isEmpty) return 'Bio requise (présentez-vous en quelques lignes).';
    if (bio.length < 40) return 'Bio trop courte (minimum 40 caractères).';

    bool hasValidEducation = false;
    for (final e in _education) {
      final level = e.levelC.text.trim().toLowerCase();
      final institution = e.institutionC.text.trim();
      final city = e.cityC.text.trim();
      final degree = e.degreeC.text.trim();
      final start = e.startYearC.text.trim();
      final degreeRequired = level.startsWith('sup') || level.startsWith('for');
      final ok = institution.isNotEmpty && city.isNotEmpty && start.isNotEmpty && (!degreeRequired || degree.isNotEmpty);
      if (ok) {
        hasValidEducation = true;
        break;
      }
    }
    if (!hasValidEducation) return 'Ajoutez au moins 1 cursus (niveau + établissement + ville + année début).';

    bool hasValidExperience = false;
    for (final e in _experience) {
      final company = e.companyC.text.trim();
      final city = e.cityC.text.trim();
      final title = e.titleC.text.trim();
      final missions = e.missionsC.text.trim();
      if (company.isNotEmpty && city.isNotEmpty && title.isNotEmpty && missions.isNotEmpty) {
        hasValidExperience = true;
        break;
      }
    }
    if (!hasValidExperience) return 'Ajoutez au moins 1 expérience (entreprise + ville + titre + missions).';

    return null;
  }

  Future<void> _proceedToPayment() async {
    final me = context.read<AuthController>().currentUser;
    if (me == null) {
      _snack('Session expirée.');
      setState(() => _step = 1);
      return;
    }
    if (!_hasSupabaseSession()) {
      _handleUnauthedWrite();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final claimed = await _firestoreUsers.ensureThixChat(uid: me.id, desired: _thixChatC.text);
      await _firestoreUsers.updateProfile(uid: me.id, thixChat: claimed, registrationStatus: 'awaiting_payment');
      if (!mounted) return;

      final receiptReturn = Uri.encodeComponent('/activation-receipt');
      context.push('${AppRoutes.payment}?returnTo=$receiptReturn');
    } catch (e) {
      debugPrint('PersonalReg: submit failed uid=${me.id} err=$e');
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('Not authenticated') || msg.toLowerCase().contains('jwt') || msg.contains('42501')) {
        _handleUnauthedWrite();
        return;
      }
      if (msg.toLowerCase().contains('déjà utilisé')) {
        _snack('THIX CHAT déjà utilisé. Choisissez un autre.');
      } else if (msg.toLowerCase().contains('invalide')) {
        _snack('THIX CHAT invalide. Exemple: thix.john_23');
      } else {
        _snack(_rawSupabaseError(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ CORRECTION 3 : _pickAndUploadDoc avec FilePicker.platform et gestion correcte
  Future<void> _pickAndUploadDoc() async {
    final result = await FilePicker.platform.pickFiles(withData: kIsWeb);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (!mounted) return;

    final payload = await showModalBottomSheet<_RegUploadDocPayload>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RegistrationUploadDocumentSheet(fileName: file.name),
    );
    if (payload == null) return;

    final me = context.read<AuthController>().currentUser;
    if (me == null) {
      setState(() => _pendingDocs.add(_PendingRegistrationDoc(file: file, docId: payload.docId, title: payload.title, docType: payload.docType, expiresAt: payload.expiresAt)));
      _snack('Document ajouté (sera upload après création du compte).');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _docs.uploadPickedFile(uid: me.id, docId: payload.docId, title: payload.title, file: file, docType: payload.docType, expiresAt: payload.expiresAt);
      _snack('Document uploadé.');
    } catch (e) {
      debugPrint('PersonalReg: doc upload failed uid=${me.id} err=$e');
      setState(() => _pendingDocs.add(_PendingRegistrationDoc(file: file, docId: payload.docId, title: payload.title, docType: payload.docType, expiresAt: payload.expiresAt)));
      _snack('Upload impossible maintenant. Document mis en attente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ... (le reste du code, y compris les méthodes _stepContent, build, et les classes auxiliaires, reste identique) ...
}
