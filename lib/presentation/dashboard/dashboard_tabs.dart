import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../theme.dart';
import '../../nav.dart';
import 'dashboard_ui.dart';
import 'dashboard_editors.dart';

// ============================================================
// DASHBOARD_TABS.DART - TOUS LES ONGLETS COMPLETS
// ============================================================

String _truncate(String v, int max) {
  final s = v.trim();
  if (s.length <= max) return s;
  return '${s.substring(0, max).trim()}…';
}

class ProfileTab extends StatelessWidget {
  final dynamic authUser, profile;
  final int score;
  final dynamic profileService, userService;

  const ProfileTab({
    super.key,
    required this.authUser,
    required this.profile,
    required this.score,
    required this.profileService,
    required this.userService,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 960;
    final user = profile;
    final isActivated = authUser.thixId.trim().toUpperCase() != 'THIX-PENDING';
    final hasActiveTrial = authUser.hasActiveTrial;

    final left = <Widget>[
      if (!isActivated && !hasActiveTrial)
        ActivationCalloutCard(
          onActivate: () {
            final receiptReturn = Uri.encodeComponent(AppRoutes.activationReceipt);
            context.go('${AppRoutes.payment}?returnTo=$receiptReturn');
          },
        ),
      DashboardCard(
        icon: Icons.badge_rounded,
        title: 'Profil Professionnel',
        subtitle: 'Données sécurisées liées à votre THIX ID',
        child: Column(
          children: [
            DashboardInfoRow(label: 'THIX ID', value: user.thixId),
            DashboardInfoRow(label: 'UID', value: authUser.id),
            DashboardInfoRow(label: 'Email', value: authUser.email.isEmpty ? '—' : authUser.email),
            DashboardInfoRow(label: 'Téléphone', value: authUser.phone ?? '—'),
            DashboardInfoRow(label: 'Contact', value: authUser.contactPhone ?? '—'),
            DashboardInfoRow(
              label: 'Profession / Poste',
              value: user.occupation?.trim().isEmpty ?? true ? '—' : user.occupation!.trim(),
            ),
            DashboardInfoRow(
              label: 'Localisation',
              value: user.countryOrOrigin?.trim().isEmpty ?? true ? '—' : user.countryOrOrigin!.trim(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _ExpandableTextRow(label: 'Bio', text: user.bio ?? '—')),
                const SizedBox(width: 8),
                _VisibilityToggle(
                  label: 'Public',
                  value: user.visibility.bio,
                  onChanged: (v) => profileService.updateVisibility(userId: user.userId, visibility: user.visibility.copyWith(bio: v)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _LanguagesRow(languages: user.languages)),
                const SizedBox(width: 8),
                const _VisibilityToggle(label: 'Public', value: true, onChanged: null, tooltip: 'Les langues sont toujours publiques.'),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      DashboardCard(
        icon: Icons.account_circle_rounded,
        title: 'Identité civile',
        subtitle: 'Informations sensibles (strictement protégées)',
        child: Column(
          children: [
            DashboardInfoRow(label: 'Date de naissance', value: authUser.dateOfBirth ?? '—'),
            DashboardInfoRow(label: 'Lieu de naissance', value: authUser.placeOfBirth ?? '—'),
            DashboardInfoRow(label: 'Nationalité', value: authUser.nationality ?? '—'),
            DashboardInfoRow(label: 'État civil', value: authUser.maritalStatus ?? '—'),
            DashboardInfoRow(label: 'Adresse', value: authUser.address ?? '—'),
            DashboardInfoRow(label: 'Père', value: authUser.fatherName ?? '—'),
            DashboardInfoRow(label: 'Mère', value: authUser.motherName ?? '—'),
          ],
        ),
      ),
    ];

    final right = <Widget>[
      DashboardCard(
        icon: Icons.school_rounded,
        title: 'Cursus scolaire',
        subtitle: '${user.education.length} entrée(s)',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (user.education.isEmpty)
              Text('Aucune formation enregistrée.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText))
            else
              ...user.education.take(3).map((e) {
                final inst = (e['institution'] as String?) ?? (e['school'] as String?) ?? '—';
                final degree = (e['degree'] as String?) ?? '';
                final city = (e['city'] as String?) ?? '';
                final start = (e['startYear'] as String?) ?? '';
                final end = (e['endYear'] as String?) ?? '';
                final period = [start, end].where((v) => v.trim().isNotEmpty).join('–');
                final meta = [degree, city, period].where((v) => v.trim().isNotEmpty).join(' • ');

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.school_rounded, color: LightModeColors.secondaryText),
                  title: Text(inst, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                  subtitle: meta.isEmpty ? null : Text(meta, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText)),
                );
              }),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.education),
                icon: const Icon(Icons.school_rounded, color: Color(0xFF123B7A)),
                label: const Text('Ajouter une formation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LightModeColors.accent,
                  foregroundColor: const Color(0xFF123B7A),
                  elevation: 0,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => ParcoursEditorSheet.show(context, profile: user, profileService: profileService),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Voir plus / Modifier'),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _VisibilityToggle(
                label: 'Public',
                value: user.visibility.education,
                onChanged: (v) => profileService.updateVisibility(userId: user.userId, visibility: user.visibility.copyWith(education: v)),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      DashboardCard(
        icon: Icons.work_history_rounded,
        title: 'Expérience professionnelle',
        subtitle: '${user.experience.length} entrée(s)',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (user.experience.isEmpty)
              Text('Aucune expérience enregistrée.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText))
            else
              ...user.experience.take(3).map((e) {
                final title = (e['title'] as String?) ?? '—';
                final company = (e['company'] as String?) ?? '';
                final city = (e['city'] as String?) ?? '';
                final meta = [company, city].where((v) => v.trim().isNotEmpty).join(' • ');

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.work_rounded, color: LightModeColors.secondaryText),
                  title: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                  subtitle: meta.isEmpty ? null : Text(meta, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText)),
                );
              }),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => ParcoursEditorSheet.show(context, profile: user, profileService: profileService),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Voir plus / Modifier'),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _VisibilityToggle(
                label: 'Public',
                value: user.visibility.experience,
                onChanged: (v) => profileService.updateVisibility(userId: user.userId, visibility: user.visibility.copyWith(experience: v)),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      DashboardCard(
        icon: Icons.insights_rounded,
        title: 'Indice de confiance',
        subtitle: 'THIX Score + conformité',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('THIX Score: $score/100', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: LinearProgressIndicator(
                value: (score.clamp(0, 100)) / 100.0,
                backgroundColor: Colors.black.withOpacity(0.08),
                valueColor: const AlwaysStoppedAnimation(LightModeColors.accent),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complétez Bio, Compétences, Formations et Documents pour améliorer votre score.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText, height: 1.35),
            ),
          ],
        ),
      ),
    ];

    if (!isWide) {
      return TabScaffold(children: [...left, const SizedBox(height: 12), ...right]);
    }
    
    return TabScaffold(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(children: left)),
            const SizedBox(width: 16),
            Expanded(child: Column(children: right)),
          ],
        ),
      ],
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? tooltip;

  const _VisibilityToggle({required this.label, required this.value, required this.onChanged, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: LightModeColors.secondaryText, fontWeight: FontWeight.w900)),
        const SizedBox(width: 8),
        Switch(value: value, onChanged: onChanged, activeColor: LightModeColors.success),
      ],
    );
    return tooltip == null ? child : Tooltip(message: tooltip!, child: child);
  }
}

class _ExpandableTextRow extends StatefulWidget {
  final String label, text;
  const _ExpandableTextRow({required this.label, required this.text});
  @override
  State<_ExpandableTextRow> createState() => _ExpandableTextRowState();
}

class _ExpandableTextRowState extends State<_ExpandableTextRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final raw = widget.text.trim();
    final text = raw.isEmpty ? '—' : raw;
    final maxLines = _expanded ? 99 : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText, fontWeight: FontWeight.w800)),
            TextButton(
              onPressed: text == '—' ? null : () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: Text(_expanded ? 'Voir moins' : 'Voir plus'),
            ),
          ],
        ),
        Text(text, maxLines: maxLines, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface, height: 1.4)),
      ],
    );
  }
}

class _LanguagesRow extends StatelessWidget {
  final List<String> languages;
  const _LanguagesRow({required this.languages});

  @override
  Widget build(BuildContext context) {
    final list = languages.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Langues', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (list.isEmpty)
          Text('—', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: list.map((l) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Text(l, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900)),
            )).toList(),
          ),
      ],
    );
  }
}

class DocumentsTab extends StatelessWidget {
  final String uid;
  final dynamic docs, userService;
  final String filter;
  final ValueChanged<String> onChangeFilter;

  const DocumentsTab({
    super.key,
    required this.uid,
    required this.docs,
    required this.userService,
    required this.filter,
    required this.onChangeFilter,
  });

  static const _filters = ['Tous', 'CIN', 'Passeport', 'Permis', 'Diplôme', 'PreuveAdresse', 'Autre'];

  @override
  Widget build(BuildContext context) => TabScaffold(
    children: [
      DashboardCard(
        icon: Icons.folder_special_rounded,
        title: 'Documents',
        subtitle: 'Portefeuille documentaire sécurisé',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _filters.map((f) => ChoiceChip(
                label: Text(f),
                selected: filter == f,
                onSelected: (_) => onChangeFilter(f),
                selectedColor: LightModeColors.accent.withOpacity(0.18),
                labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: filter == f ? LightModeColors.accent : Theme.of(context).colorScheme.onSurface,
                ),
                side: BorderSide(color: filter == f ? LightModeColors.accent : Theme.of(context).dividerColor),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              )).toList(),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: docs.streamDocuments(uid),
              builder: (context, snap) {
                final all = snap.data ?? [];
                final filtered = all.where((d) {
                  if (filter == 'Tous') return true;
                  final t = (d['doc_type'] as String?) ?? (d['docType'] as String?) ?? 'Autre';
                  return t == filter;
                }).toList();

                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('Aucun document pour ce filtre.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText)),
                  );
                }

                return Column(
                  children: filtered.take(8).map((data) {
                    final title = (data['title'] as String?) ?? (data['doc_id'] as String?) ?? 'Document';
                    final docId = (data['doc_id'] as String?) ?? '';
                    final status = (data['status'] as String?) ?? 'pending';
                    final exp = data['expires_at'];
                    final expiresAt = exp is DateTime ? exp : (exp is String ? DateTime.tryParse(exp) : null);
                    final dateStr = expiresAt == null ? '—' : '${expiresAt.day.toString().padLeft(2, '0')}/${expiresAt.month.toString().padLeft(2, '0')}/${expiresAt.year}';
                    final chip = _DocStatusChip.from(status);

                    return DocRow(
                      name: title,
                      date: docId.isEmpty ? 'Expiration: $dateStr' : '$docId • Exp: $dateStr',
                      status: chip.label,
                      statusBg: chip.bg,
                      statusText: chip.fg,
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await ConfirmFeeSheet.show(
                  context,
                  title: 'Uploader un document',
                  description: 'Frais institutionnels (simulation): 1 USD par dépôt.',
                  amountLabel: 'Payer 1 USD et continuer',
                );
                
                if (confirmed != true) return;
                
                try {
                  await userService.addPaymentTransaction(
                    uid: uid,
                    title: 'Dépôt de document',
                    amount: 1,
                    currency: 'USD',
                    method: 'Simulé',
                    status: 'paid',
                  );
                } catch (e) {
                  debugPrint('DocumentsTab: addPaymentTransaction failed $e');
                }
                
                if (!context.mounted) return;
                context.push(AppRoutes.vault);
              },
              icon: const Icon(Icons.upload_rounded, color: Color(0xFF123B7A)),
              label: const Text('Uploader un nouveau document (1 USD)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LightModeColors.accent,
                foregroundColor: const Color(0xFF123B7A),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _DocStatusChip {
  final String label;
  final Color bg, fg;

  const _DocStatusChip({required this.label, required this.bg, required this.fg});

  factory _DocStatusChip.from(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'verified') return _DocStatusChip(label: 'Vérifié', bg: const Color(0xFFE6FFFA), fg: LightModeColors.success);
    if (v == 'rejected') return _DocStatusChip(label: 'Rejeté', bg: Colors.red.shade50, fg: Colors.red.shade700);
    return _DocStatusChip(label: 'En attente', bg: LightModeColors.accent.withOpacity(0.15), fg: const Color(0xFF8A6B00));
  }
}

class ExperienceSkillsTab extends StatelessWidget {
  final dynamic profile, profileService;

  const ExperienceSkillsTab({super.key, required this.profile, required this.profileService});

  @override
  Widget build(BuildContext context) {
    final user = profile;
    return TabScaffold(
      children: [
        DashboardCard(
          icon: Icons.work_history_rounded,
          title: 'Expériences professionnelles',
          subtitle: '${user.experience.length} entrée(s)',
          child: Column(
            children: [
              if (user.experience.isEmpty)
                Text('Aucune expérience. Ajoutez votre parcours.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText))
              else
                ...user.experience.map((e) {
                  final title = (e['title'] as String?) ?? '—';
                  final org = (e['org'] as String?) ?? (e['company'] as String?) ?? '';
                  final date = (e['date'] as String?) ?? '';
                  final tasks = (e['tasks'] as String?) ?? '';
                  final meta = [org, date].where((v) => v.trim().isNotEmpty).join(' • ');

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.work_rounded, color: LightModeColors.secondaryText),
                    title: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900)),
                    subtitle: Text(
                      [meta, tasks.trim().isEmpty ? '' : _truncate(tasks, 90)].where((v) => v.trim().isNotEmpty).join('\n'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText, height: 1.35),
                    ),
                  );
                }),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => ExperienceEditorSheet.show(context, profile: user, profileService: profileService),
                  icon: const Icon(Icons.add_rounded, color: Color(0xFF123B7A)),
                  label: const Text('Ajouter une expérience'),
                  style: ElevatedButton.styleFrom(backgroundColor: LightModeColors.accent, foregroundColor: const Color(0xFF123B7A), elevation: 0),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DashboardCard(
          icon: Icons.psychology_rounded,
          title: 'Compétences',
          subtitle: '${user.skills.length} compétence(s)',
          child: Column(
            children: [
              if (user.skills.isEmpty)
                Text('Aucune compétence.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText))
              else
                ...user.skills.map((s) {
                  final name = (s['name'] as String?) ?? '—';
                  final level = (s['level'] as String?) ?? '—';
                  final details = (s['details'] as String?) ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: LightModeColors.secondaryText, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900)),
                              if (details.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(_truncate(details, 110), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText, height: 1.35)),
                              ]
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(label: level, bg: LightModeColors.accent.withOpacity(0.18), textColor: const Color(0xFF123B7A)),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => SkillsEditorSheet.show(context, profile: user, profileService: profileService),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Ajouter une compétence'),
                  style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary, side: BorderSide(color: Theme.of(context).colorScheme.primary)),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _VisibilityToggle(
                  label: 'Public',
                  value: user.visibility.skills,
                  onChanged: (v) => profileService.updateVisibility(userId: user.userId, visibility: user.visibility.copyWith(skills: v)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FormationsTab extends StatelessWidget {
  final dynamic user, userService;
  const FormationsTab({super.key, required this.user, required this.userService});

  @override
  Widget build(BuildContext context) => TabScaffold(
    children: [
      DashboardCard(
        icon: Icons.school_rounded,
        title: 'Formations',
        subtitle: 'Suivi des inscriptions',
        child: Column(
          children: [
            if (user.enrollments.isEmpty)
              Text('Aucune formation en cours. Inscrivez-vous à une formation officielle.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText))
            else
              ...user.enrollments.map((e) {
                final title = (e['title'] as String?) ?? 'Formation';
                final status = (e['status'] as String?) ?? 'En cours';
                final progress = ((e['progress'] as num?) ?? 0).clamp(0, 100);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900))),
                          const SizedBox(width: 8),
                          StatusChip(
                            label: status,
                            bg: (status.toLowerCase().contains('compl') ? LightModeColors.success : LightModeColors.accent).withOpacity(0.18),
                            textColor: const Color(0xFF123B7A),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: LinearProgressIndicator(
                          value: progress / 100.0,
                          minHeight: 10,
                          backgroundColor: Colors.black.withOpacity(0.08),
                          valueColor: const AlwaysStoppedAnimation(LightModeColors.accent),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('$progress%', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText, fontWeight: FontWeight.w800)),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.push(AppRoutes.education),
              icon: const Icon(Icons.explore_rounded, color: Color(0xFF123B7A)),
              label: const Text('Parcourir et s’inscrire'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LightModeColors.accent,
                foregroundColor: const Color(0xFF123B7A),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class CvTab extends StatefulWidget {
  final dynamic user;
  const CvTab({super.key, required this.user});

  @override
  State<CvTab> createState() => _CvTabState();
}

class _CvTabState extends State<CvTab> {
  bool _exporting = false;

  Future<Uint8List> _buildPdf() async {
    final u = widget.user;
    final doc = pw.Document();
    final theme = pw.ThemeData.withFont();

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        build: (_) => [
          pw.Text('THIX ID — CV Numérique', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text(u.displayName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text(u.thixId, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.Text([u.occupation, u.countryOrOrigin].where((v) => (v ?? '').trim().isNotEmpty).map((v) => v!.trim()).join(' • ')),
          pw.SizedBox(height: 10),
          pw.Text('Bio', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Text((u.bio ?? '').trim().isEmpty ? '—' : u.bio!.trim()),
          pw.SizedBox(height: 12),
          pw.Text('Expériences', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          if (u.experience.isEmpty) pw.Text('—') else ...u.experience.map((e) {
            final title = (e['title'] as String?) ?? '';
            final org = (e['org'] as String?) ?? '';
            final tasks = (e['tasks'] as String?) ?? '';
            return pw.Bullet(text: [title, org, _truncate(tasks, 140)].where((v) => v.trim().isNotEmpty).join(' • '));
          }),
          pw.SizedBox(height: 12),
          pw.Text('Formations', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          if (u.education.isEmpty) pw.Text('—') else ...u.education.map((e) {
            final inst = (e['institution'] as String?) ?? '';
            final degree = (e['degree'] as String?) ?? '';
            return pw.Bullet(text: [inst, degree].where((v) => v.trim().isNotEmpty).join(' • '));
          }),
          pw.SizedBox(height: 12),
          pw.Text('Langues', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Text(u.languages.isEmpty ? '—' : u.languages.join(' • ')),
        ],
      ),
    );
    return doc.save();
  }

  @override
  Widget build(BuildContext context) => TabScaffold(
    children: [
      DashboardCard(
        icon: Icons.description_rounded,
        title: 'Portfolio / CV',
        subtitle: 'CV numérique généré à partir de votre profil',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.user.displayName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(
                    [widget.user.occupation, widget.user.countryOrOrigin].where((v) => (v ?? '').trim().isNotEmpty).map((v) => v!.trim()).join(' • '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    (widget.user.bio ?? '').trim().isEmpty ? 'Bio non renseignée.' : widget.user.bio!.trim(),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  Text('Expériences', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  if (widget.user.experience.isEmpty)
                    Text('—', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText))
                  else
                    ...widget.user.experience.take(3).map((e) {
                      final title = (e['title'] as String?) ?? '—';
                      final org = (e['org'] as String?) ?? '';
                      return Text(
                        '• $title${org.trim().isEmpty ? '' : ' — $org'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface, height: 1.4),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _exporting ? null : () async {
                  setState(() => _exporting = true);
                  try {
                    final bytes = await _buildPdf();
                    if (!mounted) return;
                    await Printing.layoutPdf(onLayout: (_) async => bytes);
                  } catch (e) {
                    debugPrint('CV export failed $e');
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export PDF impossible.')));
                  } finally {
                    if (mounted) setState(() => _exporting = false);
                  }
                },
                icon: _exporting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF123B7A)))
                    : const Icon(Icons.download_rounded, color: Color(0xFF123B7A)),
                label: Text('Télécharger CV Numérique (PDF)', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF123B7A), fontWeight: FontWeight.w900)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LightModeColors.accent,
                  foregroundColor: const Color(0xFF123B7A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class PaymentsTab extends StatelessWidget {
  final String uid;
  final dynamic userService, user;

  const PaymentsTab({super.key, required this.uid, required this.userService, required this.user});

  @override
  Widget build(BuildContext context) => TabScaffold(
    children: [
      DashboardCard(
        icon: Icons.payments_rounded,
        title: 'Historique des Paiements',
        subtitle: 'Transactions liées à votre identité',
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: userService.streamPayments(uid),
          builder: (context, snap) {
            final list = snap.data ?? [];
            if (list.isEmpty) return Text('Aucune transaction enregistrée.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText));

            return Column(
              children: list.take(15).map((data) {
                final title = (data['title'] as String?) ?? (data['tx_ref'] as String?) ?? 'Transaction';
                final amount = data['amount'];
                final currency = (data['currency'] as String?) ?? 'USD';
                final method = (data['method'] as String?) ?? '—';
                final status = (data['status'] as String?) ?? 'paid';
                final created = data['created_at'];
                final dt = created is DateTime ? created : (created is String ? DateTime.tryParse(created) : null);
                final dateStr = dt == null ? '—' : '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                final amountStr = '${(amount is num ? amount.toStringAsFixed(2) : amount?.toString() ?? '0.00')} $currency';

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    status == 'paid' ? Icons.check_circle_rounded : Icons.hourglass_bottom_rounded,
                    color: status == 'paid' ? LightModeColors.success : LightModeColors.accent,
                  ),
                  title: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900)),
                  subtitle: Text('$dateStr • $method', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(amountStr, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: 'Reçu (PDF)',
                        onPressed: () async {
                          try {
                            final bytes = await _ReceiptPdf.build(user: user, tx: data);
                            if (!context.mounted) return;
                            await Printing.layoutPdf(onLayout: (_) async => bytes);
                          } catch (e) {
                            debugPrint('Receipt failed $e');
                          }
                        },
                        icon: const Icon(Icons.download_rounded),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    ],
  );
}

class _ReceiptPdf {
  static Future<Uint8List> build({required dynamic user, required Map<String, dynamic> tx}) async {
    final title = (tx['title'] as String?) ?? 'Transaction';
    final amount = tx['amount'];
    final currency = (tx['currency'] as String?) ?? 'USD';
    final method = (tx['method'] as String?) ?? '—';
    final status = (tx['status'] as String?) ?? 'paid';
    final created = tx['created_at'];
    final dt = created is DateTime ? created : (created is String ? DateTime.tryParse(created) : null);
    final dateStr = dt == null ? '—' : '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final amountStr = '${(amount is num ? amount.toStringAsFixed(2) : amount?.toString() ?? '0.00')} $currency';
    
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('THIX ID — Reçu', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Text('Utilisateur: ${user.displayName}'),
              pw.Text('THIX ID: ${user.thixId}'),
              pw.SizedBox(height: 12),
              pw.Text('Opération: $title', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Montant: $amountStr'),
              pw.Text('Méthode: $method'),
              pw.Text('Statut: $status'),
              pw.Text('Date: $dateStr'),
              pw.SizedBox(height: 18),
              pw.Text('Ce reçu est généré automatiquement (simulation).'),
            ],
          ),
        ),
      ),
    );
    return doc.save();
  }
}

class SecurityTab extends StatelessWidget {
  final String uid;
  final dynamic user, userService;

  const SecurityTab({super.key, required this.uid, required this.user, required this.userService});

  @override
  Widget build(BuildContext context) => TabScaffold(
    children: [
      DashboardCard(
        icon: Icons.security_rounded,
        title: 'Sécurité du Compte',
        subtitle: 'Paramètres de protection et journalisation',
        child: Column(
          children: [
            _SecurityToggleRow(
              icon: Icons.fingerprint_rounded,
              title: 'Biométrie (Face ID / Empreinte)',
              value: user.biometricsEnabled,
              onChanged: (v) async {
                try {
                  await userService.updateProfile(uid: uid, biometricsEnabled: v);
                  unawaited(userService.logSecurityEvent(uid: uid, type: 'security_change', label: 'Biométrie ${v ? 'activée' : 'désactivée'}'));
                } catch (e) {
                  debugPrint('Sec toggle failed $e');
                }
              },
            ),
            _SecurityToggleRow(
              icon: Icons.vpn_key_rounded,
              title: 'Double Authentification (2FA)',
              value: user.twoFaEnabled,
              onChanged: (v) async {
                try {
                  await userService.updateProfile(uid: uid, twoFaEnabled: v);
                  unawaited(userService.logSecurityEvent(uid: uid, type: 'security_change', label: '2FA ${v ? 'activée' : 'désactivée'}'));
                } catch (e) {
                  debugPrint('2fa toggle failed $e');
                }
              },
            ),
            const SizedBox(height: 12),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Historique des connexions', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                TextButton.icon(
                  onPressed: () => context.push(AppRoutes.settings),
                  icon: const Icon(Icons.settings_rounded, size: 18),
                  label: const Text('Paramètres'),
                ),
              ],
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: userService.streamSecurityEvents(uid),
              builder: (context, snap) {
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Aucun événement.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText)),
                  );
                }

                return Column(
                  children: list.take(8).map((data) {
                    final label = (data['label'] as String?) ?? (data['type'] as String?) ?? 'Événement';
                    final created = data['created_at'];
                    final dt = created is DateTime ? created : (created is String ? DateTime.tryParse(created) : null);
                    final dateStr = dt == null ? '—' : '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history_rounded, color: LightModeColors.secondaryText),
                      title: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900)),
                      subtitle: Text(dateStr, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText)),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.settings),
                icon: const Icon(Icons.lock_rounded),
                label: const Text('Gestion avancée (2FA, appareils, etc.)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _SecurityToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SecurityToggleRow({required this.icon, required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          Icon(icon, color: LightModeColors.secondaryText, size: 20),
          const SizedBox(width: 12),
          Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700)),
        ],
      ),
      Switch(value: value, onChanged: onChanged, activeColor: LightModeColors.success),
    ],
  );
}

class ConfirmFeeSheet {
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String description,
    required String amountLabel,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis)),
                IconButton(onPressed: () => context.pop(false), icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LightModeColors.secondaryText, height: 1.4)),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => context.pop(true),
                icon: const Icon(Icons.payments_rounded, color: Color(0xFF123B7A)),
                label: Text(amountLabel, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF123B7A), fontWeight: FontWeight.w900)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LightModeColors.accent,
                  foregroundColor: const Color(0xFF123B7A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => context.pop(false), child: const Text('Annuler')),
          ],
        ),
      ),
    );
  }
}
