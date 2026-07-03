import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../../theme.dart';
import '../../nav.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';

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
        // Icône plus petite, fond gold + ombre douce
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

class _SecureInput extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType type;
  final TextEditingController controller;
  final TextInputAction textInputAction;

  const _SecureInput({
    required this.label,
    required this.hint,
    required this.icon,
    required this.isPassword,
    required this.type,
    required this.controller,
    required this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _LoginSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _LoginColors.textSecondary),
              const SizedBox(width: _LoginSpacing.xs),
              Text(
                label,
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
              controller: controller,
              obscureText: isPassword,
              keyboardType: type,
              textInputAction: textInputAction,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _LoginColors.darkNavy,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: _LoginColors.textSecondary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: _LoginSpacing.l),
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

  @override
  void dispose() {
    _identifierC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
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
          _phoneSession = await auth.startPhoneAuth(phoneNumber: identifier);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SMS envoyé. Entrez le code dans le champ Mot de passe puis validez.')),
          );
          return;
        }
        final u = await auth.confirmPhoneCode(session: _phoneSession!, smsCode: password);
        if (!mounted) return;
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
      final target = u.accountType == AccountType.enterprise
          ? AppRoutes.enterpriseDashboard
          : AppRoutes.userDashboard;
      context.go(target);
    } catch (e) {
      debugPrint('Login failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _looksLikePhone(String s) =>
      RegExp(r'^\+?[0-9][0-9\s\-]{7,}$').hasMatch(s.trim());

  @override
  Widget build(BuildContext context) {
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
              // Carte de connexion
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
                      label: 'Identifiant THIX ID',
                      hint: 'Ex: TX-882-091 ou email',
                      icon: Icons.badge_rounded,
                      isPassword: false,
                      type: TextInputType.text,
                      controller: _identifierC,
                      textInputAction: TextInputAction.next,
                    ),
                    _SecureInput(
                      label: 'Mot de passe',
                      hint: '••••••••••••',
                      icon: Icons.lock_rounded,
                      isPassword: true,
                      type: TextInputType.text,
                      controller: _passwordC,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: _LoginSpacing.s),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Rester connecté
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
                        // Mot de passe oublié
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Mode local: réinitialisation par email indisponible.'),
                              ),
                            );
                          },
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
                    // Bouton principal
                    GestureDetector(
                      onTap: _isLoading ? null : _signIn,
                      child: Opacity(
                        opacity: _isLoading ? 0.8 : 1,
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
                                SizedBox(
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
                                _isLoading ? 'VÉRIFICATION…' : 'SE CONNECTER',
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
                              const SizedBox(width: _LoginSpacing.m),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: _LoginSpacing.l),
                    // Séparateur "BIOMÉTRIE"
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
              // Sécurité
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
              // Créer un compte
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
              // Sélecteur de langue
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
