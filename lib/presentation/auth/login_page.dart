// lib/features/auth/presentation/pages/login_page.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/theme.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/features/auth/presentation/providers/auth_controller.dart';

typedef PhoneAuthSession = dynamic;

// ---------------------------------------------------------------------------
// Design constants – exact match Dribbble
// ---------------------------------------------------------------------------
class _LoginColors {
  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color headerBlue = Color(0xFF1565C0);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color softShadow = Color(0x14000000);
}

class _LoginSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

class _LoginRadius {
  static const double input = 12;
  static const double button = 12;
  static const double card = 28;
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _identifierC = TextEditingController();
  final _passwordC = TextEditingController();
  bool _rememberMe = true;
  PhoneAuthSession? _phoneSession;

  int _failedAttempts = 0;
  int _lockoutSecondsLeft = 0;
  Timer? _lockoutTimer;
  static const int _lockoutThreshold = 5;
  static const int _lockoutDuration = 30;

  int _resetCooldown = 0;
  Timer? _resetCooldownTimer;
  static const int _resetCooldownDuration = 45;

  @override
  void initState() {
    super.initState();
    _identifierC.addListener(_onIdentifierChanged);
  }

  void _onIdentifierChanged() {
    if (_phoneSession != null) {
      setState(() => _phoneSession = null);
    }
  }

  @override
  void dispose() {
    _identifierC.removeListener(_onIdentifierChanged);
    _identifierC.dispose();
    _passwordC.dispose();
    _lockoutTimer?.cancel();
    _resetCooldownTimer?.cancel();
    super.dispose();
  }

  String _userFacingError(Object e) {
    if (kDebugMode) debugPrint('[Login] erreur brute: $e');
    if (e is AuthException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('rate limit') || msg.contains('too many')) {
        return 'Trop de tentatives. Merci de patienter quelques instants.';
      }
      if (msg.contains('network') || msg.contains('connection')) {
        return 'Problème de connexion. Vérifiez votre réseau et réessayez.';
      }
      return 'Identifiant ou mot de passe incorrect.';
    }
    return 'Une erreur est survenue. Vérifiez vos identifiants et réessayez.';
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    setState(() => _lockoutSecondsLeft = _lockoutDuration);
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_lockoutSecondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _lockoutSecondsLeft = 0;
          _failedAttempts = 0;
        });
      } else {
        setState(() => _lockoutSecondsLeft -= 1);
      }
    });
  }

  Future<void> _signIn() async {
    if (_lockoutSecondsLeft > 0) return;

    final identifier = _identifierC.text.trim();
    final password = _passwordC.text;
    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir votre identifiant et mot de passe.')),
      );
      return;
    }

    final authNotifier = ref.read(authControllerProvider.notifier);

    try {
      if (_looksLikePhone(identifier) && !identifier.contains('@')) {
        if (kIsWeb) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connexion par SMS non disponible dans la Preview web.')),
          );
          return;
        }
        if (_phoneSession == null) {
          final session = await authNotifier.startPhoneAuth(phoneNumber: identifier);
          if (!mounted) return;
          setState(() => _phoneSession = session);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SMS envoyé. Entrez le code reçu ci-dessous puis validez.')),
          );
          return;
        }
        await authNotifier.confirmPhoneCode(session: _phoneSession!, smsCode: password);
      } else {
        await authNotifier.signIn(
          identifier: identifier,
          password: password,
          rememberMe: _rememberMe,
        );
      }

      if (!mounted) return;

      final user = ref.read(authControllerProvider).value;
      if (user != null) {
        _failedAttempts = 0;
        final target = user.accountType == AccountType.enterprise
            ? AppRoutes.enterpriseDashboard
            : AppRoutes.userDashboard;
        context.go(target);
      }
    } catch (e) {
      debugPrint('Login failed: $e');
      if (!mounted) return;
      _failedAttempts += 1;
      if (_failedAttempts >= _lockoutThreshold) {
        _startLockoutTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Trop de tentatives échouées. Réessayez dans ${_lockoutDuration}s.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_userFacingError(e))),
        );
      }
    }
  }

  bool _looksLikePhone(String s) => RegExp(r'^\+?[0-9][0-9\s\-]{7,}$').hasMatch(s.trim());
  bool _looksLikeEmail(String s) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim());

  void _startResetCooldown() {
    _resetCooldownTimer?.cancel();
    setState(() => _resetCooldown = _resetCooldownDuration);
    _resetCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resetCooldown <= 1) {
        timer.cancel();
        setState(() => _resetCooldown = 0);
      } else {
        setState(() => _resetCooldown -= 1);
      }
    });
  }

  Future<bool> _sendPasswordReset(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      /* Ignore */
    }
    _startResetCooldown();
    return true;
  }

  void _openForgotPasswordDialog() {
    final prefill = _looksLikeEmail(_identifierC.text) ? _identifierC.text.trim() : '';
    final emailC = TextEditingController(text: prefill);
    bool isSending = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canSend = !isSending && _resetCooldown == 0;
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _LoginColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_reset_rounded, color: _LoginColors.primaryBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Réinitialiser le mot de passe',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: _LoginColors.textPrimary,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Entrez l\'email associé à votre compte. Si un compte existe, un lien de réinitialisation vous sera envoyé.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _LoginColors.textSecondary,
                            fontSize: 13,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: _LoginColors.lightGray,
                        borderRadius: BorderRadius.circular(_LoginRadius.input),
                        border: Border.all(color: _LoginColors.border),
                      ),
                      child: TextField(
                        controller: emailC,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 14, color: _LoginColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'votre@email.com',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: canSend
                                ? () async {
                                    final email = emailC.text.trim();
                                    if (!_looksLikeEmail(email)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Email invalide.')),
                                      );
                                      return;
                                    }
                                    setDialogState(() => isSending = true);
                                    await _sendPasswordReset(email);
                                    if (!dialogContext.mounted) return;
                                    Navigator.of(dialogContext).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Si un compte existe avec cet email, un lien vient d\'être envoyé.',
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _LoginColors.primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(_LoginRadius.button),
                              ),
                            ),
                            child: Text(
                              !canSend && _resetCooldown > 0
                                  ? 'Patientez ${_resetCooldown}s'
                                  : (isSending ? 'Envoi...' : 'Envoyer le lien'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final inPhoneCodeMode = _phoneSession != null;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFE8EAF6), // fond lavande comme le mockup
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // ===== CARD PRINCIPALE =====
              Container(
                decoration: BoxDecoration(
                  color: _LoginColors.white,
                  borderRadius: BorderRadius.circular(_LoginRadius.card),
                  boxShadow: [
                    BoxShadow(
                      color: _LoginColors.softShadow,
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // ===== HEADER BLEU =====
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1A73E8),
                            Color(0xFF0D47A1),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Formes décoratives (vagues)
                          Positioned(
                            right: -40,
                            top: -20,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            left: -30,
                            bottom: -40,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Log In',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Identité sécurisée • THIX ID',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Illustration placeholder (remplace par ton asset si tu as l’image)
                              Center(
                                child: Container(
                                  height: 140,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.fingerprint_rounded,
                                    size: 64,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ===== FORMULAIRE =====
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Identifiant
                          _buildInputLabel(inPhoneCodeMode ? 'Code SMS reçu' : 'Email / Identifiant THIX'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _identifierC,
                            hint: inPhoneCodeMode ? '123456' : 'TX-882-091 ou email',
                            icon: inPhoneCodeMode ? Icons.sms_rounded : Icons.email_outlined,
                            isPassword: false,
                            keyboardType: inPhoneCodeMode ? TextInputType.number : TextInputType.text,
                          ),
                          const SizedBox(height: 18),

                          // Mot de passe
                          _buildInputLabel(inPhoneCodeMode ? 'Code de vérification' : 'Mot de passe'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _passwordC,
                            hint: inPhoneCodeMode ? '••••••' : 'Mot de passe',
                            icon: Icons.lock_outline_rounded,
                            isPassword: !inPhoneCodeMode,
                            keyboardType: inPhoneCodeMode ? TextInputType.number : TextInputType.text,
                          ),

                          if (inPhoneCodeMode) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => setState(() {
                                  _phoneSession = null;
                                  _passwordC.clear();
                                }),
                                child: const Text('Changer de numéro', style: TextStyle(fontSize: 13)),
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Remember + Forgot
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: isLoading ? null : () => setState(() => _rememberMe = !_rememberMe),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: _rememberMe ? _LoginColors.primaryBlue : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: _rememberMe ? _LoginColors.primaryBlue : _LoginColors.border,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: _rememberMe
                                          ? const Icon(Icons.check, size: 13, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Rester connecté',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _LoginColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: _openForgotPasswordDialog,
                                child: const Text(
                                  'Mot de passe oublié ?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _LoginColors.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // Bouton principal
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: (isLoading || _lockoutSecondsLeft > 0) ? null : _signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _LoginColors.primaryBlue,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: _LoginColors.primaryBlue.withOpacity(0.7),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(_LoginRadius.button),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                                    )
                                  : Text(
                                      _lockoutSecondsLeft > 0
                                          ? 'RÉESSAYER DANS ${_lockoutSecondsLeft}S'
                                          : 'Se connecter  →',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // OR
                          Row(
                            children: [
                              const Expanded(child: Divider(color: _LoginColors.border, thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  'OU',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _LoginColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(color: _LoginColors.border, thickness: 1)),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Google
                          SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Google Sign-In
                              },
                              icon: const Icon(Icons.g_mobiledata_rounded, size: 26, color: Colors.red),
                              label: const Text(
                                'Continuer avec Google',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _LoginColors.textPrimary,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: _LoginColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(_LoginRadius.button),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Sign Up
                          SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () => context.push(AppRoutes.personalReg),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: _LoginColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(_LoginRadius.button),
                                ),
                              ),
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(fontSize: 14, color: _LoginColors.textSecondary),
                                  children: [
                                    TextSpan(text: 'Nouveau ? '),
                                    TextSpan(
                                      text: 'Créer un compte',
                                      style: TextStyle(
                                        color: _LoginColors.primaryBlue,
                                        fontWeight: FontWeight.w7
700,
                                      ),
                                    ),
                                  ],
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

              const SizedBox(height: 24),

              // Langues
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _LoginColors.softShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    _LangChip(label: 'FR', active: true),
                    _LangChip(label: 'EN'),
                    _LangChip(label: 'SW'),
                    _LangChip(label: 'LN'),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _LoginColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isPassword,
    required TextInputType keyboardType,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: _LoginColors.white,
        borderRadius: BorderRadius.circular(_LoginRadius.input),
        border: Border.all(color: _LoginColors.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _LoginColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _LoginColors.textSecondary, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: Icon(icon, size: 20, color: _LoginColors.textSecondary),
          suffixIcon: isPassword
              ? IconButton(
                  icon: const Icon(Icons.visibility_off_outlined, size: 20, color: _LoginColors.textSecondary),
                  onPressed: () {}, // tu peux gérer le toggle si tu veux
                )
              : null,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Petits composants
// ---------------------------------------------------------------------------
class _LangChip extends StatelessWidget {
  final String label;
  final bool active;
  const _LangChip({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: active ? _LoginColors.primaryBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : _LoginColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
