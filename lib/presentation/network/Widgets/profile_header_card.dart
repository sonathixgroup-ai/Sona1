import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/auth/auth_controller.dart';

class ProfileHeaderCard extends StatelessWidget {
  final VoidCallback? onEditPressed;
  final VoidCallback? onPhotoPressed;
  final VoidCallback? onVideoPressed;
  final VoidCallback? onDocumentPressed;
  final VoidCallback? onEventPressed;
  final VoidCallback? onJobPressed;
  final VoidCallback? onStoryPressed;

  const ProfileHeaderCard({
    super.key,
    this.onEditPressed,
    this.onPhotoPressed,
    this.onVideoPressed,
    this.onDocumentPressed,
    this.onEventPressed,
    this.onJobPressed,
    this.onStoryPressed,
  });

  String _formatTitle(String? title) {
    if (title == null || title.isEmpty) return 'Partagez votre expertise';
    if (title.length > 40) return '${title.substring(0, 37)}...';
    return title;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final user = auth.currentUser;
    final userName = user?.displayName ?? 'Utilisateur';
    final userTitle = _formatTitle(user?.profession);
    final skills = user?.skills ?? [];
    final hasAvatar = user?.photoUrl != null && user!.photoUrl!.isNotEmpty;
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1B3D), Color(0xFF1A2D56)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec avatar et infos
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white24,
                    backgroundImage: hasAvatar
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    child: !hasAvatar
                        ? const Icon(Icons.person, size: 32, color: Colors.white)
                        : null,
                  ),
                  if (onEditPressed != null)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: onEditPressed,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD4AF37),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 12,
                            color: Color(0xFF0B1B3D),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userTitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Compétences
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: skills.take(3).map((skill) {
                final skillName = skill['name']?.toString() ?? '';
                if (skillName.isEmpty) return const SizedBox.shrink();
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    skillName,
                    style: const TextStyle(fontSize: 9, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Texte d'invitation
          const Text(
            'Que souhaitez-vous partager aujourd\'hui ?',
            style: TextStyle(color: Colors.white70, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          
          // Boutons d'action
          Row(
            children: [
              _buildShareButton(
                Icons.photo_camera,
                isSmallScreen ? '' : 'Photo',
                onPressed: onPhotoPressed,
                isSmallScreen: isSmallScreen,
              ),
              const SizedBox(width: 6),
              _buildShareButton(
                Icons.videocam,
                isSmallScreen ? '' : 'Vidéo',
                onPressed: onVideoPressed,
                isSmallScreen: isSmallScreen,
              ),
              const SizedBox(width: 6),
              _buildShareButton(
                Icons.insert_drive_file,
                isSmallScreen ? '' : 'Document',
                onPressed: onDocumentPressed,
                isSmallScreen: isSmallScreen,
              ),
              const SizedBox(width: 6),
              _buildShareButton(
                Icons.event,
                isSmallScreen ? '' : 'Événement',
                onPressed: onEventPressed,
                isSmallScreen: isSmallScreen,
              ),
              const SizedBox(width: 6),
              _buildShareButton(
                Icons.work,
                isSmallScreen ? '' : 'Offre',
                onPressed: onJobPressed,
                isSmallScreen: isSmallScreen,
              ),
              const SizedBox(width: 6),
              _buildShareButton(
                Icons.auto_awesome,
                isSmallScreen ? '' : 'Story',
                onPressed: onStoryPressed,
                isSmallScreen: isSmallScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(
    IconData icon,
    String label, {
    required VoidCallback? onPressed,
    required bool isSmallScreen,
  }) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFD4AF37)),
          padding: const EdgeInsets.symmetric(vertical: 7),
          minimumSize: Size.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isSmallScreen
            ? Icon(icon, size: 16, color: const Color(0xFFD4AF37))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 14, color: const Color(0xFFD4AF37)),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ],
              ),
      ),
    );
  }
}
