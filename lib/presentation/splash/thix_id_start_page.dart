import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

/// Page de démarrage (Splash) THIX ID.
///
/// Objectif: afficher un écran premium "identité digitale" puis router vers la homepage.
class ThixIdStartPage extends StatefulWidget {
  const ThixIdStartPage({super.key});

  @override
  State<ThixIdStartPage> createState() => _ThixIdStartPageState();
}

class _ThixIdStartPageState extends State<ThixIdStartPage> {
  Timer? _timer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Robust on web + mobile: we delay navigation, but avoid relying on first-frame
    // callbacks which can be skipped in certain lifecycle edge cases.
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 5), _goHomeSafely);
  }

  void _goHomeSafely() {
    if (!mounted || _navigated) return;
    try {
      _navigated = true;
      final router = GoRouter.of(context);
      final current = router.routeInformationProvider.value.uri.toString();
      debugPrint('ThixIdStartPage: navigating $current -> ${AppRoutes.home}');

      // Use BuildContext extension to ensure we hit the active router.
      // (Equivalent to router.go, but safer in some nested-route contexts.)
      context.go(AppRoutes.home);
    } catch (e) {
      debugPrint('ThixIdStartPage: failed to navigate to home err=$e');
      _navigated = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep this page extremely light (fast first paint).
    return Scaffold(
      body: _ThixIdStartBackdrop(
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _goHomeSafely,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _ThixIdStartLogo(),
                    const SizedBox(height: 18),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Text(
                        'Appuyez pour continuer',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: 220,
                      height: 46,
                      child: FilledButton.icon(
                        onPressed: _goHomeSafely,
                        icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                        label: const Text('Continuer', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThixIdStartBackdrop extends StatelessWidget {
  final Widget child;
  const _ThixIdStartBackdrop({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B3B8F), Color(0xFF0A2A5C), Color(0xFF071B3A)],
              ),
            ),
          ),
        ),
        const Positioned.fill(child: _ThixIdStartWaves()),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _ThixIdStartWaves extends StatelessWidget {
  const _ThixIdStartWaves();

  @override
  Widget build(BuildContext context) {
    // Simple layered "arcs" to match the reference look without heavy assets.
    return Stack(
      children: const [
        _WaveLayer(opacity: 0.10, top: -130, size: 560),
        _WaveLayer(opacity: 0.12, top: -60, size: 520),
        _WaveLayer(opacity: 0.14, top: 10, size: 480),
        _WaveLayer(opacity: 0.16, top: 80, size: 440),
      ],
    );
  }
}

class _WaveLayer extends StatelessWidget {
  final double opacity;
  final double top;
  final double size;
  const _WaveLayer({required this.opacity, required this.top, required this.size});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: -120,
      right: -120,
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: opacity), width: 38),
          ),
        ),
      ),
    );
  }
}

class _ThixIdStartLogo extends StatelessWidget {
  const _ThixIdStartLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'THIX',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                height: 0.95,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
                color: const Color(0xFFFFD54A),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'ID',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                height: 0.95,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
                color: const Color(0xFFFFD54A),
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'Identité digitale',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
