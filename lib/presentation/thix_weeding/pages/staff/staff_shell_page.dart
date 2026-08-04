// lib/presentation/thix_weeding/pages/staff/staff_shell_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'staff_dashboard_page.dart';
import 'invités/guest_list_page.dart';
import 'messages/staff_messages_page.dart';
import 'parametres/settings_page.dart';

class StaffShellPage extends StatefulWidget {
  final String weddingId;
  const StaffShellPage({super.key, required this.weddingId});
  @override
  State<StaffShellPage> createState() => _StaffShellPageState();
}

class _StaffShellPageState extends State<StaffShellPage> {
  int _index = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      StaffDashboardPage(weddingId: widget.weddingId),
      GuestListPage(weddingId: widget.weddingId),
      const SizedBox(), // Ajouter -> ouvre bottomSheet
      StaffMessagesPage(weddingId: widget.weddingId),
      SettingsPage(weddingId: widget.weddingId),
    ];
  }

  void _onTap(int i) {
    if (i == 2) {
      _showAddSheet();
      return;
    }
    setState(() => _index = i);
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.person_add), title: const Text('Ajouter un invité'), onTap: () { context.pop(); context.push('/thix-weeding/staff/${widget.weddingId}/invites/add'); }),
          ListTile(leading: const Icon(Icons.store), title: const Text('Ajouter un prestataire'), onTap: () { context.pop(); context.push('/thix-weeding/staff/${widget.weddingId}/prestataires/add'); }),
          ListTile(leading: const Icon(Icons.task), title: const Text('Ajouter une tâche'), onTap: () { context.pop(); context.push('/thix-weeding/staff/${widget.weddingId}/checklist/add'); }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0B3B8F),
        unselectedItemColor: const Color(0xFF6B7280),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          const BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Invités'),
          BottomNavigationBarItem(icon: Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Color(0xFF0B3B8F), shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.white)), label: 'Ajouter'),
          BottomNavigationBarItem(icon: Badge(label: const Text('5'), child: const Icon(Icons.chat_bubble_outline)), label: 'Messages'),
          const BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Paramètres'),
        ],
      ),
    );
  }
}
