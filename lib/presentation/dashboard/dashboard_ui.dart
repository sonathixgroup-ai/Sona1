import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme.dart';
import '../../nav.dart';
import '../common/notifications_sheet.dart';

// ============================================================
// DASHBOARD_UI.DART - TOUS LES WIDGETS STATIQUES PURS
// Aucune logique métier, aucun service, 100% UI Optimisée
// ============================================================

const _blue = Color(0xFF0D2CC1);
const _blueDark = Color(0xFF0A1E8A);
const _bgLight = Color(0xFFF5F6FB);

class DashboardBackground extends StatelessWidget {
  const DashboardBackground({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container(color: _bgLight);
  }
}

class DashboardTopBar extends StatelessWidget {
  final dynamic user;
  final int score;
  final VoidCallback onBack, onOpenSettings, onEditProfile, onDownloadCv, onShareProfile;
  final Future<void> Function() onLogout;

  const DashboardTopBar({
    super.key,
    required this.user,
    required this.score,
    required this.onBack,
    required this.onOpenSettings,
    required this.onLogout,
    required this.onEditProfile,
    required this.onDownloadCv,
    required this.onShareProfile,
  });

  @override
  Widget build(BuildContext context) {
    final status = (user.registrationStatus ?? '—').toLowerCase();
    final verified = status == 'paid' || status == 'verified';
    final photoUrl = (user.photoUrl ?? '').toString().trim();
    final bio = (user.bio ?? '').toString().trim();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. En-tête bleu profond
        Container(
          height: 250,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_blue, _blueDark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
        ),
        
        // 2. Boutons de navigation supérieurs
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _TopIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
                const Spacer(),
                const Text('TABLEAU DE BORD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.6, fontSize: 16)),
                const Spacer(),
                _TopIconButton(icon: Icons.notifications_rounded, onTap: () => NotificationsSheet.show(context)),
                const SizedBox(width: 8),
                _TopIconButton(icon: Icons.settings_rounded, onTap: onOpenSettings),
                const SizedBox(width: 8),
                _TopIconButton(icon: Icons.logout_rounded, onTap: () async => onLogout()),
              ],
            ),
          ),
        ),

        // 3. Carte de profil superposée
        Container(
          margin: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: const Color(0xFFEFF4FF),
                          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                          child: photoUrl.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: verified ? Colors.green : Colors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                          alignment: Alignment.center,
                          child: Icon(verified ? Icons.check_rounded : Icons.hourglass_bottom_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName ?? 'Utilisateur', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(child: Text('THIX ID: ${user.thixId}', style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(verified ? Icons.verified_rounded : Icons.pending_rounded, size: 12, color: _blue),
                                  const SizedBox(width: 4),
                                  Text(verified ? 'Vérifié' : 'En attente', style: const TextStyle(color: _blue, fontWeight: FontWeight.w800, fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(bio.isEmpty ? 'Complétez votre biographie pour augmenter votre visibilité.' : bio, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87, fontSize: 12, height: 1.3)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _HeaderActionButton(icon: Icons.edit_rounded, label: 'Modifier', onTap: onEditProfile)),
                  const SizedBox(width: 8),
                  Expanded(child: _HeaderActionButton(icon: Icons.download_rounded, label: 'CV Doc', onTap: onDownloadCv)),
                  const SizedBox(width: 8),
                  Expanded(child: _HeaderActionButton(icon: Icons.ios_share_rounded, label: 'Partager', onTap: onShareProfile)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: _blueDark),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _blueDark, fontWeight: FontWeight.w800, fontSize: 11)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        side: BorderSide(color: _blue.withOpacity(0.2)),
        backgroundColor: _blue.withOpacity(0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class DashboardTabsHeader extends StatelessWidget {
  const DashboardTabsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.black12),
      ),
      child: TabBar(
        isScrollable: true,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.black54,
        indicator: BoxDecoration(
          color: _blue,
          borderRadius: BorderRadius.circular(30),
        ),
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        indicatorSize: TabBarIndicatorSize.tab,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'Profil'),
          Tab(text: 'Documents'),
          Tab(text: 'Expériences'),
          Tab(text: 'Formations'),
          Tab(text: 'CV'),
          Tab(text: 'Paiements'),
          Tab(text: 'Sécurité'),
        ],
      ),
    );
  }
}

class ChatFab extends StatelessWidget {
  const ChatFab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.forum_rounded, size: 28, color: _blue),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title, subtitle, actionLabel;
  final bool showAction;

  const SectionHeader({super.key, required this.title, required this.subtitle, this.actionLabel = "Action", this.showAction = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _blueDark)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          if (showAction)
            TextButton(
              onPressed: () {},
              child: Text(actionLabel, style: const TextStyle(color: _blue, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }
}

class DashboardProfileStat extends StatelessWidget {
  final String label, value;
  const DashboardProfileStat({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _blueDark)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Widget child;

  const DashboardCard({super.key, required this.icon, required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Icon(icon, color: _blue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color bg, textColor;
  const StatusChip({super.key, required this.label, required this.bg, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(30)),
      child: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 10)),
    );
  }
}

class DocRow extends StatelessWidget {
  final String name, date, status;
  final Color statusBg, statusText;

  const DocRow({super.key, required this.name, required this.date, required this.status, required this.statusBg, required this.statusText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: const Icon(Icons.insert_drive_file_rounded, color: Colors.black54, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(date, style: const TextStyle(color: Colors.black54, fontSize: 11)),
              ],
            ),
          ),
          StatusChip(label: status, bg: statusBg, textColor: statusText),
        ],
      ),
    );
  }
}

class NetworkItem extends StatelessWidget {
  final String name, role, avatarDesc;
  const NetworkItem({super.key, required this.name, required this.role, required this.avatarDesc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const CircleAvatar(radius: 22, backgroundColor: _bgLight, child: Icon(Icons.person, color: Colors.grey)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(role, style: const TextStyle(color: Colors.black54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(30)),
            child: const Text("Connecté", style: TextStyle(color: Colors.green, fontWeight: FontWeight.w800, fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

class DashboardInfoRow extends StatelessWidget {
  final String label, value;
  const DashboardInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 12))),
          const SizedBox(width: 16),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.3))),
        ],
      ),
    );
  }
}

class ActivationCalloutCard extends StatelessWidget {
  final VoidCallback onActivate;
  const ActivationCalloutCard({super.key, required this.onActivate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: const Icon(Icons.warning_rounded, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Compte en attente d\'activation', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    SizedBox(height: 4),
                    Text('Activez maintenant pour obtenir votre THIX ID officiel.', style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: onActivate,
              icon: const Icon(Icons.payments_rounded),
              label: const Text('Activer mon compte', style: TextStyle(fontWeight: FontWeight.w900)),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TabScaffold extends StatelessWidget {
  final List<Widget> children;
  const TabScaffold({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

class ShareProfileSheet {
  static Future<void> show(BuildContext context, dynamic profile) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Partager le profil', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _blueDark)),
                IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.remove_red_eye_rounded, color: _blue)),
              title: const Text('Voir mon profil public', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Aperçu en lecture seule', style: TextStyle(fontSize: 12)),
              onTap: () {
                context.pop();
                final thixId = profile.thixId.trim();
                context.push('${AppRoutes.publicProfile}?thixId=${Uri.encodeComponent(thixId)}');
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.ios_share_rounded, color: _blue)),
              title: const Text('Partager mon lien public', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Copie/partage le lien de votre profil', style: TextStyle(fontSize: 12)),
              onTap: () async {
                context.pop();
                final thixId = profile.thixId.trim();
                final url = thixId.isEmpty ? '' : 'https://thix.app/public-profile?thixId=${Uri.encodeComponent(thixId)}';
                final text = url.isEmpty ? 'Mon profil THIX ID: $thixId' : 'Mon profil THIX ID: $thixId\n$url';
                try {
                  await Share.share(text);
                } catch (e) {
                  debugPrint('Share profile failed err=$e');
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
