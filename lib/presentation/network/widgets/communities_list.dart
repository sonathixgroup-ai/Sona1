import 'package:flutter/material.dart';
import 'package:thix_id/models/network_community.dart';

class CommunitiesList extends StatelessWidget {
  final List<NetworkCommunity> communities;
  final void Function(String) onCommunityTap;
  final void Function(String) onJoinTap;

  const CommunitiesList({
    super.key,
    required this.communities,
    required this.onCommunityTap,
    required this.onJoinTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: communities.map((community) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 2)],
          ),
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(community.name.substring(0, 1), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(community.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${community.membersCount} membres', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => onJoinTap(community.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF0B1B3D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  minimumSize: const Size(80, 30),
                ),
                child: const Text('Rejoindre', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
