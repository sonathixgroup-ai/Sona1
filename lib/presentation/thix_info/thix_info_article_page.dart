import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/models/news_item.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/presentation/admin/admin_routes.dart';
import 'package:thix_id/services/news_service.dart';
import 'package:thix_id/theme.dart';

class ThixInfoArticlePage extends StatefulWidget {
  final String id;
  const ThixInfoArticlePage({super.key, required this.id});

  @override
  State<ThixInfoArticlePage> createState() => _ThixInfoArticlePageState();
}

class _ThixInfoArticlePageState extends State<ThixInfoArticlePage> {
  bool _loading = true;
  String? _error;
  NewsItem? _item;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await NewsService().listNews(limit: 400);
      final found = items.where((e) => e.id == widget.id).toList(growable: false);
      if (!mounted) return;
      setState(() => _item = found.isEmpty ? null : found.first);
    } catch (e) {
      debugPrint('ThixInfoArticlePage: load failed err=$e');
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final gold = isDark ? DarkModeColors.metalGold : LightModeColors.metalGold;

    final item = _item;
    return Scaffold(
      backgroundColor: cs.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null)
                ? _ErrorState(error: _error!, onRetry: _load)
                : (item == null)
                    ? _NotFoundState(id: widget.id)
                    : CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, 10),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () => context.popOrGo(AppRoutes.thixInfo),
                                    icon: const Icon(Icons.arrow_back_rounded),
                                    style: IconButton.styleFrom(backgroundColor: cs.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text('THIX INFO', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                                  ),
                                  IconButton(
                                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partager (bientôt)'))),
                                    icon: const Icon(Icons.ios_share_rounded),
                                    style: IconButton.styleFrom(backgroundColor: cs.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              child: Container(
                                height: 220,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: cs.onSurface.withValues(alpha: 0.10)),
                                  color: cs.surface,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: _ThixNewsImage(
                                        url: item.imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: _ThixNewsPlaceholder(gold: gold),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: 0.10), Colors.black.withValues(alpha: 0.62)]),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 14,
                                      right: 14,
                                      bottom: 14,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(999)),
                                            child: Text(item.category.toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11)),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(item.title, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, height: 1.1)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 14, AppSpacing.md, 22),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cs.surface,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: cs.onSurface.withValues(alpha: 0.10)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.verified_rounded, color: gold, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(item.source, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900))),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(item.subtitle, style: theme.textTheme.bodyMedium?.copyWith(height: 1.55)),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: FilledButton.icon(
                                            onPressed: () => context.push('${AppRoutes.admin}/${AdminModule.news.slug}'),
                                            icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
                                            label: const Text('Espace Admin Info', style: TextStyle(color: Colors.white)),
                                            style: FilledButton.styleFrom(backgroundColor: cs.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                                          ),
                                        ),
                                      ],
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

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 32),
            const SizedBox(height: 10),
            Text('Erreur', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(error, textAlign: TextAlign.center, maxLines: 5, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

class _NotFoundState extends StatelessWidget {
  final String id;
  const _NotFoundState({required this.id});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.article_outlined, size: 32),
            const SizedBox(height: 10),
            Text('Article introuvable', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('id: $id', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => context.go(AppRoutes.thixInfo), child: const Text('Retour')),
          ],
        ),
      ),
    );
  }
}

class _ThixNewsPlaceholder extends StatelessWidget {
  final Color gold;
  const _ThixNewsPlaceholder({required this.gold});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navy = isDark ? DarkModeColors.primary : LightModeColors.primary;
    final navy2 = isDark ? DarkModeColors.cyberDarkBlue : LightModeColors.secondary;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [navy.withValues(alpha: 0.96), navy2.withValues(alpha: 0.90), gold.withValues(alpha: 0.14)]),
      ),
      child: Align(
        alignment: const Alignment(-0.88, -0.78),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: gold.withValues(alpha: 0.35)), color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.10)),
          child: Text('THIX INFO', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.92), fontWeight: FontWeight.w900, letterSpacing: 0.4)),
        ),
      ),
    );
  }
}

class _ThixNewsImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final Widget placeholder;
  const _ThixNewsImage({required this.url, required this.fit, required this.placeholder});

  @override
  Widget build(BuildContext context) {
    final u = (url ?? '').trim();
    if (u.isEmpty) return placeholder;
    if (!u.startsWith('http')) return Image.asset(u, fit: fit);
    return Image.network(
      u,
      fit: fit,
      errorBuilder: (context, error, stack) {
        debugPrint('THIX INFO image load failed url=$u err=$error');
        return placeholder;
      },
    );
  }
}
