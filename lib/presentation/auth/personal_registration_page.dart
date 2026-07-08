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
// PAGE PRINCIPALE (SIMPLIFIÉE)
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
  late int _step;

  // Contrôleurs étape 1
  final _nameC = TextEditingController();
  final _dobC = TextEditingController();
  String? _gender;
  String? _country;
  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();
  final _confirmC = TextEditingController();

  // Étape 2 : vérification email
  final _otpC = TextEditingController();
  bool _otpSent = false;

  // Étape 3 : THIX CHAT
  final _thixChatC = TextEditingController();
  String _thixId = '---';
  String _uid = '---';
  bool _isLoading = false;

  static const List<String> _countryList = [
    'République Démocratique du Congo',
    'Rwanda', 'Burundi', 'Ouganda', 'Angola',
    'Côte d\'Ivoire', 'Sénégal', 'Cameroun',
    'France', 'Belgique', 'Canada', 'États-Unis', 'Autre'
  ];

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep ?? 1;
  }

  @override
  void dispose() {
    _nameC.dispose(); _dobC.dispose(); _emailC.dispose();
    _passwordC.dispose(); _confirmC.dispose(); _otpC.dispose();
    _thixChatC.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  bool _hasSupabaseSession() =>
      Supabase.instance.client.auth.currentSession != null;

  void _handleUnauthed() {
    _snack('Session expirée. Veuillez vous reconnecter.');
    context.go(AppRoutes.login);
  }

  // ========== GESTION D'ERREUR AMÉLIORÉE ==========
  String _rawError(Object e) {
    if (e is AuthException) return 'Erreur: ${e.message}';
    if (e is PostgrestException) return 'Erreur: ${e.message} (code: ${e.code})';
    return e.toString();
  }

  // ---------- Étape 1 ----------
  Future<void> _submitStep1() async {
    if (_isLoading) return;
    final name = _nameC.text.trim();
    final dob = _dobC.text.trim();
    final email = _emailC.text.trim();
    final pass = _passwordC.text;
    final confirm = _confirmC.text;

    if (name.isEmpty) return _snack('Nom complet requis.');
    if (dob.isEmpty) return _snack('Date de naissance requise.');
    if (_gender == null) return _snack('Veuillez choisir votre sexe.');
    if (_country == null) return _snack('Veuillez choisir votre pays.');
    if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return _snack('Email invalide.');
    }
    if (pass.length < 8) return _snack('Mot de passe : minimum 8 caractères.');
    if (pass != confirm) return _snack('Les mots de passe ne correspondent pas.');

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthController>();
      await auth.registerPersonal(
        email: email,
        password: pass,
        displayName: name,
        rememberMe: true,
        profileDraft: {
          'full_name': name,
          'date_of_birth': dob,
          'gender': _gender,
          'country_or_origin': _country,
          'registration_status': 'draft_step1',
        },
      );
      // Supabase envoie l'email de vérification automatiquement
      _otpSent = true;
      setState(() => _step = 2);
    } catch (e) {
      _snack(_rawError(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---------- Étape 2 : vérification OTP ----------
  Future<void> _verifyOtp() async {
    if (_isLoading) return;
    final code = _otpC.text.trim();
    if (code.isEmpty) return _snack('Veuillez saisir le code reçu par email.');

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthController>();
      await auth.verifyOTP(email: _emailC.text.trim(), token: code);
      _snack('Email vérifié avec succès !');

      final me = auth.currentUser;
      if (me == null) throw Exception('Utilisateur introuvable après vérification.');
      _thixId = await _userService.ensureThixId(uid: me.id);
      _uid = me.id;
      final suggested = _suggestChatFromName(_nameC.text.trim());
      _thixChatC.text = suggested;
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

  // ---------- Étape 3 : finalisation ----------
  Future<void> _finishRegistration() async {
    if (_isLoading) return;
    final chatId = _thixChatC.text.trim();
    if (chatId.isEmpty) return _snack('Veuillez choisir un THIX CHAT.');
    if (!RegExp(r'^@[a-zA-Z0-9._]{3,20}$').hasMatch(chatId)) {
      return _snack('Format : @ + 3 à 20 caractères (lettres, chiffres, . ou _)');
    }

    setState(() => _isLoading = true);
    try {
      final me = context.read<AuthController>().currentUser;
      if (me == null) throw Exception('Utilisateur non authentifié.');
      final claimed = await _userService.ensureThixChat(uid: me.id, desired: chatId);
      if (claimed != chatId) {
        _snack('Ce THIX CHAT est déjà pris. Nous avons choisi : $claimed');
        _thixChatC.text = claimed;
      }
      await _userService.updateProfile(
        uid: me.id,
        thixChat: claimed,
        registrationStatus: 'active',
      );
      _snack('Inscription terminée ! Bienvenue sur THIX ID.');
      context.go(AppRoutes.home);
    } catch (e) {
      _snack(_rawError(e));
    } finally {
      setState(() => _isLoading = false);
    }
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
              top: 0, left: 0, right: 0, height: 180,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF0A3D62), Color(0xFF1A5A8C)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('THIX ID', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: LightModeColors.accent, fontWeight: FontWeight.w900,
                      )),
                      const SizedBox(height: 4),
                      Text('Créer votre identité sécurisée', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 140, bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStepIndicator(),
                  const SizedBox(height: 24),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: KeyedSubtree(
                        key: ValueKey(_step),
                        child: _buildStepContent(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildMainButton(),
                  const SizedBox(height: 20),
                  if (_step > 1)
                    TextButton(
                      onPressed: () => setState(() => _step = _step - 1),
                      child: const Text('Revenir à l\'étape précédente'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Profil', 'Vérification', 'Identifiants'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i + 1 == _step;
        final done = i + 1 < _step;
        return Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? LightModeColors.accent : done ? Colors.green : Colors.grey.shade300,
              ),
              child: Center(child: Text(done ? '✓' : '${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
            if (i < 2) Container(width: 40, height: 2, color: done ? Colors.green : Colors.grey.shade300),
          ],
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 1:
        return _Step1Simplified(
          nameC: _nameC, dobC: _dobC,
          gender: _gender, onGenderChanged: (v) => setState(() => _gender = v),
          country: _country, onCountryChanged: (v) => setState(() => _country = v),
          emailC: _emailC, passwordC: _passwordC, confirmC: _confirmC,
          onPickDob: _pickDob,
        );
      case 2:
        return _Step2VerifyEmail(
          otpC: _otpC,
          email: _emailC.text.trim(),
          onResend: _resendOtp,
          isLoading: _isLoading,
        );
      case 3:
        return _Step3ChooseIdentifiers(
          thixChatC: _thixChatC,
          thixId: _thixId,
          uid: _uid,
          onSuggest: () {
            final suggested = _suggestChatFromName(_nameC.text.trim());
            _thixChatC.text = suggested;
            setState(() {});
          },
        );
      default: return const SizedBox.shrink();
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

  Future<void> _resendOtp() async {
    try {
      final auth = context.read<AuthController>();
      await auth.resendOTP(email: _emailC.text.trim());
      _snack('Un nouveau code vous a été envoyé par email.');
    } catch (e) {
      _snack('Erreur lors du renvoi : $e');
    }
  }

  Widget _buildMainButton() {
    String label;
    VoidCallback? onPressed;
    switch (_step) {
      case 1: label = 'SUIVANT →'; onPressed = _submitStep1; break;
      case 2: label = 'VÉRIFIER'; onPressed = _verifyOtp; break;
      case 3: label = 'TERMINER'; onPressed = _finishRegistration; break;
      default: label = ''; onPressed = null;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _isLoading ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFF9C74F), Color(0xFFF8961E)]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.orange.shade300.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
              if (_isLoading) const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SOUS-WIDGETS (inchangés)
// ============================================================================

class _Step1Simplified extends StatelessWidget {
  final TextEditingController nameC, dobC, emailC, passwordC, confirmC;
  final String? gender, country;
  final ValueChanged<String?> onGenderChanged, onCountryChanged;
  final VoidCallback onPickDob;

  const _Step1Simplified({required this.nameC, required this.dobC, required this.gender, required this.onGenderChanged, required this.country, required this.onCountryChanged, required this.emailC, required this.passwordC, required this.confirmC, required this.onPickDob});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Informations personnelles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A3D62))),
        const SizedBox(height: 16),
        TextField(controller: nameC, decoration: InputDecoration(labelText: 'Nom complet *', prefixIcon: const Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onPickDob,
          child: AbsorbPointer(
            child: TextField(controller: dobC, decoration: InputDecoration(labelText: 'Date de naissance *', prefixIcon: const Icon(Icons.calendar_today), suffixIcon: const Icon(Icons.arrow_drop_down), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: gender,
          isExpanded: true,
          decoration: InputDecoration(labelText: 'Sexe *', prefixIcon: const Icon(Icons.wc), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
          items: const [DropdownMenuItem(value: 'Homme', child: Text('Homme')), DropdownMenuItem(value: 'Femme', child: Text('Femme')), DropdownMenuItem(value: 'Autre', child: Text('Autre'))],
          onChanged: onGenderChanged,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: country,
          isExpanded: true,
          decoration: InputDecoration(labelText: 'Pays *', prefixIcon: const Icon(Icons.public), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
          items: const [
            DropdownMenuItem(value: 'République Démocratique du Congo', child: Text('République Démocratique du Congo')),
            DropdownMenuItem(value: 'Rwanda', child: Text('Rwanda')),
            DropdownMenuItem(value: 'Burundi', child: Text('Burundi')),
            DropdownMenuItem(value: 'Ouganda', child: Text('Ouganda')),
            DropdownMenuItem(value: 'Angola', child: Text('Angola')),
            DropdownMenuItem(value: 'Côte d\'Ivoire', child: Text('Côte d\'Ivoire')),
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
        TextField(controller: emailC, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'Email *', prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
        const SizedBox(height: 12),
        TextField(controller: passwordC, obscureText: true, decoration: InputDecoration(labelText: 'Mot de passe * (8 caractères min)', prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
        const SizedBox(height: 12),
        TextField(controller: confirmC, obscureText: true, decoration: InputDecoration(labelText: 'Confirmer le mot de passe *', prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: const Text('Mot de passe oublié ?'),
          ),
        ),
      ],
    );
  }
}

class _Step2VerifyEmail extends StatelessWidget {
  final TextEditingController otpC;
  final String email;
  final VoidCallback onResend;
  final bool isLoading;

  const _Step2VerifyEmail({required this.otpC, required this.email, required this.onResend, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Vérification par email', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A3D62))),
        const SizedBox(height: 8),
        Text('Un code de vérification a été envoyé à $email.', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        TextField(controller: otpC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Code de vérification', prefixIcon: const Icon(Icons.confirmation_number_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(onPressed: onResend, child: const Text('Renvoyer le code')),
            if (isLoading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
          ],
        ),
      ],
    );
  }
}

class _Step3ChooseIdentifiers extends StatelessWidget {
  final TextEditingController thixChatC;
  final String thixId, uid;
  final VoidCallback onSuggest;

  const _Step3ChooseIdentifiers({required this.thixChatC, required this.thixId, required this.uid, required this.onSuggest});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Vos identifiants THIX', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A3D62))),
        const SizedBox(height: 16),
        _buildIdTile('THIX ID', thixId, Icons.verified_user, Colors.green),
        const SizedBox(height: 12),
        _buildIdTile('UID (utilisateur)', uid, Icons.fingerprint, Colors.blue),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: thixChatC,
                decoration: InputDecoration(labelText: 'THIX CHAT', hintText: '@john_doe_123', prefixIcon: const Icon(Icons.chat_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(onPressed: onSuggest, icon: const Icon(Icons.auto_awesome), tooltip: 'Suggérer un nom'),
          ],
        ),
        const SizedBox(height: 8),
        Text('Choisissez un identifiant unique pour vos discussions. 3 à 20 caractères, lettres, chiffres, . et _ autorisés.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  Widget _buildIdTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
