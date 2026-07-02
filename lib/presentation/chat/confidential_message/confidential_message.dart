// lib/presentation/chat/confidential_message/confidential_message.dart
// Widget de message confidentiel : nécessite un code ou biométrie pour être déverrouillé

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../core/chat_models.dart';
import '../core/chat_bloc.dart';
import '../core/chat_events.dart';

class ConfidentialMessageWidget extends StatefulWidget {
  final ConfidentialMessage message;
  final bool isMe;
  final String conversationId;

  const ConfidentialMessageWidget({
    Key? key,
    required this.message,
    required this.isMe,
    required this.conversationId,
  }) : super(key: key);

  @override
  State<ConfidentialMessageWidget> createState() => _ConfidentialMessageWidgetState();
}

class _ConfidentialMessageWidgetState extends State<ConfidentialMessageWidget> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isUnlocked = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isUnlocked = widget.message.isOpened;
  }

  Future<void> _unlockWithCode() async {
    final codeController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message confidentiel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ce message est protégé par un code.'),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                hintText: 'Entrez le code',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déverrouiller'),
          ),
        ],
      ),
    );

    if (result == true && codeController.text.isNotEmpty) {
      setState(() => _isLoading = true);
      final bloc = context.read<ChatBloc>();
      bloc.add(UnlockConfidentialMessage(widget.message.id, codeController.text));
      // Attendre le résultat via BlocListener (simplifié ici, on écoute l'état)
      // Pour l'exemple, on suppose que l'état changera et on mettra à jour.
    }
  }

  Future<void> _unlockWithBiometrics() async {
    setState(() => _isLoading = true);
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        setState(() => _error = 'Biométrie non disponible');
        return;
      }
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Vérifiez votre identité pour voir ce message confidentiel',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (authenticated) {
        final bloc = context.read<ChatBloc>();
        bloc.add(UnlockConfidentialMessage(widget.message.id, 'biometric_placeholder'));
        setState(() => _isUnlocked = true);
      } else {
        setState(() => _error = 'Authentification échouée');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isUnlocked) {
      // Message déverrouillé : affichage normal
      return Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: widget.isMe ? Colors.blue[100] : Colors.grey[200],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: widget.isMe ? const Radius.circular(16) : const Radius.circular(4),
              bottomRight: widget.isMe ? const Radius.circular(4) : const Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_open, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  const Text('Message confidentiel (déverrouillé)',
                      style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                ],
              ),
              const SizedBox(height: 4),
              Text(widget.message.content ?? '', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                _formatTime(widget.message.sentAt),
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Message verrouillé
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: widget.isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: widget.isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                const Text('Message confidentiel (verrouillé)',
                    style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (widget.message.isBiometric)
                ElevatedButton.icon(
                  onPressed: _unlockWithBiometrics,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Déverrouiller avec biométrie'),
                ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _unlockWithCode,
                icon: const Icon(Icons.pin),
                label: const Text('Déverrouiller avec code'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatTime(widget.message.sentAt),
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
