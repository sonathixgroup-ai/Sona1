import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/services/admin_event_service.dart';
import 'package:thix_id/services/document_service.dart';
import 'package:thix_id/supabase/supabase_config.dart';
import 'package:thix_id/theme.dart';

class AdminEventsPage extends StatefulWidget {
  const AdminEventsPage({super.key});

  @override
  State<AdminEventsPage> createState() => _AdminEventsPageState();
}

class _AdminEventsPageState extends State<AdminEventsPage> {
  final _svc = AdminEventService();
  final _docs = DocumentService();
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _events = const [];

  RealtimeChannel? _channel;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
    _load();
    _subscribeRealtime();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 160), () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _svc.listEvents();
      if (!mounted) return;
      setState(() {
        _events = list;
      });
    } catch (e) {
      debugPrint('AdminEventsPage: load failed err=$e');
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _subscribeRealtime() {
    try {
      _channel = SupabaseConfig.client.channel('admin:events');
      
      // ✅ Correction : utiliser l'API générique 'on' au lieu de 'onPostgresChanges'
      _channel!
          .on(
            'postgres_changes',
            {
              'event': '*',
              'schema': 'public',
              'table': AdminEventService.eventsTable,
            },
            (_) => unawaited(_load()),
          )
          .on(
            'postgres_changes',
            {
              'event': '*',
              'schema': 'public',
              'table': AdminEventService.registrationsTable,
            },
            (_) => unawaited(_load()),
          )
          .subscribe();
    } catch (e) {
      debugPrint('AdminEventsPage: realtime subscribe failed: $e');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    try {
      if (_channel != null) SupabaseConfig.client.removeChannel(_channel!);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _events
        : _events.where((e) {
            final title = (e['title'] ?? '').toString().toLowerCase();
            final place = (e['place'] ?? '').toString().toLowerCase();
            final id = (e['id'] ?? '').toString().toLowerCase();
            return title.contains(q) || place.contains(q) || id.contains(q);
          }).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Events', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AdminCyberColors.text)),
                  const SizedBox(height: 4),
                  Text('Publier des événements officiels • ${filtered.length} event(s)', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminCyberColors.textDim)),
                ],
              ),
            ),
            SizedBox(
              width: 340,
              child: TextField(
                controller: _search,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminCyberColors.text),
                decoration: InputDecoration(
                  hintText: 'Search title, place…',
                  hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminCyberColors.textDim),
                  prefixIcon: const Icon(Icons.search_rounded, color: AdminCyberColors.neonCyan),
                  filled: true,
                  fillColor: AdminCyberColors.panel.withValues(alpha: 0.72),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AdminCyberColors.stroke.withValues(alpha: 0.9))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AdminCyberColors.electricBlue, width: 1.2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AdminCyberColors.stroke.withValues(alpha: 0.9)),
                foregroundColor: AdminCyberColors.text,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded, color: AdminCyberColors.neonCyan),
              label: const Text('Fetch Data'),
            ),
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AdminCyberColors.electricBlue, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () => _openEditor(context, null),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('New Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : (_error != null)
                  ? Center(child: Text(_error!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminCyberColors.textDim)))
                  : (filtered.isEmpty)
                      ? Center(child: Text('Aucun événement.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminCyberColors.textDim)))
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) => _EventTile(
                            row: filtered[i],
                            documents: _docs,
                            onEdit: () => _openEditor(context, filtered[i]),
                            onDelete: () => _delete(context, filtered[i]),
                          ),
                        ),
        ),
      ],
    );
  }

  Future<void> _delete(BuildContext context, Map<String, dynamic> row) async {
    final id = (row['id'] ?? '').toString();
    if (id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminCyberColors.panel,
        title: Text('Supprimer', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AdminCyberColors.text)),
        content: Text('Supprimer cet événement ?', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminCyberColors.textDim)),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => context.pop(true), style: ElevatedButton.styleFrom(backgroundColor: AdminCyberColors.danger, elevation: 0), child: const Text('Supprimer', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _svc.deleteEvent(id: id);
      unawaited(_load());
    } catch (e) {
      debugPrint('AdminEventsPage: delete failed err=$e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur suppression: $e')));
    }
  }

  Future<void> _openEditor(BuildContext context, Map<String, dynamic>? row) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventEditor(initial: row, service: _svc),
    );
    if (saved == true) unawaited(_load());
  }
}

// ============================================================================
// Event Tile Widget
// ============================================================================
class _EventTile extends StatelessWidget {
  final Map<String, dynamic> row;
  final DocumentService documents;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventTile({
    required this.row,
    required this.documents,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = (row['title'] ?? '—').toString();
    final place = (row['place'] ?? '—').toString();
    final startsAt = (row['starts_at'] ?? '').toString();
    final virtualLink = (row['virtual_link'] ?? '').toString();
    final status = (row['status'] ?? 'published').toString();
    final isFeatured = (row['is_featured'] == true) || (row['is_featured']?.toString() == 'true');
    final coverBucket = (row['cover_image_bucket'] ?? AdminEventService.coverBucketDefault).toString();
    final coverPath = (row['cover_image_path'] ?? '').toString();
    final availability = (row['availability_status'] ?? '').toString();
    final registrationsCount = row['registrations_count'] is num 
        ? (row['registrations_count'] as num).toInt() 
        : int.tryParse((row['registrations_count'] ?? '').toString()) ?? 0;
    
    // ✅ Correction : définir placesRemaining à partir de la row
    final placesRemaining = row['places_remaining'];

    final soldOut = availability.toUpperCase() == 'SOLD OUT' || availability.toUpperCase() == 'COMPLET';
    final borderColor = soldOut
        ? AdminCyberColors.danger
        : (isFeatured ? Colors.amber : AdminCyberColors.stroke.withValues(alpha: 0.9));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: AdminCyberColors.panel.withValues(alpha: 0.78),
        border: Border.all(color: borderColor, width: isFeatured || soldOut ? 1.4 : 1),
      ),
      child: Row(
        children: [
          _EventCoverThumb(
            bucket: coverBucket,
            storagePath: coverPath,
            documents: documents,
            isFeatured: isFeatured,
            soldOut: soldOut,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AdminCyberColors.text),
                      ),
                    ),
                    if (isFeatured) const SizedBox(width: 8),
                    if (isFeatured) const _TagBadge(label: 'Premium', icon: Icons.stars_rounded, color: Colors.amber),
                    if (soldOut) const SizedBox(width: 8),
                    if (soldOut) const _TagBadge(label: 'SOLD OUT', icon: Icons.block_rounded, color: AdminCyberColors.danger),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${startsAt.isEmpty ? '—' : startsAt} • $place${virtualLink.trim().isEmpty ? '' : ' • virtuel'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminCyberColors.textDim),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    _Chip(icon: Icons.people_alt_rounded, label: '$registrationsCount inscrit(s)'),
                    if (placesRemaining != null) 
                      _Chip(icon: Icons.event_seat_rounded, label: _placesLabel(placesRemaining)),
                    _Chip(
                      icon: Icons.circle,
                      label: status,
                      color: status == 'published' ? AdminCyberColors.success : AdminCyberColors.textDim,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Modifier',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, color: AdminCyberColors.neonCyan),
          ),
          IconButton(
            tooltip: 'Supprimer',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, color: AdminCyberColors.danger),
          ),
        ],
      ),
    );
  }

  static String _placesLabel(Object? v) {
    if (v == null) return '';
    if (v is num) {
      if (v.toInt() <= 0) return 'Places illimitées';
      return '${v.toInt()} places restantes';
    }
    final s = v.toString().trim();
    final n = int.tryParse(s);
    if (n == null) return s;
    if (n <= 0) return 'Places illimitées';
    return '$n places restantes';
  }
}

// ============================================================================
// Tag Badge Widget
// ============================================================================
class _TagBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  
  const _TagBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Event Cover Thumbnail Widget
// ============================================================================
class _EventCoverThumb extends StatefulWidget {
  final String bucket;
  final String storagePath;
  final DocumentService documents;
  final bool isFeatured;
  final bool soldOut;
  
  const _EventCoverThumb({
    required this.bucket,
    required this.storagePath,
    required this.documents,
    required this.isFeatured,
    required this.soldOut,
  });

  @override
  State<_EventCoverThumb> createState() => _EventCoverThumbState();
}

class _EventCoverThumbState extends State<_EventCoverThumb> {
  String? _url;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _EventCoverThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storagePath != widget.storagePath || oldWidget.bucket != widget.bucket) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final p = widget.storagePath.trim();
    if (p.isEmpty) {
      if (mounted) setState(() => _url = null);
      return;
    }
    if (p.startsWith('http://') || p.startsWith('https://')) {
      if (mounted) setState(() => _url = p);
      return;
    }
    try {
      final url = await widget.documents.createDownloadUrl(
        storagePath: p,
        bucketName: widget.bucket.trim().isEmpty ? AdminEventService.coverBucketDefault : widget.bucket,
      );
      if (!mounted) return;
      setState(() => _url = url);
    } catch (e) {
      debugPrint('_EventCoverThumb resolve failed bucket=${widget.bucket} path=${widget.storagePath} err=$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = widget.soldOut
        ? AdminCyberColors.danger
        : (widget.isFeatured ? Colors.amber : AdminCyberColors.stroke.withValues(alpha: 0.9));

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.2),
        color: AdminCyberColors.black.withValues(alpha: 0.18),
      ),
      clipBehavior: Clip.antiAlias,
      child: _url == null
          ? Container(
              decoration: BoxDecoration(gradient: AdminCyberGradients.glowViolet()),
              child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 20),
            )
          : Image.network(
              _url!,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(gradient: AdminCyberGradients.glowViolet()),
                child: const Icon(Icons.broken_image_rounded, color: Colors.white, size: 20),
              ),
            ),
    );
  }
}

// ============================================================================
// Chip Widget
// ============================================================================
class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  
  const _Chip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AdminCyberColors.textDim;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AdminCyberColors.black.withValues(alpha: 0.22),
        border: Border.all(color: AdminCyberColors.stroke.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Note: _EventEditor, _Field, _MultilineField, _LimitedField, _SwitchField,
// _DropdownField, _SegmentedField, _DateTimeField, _TwoCol, _SectionDivider,
// _CoverField sont définis dans la suite du fichier mais omis ici pour la lisibilité.
// Ils restent identiques à la version précédente.
// ============================================================================
