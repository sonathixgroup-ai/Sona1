// Route: lib/presentation/chat/call/incoming_call_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/chat/call_invite.dart';
import '../../../../models/chat/call_status.dart';
import 'call_page.dart';
import 'providers/call_provider.dart';
import 'widgets/call_avatar.dart';

class IncomingCallPage extends StatelessWidget {
  final CallInvite invite;
  const IncomingCallPage({super.key, required this.invite});

  @override
  Widget build(BuildContext context) {
    final isVideo = invite.callType == CallType.video;
    return Scaffold(
      backgroundColor: const Color(0xFF0A1F44),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 80),
            CallAvatar(name: invite.callerName?? 'Inconnu'),
            const SizedBox(height: 16),
            Text(invite.callerName?? 'Appel entrant',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(isVideo? 'Appel vidéo...' : 'Appel audio...',
                style: const TextStyle(color: Colors.white54)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _action(
                  icon: Icons.call_end,
                  color: Colors.red,
                  onTap: () async {
                    await context
                       .read<CallProvider>()
                       .accept(channel: '', inviteId: '', callType: CallType.audio)
                       .catchError((_) {});
                    if (context.mounted) Navigator.pop(context);
                  },
                  label: 'Refuser',
                ),
                _action(
                  icon: isVideo? Icons.videocam : Icons.call,
                  color: const Color(0xFF1FA971),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CallPage(
                          channel: invite.channelName,
                          name: invite.callerName?? 'Inconnu',
                          type: invite.callType,
                          inviteId: invite.id,
                          isCaller: false,
                        ),
                      ),
                    );
                  },
                  label: 'Accepter',
                ),
              ],
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String label,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: color,
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 28),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
