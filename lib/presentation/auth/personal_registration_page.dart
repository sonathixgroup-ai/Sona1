import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/services/user_service.dart';
import 'package:thix_id/theme.dart';

// ============================================================================
// THIX ID — GÉNÉRATION & VALIDATION (déterministe, avec clé de contrôle réelle)
// ============================================================================
//
// Format : THIX-<PAYS>-<MMAA>-<5 chiffres>-<3 lettres>-<clé>
// La clé de contrôle est calculée à partir des autres segments (checksum),
// pas tirée au hasard : elle permet de VALIDER un THIX ID a posteriori
// (ex: scan d'un QR code, support client) sans requête serveur.
class ThixIdGenerator {
  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static final _secureRandom = Random.secure();

  static String _countryCode(String? fullCountryName) {
    switch (fullCountryName) {
      case 'République Démocratique du Congo':
        return 'CD';
      case 'Rwanda':
        return 'RW';
      case 'Burundi':
        return 'BI';
      case 'Ouganda':
        return 'UG';
      case 'Angola':
        return 'AO';
      case "Côte d'Ivoire":
        return 'CI';
      case 'Sénégal':
        return 'SN';
      case 'Cameroun':
        return 'CM';
      case 'France':
        return 'FR';
      case 'Belgique':
        return 'BE';
      case 'Canada':
        return 'CA';
      case 'États-Unis':
        return 'US';
      default:
        return 'XX';
    }
  }

  /// Calcule la clé de contrôle (0-9) à partir du corps de l'identifiant.
  /// Algorithme simple pondéré (type Luhn simplifié) — suffisant pour
  /// détecter une faute de frappe ou un ID falsifié côté client.
  static int _checkDigit(String body) {
    var sum = 0;
    for (var i = 0; i < body.length; i++) {
      final code = body.codeUnitAt(i);
      final weight = (i % 2 == 0) ? 3 : 7;
      sum += code * weight;
    }
    return sum % 10;
  }

  /// Génère un nouveau THIX ID. Ne garantit pas l'unicité globale à lui
  /// seul : l'appelant doit retenter en cas de conflit d'unicité en base
  /// (contrainte UNIQUE requise sur la colonne thix_id).
  static String generate(String countryName) {
    final codePays = _countryCode(countryName);

    final now = DateTime.now();
    final dateStr =
        '${now.month.toString().padLeft(2, '0')}${now.year.toString().substring(2)}';

    final variable = _secureRandom.nextInt(90000) + 10000; // 10000-99999

    final codeCompl = String.fromCharCodes(
      Iterable.generate(
        3,
        (_) => _alphabet.codeUnitAt(_secureRandom.nextInt(_alphabet.length)),
      ),
    );

    final body = '$codePays-$dateStr-$variable-$codeCompl';
    final cleVerif = _checkDigit(body);

    return 'THIX-$body-$cleVerif';
  }
}

/// Validateur autonome — utilisable ailleurs dans l'app (scan QR, écran
/// support) sans dépendre du Supabase client.
class ThixIdValidator {
  static bool isValid(String thixId) {
    final parts = thixId.split('-');
    if (parts.length != 6 || parts[0] != 'THIX') return false;
    final body = parts.sublist(1, 5).join('-');
    final expected = ThixIdGenerator._checkDigit(body);
    final actual = int.tryParse(parts[5]);
    return actual != null && actual == expected;
  }
}

// ============================================================================
// PAGE D'INSCRIPTION SIMPLIFIÉE (2 ÉTAPES)
// ============================================================================

class PersonalRegistrationPage extends StatefulWidget {
  final int? initialStep;
  const PersonalRegistrationPage({super.key, this.initialStep});

  @override
  State<PersonalRegistrationPage> createState() =>
      _PersonalRegistrationPageState();
}

class _PersonalRegistrationPageState extends State<PersonalRegistrationPage> {
  final _userService = UserService(Supabase.instance.client);

  // ---------- Étape 1 : Profil ----------
  final _nameC = TextEditingController();
  final _dobC = TextEditingController();
  String? _country;
  final _occupationC = TextEditingController();

  // ---------- Étape 2 : Compte et vérification ----------
  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();
  final _confirmC = TextEditingController();
  final _otpC = TextEditingController();
  final _thixChatC = TextEditingController();

  String _thixIdGenerated = '';
  String _uid = '';
  bool _isLoading = false;
  bool _otpSent = false;
  bool _isNavigating = false; // garde anti double-tap pour la navigation d'étape
  int _step = 1;

  Timer? _resendTimer;
  int _resendCooldown = 0; // secondes restantes avant de pouvoir renvoyer l'OTP
  static const int _resendCooldownDuration = 45;

  static const List<String> _countryList = [
    'République Démocratique du Congo',
    'Rwanda',
    'Burundi',
    'Ouganda',
    'Angola',
    "Côte d'Ivoire",
    'Sénégal',
    'Cameroun',
    'France',
    'Belgique',
    'Canada',
    'États-Unis',
    'Autre'
  ];

  @override
  void dispose() {
    _nameC.dispose();
    _dobC.dispose();
    _occupationC.dispose();
    _emailC.dispose();
    _passwordC.dispose();
    _confirmC.dispose();
    _otpC.dispose();
    _thixChatC.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade600 : null,
      ),
    );
  }

  // ---------- Traduction des erreurs techniques en messages utilisateur ----------
  // Les messages bruts de Supabase (codes internes, contraintes SQL...) ne
  // doivent jamais remonter tels quels à l'utilisateur : on les journalise
  // pour le debug et on renvoie un message générique et rassurant.
  String _userFacingError(Object e) {
    if (kDebugMode) {
      debugPrint('[PersonalRegistration] erreur brute: $e');
    }
    if (e is AuthException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') || msg.contains('already exists')) {
        return 'Un compte existe déjà avec cet email.';
      }
      if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
        return 'Email ou mot de passe incorrect.';
      }
      if (msg.contains('token') && (msg.contains('expired') || msg.contains('invalid'))) {
        return 'Le code saisi est invalide ou a expiré. Demandez un nouveau code.';
      }
      if (msg.contains('rate limit') || msg.contains('too many')) {
        return 'Trop de tentatives. Merci de patienter quelques instants.';
      }
      return 'Une erreur est survenue lors de la vérification. Réessayez.';
    }
    if (e is PostgrestException) {
      if (e.code == '23505') {
        return 'Ce THIX CHAT est déjà pris, merci d\'en choisir un autre.';
      }
      return 'Une erreur est survenue côté serveur. Réessayez dans un instant.';
    }
    return 'Une erreur inattendue est survenue. Réessayez.';
  }

  // ---------- Validation ----------
  bool _isValidEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

  String? _passwordIssue(String pass) {
    if (pass.length < 8) return 'Le mot de passe doit contenir au moins 8 caractères.';
    if (!RegExp(r'[A-Za-z]').hasMatch(pass) || !RegExp(r'[0-9]').hasMatch(pass)) {
      return 'Le mot de passe doit contenir au moins une lettre et un chiffre.';
    }
    return null;
  }

  bool _isValidThixChat(String chat) {
    // Format attendu : @ + 3 à 20 caractères parmi lettres minuscules,
    // chiffres, point et underscore.
    return RegExp(r'^@[a-z0-9._]{3,20}$').hasMatch(chat);
  }

  // ---------- Navigation étape 1 → 2 ----------
  Future<void> _goToStep2() async {
    if (_isNavigating) return;
    final name = _nameC.text.trim();
    final dob = _dobC.text.trim();
    if (name.isEmpty) return _snack('Nom complet requis.', isError: true);
    if (dob.isEmpty) return _snack('Date de naissance requise.', isError: true);
    if (_country == null) return _snack('Veuillez choisir votre pays.', isError: true);

    _isNavigating = true;
    setState(() => _step = 2);
    _isNavigating = false;
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendCooldown = _resendCooldownDuration);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  // ---------- Envoi du code OTP (inscription) ----------
  Future<void> _sendOtp() async {
    if (_isLoading || _resendCooldown > 0) return;

    final email = _emailC.text.trim().toLowerCase();
    final pass = _passwordC.text;
    final confirm = _confirmC.text;

    if (email.isEmpty || !_isValidEmail(email)) {
      return _snack('Email invalide.', isError: true);
    }
    final passIssue = _passwordIssue(pass);
    if (passIssue != null) return _snack(passIssue, isError: true);
    if (pass != confirm) {
      return _snack('Les mots de passe ne correspondent pas.', isError: true);
    }

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthController>();
      await auth.registerPersonal(
        email: email,
        password: pass,
        displayName: _nameC.text.trim(),
        rememberMe: true,
        profileDraft: {
          'full_name': _nameC.text.trim(),
          'date_of_birth': _dobC.text.trim(),
          'country_or_origin': _country,
          'occupation': _occupationC.text.trim(),
          'registration_status': 'draft_step1',
        },
      );
      _otpSent = true;
      _startResendCooldown();
      _snack('Un code OTP vous a été envoyé par email.');
    } catch (e) {
      final message = e is AuthException ? e.message.toLowerCase() : '';
      if (message.contains('inscription enregistrée') ||
          message.contains('confirm') ||
          message.contains('confirmez')) {
        _otpSent = true;
        _startResendCooldown();
        _snack('Un code OTP vous a été envoyé par email.');
      } else {
        _snack(_userFacingError(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------- Vérification du code OTP et finalisation ----------
  Future<void> _verifyAndRegister() async {
    if (_isLoading) return;

    final code = _otpC.text.trim();
    if (code.isEmpty) {
      _snack('Veuillez saisir le code reçu par email.', isError: true);
      return;
    }

    final desiredChatRaw = _thixChatC.text.trim();
    final desiredChat = desiredChatRaw.isNotEmpty
        ? desiredChatRaw
        : _suggestChatFromName(_nameC.text.trim());
    if (!_isValidThixChat(desiredChat)) {
      _snack(
        'THIX CHAT invalide : utilisez 3 à 20 caractères (lettres minuscules, chiffres, "." ou "_").',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthController>();
      await auth.verifyOTP(email: _emailC.text.trim().toLowerCase(), token: code);

      final me = auth.currentUser;
      if (me == null) {
        throw Exception('Utilisateur introuvable après vérification.');
      }

      // Réservation du THIX CHAT (unique) — la logique d'unicité est gérée
      // côté service / contrainte UNIQUE en base.
      final claimed = await _userService.ensureThixChat(uid: me.id, desired: desiredChat);

      // Génération + assignation du THIX ID avec retry en cas de collision.
      // Nécessite une contrainte UNIQUE sur la colonne thix_id côté Supabase :
      // en cas de conflit, Postgres renvoie le code d'erreur '23505'.
      const maxAttempts = 5;
      String officialThixId = '';
      var assigned = false;
      for (var attempt = 0; attempt < maxAttempts && !assigned; attempt++) {
        officialThixId = ThixIdGenerator.generate(_country ?? 'Autre');
        try {
          await _userService.updateProfile(
            uid: me.id,
            thixId: officialThixId,
            thixChat: claimed,
            registrationStatus: 'active',
          );
          assigned = true;
        } on PostgrestException catch (e) {
          final isUniqueViolation = e.code == '23505';
          if (isUniqueViolation && attempt < maxAttempts - 1) {
            continue; // collision sur thix_id, on retente avec un nouvel ID
          }
          rethrow;
        }
      }
      if (!assigned) {
        throw Exception('Impossible de générer un THIX ID unique pour le moment.');
      }

      _thixIdGenerated = officialThixId;
      _uid = me.id;
      _thixChatC.text = claimed;
      _snack('Email vérifié avec succès !');
      if (mounted) setState(() => _step = 3);
    } catch (e) {
      _snack(_userFacingError(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _suggestChatFromName(String name) {
    final base = name.trim().split(RegExp(r'\s+')).first.toLowerCase();
    final cleaned = base.replaceAll(RegExp(r'[^a-z0-9._]'), '');
    final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(9);
    final candidate = '@${cleaned.isEmpty ? 'user' : cleaned}${suffix.padLeft(4, '0')}';
    return candidate.length > 21 ? candidate.substring(0, 21) : candidate;
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 160,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A3D62), Color(0xFF1A5A8C)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'THIX ID',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: LightModeColors.accent,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _step == 1
                            ? 'Étape 1/2 : Votre profil'
                            : _step == 2
                                ? 'Étape 2/2 : Création du compte'
                                : 'Inscription terminée',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 130, bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: KeyedSubtree(
                        key: ValueKey(_step),
                        child: _buildStepContent(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildMainButton(),
                  const SizedBox(height: 16),
                  if (_step < 3)
                    TextButton(
                      onPressed: () {
                        if (_step == 2) {
                          setState(() => _step = 1);
                        } else {
                          context.go(AppRoutes.login);
                        }
                      },
                      child: Text(
                        _step == 2 ? 'Revenir à l\'étape 1' : 'Déjà un compte ? Se connecter',
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

  Widget _buildStepContent() {
    switch (_step) {
      case 1:
        return _Step1Profile(
          nameC: _nameC,
          dobC: _dobC,
          country: _country,
          onCountryChanged: (v) => setState(() => _country = v),
          occupationC: _occupationC,
          onPickDob: _pickDob,
        );
      case 2:
        return _Step2Account(
          emailC: _emailC,
          passwordC: _passwordC,
          confirmC: _confirmC,
          otpC: _otpC,
          thixChatC: _thixChatC,
          onSendOtp: _sendOtp,
          isOtpSent: _otpSent,
          isLoading: _isLoading,
          resendCooldown: _resendCooldown,
        );
      case 3:
        return _Step3Final(
          thixId: _thixIdGenerated,
          thixChat: _thixChatC.text,
          uid: _uid,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 110),
      lastDate: DateTime(now.year - 10),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: LightModeColors.accent,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final v = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() => _dobC.text = v);
    }
  }

  Widget _buildMainButton() {
    String label;
    VoidCallback? onPressed;
    switch (_step) {
      case 1:
        label = 'SUIVANT →';
        onPressed = _goToStep2;
        break;
      case 2:
        label = _isLoading ? 'VÉRIFICATION...' : 'CONFIRMER LE CODE OTP';
        onPressed = _verifyAndRegister;
        break;
      case 3:
        label = 'ACCUEIL';
        onPressed = () => context.go(AppRoutes.home);
        break;
      default:
        label = '';
        onPressed = null;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _isLoading ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF9C74F), Color(0xFFF8961E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.shade300.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...const [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SOUS-WIDGETS
// ============================================================================

class _Step1Profile extends StatelessWidget {
  final TextEditingController nameC, dobC, occupationC;
  final String? country;
  final ValueChanged<String?> onCountryChanged;
  final VoidCallback onPickDob;

  const _Step1Profile({
    required this.nameC,
    required this.dobC,
    required this.occupationC,
    required this.country,
    required this.onCountryChanged,
    required this.onPickDob,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Informations personnelles',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A3D62),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: nameC,
          decoration: InputDecoration(
            labelText: 'Nom complet *',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onPickDob,
          child: AbsorbPointer(
            child: TextField(
              controller: dobC,
              decoration: InputDecoration(
                labelText: 'Date de naissance *',
                prefixIcon: const Icon(Icons.calendar_today),
                suffixIcon: const Icon(Icons.arrow_drop_down),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: country,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Pays *',
            prefixIcon: const Icon(Icons.public),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          items: const [
            DropdownMenuItem(
                value: 'République Démocratique du Congo',
                child: Text('République Démocratique du Congo')),
            DropdownMenuItem(value: 'Rwanda', child: Text('Rwanda')),
            DropdownMenuItem(value: 'Burundi', child: Text('Burundi')),
            DropdownMenuItem(value: 'Ouganda', child: Text('Ouganda')),
            DropdownMenuItem(value: 'Angola', child: Text('Angola')),
            DropdownMenuItem(
                value: "Côte d'Ivoire", child: Text("Côte d'Ivoire")),
            DropdownMenuItem(value: 'Sénégal', child: Text('Sénégal')),
            DropdownMenuItem(value: 'Cameroun', child: Text('Cameroun')),
            DropdownMenuItem(value: 'France', child: Text('France')),
            DropdownMenuItem(value: 'Belgique', child: Text('Belgique')),
            DropdownMenuItem(value: 'Canada', child: Text('Canada')),
            DropdownMenuItem(value: 'États-Unis', child: Text('États-Unis')),
            DropdownMenuItem(value: 'Autre', child: Text('Autre')),
          ],
          onChanged: onCountryChanged,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: occupationC,
          decoration: InputDecoration(
            labelText: 'Occupation (facultatif)',
            prefixIcon: const Icon(Icons.work_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ces informations permettront de générer votre identifiant THIX ID unique.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }
}

class _Step2Account extends StatelessWidget {
  final TextEditingController emailC, passwordC, confirmC, otpC, thixChatC;
  final VoidCallback onSendOtp;
  final bool isOtpSent, isLoading;
  final int resendCooldown;

  const _Step2Account({
    required this.emailC,
    required this.passwordC,
    required this.confirmC,
    required this.otpC,
    required this.thixChatC,
    required this.onSendOtp,
    required this.isOtpSent,
    required this.isLoading,
    required this.resendCooldown,
  });

  @override
  Widget build(BuildContext context) {
    final canResend = !isLoading && resendCooldown == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Création du compte',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A3D62),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: emailC,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email *',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordC,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Mot de passe * (8 car. min, 1 lettre + 1 chiffre)',
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: confirmC,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Confirmer le mot de passe *',
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canResend ? onSendOtp : null,
                icon: Icon(
                  isOtpSent ? Icons.refresh : Icons.send,
                  size: 18,
                ),
                label: Text(
                  !canResend && resendCooldown > 0
                      ? 'Renvoyer dans ${resendCooldown}s'
                      : (isOtpSent ? 'Renvoyer le code OTP' : 'Envoyer le code OTP'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LightModeColors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: LightModeColors.accent.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        if (isOtpSent) ...[
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.mark_email_read_outlined, color: Colors.blue.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Un code OTP vous a été envoyé par email',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Vérifiez aussi vos spams. Le code expire après quelques minutes.',
                        style: TextStyle(color: Colors.blue.shade700, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: otpC,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Code de vérification reçu par email *',
            prefixIcon: const Icon(Icons.confirmation_number_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: thixChatC,
          decoration: InputDecoration(
            labelText: 'THIX CHAT (nom d\'utilisateur public) *',
            hintText: '@john_doe_123',
            prefixIcon: const Icon(Icons.chat_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choisissez un identifiant unique pour vos discussions. (3 à 20 caractères : lettres, chiffres, "." ou "_")',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }
}

class _Step3Final extends StatelessWidget {
  final String thixId, thixChat, uid;

  const _Step3Final({
    required this.thixId,
    required this.thixChat,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '🎉 Inscription terminée !',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A3D62),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Votre compte est actif et votre identité THIX ID est générée.',
                  style: TextStyle(color: Colors.green.shade800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Liste groupée style natif (une seule carte, lignes séparées par
        // des dividers) plutôt que 3 blocs colorés séparés.
        _NativeInfoGroup(
          rows: [
            _NativeInfoRow(
              label: 'THIX ID',
              value: thixId,
              icon: Icons.verified_user,
              iconColor: Colors.blue,
              showCopy: true,
            ),
            _NativeInfoRow(
              label: 'THIX CHAT',
              value: thixChat,
              icon: Icons.chat,
              iconColor: Colors.orange,
              showCopy: true,
            ),
            _NativeInfoRow(
              label: 'UID (identifiant unique)',
              value: uid,
              icon: Icons.fingerprint,
              iconColor: Colors.grey.shade700,
              showCopy: false,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.qr_code, color: Colors.black),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Un QR code sera disponible dans votre profil pour un partage sécurisé.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Format THIX ID : ${thixId.length >= 15 ? thixId.substring(0, 15) : thixId}... (clé de vérification incluse)',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }
}

/// Ligne d'information réutilisable pour une liste groupée native.
class _NativeInfoRow {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool showCopy;

  const _NativeInfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.showCopy,
  });
}

/// Groupe de lignes façon "Réglages iOS" / Material grouped list :
/// une seule carte blanche arrondie, lignes séparées par de fins dividers,
/// icône ronde colorée à gauche, label + valeur, bouton copier à droite.
class _NativeInfoGroup extends StatelessWidget {
  final List<_NativeInfoRow> rows;
  const _NativeInfoGroup({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _buildRow(context, rows[i]),
            if (i != rows.length - 1)
              Divider(height: 1, indent: 60, endIndent: 16, color: Colors.grey.shade200),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, _NativeInfoRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: row.iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(row.icon, color: row.iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  row.value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (row.showCopy)
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: row.value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${row.label} copié dans le presse-papier !'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Copier',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
