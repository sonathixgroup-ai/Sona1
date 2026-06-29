import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StatsRow extends StatelessWidget {
  final int? connexionsCount;
  final int? publicationsCount;
  final int? communautesCount;
  final int? messagesCount;
  
  final VoidCallback? onConnexionsTap;
  final VoidCallback? onPublicationsTap;
  final VoidCallback? onCommunitiesTap;
  final VoidCallback? onMessagesTap;

  const StatsRow({
    super.key,
    this.connexionsCount,
    this.publicationsCount,
    this.communautesCount,
    this.messagesCount,
    this.onConnexionsTap,
    this.onPublicationsTap,
    this.onCommunitiesTap,
    this.onMessagesTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStatCard(
          connexionsCount ?? 0,
          'Connexions',
          Icons.people_outline,
          onConnexionsTap,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          publicationsCount ?? 0,
          'Publications',
          Icons.post_add_outlined,
          onPublicationsTap,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          communautesCount ?? 0,
          'Communautés',
          Icons.groups_outlined,
          onCommunitiesTap,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          messagesCount ?? 0,
          'Messages',
          Icons.message_outlined,
          onMessagesTap,
        ),
      ],
    );
  }

  Widget _buildStatCard(int value, String label, IconData icon, VoidCallback? onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: const Color(0xFFD4AF37)),
              const SizedBox(height: 4),
              Text(
                _formatNumber(value),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B1B3D),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toString();
  }
}
