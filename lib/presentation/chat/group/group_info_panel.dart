import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/chat/group_info.dart';
import '../../../models/chat/chat_conversation.dart';
import 'group_member_list.dart';
import 'group_badge.dart';

/// Panneau des informations du groupe, affiché en haut de ChatScreen pour les groupes.
class GroupInfoPanel extends StatefulWidget {
  final ChatConversation conversation;
  final List<GroupMember> members;
  final VoidCallback? onViewAllMembers;
  final VoidCallback? onEditGroup;
  final VoidCallback? onLeaveGroup;
  final VoidCallback? onDeleteGroup;

  const GroupInfoPanel({
    super.key,
    required this.conversation,
    required this.members,
    this.onViewAllMembers,
    this.onEditGroup,
    this.onLeaveGroup,
    this.onDeleteGroup,
  });

  @override
  State<GroupInfoPanel> createState() => _GroupInfoPanelState();
}

class _GroupInfoPanelState extends State<GroupInfoPanel> {
  bool _isExpanded = false;

  // Couleurs THIX ID
  static const navyDeep = Color(0xFF0A1F44);
  static const navy = Color(0xFF123B7A);
  static const gold = Color(0xFFE3B23C);
  static const ivory = Color(0xFFF3F5FA);
  static const darkText = Color(0xFF10182B);
  static const mutedText = Color(0xFF6B7690);
  static const hairline = Color(0xFFE7EAF3);

  @override
  Widget build(BuildContext context) {
    final onlineCount = widget.members.where((m) => m.isOnline).length;
    final memberCount = widget.members.length;
    final displayName = widget.conversation.displayName;
    final avatarUrl = widget.conversation.groupAvatar;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: hairline,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // En-tête du groupe (réductible)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Avatar du groupe
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: navy.withOpacity(0.1),
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : 'G',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: navy,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  // Infos principales
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '$memberCount membres',
                              style: const TextStyle(
                                fontSize: 13,
                                color: mutedText,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: mutedText,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Indicateur de présence
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: onlineCount > 0 ? const Color(0xFF1FA971) : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$onlineCount en ligne',
                              style: TextStyle(
                                fontSize: 13,
                                color: onlineCount > 0 ? const Color(0xFF1FA971) : mutedText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Bouton expansion
                  Icon(
                    _isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: mutedText,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          // Contenu expansé
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    final membersToShow = widget.members.take(5).toList();
    final hasMore = widget.members.length > 5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description du groupe (si disponible)
          if (widget.conversation.groupName != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: ivory,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: mutedText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.conversation.groupName!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: darkText,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Liste des membres (aperçu)
          const Text(
            'Membres',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          const SizedBox(height: 8),
          ...membersToShow.map((member) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: navy.withOpacity(0.1),
                    backgroundImage: member.avatarUrl != null
                        ? NetworkImage(member.avatarUrl!)
                        : null,
                    child: member.avatarUrl == null
                        ? Text(
                            member.displayName.isNotEmpty
                                ? member.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: navy,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      member.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: darkText,
                      ),
                    ),
                  ),
                  if (member.isAdmin)
                    GroupBadge(
                      role: 'admin',
                      isCompact: true,
                    ),
                  if (member.isOnline)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1FA971),
                      ),
                    ),
                ],
              ),
            );
          }),

          if (hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: widget.onViewAllMembers,
                child: const Text(
                  'Voir tous les membres',
                  style: TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          const Divider(height: 24),

          // Actions du groupe
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (widget.onEditGroup != null)
                _buildActionButton(
                  icon: Icons.edit_rounded,
                  label: 'Modifier',
                  color: navy,
                  onTap: widget.onEditGroup!,
                ),
              if (widget.onLeaveGroup != null)
                _buildActionButton(
                  icon: Icons.exit_to_app_rounded,
                  label: 'Quitter',
                  color: Colors.orange,
                  onTap: widget.onLeaveGroup!,
                ),
              if (widget.onDeleteGroup != null)
                _buildActionButton(
                  icon: Icons.delete_rounded,
                  label: 'Supprimer',
                  color: const Color(0xFFD64545),
                  onTap: widget.onDeleteGroup!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(color: color),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
    );
  }
}
