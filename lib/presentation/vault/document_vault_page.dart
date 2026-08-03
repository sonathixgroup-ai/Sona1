import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/services/document_service.dart';
import '../../theme.dart';

const Color _facebookBlue = Color(0xFF1877F2);

// =============================================================
// Widgets réutilisables
// =============================================================

class CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: selected ? _facebookBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? Colors.transparent : context.theme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : LightModeColors.secondaryText),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: context.textStyles.labelSmall?.copyWith(
                color: selected ? Colors.white : LightModeColors.secondaryText,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DocItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  const DocItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_facebookBlue, Color(0xFF0D65D9)],
                ),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textStyles.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.theme.colorScheme.onSurface,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: LightModeColors.secondaryText,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  trailing!,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: LightModeColors.secondaryText,
                    fontSize: 10,
                  ),
                ),
              ),
            if (onMore != null)
              IconButton(
                icon: const Icon(Icons.more_vert, color: LightModeColors.secondaryText, size: 18),
                onPressed: onMore,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// PAGE PRINCIPALE
// =============================================================

class DocumentVaultPage extends StatefulWidget {
  const DocumentVaultPage({super.key});

  @override
  State<DocumentVaultPage> createState() => _DocumentVaultPageState();
}

class _DocumentVaultPageState extends State<DocumentVaultPage>
    with SingleTickerProviderStateMixin {
  final _docs = DocumentService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(
        uri,
        mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
        webOnlyWindowName: kIsWeb ? '_blank' : null,
      );
      if (!ok) throw Exception('launch failed');
    } catch (e) {
      debugPrint('Vault: openUrl failed url=$url err=$e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ouverture impossible.')),
      );
    }
  }

  Future<void> _openDoc(Map<String, dynamic> row) async {
    try {
      final url = await _docs.resolveRowDownloadUrl(row);
      if (url.trim().isEmpty) throw Exception('URL vide');
      await _openUrl(url);
    } catch (e) {
      debugPrint('Vault: openDoc failed err=$e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Téléchargement / ouverture impossible.')),
      );
    }
  }

  IconData _iconForMime(String? mime) {
    final m = (mime ?? '').toLowerCase();
    if (m.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (m.contains('image')) return Icons.image_rounded;
    return Icons.description_rounded;
  }

  String _formatDate(dynamic createdAt) {
    final date = createdAt is DateTime
        ? createdAt
        : (createdAt is String)
            ? DateTime.tryParse(createdAt)
            : null;
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatSize(int sizeBytes) {
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ---------------------------------------------------------------------------
  // DÉPÔT
  // ---------------------------------------------------------------------------

  Future<void> _pickAndUpload() async {
    final me = context.read<AuthController>().currentUser;
    if (me == null) return;

    final picked = await FilePicker.platform.pickFiles(withData: kIsWeb);
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;

    if (!mounted) return;
    final res = await showModalBottomSheet<_UploadDocPayload>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UploadDocumentSheet(fileName: file.name),
    );
    if (res == null) return;

    try {
      final generatedId = await _docs.uploadPickedFileSimple(
        uid: me.id,
        file: file,
        docType: res.docType,
        expiresAt: res.expiresAt,
        title: res.title,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document déposé • $generatedId')),
      );
    } catch (e) {
      debugPrint('Vault: upload failed err=$e');
      if (!mounted) return;
      final msg = DocumentService.isBucketNotFound(e)
          ? 'Upload impossible : bucket Storage manquant ("${DocumentService.bucket}").'
          : 'Upload impossible.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ---------------------------------------------------------------------------
  // ENVOYER
  // ---------------------------------------------------------------------------

  Future<void> _openSendSheet() async {
    final me = context.read<AuthController>().currentUser;
    if (me == null) return;

    final docs = await _docs.fetchDocuments(me.id, limit: 50);
    if (!mounted) return;

    if (docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun document à envoyer. Déposez-en un d\'abord.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SendDocumentSheet(
        documents: docs,
        onSend: (payload) async {
          try {
            await _docs.shareDocument(
              senderId: me.id,
              documentId: payload.documentId,
              recipientThixIds: payload.recipients,
              subject: payload.subject,
              body: payload.body,
              password: payload.password,
              availableFrom: payload.availableFrom,
              autoDestructAt: payload.autoDestructAt,
            );
            if (!mounted) return;
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Document envoyé.')),
            );
          } catch (e) {
            debugPrint('Vault: share failed err=$e');
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Envoi impossible : $e')),
            );
          }
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MENU DOCUMENT
  // ---------------------------------------------------------------------------

  Future<void> _showDocMenu({required Map<String, dynamic> row}) async {
    final title = (row['title'] as String?) ?? 'Document';
    final storagePath = (row['storage_path'] as String?) ?? '';
    final me = context.read<AuthController>().currentUser;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: context.theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.lg),
              topRight: Radius.circular(AppRadius.lg),
            ),
            border: Border.all(color: context.theme.dividerColor),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: context.textStyles.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton.icon(
                onPressed: () => _openDoc(row),
                icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 16),
                label: const Text('Ouvrir', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _facebookBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: me == null
                    ? null
                    : () async {
                        try {
                          final docRowId = (row['id'] ?? '').toString();
                          if (docRowId.trim().isEmpty) throw Exception('id manquant');
                          await _docs.deleteDocument(
                            uid: me.id,
                            documentId: docRowId,
                            storagePath: storagePath,
                          );
                          if (!mounted) return;
                          context.pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Document supprimé.')),
                          );
                        } catch (e) {
                          debugPrint('Vault: delete failed err=$e');
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Suppression impossible.')),
                          );
                        }
                      },
                icon: Icon(Icons.delete_outline_rounded,
                    color: context.theme.colorScheme.error, size: 16),
                label: Text(
                  'Supprimer',
                  style: context.textStyles.labelMedium?.copyWith(
                    color: context.theme.colorScheme.error,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: context.theme.colorScheme.error.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().currentUser;

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== HEADER =====
            Container(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: _facebookBlue,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadius.lg),
                  bottomRight: Radius.circular(AppRadius.lg),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 18),
                          onPressed: () {
                            final auth = context.read<AuthController>();
                            if (auth.isAuthenticated) {
                              final t = auth.currentUser?.accountType;
                              context.go(t == AccountType.enterprise
                                  ? AppRoutes.enterpriseDashboard
                                  : AppRoutes.userDashboard);
                              return;
                            }
                            context.go(AppRoutes.home);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Text(
                          "THIX VAULT",
                          style: context.textStyles.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Onglets
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        labelColor: _facebookBlue,
                        unselectedLabelColor: Colors.white70,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Dépôt'),
                          Tab(text: 'Envoyer'),
                          Tab(text: 'Reçu'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===== CONTENU DES ONGLETS =====
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ---------- ONGLET DÉPÔT ----------
                  _DepotTab(
                    me: me,
                    docsService: _docs,
                    iconForMime: _iconForMime,
                    formatDate: _formatDate,
                    formatSize: _formatSize,
                    onOpenDoc: _openDoc,
                    onMore: (row) => _showDocMenu(row: row),
                    onDeposit: _pickAndUpload,
                  ),

                  // ---------- ONGLET ENVOYER ----------
                  _EnvoyerTab(
                    me: me,
                    onOpenSend: _openSendSheet,
                  ),

                  // ---------- ONGLET REÇU ----------
                  _RecuTab(
                    me: me,
                    docsService: _docs,
                    onOpenDoc: _openDoc,
                    formatDate: _formatDate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _pickAndUpload,
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              label: Text(
                "DÉPOSER",
                style: context.textStyles.labelLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              backgroundColor: _facebookBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            )
          : null,
    );
  }
}

// =============================================================
// ONGLET DÉPÔT
// =============================================================

class _DepotTab extends StatelessWidget {
  final AppUser? me;
  final DocumentService docsService;
  final IconData Function(String?) iconForMime;
  final String Function(dynamic) formatDate;
  final String Function(int) formatSize;
  final Future<void> Function(Map<String, dynamic>) onOpenDoc;
  final void Function(Map<String, dynamic>) onMore;
  final VoidCallback onDeposit;

  const _DepotTab({
    required this.me,
    required this.docsService,
    required this.iconForMime,
    required this.formatDate,
    required this.formatSize,
    required this.onOpenDoc,
    required this.onMore,
    required this.onDeposit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Catégories",
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Icon(Icons.tune_rounded, color: LightModeColors.secondaryText, size: 16),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                CategoryChip(icon: Icons.folder_rounded, label: "Tout", selected: true),
                CategoryChip(icon: Icons.account_balance_rounded, label: "Identité", selected: false),
                CategoryChip(icon: Icons.school_rounded, label: "Diplômes", selected: false),
                CategoryChip(icon: Icons.description_rounded, label: "Certificats", selected: false),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Mes documents",
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  "Voir tout",
                  style: context.textStyles.labelMedium?.copyWith(
                    color: _facebookBlue,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (me == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Connectez-vous pour voir vos documents.',
                style: context.textStyles.bodyMedium?.copyWith(
                  color: LightModeColors.secondaryText,
                  fontSize: 13,
                ),
              ),
            )
          else
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: docsService.streamDocuments(me!.id),
              builder: (context, snap) {
                final docs = snap.data ?? const <Map<String, dynamic>>[];
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Aucun document.',
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: LightModeColors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: onDeposit,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Déposer mon premier document'),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: docs.map<Widget>((data) {
                    final title = (data['title'] as String?) ??
                        (data['generated_doc_id'] as String?) ??
                        (data['doc_id'] as String?) ??
                        'Document';
                    final mime = (data['mime_type'] as String?) ?? (data['mimeType'] as String?);
                    final sizeBytes =
                        (data['size_bytes'] as num?)?.toInt() ?? (data['sizeBytes'] as num?)?.toInt() ?? 0;
                    final dateStr = formatDate(data['created_at']);
                    final sizeStr = formatSize(sizeBytes);
                    final docId = (data['generated_doc_id'] as String?) ??
                        (data['doc_id'] as String?) ??
                        '';

                    return DocItem(
                      icon: iconForMime(mime),
                      title: title,
                      subtitle: '$dateStr • $sizeStr${docId.isNotEmpty ? ' • $docId' : ''}',
                      onTap: () => onOpenDoc(data),
                      onMore: () => onMore(data),
                    );
                  }).toList(growable: false),
                );
              },
            ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: _facebookBlue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _facebookBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.verified_user_rounded, color: _facebookBlue, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SÉCURITÉ INSTITUTIONNELLE",
                        style: context.textStyles.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Chiffrement AES-256. Vos données ne quittent jamais le territoire.",
                        style: context.textStyles.bodySmall?.copyWith(
                          color: LightModeColors.secondaryText,
                          fontSize: 10,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// =============================================================
// ONGLET ENVOYER
// =============================================================

class _EnvoyerTab extends StatelessWidget {
  final AppUser? me;
  final VoidCallback onOpenSend;

  const _EnvoyerTab({required this.me, required this.onOpenSend});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_rounded, size: 48, color: _facebookBlue.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(
              'Envoyer un document sécurisé',
              style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Mot de passe • Auto-destruction • Disponibilité différée\nNotification de capture d\'écran',
              style: context.textStyles.bodySmall?.copyWith(
                color: LightModeColors.secondaryText,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: me == null ? null : onOpenSend,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('NOUVEL ENVOI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _facebookBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// ONGLET REÇU
// =============================================================

class _RecuTab extends StatelessWidget {
  final AppUser? me;
  final DocumentService docsService;
  final Future<void> Function(Map<String, dynamic>) onOpenDoc;
  final String Function(dynamic) formatDate;

  const _RecuTab({
    required this.me,
    required this.docsService,
    required this.onOpenDoc,
    required this.formatDate,
  });

  Future<void> _handleOpenShare(BuildContext context, Map<String, dynamic> share) async {
    final status = (share['status'] as String?) ?? 'pending';
    final availableFromRaw = share['available_from'];
    final autoDestructRaw = share['auto_destruct_at'];
    final hasPassword = (share['password_hash'] as String?)?.isNotEmpty == true;
    final shareId = share['id']?.toString();
    final documentId = share['document_id']?.toString();

    if (shareId == null || documentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Données du partage invalides.')),
      );
      return;
    }

    if (autoDestructRaw != null) {
      final autoAt = DateTime.tryParse(autoDestructRaw.toString());
      if (autoAt != null && autoAt.isBefore(DateTime.now())) {
        await docsService.markShareDestroyed(shareId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ce document a été auto-détruit.')),
        );
        return;
      }
    }

    if (status == 'pending' || status == 'available') {
      if (availableFromRaw != null) {
        final avail = DateTime.tryParse(availableFromRaw.toString());
        if (avail != null && avail.isAfter(DateTime.now())) {
          final d = '${avail.day.toString().padLeft(2, '0')}/${avail.month.toString().padLeft(2, '0')}/${avail.year}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Document disponible à partir du $d.')),
          );
          return;
        }
      }
    }

    if (status == 'destroyed' || status == 'expired') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce document n\'est plus disponible.')),
      );
      return;
    }

    String? enteredPassword;
    if (hasPassword) {
      enteredPassword = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final ctrl = TextEditingController();
          return AlertDialog(
            title: const Text('Mot de passe requis'),
            content: TextField(
              controller: ctrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text),
                style: ElevatedButton.styleFrom(backgroundColor: _facebookBlue),
                child: const Text('Ouvrir', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );

      if (enteredPassword == null) return;

      final stored = share['password_hash'] as String?;
      if (stored != enteredPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mot de passe incorrect.')),
        );
        return;
      }
    }

    try {
      final docRow = await docsService.fetchDocumentById(documentId);
      if (docRow == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document introuvable.')),
        );
        return;
      }

      await docsService.markShareOpened(shareId);
      await onOpenDoc(docRow);
    } catch (e) {
      debugPrint('Open received share failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir le document.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (me == null) {
      return const Center(child: Text('Connectez-vous pour voir les documents reçus.'));
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: docsService.streamReceivedShares(me!.id, me!.thixId),
      builder: (context, snap) {
        final shares = snap.data ?? [];
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (shares.isEmpty) {
          return Center(
            child: Text(
              'Aucun document reçu.',
              style: context.textStyles.bodyMedium?.copyWith(
                color: LightModeColors.secondaryText,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: shares.length,
          itemBuilder: (context, i) {
            final s = shares[i];
            final subject = (s['subject'] as String?)?.trim().isNotEmpty == true
                ? s['subject'] as String
                : 'Document partagé';
            final status = (s['status'] as String?) ?? 'pending';
            final hasPassword = (s['password_hash'] as String?)?.isNotEmpty == true;
            final screenshotCount = (s['screenshot_count'] as num?)?.toInt() ?? 0;

            String statusLabel;
            switch (status) {
              case 'available':
                statusLabel = 'Disponible';
                break;
              case 'opened':
                statusLabel = 'Ouvert';
                break;
              case 'pending':
                statusLabel = 'Verrouillé';
                break;
              case 'expired':
                statusLabel = 'Expiré';
                break;
              case 'destroyed':
                statusLabel = 'Détruit';
                break;
              default:
                statusLabel = status;
            }

            return DocItem(
              icon: Icons.mail_outline_rounded,
              title: subject,
              subtitle:
                  '${formatDate(s['created_at'])}'
                  '${hasPassword ? ' • 🔒' : ''}'
                  '${screenshotCount > 0 ? ' • 📸 $screenshotCount' : ''}',
              trailing: statusLabel,
              onTap: () => _handleOpenShare(context, s),
            );
          },
        );
      },
    );
  }
}

// =============================================================
// SHEET : DÉPÔT (simplifié – type uniquement)
// =============================================================

class _UploadDocPayload {
  final String docType;
  final String? title;
  final DateTime? expiresAt;
  const _UploadDocPayload({required this.docType, this.title, this.expiresAt});
}

class _UploadDocumentSheet extends StatefulWidget {
  final String fileName;
  const _UploadDocumentSheet({required this.fileName});

  @override
  State<_UploadDocumentSheet> createState() => _UploadDocumentSheetState();
}

class _UploadDocumentSheetState extends State<_UploadDocumentSheet> {
  String _type = 'Autre';
  DateTime? _expiresAt;
  final _titleC = TextEditingController();

  @override
  void dispose() {
    _titleC.dispose();
    super.dispose();
  }

  bool get _needsExpiry =>
      _type == 'CIN' || _type == 'Passeport' || _type == 'Permis';

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 20)),
      lastDate: now.add(const Duration(days: 365 * 50)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: _facebookBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _expiresAt = DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final expiryLabel = _expiresAt == null
        ? 'Choisir une date'
        : '${_expiresAt!.year.toString().padLeft(4, '0')}-${_expiresAt!.month.toString().padLeft(2, '0')}-${_expiresAt!.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        decoration: BoxDecoration(
          color: context.theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.lg),
            topRight: Radius.circular(AppRadius.lg),
          ),
          border: Border.all(color: context.theme.dividerColor),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Déposer un document',
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
            Text(
              widget.fileName,
              style: context.textStyles.bodySmall?.copyWith(
                color: LightModeColors.secondaryText,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'L\'identifiant unique sera généré automatiquement\n(THIX-DOC-MMAAAA-XXXXXX-XXX/CC)',
              style: context.textStyles.bodySmall?.copyWith(
                color: LightModeColors.secondaryText,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              value: _type,
              items: const [
                DropdownMenuItem(value: 'CIN', child: Text('Pièce d\'identité — CIN')),
                DropdownMenuItem(value: 'Passeport', child: Text('Pièce d\'identité — Passeport')),
                DropdownMenuItem(value: 'Permis', child: Text('Pièce d\'identité — Permis')),
                DropdownMenuItem(value: 'Diplôme', child: Text('Diplôme / Attestation')),
                DropdownMenuItem(value: 'PreuveAdresse', child: Text('Preuve d\'adresse')),
                DropdownMenuItem(value: 'Autre', child: Text('Autre')),
              ],
              onChanged: (v) => setState(() {
                _type = v ?? 'Autre';
                if (!_needsExpiry) _expiresAt = null;
              }),
              decoration: InputDecoration(
                labelText: 'Type de document',
                prefixIcon: const Icon(Icons.folder_rounded, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _titleC,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Titre (optionnel)',
                hintText: 'Ex: Carte d\'identité nationale',
                prefixIcon: const Icon(Icons.description_rounded, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            if (_needsExpiry) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: _pickExpiry,
                  icon: const Icon(Icons.event_available_rounded, size: 16),
                  label: Text('Date d\'expiration: $expiryLabel', style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.theme.colorScheme.primary,
                    side: BorderSide(color: context.theme.colorScheme.primary, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_needsExpiry && _expiresAt == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Date d\'expiration requise pour cette pièce.')),
                    );
                    return;
                  }
                  context.pop(_UploadDocPayload(
                    docType: _type,
                    title: _titleC.text.trim().isEmpty ? null : _titleC.text.trim(),
                    expiresAt: _expiresAt,
                  ));
                },
                icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
                label: const Text('DÉPOSER', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _facebookBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
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

// =============================================================
// SHEET : ENVOI
// =============================================================

class _SendPayload {
  final String documentId;
  final List<String> recipients;
  final String? subject;
  final String? body;
  final String? password;
  final DateTime? availableFrom;
  final DateTime? autoDestructAt;

  const _SendPayload({
    required this.documentId,
    required this.recipients,
    this.subject,
    this.body,
    this.password,
    this.availableFrom,
    this.autoDestructAt,
  });
}

class _SendDocumentSheet extends StatefulWidget {
  final List<Map<String, dynamic>> documents;
  final Future<void> Function(_SendPayload) onSend;

  const _SendDocumentSheet({
    required this.documents,
    required this.onSend,
  });

  @override
  State<_SendDocumentSheet> createState() => _SendDocumentSheetState();
}

class _SendDocumentSheetState extends State<_SendDocumentSheet> {
  String? _selectedDocId;
  final _recipientsC = TextEditingController();
  final _subjectC = TextEditingController();
  final _bodyC = TextEditingController();
  final _passwordC = TextEditingController();
  DateTime? _availableFrom;
  DateTime? _autoDestructAt;
  bool _sending = false;

  @override
  void dispose() {
    _recipientsC.dispose();
    _subjectC.dispose();
    _bodyC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isAvailableFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isAvailableFrom) {
          _availableFrom = DateTime(picked.year, picked.month, picked.day);
        } else {
          _autoDestructAt = DateTime(picked.year, picked.month, picked.day, 23, 59);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: context.theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.lg),
            topRight: Radius.circular(AppRadius.lg),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Envoyer un document',
                    style: context.textStyles.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: _selectedDocId,
                decoration: InputDecoration(
                  labelText: 'Document à envoyer',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                items: widget.documents.map((d) {
                  final id = d['id'].toString();
                  final title = (d['title'] as String?) ??
                      (d['generated_doc_id'] as String?) ??
                      'Document';
                  return DropdownMenuItem(value: id, child: Text(title, overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (v) => setState(() => _selectedDocId = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _recipientsC,
                decoration: InputDecoration(
                  labelText: 'THIX ID destinataires',
                  hintText: 'THIX-XXXX, THIX-YYYY (séparés par virgule)',
                  prefixIcon: const Icon(Icons.people_outline, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _subjectC,
                decoration: InputDecoration(
                  labelText: 'Objet',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _bodyC,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _passwordC,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mot de passe (optionnel)',
                  prefixIcon: const Icon(Icons.lock_outline, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(isAvailableFrom: true),
                      icon: const Icon(Icons.schedule, size: 16),
                      label: Text(
                        _availableFrom == null
                            ? 'Disponible dès'
                            : '${_availableFrom!.day}/${_availableFrom!.month}/${_availableFrom!.year}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(isAvailableFrom: false),
                      icon: const Icon(Icons.timer_off_outlined, size: 16),
                      label: Text(
                        _autoDestructAt == null
                            ? 'Auto-destruction'
                            : '${_autoDestructAt!.day}/${_autoDestructAt!.month}/${_autoDestructAt!.year}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _sending
                      ? null
                      : () async {
                          if (_selectedDocId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sélectionnez un document.')),
                            );
                            return;
                          }
                          final recipients = _recipientsC.text
                              .split(RegExp(r'[,;\s]+'))
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          if (recipients.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Indiquez au moins un THIX ID.')),
                            );
                            return;
                          }

                          setState(() => _sending = true);
                          await widget.onSend(_SendPayload(
                            documentId: _selectedDocId!,
                            recipients: recipients,
                            subject: _subjectC.text.trim().isEmpty ? null : _subjectC.text.trim(),
                            body: _bodyC.text.trim().isEmpty ? null : _bodyC.text.trim(),
                            password: _passwordC.text.trim().isEmpty ? null : _passwordC.text.trim(),
                            availableFrom: _availableFrom,
                            autoDestructAt: _autoDestructAt,
                          ));
                          if (mounted) setState(() => _sending = false);
                        },
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_sending ? 'Envoi...' : 'ENVOYER'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _facebookBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension ThemeHelper on BuildContext {
  ThemeData get theme => Theme.of(this);
}
