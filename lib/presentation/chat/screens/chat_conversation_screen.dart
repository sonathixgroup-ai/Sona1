import 'dart:async';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/services/chat_service.dart';
import 'package:thix_id/theme.dart';
import 'package:thix_id/utils/time_ago.dart';

class ChatConversationScreen extends StatefulWidget {
  final String chatId;
  final String title;
  final String type;

  const ChatConversationScreen({super.key, required this.chatId, required this.title, required this.type});

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  late final ChatService _chat = ChatService();
  StreamSubscription<List<ChatMessage>>? _sub;
  List<ChatMessage> _messages = const [];
  bool _loading = true;
  Object? _error;

  final TextEditingController _composer = TextEditingController();
  bool _sending = false;

  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;
  DateTime? _recordingStartedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bind());
  }

  void _bind() {
    final me = context.read<AuthController>().currentUser;
    if (me == null) {
      setState(() {
        _loading = false;
        _error = 'not_logged_in';
      });
      return;
    }

    _sub?.cancel();
    _sub = _chat.streamMessages(widget.chatId).listen((rows) {
      if (!mounted) return;
      setState(() {
        _messages = rows;
        _loading = false;
        _error = null;
      });
      // Mark as read opportunistically.
      _chat.markChatRead(chatId: widget.chatId, uid: me.id);
    }, onError: (e) {
      debugPrint('ChatConversationScreen: stream failed err=$e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _composer.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final me = context.read<AuthController>().currentUser;
    if (me == null) return;
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _sending = true;
    });
    try {
      _composer.clear();
      await _chat.sendMessage(chatId: widget.chatId, sender: me, text: text);
    } catch (e) {
      debugPrint('ChatConversationScreen: sendText failed err=$e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'envoyer le message.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickFile() async {
    final me = context.read<AuthController>().currentUser;
    if (me == null) return;
    try {
      final res = await FilePicker.platform.pickFiles(withData: kIsWeb);
      final f = res?.files.firstOrNull;
      if (f == null) return;
      setState(() => _sending = true);
      await _chat.sendAttachment(chatId: widget.chatId, sender: me, file: f);
    } catch (e) {
      debugPrint('ChatConversationScreen: pickFile failed err=$e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fichier non envoyé.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleRecording() async {
    final me = context.read<AuthController>().currentUser;
    if (me == null) return;
    try {
      if (_recording) {
        final path = await _recorder.stop();
        setState(() {
          _recording = false;
          _recordingStartedAt = null;
        });
        if (path == null || path.trim().isEmpty) return;

        // We already have a local path. Create a synthetic PlatformFile.
        final file = PlatformFile(name: 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a', size: 0, path: path);
        setState(() => _sending = true);
        await _chat.sendAttachment(chatId: widget.chatId, sender: me, file: file);
        return;
      }

      final ok = await _recorder.hasPermission();
      if (!ok) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission micro refusée.')));
        return;
      }
      final path = 'thix_chat_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100), path: path);
      setState(() {
        _recording = true;
        _recordingStartedAt = DateTime.now();
      });
    } catch (e) {
      debugPrint('ChatConversationScreen: toggleRecording failed err=$e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enregistrement indisponible.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final me = context.watch<AuthController>().currentUser;
    final messages = _messages;
    final isGroup = widget.type == 'group';

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          const _ConversationBackdrop(),
          SafeArea(
            child: Column(
              children: [
                _ConversationAppBar(
                  title: widget.title,
                  subtitle: isGroup ? '12 membres • 8 en ligne' : 'En ligne',
                  onBack: () => context.pop(),
                ),
                if (isGroup)
                  const _ConversationTopTabs(
                    tabs: ['Discussion', 'Membres', 'Fichiers', 'Tâches', 'Paramètres'],
                  ),
                const SizedBox(height: 8),
                const _PinnedMessageBanner(),
                Expanded(
                  child: _loading
                      ? const _MessageListSkeleton()
                      : (_error != null
                          ? _InlineStateCard(
                              icon: Icons.wifi_off_rounded,
                              title: _error == 'not_logged_in' ? 'Connexion requise' : 'Erreur de chargement',
                              subtitle: 'Impossible de charger cette conversation.',
                              actionLabel: 'Réessayer',
                              onAction: _bind,
                            )
                          : _MessageList(
                              messages: messages,
                              myUid: me?.id ?? '',
                            )),
                ),
                _ComposerBar(
                  controller: _composer,
                  busy: _sending,
                  recording: _recording,
                  recordingStartedAt: _recordingStartedAt,
                  onAttach: _pickFile,
                  onMic: _toggleRecording,
                  onSend: _sendText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationBackdrop extends StatelessWidget {
  const _ConversationBackdrop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c0 = isDark ? EventsCyberColors.bg0 : LightModeColors.background;
    final c1 = isDark ? EventsCyberColors.bg1 : Colors.white;
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c0, c1]),
        ),
      ),
    );
  }
}

class _ConversationAppBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  const _ConversationAppBar({required this.title, required this.subtitle, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.95),
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.25))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          const SizedBox(width: 2),
          CircleAvatar(
            radius: 20,
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Text(title.isEmpty ? '?' : title[0].toUpperCase(), style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: LightModeColors.success, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant))),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.call_rounded, color: cs.primary),
            tooltip: 'Appel',
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.videocam_rounded, color: cs.primary),
            tooltip: 'Vidéo',
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert_rounded, color: cs.onSurfaceVariant),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _ConversationTopTabs extends StatefulWidget {
  final List<String> tabs;
  const _ConversationTopTabs({required this.tabs});

  @override
  State<_ConversationTopTabs> createState() => _ConversationTopTabsState();
}

class _ConversationTopTabsState extends State<_ConversationTopTabs> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: widget.tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final selected = i == _index;
          return InkWell(
            onTap: () => setState(() => _index = i),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(widget.tabs[i], style: Theme.of(context).textTheme.labelLarge?.copyWith(color: selected ? cs.primary : cs.onSurfaceVariant, fontWeight: selected ? FontWeight.w900 : FontWeight.w700)),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  height: 3,
                  width: 46,
                  decoration: BoxDecoration(color: selected ? cs.primary : Colors.transparent, borderRadius: BorderRadius.circular(99)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PinnedMessageBanner extends StatelessWidget {
  const _PinnedMessageBanner();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(Icons.push_pin_rounded, color: cs.primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Message épinglé', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: cs.primary)),
                  const SizedBox(height: 2),
                  Text('Réunion projet THIX ce vendredi à 14h…', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final String myUid;
  const _MessageList({required this.messages, required this.myUid});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final m = messages[i];
        final isMe = m.senderId == myUid;
        final time = m.createdAt == null ? '' : formatTimeAgo(m.createdAt!);
        final attachmentUrl = (m.extra['download_url'] as String?)?.trim();
        final fileName = (m.extra['file_name'] as String?)?.trim();

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isMe) ...[
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: cs.primary.withValues(alpha: 0.12),
                      child: Text((m.senderName.isEmpty ? 'U' : m.senderName[0]).toUpperCase(), style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isMe ? cs.primary : cs.surface.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isMe ? 18 : 6),
                          bottomRight: Radius.circular(isMe ? 6 : 18),
                        ),
                        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.22)),
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (attachmentUrl != null && attachmentUrl.isNotEmpty)
                            _AttachmentCard(
                              fileName: fileName ?? 'Fichier',
                              url: attachmentUrl,
                              isMe: isMe,
                            ),
                          if (m.text.trim().isNotEmpty)
                            Text(m.text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isMe ? cs.onPrimary : cs.onSurface, height: 1.35)),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(time, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: (isMe ? cs.onPrimary : cs.onSurfaceVariant).withValues(alpha: 0.8))),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  final String fileName;
  final String url;
  final bool isMe;
  const _AttachmentCard({required this.fileName, required this.url, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: (isMe ? cs.onPrimary.withValues(alpha: 0.14) : cs.surfaceContainerHighest.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.20)),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(Icons.insert_drive_file_rounded, color: isMe ? cs.onPrimary : cs.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isMe ? cs.onPrimary : cs.onSurface, fontWeight: FontWeight.w700))),
            const SizedBox(width: 10),
            Icon(Icons.download_rounded, color: isMe ? cs.onPrimary : cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _ComposerBar extends StatefulWidget {
  final TextEditingController controller;
  final bool busy;
  final bool recording;
  final DateTime? recordingStartedAt;
  final VoidCallback onAttach;
  final VoidCallback onMic;
  final VoidCallback onSend;

  const _ComposerBar({
    required this.controller,
    required this.busy,
    required this.recording,
    required this.recordingStartedAt,
    required this.onAttach,
    required this.onMic,
    required this.onSend,
  });

  @override
  State<_ComposerBar> createState() => _ComposerBarState();
}

class _ComposerBarState extends State<_ComposerBar> {
  bool _pressedSend = false;
  void _setPressed(bool v) {
    if (_pressedSend == v) return;
    setState(() => _pressedSend = v);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final canSend = widget.controller.text.trim().isNotEmpty && !widget.busy && !widget.recording;
    final recordingFor = widget.recordingStartedAt == null ? null : DateTime.now().difference(widget.recordingStartedAt!);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.92),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    _CircleAction(
                      icon: Icons.add_rounded,
                      onTap: widget.busy ? null : widget.onAttach,
                      foreground: cs.primary,
                      background: cs.primary.withValues(alpha: 0.10),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        onChanged: (_) => setState(() {}),
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: widget.recording ? 'Enregistrement…' : 'Écrivez un message…',
                          border: InputBorder.none,
                        ),
                        enabled: !widget.busy && !widget.recording,
                      ),
                    ),
                    if (widget.recording && recordingFor != null) ...[
                      const SizedBox(width: 6),
                      Text('${recordingFor.inSeconds}s', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.error, fontWeight: FontWeight.w900)),
                    ],
                    const SizedBox(width: 8),
                    _CircleAction(
                      icon: widget.recording ? Icons.stop_rounded : Icons.mic_rounded,
                      onTap: widget.busy ? null : widget.onMic,
                      foreground: widget.recording ? cs.onError : cs.primary,
                      background: widget.recording ? cs.error : cs.primary.withValues(alpha: 0.10),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: canSend ? widget.onSend : null,
                      onTapDown: (_) => _setPressed(true),
                      onTapCancel: () => _setPressed(false),
                      onTapUp: (_) => _setPressed(false),
                      child: AnimatedScale(
                        scale: _pressedSend ? 0.96 : 1,
                        duration: const Duration(milliseconds: 120),
                        child: _CircleAction(
                          icon: Icons.send_rounded,
                          onTap: canSend ? widget.onSend : null,
                          foreground: cs.onPrimary,
                          background: canSend ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _QuickAction(label: 'Galerie', icon: Icons.photo_library_rounded),
                _QuickAction(label: 'Document', icon: Icons.insert_drive_file_rounded),
                _QuickAction(label: 'Localisation', icon: Icons.location_on_rounded),
                _QuickAction(label: 'Contact', icon: Icons.person_add_alt_1_rounded),
                _QuickAction(label: 'Paiement', icon: Icons.payments_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color foreground;
  final Color background;
  const _CircleAction({required this.icon, required this.onTap, required this.foreground, required this.background});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: foreground, size: 22),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  const _QuickAction({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.primary, size: 18),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface)),
          ],
        ),
      ),
    );
  }
}

class _PillIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;
  const _PillIconButton({required this.icon, required this.tooltip, required this.background, required this.foreground, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: onTap == null ? foreground.withValues(alpha: 0.45) : foreground),
        ),
      ),
    );
  }
}

class _InlineStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InlineStateCard({required this.icon, required this.title, required this.subtitle, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(color: cs.surface.withValues(alpha: 0.76), border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25))),
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 56, height: 56, decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: cs.primary)),
                  const SizedBox(height: 12),
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 12),
                    FilledButton(onPressed: onAction, child: Text(actionLabel!)),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageListSkeleton extends StatelessWidget {
  const _MessageListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: 14,
      itemBuilder: (_, i) => Align(
        alignment: i.isEven ? Alignment.centerLeft : Alignment.centerRight,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: _BubbleSkeleton(),
        ),
      ),
    );
  }
}

class _BubbleSkeleton extends StatefulWidget {
  const _BubbleSkeleton();

  @override
  State<_BubbleSkeleton> createState() => _BubbleSkeletonState();
}

class _BubbleSkeletonState extends State<_BubbleSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 0.92).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: Container(
        width: 220,
        height: 44,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.18)),
        ),
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
