// ============================================================
// 📁 lib/presentation/chat/settings/chat_settings_page.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/chat/chat_settings_provider.dart';
import 'widgets/chat_settings_tile.dart';
import 'widgets/chat_settings_section.dart';

class ChatSettingsPage extends StatelessWidget {
  const ChatSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatSettingsProvider>();
    final settings = provider.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres du chat'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : settings == null
              ? const Center(child: Text('Impossible de charger les réglages'))
              : ListView(
                  children: [
                    // Apparence
                    ChatSettingsSection(
                      title: 'Apparence',
                      children: [
                        ChatSettingsTile(
                          icon: Icons.palette_rounded,
                          title: 'Thème',
                          subtitle: _getThemeLabel(settings.theme),
                          onTap: () => context.push('/chat/settings/appearance'),
                        ),
                        ChatSettingsTile(
                          icon: Icons.brush_rounded,
                          title: 'Fond d\'écran',
                          subtitle: settings.wallpaper == 'default' ? 'Par défaut' : 'Personnalisé',
                          onTap: () => context.push('/chat/settings/appearance'),
                        ),
                      ],
                    ),
                    // Confidentialité
                    ChatSettingsSection(
                      title: 'Confidentialité',
                      children: [
                        ChatSettingsTile(
                          icon: Icons.visibility_rounded,
                          title: 'Dernière activité',
                          subtitle: _getVisibilityLabel(settings.lastSeenVisibility),
                          onTap: () => context.push('/chat/settings/privacy'),
                        ),
                        ChatSettingsTile(
                          icon: Icons.image_rounded,
                          title: 'Photo de profil',
                          subtitle: _getVisibilityLabel(settings.profilePhotoVisibility),
                          onTap: () => context.push('/chat/settings/privacy'),
                        ),
                      ],
                    ),
                    // Notifications
                    ChatSettingsSection(
                      title: 'Notifications',
                      children: [
                        ChatSettingsTile(
                          icon: Icons.notifications_rounded,
                          title: 'Messages',
                          subtitle: settings.notifMessages ? 'Activé' : 'Désactivé',
                          onTap: () => context.push('/chat/settings/notifications'),
                        ),
                        ChatSettingsTile(
                          icon: Icons.phone_rounded,
                          title: 'Appels',
                          subtitle: settings.notifCalls ? 'Activé' : 'Désactivé',
                          onTap: () => context.push('/chat/settings/notifications'),
                        ),
                      ],
                    ),
                    // Messages
                    ChatSettingsSection(
                      title: 'Messages',
                      children: [
                        ChatSettingsTile(
                          icon: Icons.timer_rounded,
                          title: 'Messages éphémères',
                          subtitle: settings.ephemeralDuration == null
                              ? 'Désactivé'
                              : '${settings.ephemeralDuration}s',
                          onTap: () => context.push('/chat/settings/data'),
                        ),
                        ChatSettingsTile(
                          icon: Icons.cloud_download_rounded,
                          title: 'Téléchargement auto',
                          subtitle: _getDownloadLabel(settings.autoDownload),
                          onTap: () => context.push('/chat/settings/data'),
                        ),
                      ],
                    ),
                    // Compte
                    ChatSettingsSection(
                      title: 'Compte',
                      children: [
                        ChatSettingsTile(
                          icon: Icons.person_rounded,
                          title: 'Voir mon profil',
                          onTap: () => context.push('/chat/profile/${provider.chatUser?.id}'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout_rounded, color: Colors.red),
                          title: const Text('Se déconnecter', style: TextStyle(color: Colors.red)),
                          onTap: () {
                            // Action de déconnexion
                          },
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }

  String _getThemeLabel(String theme) {
    switch (theme) {
      case 'light':
        return 'Clair';
      case 'dark':
        return 'Sombre';
      default:
        return 'Système';
    }
  }

  String _getVisibilityLabel(String visibility) {
    switch (visibility) {
      case 'everyone':
        return 'Tout le monde';
      case 'contacts':
        return 'Mes contacts';
      case 'nobody':
        return 'Personne';
      default:
        return 'Tout le monde';
    }
  }

  String _getDownloadLabel(String mode) {
    switch (mode) {
      case 'wifi':
        return 'Wi-Fi uniquement';
      case 'mobile':
        return 'Données mobiles';
      default:
        return 'Jamais';
    }
  }
}
