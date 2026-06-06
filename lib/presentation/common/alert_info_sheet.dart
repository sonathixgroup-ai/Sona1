import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/models/news_item.dart';
import 'package:thix_id/services/news_service.dart';
import 'package:thix_id/supabase/supabase_config.dart';
import 'package:thix_id/theme.dart';

/// ALERT INFO
///
/// Feed d'informations institutionnelles/verified.
/// Publication réservée aux comptes Entreprise autorisés + Admins.
class AlertInfoSheet extends StatelessWidget {
  const AlertInfoSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints.tightFor(height: MediaQuery.sizeOf(context).height),
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      enableDrag: false,
      builder: (context) => const _AlertInfoSheetBody(),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _AlertInfoSheetBody extends StatefulWidget {
  const _AlertInfoSheetBody();

  @override
  State<_AlertInfoSheetBody> createState() => _AlertInfoSheetBodyState();
}

class _AlertInfoSheetBodyState extends State<_AlertInfoSheetBody> {
  final _pageController = PageController(viewportFraction: 0.92);
  Timer? _auto;
  int _page = 0;

  RealtimeChannel? _newsRealtimeChannel;
  Timer? _realtimeDebounce;

  String _selectedCategory = 'À la Une';
  String _query = '';

  bool _loading = true;
  List<NewsItem> _news = const [];
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await NewsService().listNews(limit: 200);
      if (!mounted) return;
      setState(() => _news = items);
    } catch (e) {
      debugPrint('AlertInfoSheet: load news failed err=$e');
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reloadFromRealtime() async {
    try {
      final items = await NewsService().listNews(limit: 200);
      if (!mounted) return;
      setState(() {
        _news = items;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      debugPrint('AlertInfoSheet: realtime reload failed err=$e');
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  void _scheduleRealtimeReload() {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 250), _reloadFromRealtime);
  }

  void _startRealtime() {
    try {
      final channel = SupabaseConfig.client.channel('realtime:${NewsService.table}');
      _newsRealtimeChannel = channel;

      // ✅ API Realtime moderne avec 'on' au lieu de 'onPostgresChanges'
      channel
          .on(
            'postgres_changes',
            {
              'event': '*', // '*' pour tous les événements
              'schema': 'public',
              'table': NewsService.table,
            },
            (_) {
              debugPrint('THIX INFO realtime: change detected');
              _scheduleRealtimeReload();
            },
          )
          .subscribe((status, [error]) {
            if (error != null) debugPrint('THIX INFO realtime subscribe error: $error');
            debugPrint('THIX INFO realtime status: $status');
          });
    } catch (e) {
      debugPrint('AlertInfoSheet: start realtime failed err=$e');
    }
  }

  void _stopRealtime() {
    try {
      _realtimeDebounce?.cancel();
      _realtimeDebounce = null;
      final ch = _newsRealtimeChannel;
      _newsRealtimeChannel = null;
      if (ch != null) SupabaseConfig.client.removeChannel(ch);
    } catch (e) {
      debugPrint('AlertInfoSheet: stop realtime failed err=$e');
    }
  }

  bool _isAdmin(AppUser? user) {
    const admins = <String>{'admin@thix.id', 'security@thix.id'};
    final email = (user?.email ?? '').toLowerCase().trim();
    return admins.contains(email);
  }

  List<_AlertInfoItem> _applyFilters(List<_AlertInfoItem> all) {
    final q = _query.trim().toLowerCase();
    Iterable<_AlertInfoItem> res = all;

    if (_selectedCategory == 'À la Une') {
      res = res.where((e) => e.featured);
    } else if (_selectedCategory != 'Actualités') {
      res = res.where((e) => e.category == _selectedCategory);
    }

    if (q.isNotEmpty) {
      res = res.where((e) {
        return e.title.toLowerCase().contains(q) || 
               e.subtitle.toLowerCase().contains(q) || 
               e.source.toLowerCase().contains(q);
      });
    }

    return res.toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _load();
    _startRealtime();
    _auto = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pageController.hasClients) return;
      _pageController.nextPage(duration: const Duration(milliseconds: 520), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _stopRealtime();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final gold = isDark ? DarkModeColors.metalGold : LightModeColors.metalGold;
    final cyberBg = isDark ? DarkModeColors.cyberDarkBlue : LightModeColors.background;
    final divider = isDark ? Colors.white.withValues(alpha: 0.10) : LightModeColors.divider;

    final auth = context.watch<AuthController>();
    final me = auth.currentUser;
    final canPublish = (me?.accountType == AccountType.enterprise) || _isAdmin(me);

    final allItems = _loading
        ? _AlertInfoDemoData.institutionalFeed
        : (_news.isEmpty ? _AlertInfoDemoData.institutionalFeed : _mapNewsToUi(_news));
    final items = _applyFilters(allItems);
    final featured = allItems.where((e) => e.featured).toList(growable: false);
    final categories = _AlertInfoDemoData.categories;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(0),
          border: Border.all(color: isDark ? gold.withValues(alpha: 0.32) : divider),
          color: isDark ? cyberBg.withValues(alpha: 0.86) : Colors.white.withValues(alpha: 0.96),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08), blurRadius: 36, offset: const Offset(0, 18))],
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints.tightFor(height: MediaQuery.sizeOf(context).height),
          child: Column(
            children: [
              _ThixInfoTopBar(canPublish: canPublish, email: me?.email, gold: gold),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
                child: _ThixInfoSearchBar(
                  hintText: 'Rechercher une information…',
                  onChanged: (v) => setState(() => _query = v),
                  onFilterTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Filtres: à connecter.'))),
                ),
              ),
              _CategoryTabs(
                categories: categories,
                selected: _selectedCategory,
                onSelected: (c) => setState(() => _selectedCategory = c),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.10) : LightModeColors.divider),
                        ),
                        child: Text(
                          'Supabase: ${NewsService.table} • ${_error!}',
                          style: context.textStyles.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.75), height: 1.35),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (_selectedCategory == 'À la Une' || _selectedCategory == 'Actualités') ...[
                      const _SectionTitle(title: 'À la une', subtitle: 'Informations prioritaires', icon: Icons.auto_awesome_rounded),
                      const SizedBox(height: AppSpacing.sm),
                      _FeaturedCarousel(
                        pageController: _pageController,
                        featured: featured,
                        gold: gold,
                        onIndexChanged: (idx) => setState(() => _page = idx),
                      ),
                      if (featured.length > 1) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _DotsIndicator(count: featured.length, index: _page, activeColor: gold),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _SectionTitleInline(title: 'Dernières actualités'),
                        TextButton(
                          onPressed: () => setState(() => _selectedCategory = 'Actualités'),
                          style: TextButton.styleFrom(foregroundColor: gold, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                          child: const Text('Voir tout  ›', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (items.isEmpty)
                      _EmptyResultsCard(query: _query, gold: gold)
                    else
                      for (final item in items) ...[
                        _NewsListTile(item: item),
                        const SizedBox(height: AppSpacing.md),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_AlertInfoItem> _mapNewsToUi(List<NewsItem> items) {
    String relTime(DateTime dt) {
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} min';
      if (diff.inHours < 24) return '${diff.inHours} h';
      return '${diff.inDays} j';
    }

    IconData iconFor(String category) {
      final c = category.toLowerCase();
      if (c.contains('sécur') || c.contains('security')) return Icons.shield_rounded;
      if (c.contains('alerte') || c.contains('urgent')) return Icons.warning_amber_rounded;
      if (c.contains('évén')) return Icons.event_rounded;
      if (c.contains('institution')) return Icons.account_balance_rounded;
      return Icons.campaign_rounded;
    }

    return items
        .map(
          (e) => _AlertInfoItem(
            icon: iconFor(e.category),
            title: e.title,
            subtitle: e.subtitle,
            tag: e.category,
            time: relTime(e.createdAt),
            source: e.source,
            severity: e.severity,
            category: e.category,
            featured: e.featured,
            imageAssetPath: e.imageUrl,
          ),
        )
        .toList(growable: false);
  }
}

// ... (tous les widgets restants restent identiques) ...

class _AlertInfoDemoData {
  static const categories = <String>['À la Une', 'Actualités', 'Économie', 'Politique', 'Technologie', 'Santé', 'Sécurité'];

  static const fallbackFeatured = _AlertInfoItem(
    icon: Icons.notifications_active_rounded,
    title: 'Aucune info à la une',
    subtitle: 'Les publications institutionnelles apparaîtront ici.',
    tag: 'Système',
    time: 'Maintenant',
    source: 'THIX',
    severity: 'Info',
    category: 'Actualités',
    featured: true,
  );

  static const institutionalFeed = <_AlertInfoItem>[
    // ... (contenu existant inchangé) ...
  ];
}
