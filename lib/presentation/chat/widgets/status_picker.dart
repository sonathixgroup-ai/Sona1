// lib/presentation/chat/widgets/status_picker.dart
import 'package:flutter/material.dart';
import '../../../models/chat/user_status.dart';

class StatusPicker extends StatelessWidget {
  final Function(String status, String? customStatus) onStatusSelected;
  final String currentStatus;

  const StatusPicker({
    super.key,
    required this.onStatusSelected,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = [
      UserStatus.online,
      UserStatus.busy,
      UserStatus.away,
      UserStatus.doNotDisturb,
      UserStatus.offline,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisissez votre statut',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...statuses.map((status) {
            final isSelected = status == currentStatus;
            return ListTile(
              leading: UserStatus.presenceIndicator(status, size: 20),
              title: Text(
                UserStatus.getLabel(status),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFFD4AF37) : Colors.black,
                ),
              ),
              trailing: isSelected ? const Icon(Icons.check, color: Color(0xFFD4AF37)) : null,
              onTap: () {
                Navigator.pop(context);
                onStatusSelected(status, null);
              },
            );
          }).toList(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.grey),
            title: const Text('Statut personnalisé'),
            onTap: () {
              Navigator.pop(context);
              _showCustomStatusDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showCustomStatusDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statut personnalisé'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ex: En réunion, En congé...',
            border: OutlineInputBorder(),
          ),
          maxLength: 50,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final custom = controller.text.trim();
              if (custom.isNotEmpty) {
                onStatusSelected(UserStatus.online, custom);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
            ),
            child: const Text('Définir'),
          ),
        ],
      ),
    );
  }
}
