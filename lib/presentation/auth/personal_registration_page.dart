import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/services/user_service.dart';
import 'package:thix_id/theme.dart';
import '../providers/auth_controller.dart'; // Ton nouveau provider

// ============================================================================
// THIX ID — GÉNÉRATION & VALIDATION
// ============================================================================
class ThixIdGenerator {
  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static final _secureRandom = Random.secure();

  static String _countryCode(String? fullCountryName) {
    switch (fullCountryName) {
      case 'République Démocratique du Congo': return 'CD';
      case 'Rwanda': return 'RW';
      case 'Burundi': return 'BI';
      case 'Ouganda': return 'UG';
      case 'Angola': return 'AO';
      case "Côte d'Ivoire": return 'CI';
      case 'Sénégal': return 'SN';
      case 'Cameroun': return 'CM';
      case 'France': return 'FR';
      case 'Belgique': return 'BE';
      case 'Canada': return 'CA';
      case 'États-Unis': return 'US';
      default: return 'XX';
    }
  }

  static int _checkDigit(String body) {
    var sum = 0;
    for (var i = 0; i < body.length; i++) {
      final code = body.codeUnitAt(i);
      final weight = (i % 2 == 0) ? 3 : 7;
      sum += code * weight;
    }
    return sum % 10;
  }

  static String generate(String countryName) {
    final codePays = _countryCode(countryName);
    final now = DateTime.now();
    final dateStr = '${now.month.toString().padLeft(2, '0')}${now.year.toString().substring(2)}';
    final variable = _secureRandom.nextInt(90000) + 10000;
    final codeCompl = String.fromCharCodes(
      Iterable.generate(3, (_) => _alphabet.codeUnitAt(_secureRandom.nextInt(_alphabet.length))),
    );
    final body = '$codePays-$dateStr-$variable-$codeCompl';
    final cleVerif = _checkDigit(body);
    return 'THIX-$body-$cleVerif';
  }
}

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
// DESIGN — champs compacts façon app native
// ============================================================================
class _FormColors {
  static const Color navy = Color(0xFF0A3D62);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color fieldBg = Color(0xFFFFFFFF);
}

class _CompactField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _CompactField({
    required this.label,
    this.hint = '',
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
    this.trailing,
  });

  @override
  State<_CompactField> createState() => _CompactFieldState();
}

class _CompactFieldState extends State<_CompactField> {
  late bool _obscured = widget.isPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _FormColors.navy)),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: _FormColors.fieldBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _FormColors.border),
          ),
          child: TextField(
            controller: widget.controller,
            obscureText: _obscured,
            keyboardType: widget.keyboardType,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            style: const TextStyle(fontSize: 13.5, color: _FormColors.navy),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hint,
              hintStyle: const TextStyle(fontSize: 13, color: _FormColors.textSecondary),
              prefixIcon: Icon(widget.icon, size: 17, color: _FormColors.textSecondary),
              prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              suffixIcon: widget.trailing ??
                  (widget.isPassword
                      ? IconButton(
                          splashRadius: 16,
                          icon: Icon(_obscured ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 16, color: _FormColors.textSecondary),
                          onPressed: () => setState(() => _obscured = !_obscured),
                        )
                      : null),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _CompactDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _FormColors.navy)),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _FormColors.fieldBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _FormColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 17, color: _FormColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    isDense: true,
                    icon: const Icon(Icons.expand_more_rounded, size: 18, color: _FormColors.textSecondary),
                    style: const TextStyle(fontSize: 13.5, color: _FormColors.navy),
                    hint: const Text('Sélectionner', style: TextStyle(fontSize: 13, color: _FormColors.textSecondary)),
                    items: items.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PAGE D'INSCRIPTION SIMPLIFIÉE (ConsumerStatefulWidget)
// ============================================================================

class PersonalRegistrationPage extends ConsumerStatefulWidget {
  final int? initialStep;
  const PersonalRegistrationPage({super.key, this.initialStep});

  @override
  ConsumerState<PersonalRegistrationPage> createState() => _PersonalRegistrationPageState();
}

class _PersonalRegistrationPageState extends ConsumerState<PersonalRegistrationPage> {
  final _userService = UserService(Supabase.instance.client);

  final _nameC = TextEditingController();
  final _dobC = TextEditingController();
  String? _country;
  final _occupationC = TextEditingController();

  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();
  final _confirmC = TextEditingController();
  final _otpC = TextEditingController();
  final _thixChatC = TextEditingController();

  String _thixIdGenerated = '';
  String _uid = '';
  
  // _isLoading a été supprimé ! On utilise Riverpod.
  bool _otpSent = false;
  bool _isNavigating = false;
  int _step = 1;

  Timer? _resendTimer;
  int _resendCooldown = 0;
  static const int _resendCooldownDuration = 45;

  static const List<String> _countryList = [
    'République Démocratique du Congo', 'Rwanda', 'Burundi', 'Ouganda', 'Angola', 
    "Côte d'Ivoire", 'Sénégal', 'Cameroun', 'France', 'Belgique', 'Canada', 'États-Unis', 'Autre'
  ];

  @override
  void dispose() {
    _nameC.dispose(); _dobC.dispose(); _occupationC.dispose();
    _emailC.dispose(); _passwordC.dispose(); _confirmC.dispose();
    _otpC.dispose(); _thixChatC.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade600 : null,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  String _userFacingError(Object e) {
    debugPrint('[PersonalRegistration] erreur brute: $e');
    final msg = e.toString().toLowerCase();

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
    if (msg.contains('23505')) {
      return 'Ce THIX CHAT est déjà pris, merci d\'en choisir un autre.';
    }
    return 'Erreur exacte : $e';
  }

  bool _isValidEmail(String email) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

  String? _passwordIssue(String pass) {
    if (pass.length < 8) return 'Le mot de passe doit contenir au moins 8 caractères.';
    if (!RegExp(r'[A-Za-z]').hasMatch(pass) || !RegExp(r'[0-9]').hasMatch(pass)) {
      return 'Le mot de passe doit contenir au moins une lettre et un chiffre.';
    }
    return null;
  }

  bool _isValidThixChat(String chat) {
    return RegExp(r'^@[a-z0-9._]{3,20}$').hasMatch(chat);
  }

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
      if (!mounted) { timer.cancel(); return; }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  Future<void> _sendOtp() async {
    final isLoading = ref.read(authControllerProvider).isLoading;
    if (isLoading || _resendCooldown > 0) return;

    final email = _emailC.text.trim().toLowerCase();
    final pass = _passwordC.text;
    final confirm = _confirmC.text;

    if (email.isEmpty || !_isValidEmail(email)) return _snack('Email invalide.', isError: true);
    final passIssue = _passwordIssue(pass);
    if (passIssue != null) return _snack(passIssue, isError: true);
    if (pass != confirm) return _snack('Les mots de passe ne correspondent pas.', isError: true);

    // MOTEUR RIVERPOD
    final authNotifier = ref.read(authControllerProvider.notifier);
    
    try {
      await authNotifier.registerPersonal(
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
      if (!mounted) return;
      
      // En cas de succès sans exception
      setState(() => _otpSent = true);
      _startResendCooldown();
      _snack('Un code OTP vous a été envoyé par email.');
      
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('inscription enregistrée') || message.contains('confirm') || message.contains('confirmez')) {
        if (!mounted) return;
        setState(() => _otpSent = true);
        _startResendCooldown();
        _snack('Un code OTP vous a été envoyé par email.');
      } else {
        _snack(_userFacingError(e), isError: true);
      }
    }
  }

  Future<void> _verifyAndRegister() async {
    final isLoading = ref.read(authControllerProvider).isLoading;
    if (isLoading) return;

    final code = _otpC.text.trim();
    if (code.isEmpty) {
      _snack('Veuillez saisir le code reçu par email.', isError: true);
      return;
    }

    final desiredChatRaw = _thixChatC.text.trim();
    final desiredChat = desiredChatRaw.isNotEmpty ? desiredChatRaw : _suggestChatFromName(_nameC.text.trim());
    if (!_isValidThixChat(desiredChat)) {
      _snack('THIX CHAT invalide : utilisez 3 à 20 caractères (lettres minuscules, chiffres, "." ou "_").', isError: true);
      return;
    }

    final authNotifier = ref.read(authControllerProvider.notifier);

    try {
      await authNotifier.verifyOTP(email: _emailC.text.trim().toLowerCase(), token: code);
      
      // On récupère l'utilisateur depuis l'état du provider
      final me = ref.read(authControllerProvider).value;

      if (me == null) throw Exception('Utilisateur introuvable après vérification.');

      final claimed = await _userService.ensureThixChat(uid: me.id, desired: desiredChat);

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
          if (isUniqueViolation && attempt < maxAttempts - 1) continue;
          rethrow;
        }
      }
      if (!assigned) throw Exception('Impossible de générer un THIX ID unique pour le moment.');

      if (mounted) {
        setState(() {
          _thixIdGenerated = officialThixId;
          _uid = me.id;
          _thixChatC.text = claimed;
          _step = 3;
        });
        _snack('Email vérifié avec succès !');
      }
    } catch (e) {
      _snack(_userFacingError(e), isError: true);
    }
  }

  String _suggestChatFromName(String name) {
    final base = name.trim().split(RegExp(r'\s+')).first.toLowerCase();
    final cleaned = base.replaceAll(RegExp(r'[^a-z0-9._]'), '');
    final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(9);
    final candidate = '@${cleaned.isEmpty ? 'user' : cleaned}${suffix.padLeft(4, '0')}';
    return candidate.length > 21 ? candidate.substring(0, 21) : candidate;
  }

  @override
  Widget build(BuildContext context) {
    // Écoute de l'état de chargement Riverpod
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0, left: 0, right: 0, height: 160,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0A3D62), Color(0xFF1A5A8C)]),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('THIX ID', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: LightModeColors.accent, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(
                        _step == 1 ? 'Étape 1/2 : Votre profil' : _step == 2 ? 'Étape 2/2 : Création du compte' : 'Inscription terminée',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
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
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400), switchInCurve: Curves.easeOutCubic, switchOutCurve: Curves.easeInCubic,
                      child: KeyedSubtree(key: ValueKey(_step), child: _buildStepContent(isLoading)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildMainButton(isLoading),
                  const SizedBox(height: 16),
                  if (_step < 3)
                    TextButton(
                      onPressed: () {
                        if (_step == 2) setState(() => _step = 1);
                        else context.go(AppRoutes.login);
                      },
                      child: Text(_step == 2 ? 'Revenir à l\'étape 1' : 'Déjà un compte ? Se connecter'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isLoading) {
    switch (_step) {
      case 1:
        return _Step1Profile(
          nameC: _nameC, dobC: _dobC, country: _country,
          onCountryChanged: (v) => setState(() => _country = v),
          occupationC: _occupationC, onPickDob: _pickDob,
        );
      case 2:
        return _Step2Account(
          emailC: _emailC, passwordC: _passwordC, confirmC: _confirmC,
          otpC: _otpC, thixChatC: _thixChatC, onSendOtp: _sendOtp,
          isOtpSent: _otpSent, isLoading: isLoading, resendCooldown: _resendCooldown,
        );
      case 3:
        return _Step3Final(thixId: _thixIdGenerated, thixChat: _thixChatC.text, uid: _uid);
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
        data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: LightModeColors.accent)),
        child: child!,
      ),
    );
    if (picked != null) {
      final v = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() => _dobC.text = v);
    }
  }

  Widget _buildMainButton(bool isLoading) {
    String label;
    VoidCallback? onPressed;
    switch (_step) {
      case 1:
        label = 'SUIVANT →';
        onPressed = _goToStep2;
        break;
      case 2:
        label = isLoading ? 'VÉRIFICATION...' : 'CONFIRMER LE CODE OTP';
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
        onTap: isLoading ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFF9C74F), Color(0xFFF8961E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.orange.shade300.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...const [
                SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
                SizedBox(width: 12),
              ],
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SOUS-WIDGETS (IDENTIQUES AU PREMIER BLOC)
// ============================================================================
class _Step1Profile extends StatelessWidget {
  final TextEditingController nameC, dobC, occupationC;
  final String? country;
  final ValueChanged<String?> onCountryChanged;
  final VoidCallback onPickDob;

  const _Step1Profile({required this.nameC, required this.dobC, required this.occupationC, required this.country, required this.onCountryChanged, required this.onPickDob});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Informations personnelles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _FormColors.navy)),
        const SizedBox(height: 14),
        _CompactField(label: 'Nom complet *', hint: 'Ex : Jean Mukendi', icon: Icons.person_outline_rounded, controller: nameC),
        const SizedBox(height: 10),
        _CompactField(label: 'Date de naissance *', hint: 'JJ-MM-AAAA', icon: Icons.calendar_today_rounded, controller: dobC, readOnly: true, onTap: onPickDob, trailing: const Icon(Icons.expand_more_rounded, size: 18, color: _FormColors.textSecondary)),
        const SizedBox(height: 10),
        _CompactDropdown(label: 'Pays *', icon: Icons.public_rounded, value: country, items: const ['République Démocratique du Congo', 'Rwanda', 'Burundi', 'Ouganda', 'Angola', "Côte d'Ivoire", 'Sénégal', 'Cameroun', 'France', 'Belgique', 'Canada', 'États-Unis', 'Autre'], onChanged: onCountryChanged),
        const SizedBox(height: 10),
        _CompactField(label: 'Occupation (facultatif)', hint: 'Ex : Étudiant, Entrepreneur...', icon: Icons.work_outline_rounded, controller: occupationC),
        const SizedBox(height: 10),
        Text('Ces informations permettront de générer votre identifiant THIX ID unique.', style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5)),
      ],
    );
  }
}

class _Step2Account extends StatelessWidget {
  final TextEditingController emailC, passwordC, confirmC, otpC, thixChatC;
  final VoidCallback onSendOtp;
  final bool isOtpSent, isLoading;
  final int resendCooldown;

  const _Step2Account({required this.emailC, required this.passwordC, required this.confirmC, required this.otpC, required this.thixChatC, required this.onSendOtp, required this.isOtpSent, required this.isLoading, required this.resendCooldown});

  @override
  Widget build(BuildContext context) {
    final canResend = !isLoading && resendCooldown == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Création du compte', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _FormColors.navy)),
        const SizedBox(height: 14),
        _CompactField(label: 'Email *', hint: 'votre@email.com', icon: Icons.email_outlined, controller: emailC, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 10),
        _CompactField(label: 'Mot de passe * (8 car. min, 1 lettre + 1 chiffre)', hint: '••••••••', icon: Icons.lock_outline_rounded, controller: passwordC, isPassword: true),
        const SizedBox(height: 10),
        _CompactField(label: 'Confirmer le mot de passe *', hint: '••••••••', icon: Icons.lock_outline_rounded, controller: confirmC, isPassword: true),
        const SizedBox(height: 14),
        SizedBox(
          height: 46,
          child: ElevatedButton.icon(
            onPressed: canResend ? onSendOtp : null,
            icon: Icon(isOtpSent ? Icons.refresh_rounded : Icons.send_rounded, size: 16),
            label: Text(!canResend && resendCooldown > 0 ? 'Renvoyer dans ${resendCooldown}s' : (isOtpSent ? 'Renvoyer le code OTP' : 'Envoyer le code OTP'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: LightModeColors.accent, foregroundColor: Colors.white, disabledBackgroundColor: LightModeColors.accent.withValues(alpha: 0.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ),
        if (isOtpSent) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.blue.shade100)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.mark_email_read_outlined, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Un code OTP vous a été envoyé par email', style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w700, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text('Vérifiez aussi vos spams. Le code expire après quelques minutes.', style: TextStyle(color: Colors.blue.shade700, fontSize: 10.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        _CompactField(label: 'Code de vérification reçu par email *', hint: '000000', icon: Icons.confirmation_number_outlined, controller: otpC, keyboardType: TextInputType.number),
        const SizedBox(height: 10),
        _CompactField(label: 'THIX CHAT (nom d\'utilisateur public) *', hint: '@john_doe_123', icon: Icons.chat_outlined, controller: thixChatC),
        const SizedBox(height: 8),
        Text('Choisissez un identifiant unique pour vos discussions. (3 à 20 caractères : lettres, chiffres, "." ou "_")', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
      ],
    );
  }
}

class _Step3Final extends StatelessWidget {
  final String thixId, thixChat, uid;
  const _Step3Final({required this.thixId, required this.thixChat, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('🎉 Inscription terminée !', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0A3D62))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.shade200)),
          child: Row(children: [const Icon(Icons.verified, color: Colors.green, size: 28), const SizedBox(width: 12), Expanded(child: Text('Votre compte est actif et votre identité THIX ID est générée.', style: TextStyle(color: Colors.green.shade800)))]),
        ),
        const SizedBox(height: 24),
        _NativeInfoGroup(
          rows: [
            _NativeInfoRow(label: 'THIX ID', value: thixId, icon: Icons.verified_user, iconColor: Colors.blue, showCopy: true),
            _NativeInfoRow(label: 'THIX CHAT', value: thixChat, icon: Icons.chat, iconColor: Colors.orange, showCopy: true),
            _NativeInfoRow(label: 'UID (identifiant unique)', value: uid, icon: Icons.fingerprint, iconColor: Colors.grey.shade700, showCopy: false),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [const Icon(Icons.qr_code, color: Colors.black), const SizedBox(width: 12), Expanded(child: Text('Un QR code sera disponible dans votre profil pour un partage sécurisé.', style: TextStyle(color: Colors.grey.shade700)))]),
        ),
        const SizedBox(height: 8),
        Text('Format THIX ID : ${thixId.length >= 15 ? thixId.substring(0, 15) : thixId}... (clé de vérification incluse)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }
}

class _NativeInfoRow {
  final String label, value;
  final IconData icon;
  final Color iconColor;
  final bool showCopy;
  const _NativeInfoRow({required this.label, required this.value, required this.icon, required this.iconColor, required this.showCopy});
}

class _NativeInfoGroup extends StatelessWidget {
  final List<_NativeInfoRow> rows;
  const _NativeInfoGroup({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _buildRow(context, rows[i]),
            if (i != rows.length - 1) Divider(height: 1, indent: 60, endIndent: 16, color: Colors.grey.shade200),
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
          Container(width: 34, height: 34, decoration: BoxDecoration(color: row.iconColor.withValues(alpha: 0.12), shape: BoxShape.circle), child: Icon(row.icon, color: row.iconColor, size: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(row.value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (row.showCopy)
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: row.value));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${row.label} copié dans le presse-papier !'), backgroundColor: Colors.green));
              },
              icon: const Icon(Icons.copy, size: 18), tooltip: 'Copier', visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
