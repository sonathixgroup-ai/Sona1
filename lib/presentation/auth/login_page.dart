import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';
import '../../nav.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';

// ---------------------------------------------------------------------------
// Phone Auth Session Type (placeholder for Supabase phone auth)
// ---------------------------------------------------------------------------
typedef PhoneAuthSession = dynamic;

// ---------------------------------------------------------------------------
// Constantes de design alignées sur la homepage (HomePagePremium)
// ---------------------------------------------------------------------------
class _LoginColors {
  static const Color primaryBlue = Color(0xFF1877F2);
  static const Color darkNavy = Color(0xFF111827);
  static const Color lightGrayBg = Color(0xFFF0F2F5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color goldBadge = Color(0xFFFBBF24);
  static const Color dangerRed = Color(0xFFFF3B30);
  static const Color shadowLight = Color(0x0F000000);
  static const Color shadowSecondary = Color(0x0A000000);
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
  static const double input = 24;
  static const double card = 22;
  static const double button = 14;
  static const double avatar = 20;
  static const double chip = 24;
}

class _LoginShadows {
  static List<BoxShadow> card = [
    BoxShadow(
      color: _LoginColors.shadowSecondary,
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}

// ---------------------------------------------------------------------------
// Composants internes légers
// ---------------------------------------------------------------------------
class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _LoginColors.goldBadge,
            borderRadius: BorderRadius.circular(_LoginRadius.avatar),
            boxShadow: _LoginShadows.card,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.fingerprint_rounded,
            color: _LoginColors.darkNavy,
            size: 28,
          ),
        ),
        const SizedBox(height: _LoginSpacing.m),
        Text(
          'THIX ID',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _LoginColors.darkNavy,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: _LoginSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _LoginColors.goldBadge.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(_LoginRadius.chip),
            border: Border.all(
              color: _LoginColors.goldBadge.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            'IDENTITÉ SÉCURISÉE • AVENIR DE CONFIANCE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _LoginColors.darkNavy,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Champ de saisie sécurisé — avec bascule afficher/masquer pour les mots
// de passe (standard natif iOS/Android).
// ---------------------------------------------------------------------------
class _SecureInput extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType type;
  final TextEditingController controller;
  final TextInputAction textInputAction;

  const _SecureInput({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isPassword,
    required this.type,
    required this.controller,
    required this.textInputAction,
  });

  @override
  State<_SecureInput> createState() => _SecureInputState();
}

class _SecureInputState extends State<_SecureInput> {
  late bool _obscured = widget.isPassword;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _LoginSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, size: 16, color: _LoginColors.textSecondary),
              const SizedBox(width: _LoginSpacing.xs),
              Text(
                widget.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _LoginColors.darkNavy,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: _LoginSpacing.s),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: _LoginColors.white,
              borderRadius: BorderRadius.circular(_LoginRadius.input),
              border: Border.all(color: _LoginColors.cardBorder),
              boxShadow: _LoginShadows.card,
            ),
            child: TextField(
              controller: widget.controller,
              obscureText: _obscured,
              keyboardType: widget.type,
              textInputAction: widget.textInputAction,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _LoginColors.darkNavy,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  color: _LoginColors.textSecondary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: _LoginSpacing.l),
                suffixIcon: widget.isPassword
                    ? IconButton(
                        splashRadius: 18,
                        icon: Icon(
                          _obscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 18,
                          color: _LoginColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscured = !_obscured),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page de connexion principale
// ---------------------------------------------------------------------------
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LoginPageBody();
  }
}

class _LoginPageBody extends StatefulWidget {
  const _LoginPageBody();

  @override
  State<_LoginPageBody> createState() => _LoginPageBodyState();
}

class _LoginPageBodyState extends State<_LoginPageBody> {
  final _identifierC = TextEditingController();
  final _passwordC = TextEditingController();
  bool _rememberMe = true;
  bool _isLoading = false;
  PhoneAuthSession? _phoneSession;

  // ---------- Anti brute-force (soft lockout côté client) ----------
  // La vraie protection reste côté serveur (rate limiting Supabase Auth) ;
  // ceci évite juste de marteler le bouton et donne un retour clair.
  int _failedAttempts = 0;
  int _lockoutSecondsLeft = 0;
  Timer? _lockoutTimer;
  static const int _lockoutThreshold = 5;
  static const int _lockoutDuration = 30;

  // ---------- Réinitialisation de mot de passe ----------
  int _resetCooldown = 0;
  Timer? _resetCooldownTimer;
  static const int _resetCooldownDuration = 45;

  @override
  void initState() {
    super.initState();
    // Si l'utilisateur modifie l'identifiant après avoir démarré une
    // session SMS, on invalide cette session : on ne veut jamais valider
    // un code reçu pour un numéro contre un identifiant différent.
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

  // ---------- Erreurs techniques → messages utilisateur ----------
  // On ne renvoie jamais le message brut de Supabase à l'écran (fuite
  // d'info technique). Pour la connexion, on reste volontairement vague
  // entre "email inconnu" et "mot de passe incorrect" pour ne pas
  // permettre l'énumération de comptes.
  String _userFacingError(Object e) {
    if (kDebugMode) {
      debugPrint('[Login] erreur brute: $e');
    }
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

    final auth = context.read<AuthController>();
    final identifier = _identifierC.text.trim();
    final password = _passwordC.text;
    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir votre identifiant et mot de passe.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_looksLikePhone(identifier) && !identifier.contains('@')) {
        if (kIsWeb) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connexion par SMS non disponible dans la Preview web.')),
          );
          return;
        }
        if (_phoneSession == null) {
          final session = await auth.startPhoneAuth(phoneNumber: identifier);
          if (!mounted) return;
          setState(() => _phoneSession = session);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SMS envoyé. Entrez le code reçu ci-dessous puis validez.')),
          );
          return;
        }
        final u = await auth.confirmPhoneCode(session: _phoneSession!, smsCode: password);
        if (!mounted) return;
        _failedAttempts = 0;
        final target = u.accountType == AccountType.enterprise
            ? AppRoutes.enterpriseDashboard
            : AppRoutes.userDashboard;
        context.go(target);
        return;
      }

      final u = await auth.signIn(
        identifier: identifier,
        password: password,
        rememberMe: _rememberMe,
      );
      if (!mounted) return;
      _failedAttempts = 0;
      final target = u.accountType == AccountType.enterprise
          ? AppRoutes.enterpriseDashboard
          : AppRoutes.userDashboard;
      context.go(target);
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _looksLikePhone(String s) =>
      RegExp(r'^\+?[0-9][0-9\s\-]{7,}$').hasMatch(s.trim());

  bool _looksLikeEmail(String s) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim());

  // ---------- Réinitialisation de mot de passe ----------
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
      if (kDebugMode) debugPrint('[ResetPassword] erreur brute: $e');
      // Volontairement : on ne révèle jamais si l'échec vient d'un email
      // inconnu ou d'une autre cause. Même message dans tous les cas.
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
                  borderRadius: BorderRadius.circular(_LoginRadius.card),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_reset_rounded, color: _LoginColors.primaryBlue),
                        const SizedBox(width: _LoginSpacing.s),
                        Expanded(
                          child: Text(
                            'Réinitialiser le mot de passe',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: _LoginColors.darkNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _LoginSpacing.m),
                    Text(
                      'Entrez l\'email associé à votre compte. Si un compte existe, un lien de réinitialisation vous sera envoyé.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _LoginColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: _LoginSpacing.l),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _LoginColors.lightGrayBg,
                        borderRadius: BorderRadius.circular(_LoginRadius.input),
                        border: Border.all(color: _LoginColors.cardBorder),
                      ),
                      child: TextField(
                        controller: emailC,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 14, color: _LoginColors.darkNavy),
                        decoration: const InputDecoration(
                          hintText: 'votre@email.com',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: _LoginSpacing.l),
                        ),
                      ),
                    ),
                    const SizedBox(height: _LoginSpacing.l),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: _LoginSpacing.s),
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
                                          'Si un compte existe avec cet email, un lien de réinitialisation vient d\'être envoyé.',
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
    return Scaffold(
      backgroundColor: _LoginColors.lightGrayBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const _LoginHeader(),
              const SizedBox(height: _LoginSpacing.xxl),
              Container(
                decoration: BoxDecoration(
                  color: _LoginColors.white,
                  borderRadius: BorderRadius.circular(_LoginRadius.card),
                  border: Border.all(color: _LoginColors.cardBorder, width: 0.7),
                  boxShadow: _LoginShadows.card,
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Connexion',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: _LoginColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Connectez-vous avec votre email ou votre identifiant THIX (TX-XXX-XXX)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _LoginColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: _LoginSpacing.xl),
                    _SecureInput(
                      key: const ValueKey('identifier'),
                      label: 'Identifiant THIX ID',
                      hint: 'Ex: TX-882-091 ou email',
                      icon: Icons.badge_rounded,
                      isPassword: false,
                      type: TextInputType.text,
                      controller: _identifierC,
                      textInputAction: TextInputAction.next,
                    ),
                    _SecureInput(
                      key: ValueKey(inPhoneCodeMode ? 'sms_code' : 'password'),
                      label: inPhoneCodeMode ? 'Code SMS reçu' : 'Mot de passe',
                      hint: inPhoneCodeMode ? '123456' : '••••••••••••',
                      icon: inPhoneCodeMode ? Icons.sms_rounded : Icons.lock_rounded,
                      isPassword: !inPhoneCodeMode,
                      type: inPhoneCodeMode ? TextInputType.number : TextInputType.text,
                      controller: _passwordC,
                      textInputAction: TextInputAction.done,
                    ),
                    if (inPhoneCodeMode)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setState(() {
                            _phoneSession = null;
                            _passwordC.clear();
                          }),
                          child: const Text('Changer de numéro'),
                        ),
                      ),
                    const SizedBox(height: _LoginSpacing.s),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () => setState(() => _rememberMe = !_rememberMe),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _rememberMe
                                      ? _LoginColors.primaryBlue
                                      : _LoginColors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _rememberMe
                                        ? _LoginColors.primaryBlue
                                        : _LoginColors.cardBorder,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 12,
                                  color: _rememberMe
                                      ? Colors.white
                                      : Colors.transparent,
                                ),
                              ),
                              const SizedBox(width: _LoginSpacing.xs),
                              Text(
                                'Rester connecté',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: _LoginColors.textSecondary,
                                      fontSize: 12,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _openForgotPasswordDialog,
                          child: Text(
                            'Oublié ?',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: _LoginColors.primaryBlue,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _LoginSpacing.xl),
                    GestureDetector(
                      onTap: (_isLoading || _lockoutSecondsLeft > 0) ? null : _signIn,
                      child: Opacity(
                        opacity: (_isLoading || _lockoutSecondsLeft > 0) ? 0.8 : 1,
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                _LoginColors.primaryBlue,
                                _LoginColors.darkNavy,
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(_LoginRadius.button),
                            boxShadow: _LoginShadows.card,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLoading) ...[
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: _LoginSpacing.m),
                              ],
                              Text(
                                _lockoutSecondsLeft > 0
                                    ? 'RÉESSAYER DANS ${_lockoutSecondsLeft}S'
                                    : (_isLoading ? 'VÉRIFICATION…' : 'SE CONNECTER'),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      letterSpacing: 0.4,
                                    ),
                              ),
                              if (_lockoutSecondsLeft == 0) ...[
                                const SizedBox(width: _LoginSpacing.m),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: _LoginSpacing.l),
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: _LoginColors.cardBorder,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: _LoginSpacing.m),
                          child: Text(
                            'BIOMÉTRIE',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: _LoginColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            color: _LoginColors.cardBorder,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _LoginSpacing.m),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialAuth(
                          icon: Icons.face_rounded,
                          label: 'Face ID',
                        ),
                        const SizedBox(width: _LoginSpacing.m),
                        _SocialAuth(
                          icon: Icons.fingerprint_rounded,
                          label: 'Touch ID',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _LoginSpacing.xxl),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _LoginColors.white,
                  borderRadius: BorderRadius.circular(_LoginRadius.card),
                  border: Border.all(
                    color: _LoginColors.goldBadge.withValues(alpha: 0.25),
                  ),
                  boxShadow: _LoginShadows.card,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      color: _LoginColors.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: _LoginSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Standard de Sécurité Étatique',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: _LoginColors.darkNavy,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Chiffrement local & session persistante',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: _LoginColors.textSecondary,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _LoginSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Nouvel utilisateur ?',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _LoginColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.personalReg),
                    child: Text(
                      'Créer un compte THIX ID',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _LoginColors.primaryBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _LoginSpacing.l),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _LoginColors.white,
                  borderRadius: BorderRadius.circular(_LoginRadius.chip),
                  border: Border.all(color: _LoginColors.cardBorder),
                  boxShadow: _LoginShadows.card,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LangChip(label: 'FR', active: true),
                    _LangChip(label: 'EN'),
                    _LangChip(label: 'SW'),
                    _LangChip(label: 'LN'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialAuth extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SocialAuth({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 56,
      decoration: BoxDecoration(
        color: _LoginColors.white,
        borderRadius: BorderRadius.circular(_LoginRadius.button),
        border: Border.all(color: _LoginColors.cardBorder),
        boxShadow: _LoginShadows.card,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _LoginColors.darkNavy, size: 20),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _LoginColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool active;

  const _LangChip({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: active ? _LoginColors.primaryBlue : _LoginColors.white,
        borderRadius: BorderRadius.circular(_LoginRadius.chip),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: active ? Colors.white : _LoginColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
