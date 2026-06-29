import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:thix_id/presentation/thix_sante/snackbar_utils.dart';
import 'package:thix_id/presentation/thix_sante/thix_role.dart';

const _patientRoute = '/sante/patient';
const _doctorRoute = '/sante/medecin';
const _pharmacyRoute = '/sante/pharmacie';

class ThixSantePage extends StatelessWidget {
  const ThixSantePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ThixSanteHeader(),
              const SizedBox(height: 16),
              _HeroCard(
                role: ThixRole.patient,
                onOpenMainAction: () => context.push(_patientRoute),
              ),
              const SizedBox(height: 16),
              const Text(
                'Accès par rôle',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F1E4A),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: ThixRole.values
                    .map(
                      (role) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _RoleEntryCard(
                            role: role,
                            onTap: () => context.push(_routeForRole(role)),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              _QuickSummaryStrip(
                data: _roleData[ThixRole.patient]!,
                onOpenDashboard: () => context.push(_patientRoute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ThixSanteRolePage extends StatefulWidget {
  final ThixRole role;

  const ThixSanteRolePage({super.key, required this.role});

  @override
  State<ThixSanteRolePage> createState() => _ThixSanteRolePageState();
}

class _ThixSanteRolePageState extends State<ThixSanteRolePage> {
  late ThixRole _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.role;
  }

  @override
  void didUpdateWidget(covariant ThixSanteRolePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role) {
      _selectedRole = widget.role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final module = _roleData[_selectedRole]!;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ThixSanteHeader(),
                    const SizedBox(height: 14),
                    _RoleSwitcher(
                      selectedRole: _selectedRole,
                      onRoleChanged: (nextRole) {
                        if (nextRole == _selectedRole) return;
                        setState(() => _selectedRole = nextRole);
                        context.go(_routeForRole(nextRole));
                      },
                    ),
                    const SizedBox(height: 14),
                    _HeroCard(
                      role: _selectedRole,
                      onOpenMainAction: () {
                        showThixFeatureReadySnackBar(context, module.mainActionLabel);
                      },
                    ),
                    const SizedBox(height: 14),
                    _QuickSummaryStrip(
                      data: module,
                      onOpenDashboard: () {
                        final dashboard = module.categories.first.items.first;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ThixSanteFeaturePage(
                              role: _selectedRole,
                              feature: dashboard,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              sliver: SliverList.separated(
                itemCount: module.categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final category = module.categories[index];
                  return _FeatureCategoryCard(
                    role: _selectedRole,
                    category: category,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThixSanteFeaturePage extends StatelessWidget {
  final ThixRole role;
  final _ThixFeatureItem feature;

  const ThixSanteFeaturePage({
    super.key,
    required this.role,
    required this.feature,
  });

  @override
  Widget build(BuildContext context) {
    final roleData = _roleData[role]!;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F1E4A),
        title: Text(feature.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: role.gradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x261A3B8F),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    child: Icon(feature.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    feature.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    feature.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ActionTile(
              icon: Icons.rocket_launch_rounded,
              title: 'Action principale',
              subtitle: roleData.mainActionLabel,
              onTap: () => showThixFeatureReadySnackBar(context, roleData.mainActionLabel),
            ),
            _ActionTile(
              icon: Icons.checklist_rounded,
              title: 'Workflow',
              subtitle: 'Créer, suivre et valider les étapes métier',
              onTap: () => showThixFeatureReadySnackBar(context, 'Workflow ${feature.title}'),
            ),
            _ActionTile(
              icon: Icons.notifications_active_rounded,
              title: 'Alertes',
              subtitle: 'Notifications configurées pour ce module',
              onTap: () => showThixFeatureReadySnackBar(context, 'Alertes ${feature.title}'),
            ),
            _ActionTile(
              icon: Icons.lock_person_rounded,
              title: 'Sécurité & accès',
              subtitle: 'Permissions et traçabilité conformes',
              onTap: () => showThixFeatureReadySnackBar(context, 'Sécurité ${feature.title}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThixSanteHeader extends StatelessWidget {
  const _ThixSanteHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.menu_rounded, color: Color(0xFF1B2A57)),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THIX SANTÉ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B2A57),
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Votre santé, notre priorité.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6C7899),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1B2A57)),
        ),
        const SizedBox(width: 10),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF5F9FF),
            border: Border.all(color: const Color(0xFFE3EBFF)),
          ),
          child: const Icon(Icons.person_rounded, color: Color(0xFF1B2A57)),
        ),
      ],
    );
  }
}

class _RoleSwitcher extends StatelessWidget {
  final ThixRole selectedRole;
  final ValueChanged<ThixRole> onRoleChanged;

  const _RoleSwitcher({
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ThixRole.values
          .map(
            (role) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onRoleChanged(role),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selectedRole == role ? role.accent : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selectedRole == role ? role.accent : const Color(0xFFDCE5FF),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          role.icon,
                          color: selectedRole == role ? Colors.white : const Color(0xFF2E3A63),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          role.label,
                          style: TextStyle(
                            color: selectedRole == role ? Colors.white : const Color(0xFF2E3A63),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RoleEntryCard extends StatelessWidget {
  final ThixRole role;
  final VoidCallback onTap;

  const _RoleEntryCard({required this.role, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4EAFA)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: role.accent.withValues(alpha: 0.12),
              child: Icon(role.icon, color: role.accent, size: 20),
            ),
            const SizedBox(height: 9),
            Text(
              role.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C2B58),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final ThixRole role;
  final VoidCallback onOpenMainAction;

  const _HeroCard({required this.role, required this.onOpenMainAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: role.gradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331852C7),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role == ThixRole.patient ? 'Bonjour, Michel 👋' : 'Module ${role.label}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            role.headline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              height: 1.05,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            role.subtitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onOpenMainAction,
            icon: const Icon(Icons.folder_shared_rounded),
            label: Text(role.ctaLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0D2B88),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickSummaryStrip extends StatelessWidget {
  final _RoleModuleData data;
  final VoidCallback onOpenDashboard;

  const _QuickSummaryStrip({required this.data, required this.onOpenDashboard});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5ECFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Résumé ${data.role.shortLabel.toLowerCase()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10214F),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onOpenDashboard,
                child: const Text('Voir dashboard'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: data.stats
                .map(
                  (stat) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: stat.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stat.label,
                              style: TextStyle(
                                fontSize: 12,
                                color: stat.color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stat.value,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF10214F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _FeatureCategoryCard extends StatelessWidget {
  final ThixRole role;
  final _ThixFeatureCategory category;

  const _FeatureCategoryCard({required this.role, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6EDFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: role.accent.withValues(alpha: 0.14),
                child: Icon(category.icon, color: role.accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14224B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            category.description,
            style: const TextStyle(
              color: Color(0xFF607093),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          ...category.items.map(
            (feature) => _FeatureListTile(
              role: role,
              feature: feature,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureListTile extends StatelessWidget {
  final ThixRole role;
  final _ThixFeatureItem feature;

  const _FeatureListTile({required this.role, required this.feature});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ThixSanteFeaturePage(role: role, feature: feature),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: feature.color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(feature.icon, color: feature.color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF14224B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    feature.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF677899),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF5A6B90)),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE7EDFF)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF1F5FF),
                child: Icon(icon, color: const Color(0xFF1D3BA6), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF14224B),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF617191),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF62739A)),
            ],
          ),
        ),
      ),
    );
  }
}

String _routeForRole(ThixRole role) {
  switch (role) {
    case ThixRole.patient:
      return _patientRoute;
    case ThixRole.doctor:
      return _doctorRoute;
    case ThixRole.pharmacy:
      return _pharmacyRoute;
  }
}

class _ThixStat {
  final String label;
  final String value;
  final Color color;

  const _ThixStat(this.label, this.value, this.color);
}

class _ThixFeatureItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _ThixFeatureItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _ThixFeatureCategory {
  final String title;
  final String description;
  final IconData icon;
  final List<_ThixFeatureItem> items;

  const _ThixFeatureCategory({
    required this.title,
    required this.description,
    required this.icon,
    required this.items,
  });
}

class _RoleModuleData {
  final ThixRole role;
  final String mainActionLabel;
  final List<_ThixStat> stats;
  final List<_ThixFeatureCategory> categories;

  const _RoleModuleData({
    required this.role,
    required this.mainActionLabel,
    required this.stats,
    required this.categories,
  });
}

const Map<ThixRole, _RoleModuleData> _roleData = {
  ThixRole.patient: _RoleModuleData(
    role: ThixRole.patient,
    mainActionLabel: 'Dossier de santé',
    stats: [
      _ThixStat('Consultations', '12', Color(0xFF1A63F2)),
      _ThixStat('Examens', '7', Color(0xFF00A08A)),
      _ThixStat('Médicaments', '3', Color(0xFF7A3CFF)),
      _ThixStat('RDV', '2', Color(0xFFFF7A00)),
    ],
    categories: [
      _ThixFeatureCategory(
        title: 'Pilotage patient',
        description: 'Suivi global de santé et indicateurs de risque.',
        icon: Icons.dashboard_customize_rounded,
        items: [
          _ThixFeatureItem(title: 'Dashboard', description: 'Statistiques, score santé, prochains RDV, traitements, articles.', icon: Icons.dashboard_rounded, color: Color(0xFF1F66F3)),
          _ThixFeatureItem(title: 'Analyse prédictive', description: 'Score de santé et estimation de risque personnalisée.', icon: Icons.insights_rounded, color: Color(0xFF18A37F)),
          _ThixFeatureItem(title: 'Alertes sanitaires locales', description: 'Alertes contextuelles selon votre zone géographique.', icon: Icons.campaign_rounded, color: Color(0xFFEF476F)),
          _ThixFeatureItem(title: 'Notifications push', description: 'Rappels temps réel pour traitement, RDV et urgences.', icon: Icons.notifications_active_rounded, color: Color(0xFF7A3CFF)),
        ],
      ),
      _ThixFeatureCategory(
        title: 'Suivi clinique',
        description: 'Mesures, dossiers et prévention médicale continue.',
        icon: Icons.health_and_safety_rounded,
        items: [
          _ThixFeatureItem(title: 'Suivi des symptômes', description: 'Nom, intensité 1-5, date et notes de suivi.', icon: Icons.monitor_heart_rounded, color: Color(0xFF1F66F3)),
          _ThixFeatureItem(title: 'Constantes vitales', description: 'Tension, glycémie, poids, IMC.', icon: Icons.favorite_rounded, color: Color(0xFFE53965)),
          _ThixFeatureItem(title: 'Médicaments & rappels', description: 'Traitements actifs et rappels automatiques.', icon: Icons.medication_rounded, color: Color(0xFF7A3CFF)),
          _ThixFeatureItem(title: 'Dossier médical', description: 'Antécédents, consultations, examens, ordonnances.', icon: Icons.folder_shared_rounded, color: Color(0xFF00A08A)),
          _ThixFeatureItem(title: 'Carnet de vaccination', description: 'Suivi des vaccins et prochaines doses.', icon: Icons.vaccines_rounded, color: Color(0xFF1F66F3)),
          _ThixFeatureItem(title: 'Suivi grossesse', description: 'Parcours maternité étape par étape.', icon: Icons.pregnant_woman_rounded, color: Color(0xFFFF7A00)),
          _ThixFeatureItem(title: 'Consentements (RGPD)', description: 'Gestion des consentements et accès aux données.', icon: Icons.verified_user_rounded, color: Color(0xFF18A37F)),
        ],
      ),
      _ThixFeatureCategory(
        title: 'Accès aux soins',
        description: 'Rendez-vous, téléservices, documents et urgence.',
        icon: Icons.local_hospital_rounded,
        items: [
          _ThixFeatureItem(title: 'Rendez-vous', description: 'Prise, annulation et téléconsultation Jitsi.', icon: Icons.calendar_month_rounded, color: Color(0xFF1F66F3)),
          _ThixFeatureItem(title: 'Téléexpertise', description: 'Demande d’avis médical à distance.', icon: Icons.group_rounded, color: Color(0xFF18A37F)),
          _ThixFeatureItem(title: 'Partage sécurisé du dossier', description: 'Partage temporaire et contrôlé des données.', icon: Icons.share_rounded, color: Color(0xFF7A3CFF)),
          _ThixFeatureItem(title: 'Scan d’ordonnance (OCR)', description: 'Numérisation et extraction intelligente.', icon: Icons.document_scanner_rounded, color: Color(0xFFFF7A00)),
          _ThixFeatureItem(title: 'Carte urgences / pharmacies', description: 'Points de soins et officines proches.', icon: Icons.map_rounded, color: Color(0xFFEF476F)),
        ],
      ),
      _ThixFeatureCategory(
        title: 'Accompagnement quotidien',
        description: 'Famille, bien-être, messagerie et assistance IA.',
        icon: Icons.self_improvement_rounded,
        items: [
          _ThixFeatureItem(title: 'Espace famille', description: 'Gestion des proches et accès délégués.', icon: Icons.family_restroom_rounded, color: Color(0xFF1F66F3)),
          _ThixFeatureItem(title: 'Assistant IA', description: 'Chatbot santé contextuel 24/7.', icon: Icons.smart_toy_rounded, color: Color(0xFF00A08A)),
          _ThixFeatureItem(title: 'Messagerie', description: 'Échanges avec médecins, pharmacie et IA.', icon: Icons.chat_rounded, color: Color(0xFF7A3CFF)),
          _ThixFeatureItem(title: 'Programmes bien-être', description: 'Plans de nutrition, activité et prévention.', icon: Icons.spa_rounded, color: Color(0xFF18A37F)),
        ],
      ),
    ],
  ),
  ThixRole.doctor: _RoleModuleData(
    role: ThixRole.doctor,
    mainActionLabel: 'Agenda du jour',
    stats: [
      _ThixStat('Patients', '148', Color(0xFF1F66F3)),
      _ThixStat('Consultations', '31', Color(0xFF00A08A)),
      _ThixStat('Alertes', '6', Color(0xFFEF476F)),
      _ThixStat('Téléexpertise', '9', Color(0xFF7A3CFF)),
    ],
    categories: [
      _ThixFeatureCategory(
        title: 'Pilotage médical',
        description: 'Vue praticien, activité clinique et alertes.',
        icon: Icons.medical_information_rounded,
        items: [
          _ThixFeatureItem(title: 'Dashboard', description: 'Patients, alertes critiques et téléexpertises.', icon: Icons.dashboard_rounded, color: Color(0xFF1F66F3)),
          _ThixFeatureItem(title: 'Statistiques', description: 'KPIs consultations, charge médicale et qualité.', icon: Icons.query_stats_rounded, color: Color(0xFF18A37F)),
          _ThixFeatureItem(title: 'Alertes patients', description: 'Risque santé et actions préventives prioritaires.', icon: Icons.warning_amber_rounded, color: Color(0xFFEF476F)),
          _ThixFeatureItem(title: 'Graphiques des constantes', description: 'Tendances longitudinales des mesures vitales.', icon: Icons.show_chart_rounded, color: Color(0xFF7A3CFF)),
        ],
      ),
      _ThixFeatureCategory(
        title: 'Gestion des patients',
        description: 'Recherche, suivi et dossier clinique complet.',
        icon: Icons.groups_2_rounded,
        items: [
          _ThixFeatureItem(title: 'Liste patients', description: 'Recherche multicritères et filtres avancés.', icon: Icons.people_alt_rounded, color: Color(0xFF1F66F3)),
          _ThixFeatureItem(title: 'Détail patient', description: 'Antécédents, constantes et traitements.', icon: Icons.badge_rounded, color: Color(0xFF00A08A)),
          _ThixFeatureItem(title: 'Notes médicales', description: 'Compte-rendus structurés et historique.', icon: Icons.note_alt_rounded, color: Color(0xFF7A3CFF)),
          _ThixFeatureItem(title: 'Prescription électronique', description: 'Ordonnances digitales sécurisées.', icon: Icons.receipt_long_rounded, color: Color(0xFFFF7A00)),
        ],
      ),
      _ThixFeatureCategory(
        title: 'Consultation & coordination',
        description: 'Télésoin, collaboration et communication temps réel.',
        icon: Icons.video_call_rounded,
        items: [
          _ThixFeatureItem(title: 'Téléconsultation (Jitsi)', description: 'Sessions vidéo sécurisées avec patients.', icon: Icons.video_camera_front_rounded, color: Color(0xFF1F66F3)),
          _ThixFeatureItem(title: 'Téléexpertise', description: 'Demandes et avis entre médecins.', icon: Icons.psychology_alt_rounded, color: Color(0xFF18A37F)),
          _ThixFeatureItem(title: 'Agenda', description: 'Calendrier intelligent et créneaux.', icon: Icons.calendar_today_rounded, color: Color(0xFF7A3CFF)),
          _ThixFeatureItem(title: 'Messagerie', description: 'Canaux patients et pharmacie.', icon: Icons.chat_bubble_rounded, color: Color(0xFF00A08A)),
          _ThixFeatureItem(title: 'Mobile terrain', description: 'Scan bracelet, dictée vocale, mode offline.', icon: Icons.phone_android_rounded, color: Color(0xFFFF7A00)),
        ],
      ),
    ],
  ),
  ThixRole.pharmacy: _RoleModuleData(
    role: ThixRole.pharmacy,
    mainActionLabel: 'Valider les ordonnances',
    stats: [
      _ThixStat('Commandes', '56', Color(0xFF1F66F3)),
      _ThixStat('Stock critique', '8', Color(0xFFEF476F)),
      _ThixStat('Livraisons', '14', Color(0xFF00A08A)),
      _ThixStat('CA', '2.4M', Color(0xFFFF7A00)),
    ],
    categories: [
      _ThixFeatureCategory(
        title: 'Opérations officine',
        description: 'Production quotidienne, stock et dispensation.',
        icon: Icons.local_pharmacy_rounded,
        items: [
          _ThixFeatureItem(title: 'Dashboard', description: 'Commandes en cours et stock critique.', icon: Icons.dashboard_rounded, color: Color(0xFF1F66F3)),
          _ThixFeatureItem(title: 'Commandes', description: 'Liste, filtres et statuts de traitement.', icon: Icons.shopping_bag_rounded, color: Color(0xFF00A08A)),
          _ThixFeatureItem(title: 'Validation d’ordonnance', description: 'Accepter ou rejeter une ordonnance.', icon: Icons.fact_check_rounded, color: Color(0xFFFF7A00)),
          _ThixFeatureItem(title: 'Inventaire', description: 'Quantité, seuil et gestion des lots.', icon: Icons.inventory_2_rounded, color: Color(0xFF7A3CFF)),
          _ThixFeatureItem(title: 'Dispensation', description: 'Attribution sécurisée à un patient.', icon: Icons.medication_liquid_rounded, color: Color(0xFF1F66F3)),
        ],
      ),
      _ThixFeatureCategory(
        title: 'Supervision & logistique',
        description: 'Réapprovisionnement, livraisons et reporting.',
        icon: Icons.local_shipping_rounded,
        items: [
          _ThixFeatureItem(title: 'Alertes stock bas', description: 'Prévision de rupture et réapprovisionnement.', icon: Icons.inventory_rounded, color: Color(0xFFEF476F)),
          _ThixFeatureItem(title: 'Suivi des livraisons', description: 'Traçabilité des colis et délais.', icon: Icons.route_rounded, color: Color(0xFF00A08A)),
          _ThixFeatureItem(title: 'Rapports', description: 'CA, commandes et médicaments prescrits.', icon: Icons.pie_chart_rounded, color: Color(0xFF7A3CFF)),
          _ThixFeatureItem(title: 'Profil pharmacie', description: 'Informations, horaires et conformité.', icon: Icons.storefront_rounded, color: Color(0xFF1F66F3)),
          _ThixFeatureItem(title: 'Messagerie', description: 'Coordination médecins et patients.', icon: Icons.mark_unread_chat_alt_rounded, color: Color(0xFFFF7A00)),
        ],
      ),
    ],
  ),
};
