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

// Couleur bleue Facebook
const Color _facebookBlue = Color(0xFF1877F2);

class CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const CategoryChip({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Icon(
            icon,
            size: 14, // plus petit
            color: selected ? Colors.white : LightModeColors.secondaryText,
          ),
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
    );
  }
}

class DocItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String date;
  final String size;
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  const DocItem({
    super.key,
    required this.icon,
    required this.title,
    required this.date,
    required this.size,
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
                  Row(
                    children: [
                      Text(
                        date,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: LightModeColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: context.theme.dividerColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        size,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: LightModeColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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

class DocumentVaultPage extends StatefulWidget {
  const DocumentVaultPage({super.key});

  @override
  State<DocumentVaultPage> createState() => _DocumentVaultPageState();
}

class _DocumentVaultPageState extends State<DocumentVaultPage> {
  final _docs = DocumentService();

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
      await _docs.uploadPickedFile(uid: me.id, docId: res.docId, title: res.title, file: file, docType: res.docType, expiresAt: res.expiresAt);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploadé.')));
    } catch (e) {
      debugPrint('Vault: upload failed err=$e');
      if (!mounted) return;
      final msg = DocumentService.isBucketNotFound(e)
          ? 'Upload impossible : bucket Storage manquant ("${DocumentService.bucket}").'
          : 'Upload impossible.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(
        uri,
        mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
        webOnlyWindowName: kIsWeb ? '_blank' : null,
      );
      if (!ok) {
        throw Exception('launch failed');
      }
    } catch (e) {
      debugPrint('Vault: openUrl failed url=$url err=$e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ouverture impossible.')));
    }
  }

  Future<void> _openDoc(Map<String, dynamic> row) async {
    try {
      final url = await _docs.resolveRowDownloadUrl(row);
      if (url.trim().isEmpty) throw Exception('URL vide');
      await _openUrl(url);
    } catch (e) {
      debugPrint('Vault: openDoc failed err=$e rowKeys=${row.keys.toList()}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Téléchargement / ouverture impossible.')));
    }
  }

  IconData _iconForMime(String? mime) {
    final m = (mime ?? '').toLowerCase();
    if (m.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (m.contains('image')) return Icons.image_rounded;
    return Icons.description_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().currentUser;
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête réduit
            Container(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                          onPressed: () {
                            final auth = context.read<AuthController>();
                            if (auth.isAuthenticated) {
                              final t = auth.currentUser?.accountType;
                              context.go(t == AccountType.enterprise ? AppRoutes.enterpriseDashboard : AppRoutes.userDashboard);
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
                    // Espace de stockage (simplifié, sans mock-up)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Stockage sécurisé",
                                style: context.textStyles.labelSmall?.copyWith(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                "Documents chiffrés",
                                style: context.textStyles.bodySmall?.copyWith(
                                  color: Colors.white60,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              "GÉRER",
                              style: context.textStyles.labelSmall?.copyWith(
                                color: _facebookBlue,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    // Catégories
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Catégories",
                              style: context.textStyles.titleSmall?.copyWith(
                                color: context.theme.colorScheme.onSurface,
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
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Liste des documents
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Documents Certifiés",
                              style: context.textStyles.titleSmall?.copyWith(
                                color: context.theme.colorScheme.onSurface,
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
                            child: Text('Connectez-vous pour voir vos documents.', style: context.textStyles.bodyMedium?.copyWith(color: LightModeColors.secondaryText, fontSize: 13)),
                          )
                        else
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _docs.streamDocuments(me.id),
                            builder: (context, snap) {
                              final docs = snap.data ?? const <Map<String, dynamic>>[];
                              if (snap.connectionState == ConnectionState.waiting) {
                                return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                              }
                              if (docs.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text('Aucun document.', style: context.textStyles.bodyMedium?.copyWith(color: LightModeColors.secondaryText, fontSize: 13)),
                                );
                              }
                              return Column(
                                children: docs.map<Widget>((data) {
                                  final title = (data['title'] as String?) ?? 'Document';
                                  final url = (data['download_url'] as String?) ?? (data['downloadUrl'] as String?) ?? '';
                                  final storagePath = (data['storage_path'] as String?) ?? (data['storagePath'] as String?) ?? '';
                                  final mime = (data['mime_type'] as String?) ?? (data['mimeType'] as String?);
                                  final sizeBytes = (data['size_bytes'] as num?)?.toInt() ?? (data['sizeBytes'] as num?)?.toInt() ?? 0;
                                  final createdAt = data['created_at'];
                                  final date = createdAt is DateTime
                                      ? createdAt
                                      : (createdAt is String)
                                          ? DateTime.tryParse(createdAt)
                                          : null;
                                  final dateStr = date == null ? '—' : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                                  final sizeStr = sizeBytes < 1024 * 1024 ? '${(sizeBytes / 1024).toStringAsFixed(0)} KB' : '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
                                  return DocItem(
                                    icon: _iconForMime(mime),
                                    title: title,
                                    date: dateStr,
                                    size: sizeStr,
                                    onTap: (url.isEmpty && storagePath.trim().isEmpty) ? null : () => _openDoc(data),
                                    onMore: () => _showDocMenu(row: data),
                                  );
                                }).toList(growable: false),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Bloc sécurité réduit
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: context.theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: _facebookBlue.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
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
                                    color: context.theme.colorScheme.onSurface,
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
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
    );
  }

  Future<void> _showDocMenu({required Map<String, dynamic> row}) async {
    final title = (row['title'] as String?) ?? 'Document';
    final url = (row['download_url'] as String?) ?? (row['downloadUrl'] as String?) ?? '';
    final storagePath = (row['storage_path'] as String?) ?? (row['storagePath'] as String?) ?? '';
    final me = context.read<AuthController>().currentUser;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: context.theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(AppRadius.lg), topRight: Radius.circular(AppRadius.lg)),
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
                  Expanded(child: Text(title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded, size: 18)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton.icon(
                onPressed: (url.trim().isEmpty && storagePath.trim().isEmpty) ? null : () => _openDoc(row),
                icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 16),
                label: const Text('Ouvrir', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(backgroundColor: _facebookBlue, foregroundColor: Colors.white, elevation: 0),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: me == null
                    ? null
                    : () async {
                        try {
                          final docRowId = (row['id'] ?? '').toString();
                          if (docRowId.trim().isEmpty) throw Exception('id manquant');
                          await _docs.deleteDocument(uid: me.id, documentId: docRowId, storagePath: storagePath);
                          if (!mounted) return;
                          context.pop();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document supprimé.')));
                        } catch (e) {
                          debugPrint('Vault: delete failed err=$e');
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suppression impossible.')));
                        }
                      },
                icon: Icon(Icons.delete_outline_rounded, color: context.theme.colorScheme.error, size: 16),
                label: Text('Supprimer', style: context.textStyles.labelMedium?.copyWith(color: context.theme.colorScheme.error, fontSize: 13)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: context.theme.colorScheme.error.withValues(alpha: 0.5))),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ... (les classes _UploadDocPayload et _UploadDocumentSheet restent inchangées, elles sont fonctionnelles)
// Je les inclus par souci de complétude mais elles ne changent pas.

class _UploadDocPayload {
  final String docId;
  final String title;
  final String docType;
  final DateTime? expiresAt;
  const _UploadDocPayload({required this.docId, required this.title, required this.docType, required this.expiresAt});
}

class _UploadDocumentSheet extends StatefulWidget {
  final String fileName;
  const _UploadDocumentSheet({required this.fileName});

  @override
  State<_UploadDocumentSheet> createState() => _UploadDocumentSheetState();
}

class _UploadDocumentSheetState extends State<_UploadDocumentSheet> {
  final _docIdC = TextEditingController();
  final _titleC = TextEditingController();
  String _type = 'Autre';
  DateTime? _expiresAt;

  @override
  void dispose() {
    _docIdC.dispose();
    _titleC.dispose();
    super.dispose();
  }

  bool get _needsExpiry => _type == 'CIN' || _type == 'Passeport' || _type == 'Permis';

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 20)),
      lastDate: now.add(const Duration(days: 365 * 50)),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: _facebookBlue)), child: child!),
    );
    if (picked != null) setState(() => _expiresAt = DateTime(picked.year, picked.month, picked.day));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final expiryLabel = _expiresAt == null ? 'Choisir une date' : '${_expiresAt!.year.toString().padLeft(4, '0')}-${_expiresAt!.month.toString().padLeft(2, '0')}-${_expiresAt!.day.toString().padLeft(2, '0')}';
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        decoration: BoxDecoration(
          color: context.theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(AppRadius.lg), topRight: Radius.circular(AppRadius.lg)),
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
                Text('Déposer un document', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
                IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded, size: 18))
              ],
            ),
            Text(widget.fileName, style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText, fontSize: 12)),
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
              decoration: InputDecoration(labelText: 'Type de document', prefixIcon: const Icon(Icons.folder_rounded, size: 18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _docIdC,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Doc ID',
                hintText: 'CIN-2023-001',
                prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _titleC,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Titre',
                hintText: 'Carte d\'identité nationale',
                prefixIcon: const Icon(Icons.description_rounded, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_needsExpiry)
              SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: _pickExpiry,
                  icon: const Icon(Icons.event_available_rounded, size: 16),
                  label: Text('Date d\'expiration: $expiryLabel', style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(foregroundColor: context.theme.colorScheme.primary, side: BorderSide(color: context.theme.colorScheme.primary, width: 1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  final docId = _docIdC.text.trim();
                  if (docId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doc ID requis.')));
                    return;
                  }
                  if (_needsExpiry && _expiresAt == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Date d\'expiration requise pour cette pièce.')));
                    return;
                  }
                  context.pop(_UploadDocPayload(docId: docId, title: _titleC.text, docType: _type, expiresAt: _expiresAt));
                },
                icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
                label: const Text('UPLOAD', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(backgroundColor: _facebookBlue, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension ThemeHelper on BuildContext {
  ThemeData get theme => Theme.of(this);
}
