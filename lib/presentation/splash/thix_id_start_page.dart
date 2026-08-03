import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/nav.dart';

class ThixIdStartPage extends StatefulWidget {
  const ThixIdStartPage({super.key});

  @override
  State<ThixIdStartPage> createState() => _ThixIdStartPageState();
}

class _ThixIdStartPageState extends State<ThixIdStartPage> {
  static const String _logoAsset = 'assets/images/sonathix_logo.png';

  Timer? _timer;
  bool _navigated = false;
  bool _revealed = false;
  bool _didPrecache = false;
  String? _statusMessage;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeAppAndNavigate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _revealed = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecache) return;
    _didPrecache = true;
    precacheImage(const AssetImage(_logoAsset), context);
  }

  Future<void> _initializeAppAndNavigate() async {
    try {
      if (!mounted) return;
      
      setState(() => _statusMessage = 'Initialisation...');
      
      // Get AuthController from Provider
      final authController = Provider.of<AuthController>(context, listen: false);
      
      // Initialize auth if not already done
      if (!authController.isAuthenticated) {
        setState(() => _statusMessage = 'Vérification authentification...');
        await authController.init();
      }
      
      setState(() => _statusMessage = 'Chargement complet...');
      
      // Set minimum display time for splash screen (2 seconds)
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      
      _goHomeSafely();
    } catch (e) {
      debugPrint('Splash initialization error: $e');
      if (!mounted) return;
      
      setState(() {
        _statusMessage = 'Erreur: $e';
        _hasError = true;
      });
      
      // Try navigating anyway after 3 seconds
      _timer = Timer(const Duration(seconds: 3), _goHomeSafely);
    }
  }

  void _goHomeSafely() {
    if (!mounted || _navigated) return;
    _navigated = true;
    
    try {
      final authController = context.read<AuthController>();
      
      // Navigate based on auth state
      if (authController.isAuthenticated) {
        context.go(AppRoutes.home);
      } else {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      // Fallback navigation
      context.go(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navigated ? null : _goHomeSafely,
        child: Stack(
          children: [
            const Positioned.fill(child: _ThixIdStartBackdrop()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOut,
                  opacity: _revealed ? 1 : 0,
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      const _LogoPanel(),
                      const SizedBox(height: 28),
                      Text(
                        'THIX CENTRAL',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'une identité vérifiée, avenir de confiance',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 26),
                      if (_statusMessage != null)
                        Column(
                          children: [
                            if (!_hasError)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Color(0xFFEAF2FF),
                                ),
                              )
                            else
                              Icon(
                                Icons.warning_rounded,
                                size: 18,
                                color: Colors.redAccent.shade200,
                              ),
                            const SizedBox(height: 12),
                            Text(
                              _statusMessage!,
                              textAlign: TextAlign.center,
                              style: textTheme.labelMedium?.copyWith(
                                color: _hasError
                                    ? Colors.redAccent.shade200
                                    : Colors.white.withValues(alpha: 0.88),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Color(0xFFEAF2FF),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Appuyez pour continuer',
                              style: textTheme.labelLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      const Spacer(flex: 3),
                      Text(
                        'BY SONATHIX GROUP',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.68),
                          letterSpacing: 2.3,
                          fontWeight: FontWeight.w700,
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
    );
  }
}

class _LogoPanel extends StatelessWidget {
  const _LogoPanel();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x29001A4A),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/sonathix_logo.png',
          height: 84,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_rounded,
                size: 46,
                color: Colors.white.withValues(alpha: 0.95),
              ),
              const SizedBox(height: 8),
              Text(
                'SONATHIX',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThixIdStartBackdrop extends StatelessWidget {
  const _ThixIdStartBackdrop();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0A1A3A),
                    Color(0xFF0B3B8F),
                    Color(0xFF0E2C63),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -180,
            right: -120,
            child: _GlowOrb(
              size: 360,
              color: const Color(0x33FFFFFF),
            ),
          ),
          Positioned(
            bottom: -220,
            left: -140,
            child: _GlowOrb(
              size: 420,
              color: const Color(0x26000000),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
            stops: const [0, 1],
          ),
        ),
      ),
    );
  }
}
