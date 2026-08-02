import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

class ThixIdStartPage extends StatefulWidget {
  const ThixIdStartPage({super.key});
  @override State<ThixIdStartPage> createState() => _ThixIdStartPageState();
}

class _ThixIdStartPageState extends State<ThixIdStartPage> {
  Timer? _timer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), _goHomeSafely);
  }

  void _goHomeSafely() {
    if (!mounted || _navigated) return;
    _navigated = true;
    context.go(AppRoutes.home);
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
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
                  children: [
                    const Spacer(),
                    // LOGO FIX - plus de 404
                    Image.asset(
                      'assets/images/sonathix_logo.png',
                      width: 120,
                      errorBuilder: (_, __, ___) => Column(
                        children: [
                          Text('THIX', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFFFFD54A))),
                          Text('ID', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFFFFD54A))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('une identité vérifiée, avenir de confiance',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, letterSpacing: 0.5)),
                    const SizedBox(height: 18),
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD54A))),
                    const SizedBox(height: 18),
                    Text('Appuyez pour continuer', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white.withOpacity(0.78), fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: 220, height: 46,
                      child: FilledButton.icon(onPressed: _goHomeSafely, icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white), label: const Text('Continuer', style: TextStyle(color: Colors.white))),
                    ),
                    const Spacer(),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text('BY SONATHIX GROUP', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2)),
                    )
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
  final Widget child; const _ThixIdStartBackdrop({required this.child});
  @override Widget build(BuildContext context) => Stack(children: [Positioned.fill(child: DecoratedBox(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0B3B8F), Color(0xFF0A2A5C), Color(0xFF071B3A)])))), const Positioned.fill(child: _ThixIdStartWaves()), Positioned.fill(child: child)]);
}
class _ThixIdStartWaves extends StatelessWidget { const _ThixIdStartWaves(); @override Widget build(BuildContext context) => const Stack(children: [_WaveLayer(opacity: 0.10, top: -130, size: 560), _WaveLayer(opacity: 0.12, top: -60, size: 520), _WaveLayer(opacity: 0.14, top: 10, size: 480), _WaveLayer(opacity: 0.16, top: 80, size: 440)]); }
class _WaveLayer extends StatelessWidget { final double opacity; final double top; final double size; const _WaveLayer({required this.opacity, required this.top, required this.size}); @override Widget build(BuildContext context) => Positioned(top: top, left: -120, right: -120, child: Center(child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(opacity), width: 38))))); }
