import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/services/user_service.dart';
import 'package:thix_id/theme.dart';

// ============================================================================
// PAGE D'INSCRIPTION SIMPLIFIÉE (2 ÉTAPES)
// ============================================================================

class PersonalRegistrationPage extends StatefulWidget {
  const PersonalRegistrationPage({super.key});

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
  bool _isVerified = false;
  int _step = 1; // 1: profil, 2: compte+OTP, 3: final

  static const Map<String, String> _countryCodes = {
    'République Démocratique du Congo': 'CD',
    'Rwanda': 'RW',
    'Burundi': 'BI',
    'Ouganda': 'UG',
    'Angola': 'AO',
    "Côte d'Ivoire": 'CI',
    'Sénégal': 'SN',
    'Cameroun': 'CM',
    'France': 'FR',
    'Belgique': 'BE',
    'Canada': 'CA',
    'États-Unis': 'US',
    'Autre': 'XX',
  };

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
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String _rawError(Object e) {
    if (e is AuthException) return 'Erreur: ${e.message}';
    if (e is PostgrestException) return 'Erreur: ${e.message} (code: ${e.code})';
    return e.toString();
  }

  // ---------- Gestion du THIX ID personnalisé ----------
  String _generateThixId(String country, String dob, String uid) {
    final countryCode = _countryCodes[country] ?? 'XX';
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    final key = _generateVerificationKey(uid, countryCode, now);
    return 'THIX-$countryCode-$year$month-$random-$key';
  }

  String _generateVerificationKey(String uid, String countryCode, DateTime date) {
    final raw = '$uid-$countryCode-${date.millisecondsSinceEpoch}';
    final hash = raw.hashCode.abs();
    return hash.toString().substring(0, 6).toUpperCase();
  }

  // ---------- Étape 1 : validation et passage ----------
  Future<void> _goToStep2() async {
    final name = _nameC.text.trim();
    final dob = _dobC.text.trim();
    if (name.isEmpty) return _snack('Nom complet requis.');
    if (dob.isEmpty) return _snack('Date de naissance requise.');
    if (_country == null) return _snack('Veuillez choisir votre pays.');
    // Occupation optionnelle
    setState(() => _step = 2);
  }

  // ---------- Envoi de l'OTP (inscription) ----------
  Future<void> _sendOtp() async {
    if (_isLoading) return;
    final email = _emailC.text.trim();
    final pass = _passwordC.text;
    final confirm = _confirmC.text;

    if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return _snack('Email invalide.');
    }
    if (pass.length < 8) return _snack('Mot de passe : minimum 8 caractères.');
    if (pass != confirm) return _snack('Les mots de passe ne correspondent pas.');

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthController>();
      // On crée le compte (l'email de confirmation est envoyé automatiquement)
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
      _snack('Un code de vérification a été envoyé à votre email.');
    } catch (e) {
      if (e is AuthException && e.message.contains('Inscription enregistrée')) {
        // Cas où l'email de confirmation est envoyé mais pas de session immédiate
        _otpSent = true;
        _snack('Un code de vérification a été envoyé à votre email.');
      } else {
        _snack(_rawError(e));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---------- Vérification OTP et finalisation ----------
  Future<void> _verifyAndRegister() async {
    if (_isLoading) return;
    final code = _otpC.text.trim();
    if (code.isEmpty) return _snack('Veuillez saisir le code reçu par email.');

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthController>();
      // Vérifier l'OTP
      await auth.verifyOTP(email: _emailC.text.trim(), token: code);
      _snack('Email vérifié avec succès !');

      final me = auth.currentUser;
      if (me == null) throw Exception('Utilisateur introuvable après vérification.');

      // Générer le THIX ID personnalisé
      final thixId = _generateThixId(_country!, _dobC.text.trim(), me.id);
      _thixIdGenerated = thixId;
      _uid = me.id;

      // Mettre à jour le profil avec le THIX ID et le THIX CHAT
      final chatId = _thixChatC.text.trim().isNotEmpty
          ? _thixChatC.text.trim()
          : _suggestChatFromName(_nameC.text.trim());

      final claimed = await _userService.ensureThixChat(uid: me.id, desired: chatId);
      await _userService.updateProfile(
        uid: me.id,
        thixId: thixId,
        thixChat: claimed,
        registrationStatus: 'active',
      );

      _thixChatC.text = claimed;
      _isVerified = true;
      setState(() => _step = 3);
    } catch (e) {
      _snack(_rawError(e));
    } finally {
      setState(() => _isLoading = false);
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
      final v =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
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
        label = _isLoading ? 'ENVOI EN COURS...' : 'S\'INSCRIRE';
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

  const _Step2Account({
    required this.emailC,
    required this.passwordC,
    required this.confirmC,
    required this.otpC,
    required this.thixChatC,
    required this.onSendOtp,
    required this.isOtpSent,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
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
            labelText: 'Mot de passe * (8 caractères min)',
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
                onPressed: isLoading ? null : onSendOtp,
                icon: const Icon(Icons.send, size: 18),
                label: Text(isOtpSent ? 'Code envoyé ✓' : 'Envoyer le code OTP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOtpSent ? Colors.green.shade600 : LightModeColors.accent,
                  foregroundColor: Colors.white,
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
          TextField(
            controller: otpC,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Code de vérification reçu par email',
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
              labelText: 'THIX CHAT (nom d\'utilisateur public)',
              hintText: '@john_doe_123',
              prefixIcon: const Icon(Icons.chat_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choisissez un identifiant unique pour vos discussions. (3 à 20 caractères)',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
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
        _buildInfoTile('THIX ID', thixId, Icons.verified_user, Colors.blue),
        const SizedBox(height: 12),
        _buildInfoTile('THIX CHAT', thixChat, Icons.chat, Colors.orange),
        const SizedBox(height: 12),
        _buildInfoTile('UID (identifiant unique)', uid, Icons.fingerprint, Colors.grey),
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
          'Format THIX ID : ${thixId.substring(0, 15)}... (clé de vérification incluse)',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (label == 'THIX ID')
            IconButton(
              onPressed: () {
                // Copier le THIX ID dans le presse-papier
                // (à implémenter avec Clipboard)
              },
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Copier',
            ),
        ],
      ),
    );
  }
}
