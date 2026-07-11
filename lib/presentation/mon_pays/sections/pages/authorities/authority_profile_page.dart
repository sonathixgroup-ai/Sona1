// lib/presentation/mon_pays/pages/authorities/authority_profile_page.dart
// Détail complet d'une autorité

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/authorities_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../utils/helpers.dart';

class AuthorityProfilePage extends ConsumerWidget {
  final String authorityId;

  const AuthorityProfilePage({required this.authorityId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorityAsync = ref.watch(authorityDetailProvider(authorityId));
    final isFavorite = ref.watch(favoritesProvider).contains(authorityId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  ref.read(favoritesProvider.notifier).toggleFavorite(authorityId);
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implémenter le partage
            },
          ),
        ],
      ),
      body: authorityAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement du profil...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text('Erreur: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(authorityDetailProvider(authorityId));
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (authority) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec photo
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: authority.imageUrl != null && authority.imageUrl!.isNotEmpty
                            ? NetworkImage(authority.imageUrl!)
                            : null,
                        backgroundColor: Colors.grey.shade300,
                        child: authority.imageUrl == null || authority.imageUrl!.isEmpty
                            ? Text(
                                MonPaysHelpers.getInitials(authority.name),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A5276),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        authority.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authority.title,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      if (authority.party.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A5276).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            authority.party,
                            style: const TextStyle(
                              color: Color(0xFF1A5276),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (authority.mandate.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Mandat: ${authority.mandate}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Biographie
                if (authority.biography.isNotEmpty) ...[
                  const Text(
                    'Biographie',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authority.biography,
                    style: TextStyle(
                      height: 1.6,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Discours
                if (authority.speeches.isNotEmpty) ...[
                  const Text(
                    'Discours',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...authority.speeches.map((speech) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(
                            Icons.play_circle_outline,
                            color: Color(0xFF1A5276),
                          ),
                          title: Text(speech),
                          trailing: const Icon(Icons.arrow_forward, size: 16),
                          onTap: () {
                            // TODO: Ouvrir le discours
                          },
                        ),
                      )),
                  const SizedBox(height: 16),
                ],

                // Vidéos
                if (authority.videos.isNotEmpty) ...[
                  const Text(
                    'Vidéos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...authority.videos.map((video) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(
                            Icons.video_library,
                            color: Color(0xFF1A5276),
                          ),
                          title: Text(video),
                          trailing: const Icon(Icons.play_arrow, color: Colors.red),
                          onTap: () {
                            // TODO: Lire la vidéo
                          },
                        ),
                      )),
                  const SizedBox(height: 16),
                ],

                // Agenda
                if (authority.agenda.isNotEmpty) ...[
                  const Text(
                    'Agenda',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...authority.agenda.map((item) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(
                            Icons.event,
                            color: Color(0xFF1A5276),
                          ),
                          title: Text(item['event'] ?? ''),
                          subtitle: Text(item['date'] ?? ''),
                          trailing: const Icon(Icons.calendar_today, size: 16),
                        ),
                      )),
                  const SizedBox(height: 16),
                ],

                // Réseaux sociaux
                if (authority.socialNetworks.isNotEmpty) ...[
                  const Text(
                    'Réseaux officiels',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...authority.socialNetworks.entries.map((entry) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            entry.key == 'Twitter'
                                ? Icons.chat
                                : entry.key == 'Facebook'
                                    ? Icons.facebook
                                    : Icons.link,
                            color: const Color(0xFF1A5276),
                          ),
                          title: Text(entry.key),
                          subtitle: Text(entry.value),
                          trailing: const Icon(Icons.open_in_new, size: 16),
                          onTap: () {
                            // TODO: Ouvrir le lien
                          },
                        ),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
