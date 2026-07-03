// lib/presentation/chat/chat_status_update.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/chat_provider.dart';

class ChatStatusUpdatePage extends StatefulWidget {
  const ChatStatusUpdatePage({super.key});

  @override
  State<ChatStatusUpdatePage> createState() => _ChatStatusUpdatePageState();
}

class _ChatStatusUpdatePageState extends State<ChatStatusUpdatePage> {
  String _selectedStatus = 'online';
  final TextEditingController _customController = TextEditingController();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _statuses = [
    {'label': 'En ligne', 'value': 'online', 'color': Colors.green},
    {'label': 'Absent', 'value': 'away', 'color': Colors.orange},
    {'label': 'Occupé', 'value': 'busy', 'color': Colors.red},
    {'label': 'Hors ligne', 'value': 'offline', 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  Future<void> _loadCurrentStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getString('user_status') ?? 'online';
    final custom = prefs.getString('custom_status') ?? '';
    setState(() {
      _selectedStatus = status;
      _customController.text = custom;
    });
  }

  Future<void> _saveStatus() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_status', _selectedStatus);
    await prefs.setString('custom_status', _customController.text.trim());

    // Mettre à jour la présence via le provider
    final provider = context.read<ChatProvider>();
    await provider.updatePresence(_selectedStatus);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mettre à jour le statut'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveStatus,
            child: const Text(
              'Enregistrer',
              style: TextStyle(color: Color(0xFFD4AF37)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choisissez votre statut',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ..._statuses.map((status) {
              final isSelected = _selectedStatus == status['value'];
              return RadioListTile<String>(
                value: status['value'],
                groupValue: _selectedStatus,
                onChanged: (value) => setState(() => _selectedStatus = value!),
                title: Text(status['label']),
                secondary: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: status['color'],
                    shape: BoxShape.circle,
                  ),
                ),
                activeColor: const Color(0xFFD4AF37),
              );
            }).toList(),
            const SizedBox(height: 24),
            const Text(
              'Message personnalisé (optionnel)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customController,
              decoration: const InputDecoration(
                hintText: 'Que faites-vous ?',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLength: 30,
            ),
            const Spacer(),
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF0B1B3D),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Enregistrer le statut',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
