// ============================================================
// 📁 lib/presentation/chat/settings/chat_settings_page.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/chat/chat_settings_provider.dart';
import 'widgets/chat_settings_tile.dart';
import 'widgets/chat_settings_section.dart';

class ChatSettingsPage extends StatefulWidget {
  const ChatSettingsPage({super.key});

  @override
  State<ChatSettingsPage> createState() => _ChatSettingsPageState();
}

class _ChatSettingsPageState extends State<ChatSettingsPage> {
  // Couleurs THIX ID pour harmoniser le design
  static const Color primaryBlue = Color(0xFF4A8BFF);
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color ivory = Color(0xFFF3F5FA);
  static const Color danger = Color(0xFFD64545);
  static const Color mutedText = Color(0xFF6B7690);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatSettingsProvider>();
    final settings = provider.settings;

    // Valeurs par défaut sécurisées au cas où 'settings' est null dans Supabase
    final theme = settings?.theme ?? 'system';
    final wallpaper = settings?.wallpaper ?? 'default';
    final lastSeen = settings?.lastSeenVisibility ?? 'everyone';
    final profilePhoto = settings?.profilePhotoVisibility ?? 'everyone';
    final notifMsgs = settings?.notifMessages ?? true;
    final notifCalls = settings?.notifCalls ?? true;
    final ephemeralDuration = settings?.ephemeralDuration;
    final autoDownload = settings?.autoDownload ?? 'wifi';

    return Scaffold(
      backgroundColor: ivory, // Fond global
      appBar: AppBar(
        title: const Text('Paramètres du chat', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: navyDeep, // Remplacement du violet par le bleu THIX
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // Apparence
                ChatSettingsSection(
                  title: 'Apparence',
                  children: [
                    ChatSettingsTile(
                      icon: Icons.palette_rounded,
                      title: 'Thème',
                      subtitle: _getThemeLabel(theme),
                      onTap: () => context.push('/chat/settings/appearance'),
                    ),
                    ChatSettingsTile(
                      icon: Icons.brush_rounded,
                      title: 'Fond d\'écran',
                      subtitle: wallpaper == 'default' ? 'Par défaut' : 'Personnalisé',
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
                      subtitle: _getVisibilityLabel(lastSeen),
                      onTap: () => context.push('/chat/settings/privacy'),
                    ),
                    ChatSettingsTile(
                      icon: Icons.image_rounded,
                      title: 'Photo de profil',
                      subtitle: _getVisibilityLabel(profilePhoto),
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
                      subtitle: notifMsgs ? 'Activé' : 'Désactivé',
                      onTap: () => context.push('/chat/settings/notifications'),
                    ),
                    ChatSettingsTile(
                      icon: Icons.phone_rounded,
                      title: 'Appels',
                      subtitle: notifCalls ? 'Activé' : 'Désactivé',
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
                      subtitle: ephemeralDuration == null
                          ? 'Désactivé'
                          : '${ephemeralDuration}s',
                      onTap: () => context.push('/chat/settings/data'),
                    ),
                    ChatSettingsTile(
                      icon: Icons.cloud_download_rounded,
                      title: 'Téléchargement auto',
                      subtitle: _getDownloadLabel(autoDownload),
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
                      onTap: () {
                        if (provider.chatUser?.id != null) {
                          context.push('/chat/profile/${provider.chatUser?.id}');
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded, color: danger),
                      title: const Text('Se déconnecter', style: TextStyle(color: danger, fontWeight: FontWeight.bold)),
                      onTap: () {
                        // Action de déconnexion
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 32), // Espace en bas
              ],
            ),
    );
  }

  // --- Fonctions utilitaires ---

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
