// lib/presentation/chat/home_widgets/chat_widget_config.dart
// Configuration du widget d'écran d'accueil : conversations + raccourcis rapides

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widget_preview.dart';

class ChatWidgetConfig extends StatefulWidget {
  const ChatWidgetConfig({Key? key}) : super(key: key);

  @override
  State<ChatWidgetConfig> createState() => _ChatWidgetConfigState();
}

class _ChatWidgetConfigState extends State<ChatWidgetConfig> {
  bool _showRecentConversations = true;
  int _conversationCount = 3;
  bool _showShortcuts = true;
  bool _shortcutNewMessage = true;
  bool _shortcutNewCall = true;
  bool _shortcutCamera = false;
  bool _isLoading = true;

  static const String _keyShowConversations = 'widget_show_conversations';
  static const String _keyConversationCount = 'widget_conversation_count';
  static const String _keyShowShortcuts = 'widget_show_shortcuts';
  static const String _keyShortcutNewMessage = 'widget_shortcut_new_message';
  static const String _keyShortcutNewCall = 'widget_shortcut_new_call';
  static const String _keyShortcutCamera = 'widget_shortcut_camera';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _showRecentConversations = prefs.getBool(_keyShowConversations) ?? true;
      _conversationCount = prefs.getInt(_keyConversationCount) ?? 3;
      _showShortcuts = prefs.getBool(_keyShowShortcuts) ?? true;
      _shortcutNewMessage = prefs.getBool(_keyShortcutNewMessage) ?? true;
      _shortcutNewCall = prefs.getBool(_keyShortcutNewCall) ?? true;
      _shortcutCamera = prefs.getBool(_keyShortcutCamera) ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowConversations, _showRecentConversations);
    await prefs.setInt(_keyConversationCount, _conversationCount);
    await prefs.setBool(_keyShowShortcuts, _showShortcuts);
    await prefs.setBool(_keyShortcutNewMessage, _shortcutNewMessage);
    await prefs.setBool(_keyShortcutNewCall, _shortcutNewCall);
    await prefs.setBool(_keyShortcutCamera, _shortcutCamera);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Widget mis à jour')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget d\'accueil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'Aperçu',
            onPressed: _openPreview,
          ),
        ],
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Personnalisez ce qui apparaît sur le widget THIX Chat de votre écran d\'accueil.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          SwitchListTile(
            title: const Text('Afficher les conversations récentes'),
            value: _showRecentConversations,
            onChanged: (val) => setState(() => _showRecentConversations = val),
          ),
          if (_showRecentConversations)
            ListTile(
              title: const Text('Nombre de conversations'),
              subtitle: Slider(
                value: _conversationCount.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$_conversationCount',
                onChanged: (val) => setState(() => _conversationCount = val.toInt()),
              ),
            ),
          const Divider(),
          SwitchListTile(
            title: const Text('Afficher les raccourcis rapides'),
            value: _showShortcuts,
            onChanged: (val) => setState(() => _showShortcuts = val),
          ),
          if (_showShortcuts) ...[
            CheckboxListTile(
              title: const Text('Nouveau message'),
              value: _shortcutNewMessage,
              onChanged: (val) => setState(() => _shortcutNewMessage = val ?? false),
            ),
            CheckboxListTile(
              title: const Text('Nouvel appel'),
              value: _shortcutNewCall,
              onChanged: (val) => setState(() => _shortcutNewCall = val ?? false),
            ),
            CheckboxListTile(
              title: const Text('Appareil photo'),
              value: _shortcutCamera,
              onChanged: (val) => setState(() => _shortcutCamera = val ?? false),
            ),
          ],
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }

  void _openPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WidgetPreview(
          showConversations: _showRecentConversations,
          conversationCount: _conversationCount,
          showShortcuts: _showShortcuts,
          shortcutNewMessage: _shortcutNewMessage,
          shortcutNewCall: _shortcutNewCall,
          shortcutCamera: _shortcutCamera,
        ),
      ),
    );
  }
}
