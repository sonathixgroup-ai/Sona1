import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';

/// Lightweight chat entry screen.
///
/// The project previously included a large Riverpod-based chat module. Because
/// Dreamflow’s environment may not fetch new pub packages reliably, we keep a
/// minimal, dependency-free version here so the app compiles and navigation works.
class ChatHomeScreen extends StatelessWidget {
  const ChatHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            tooltip: 'Nouveau message',
            onPressed: () {},
            icon: Icon(Icons.edit_note_rounded, color: cs.onSurface),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.forum_rounded, size: 56, color: cs.primary),
              const SizedBox(height: 12),
              Text('THIX Chat', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Module en cours de stabilisation.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(AppRoutes.network),
                child: const Text('Aller au Network'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
