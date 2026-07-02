// lib/presentation/chat/archive/password_lock_dialog.dart
// Dialogue pour protéger l'accès aux archives par mot de passe (PIN)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class PasswordLockDialog extends StatefulWidget {
  final VoidCallback onUnlocked;

  const PasswordLockDialog({Key? key, required this.onUnlocked}) : super(key: key);

  @override
  State<PasswordLockDialog> createState() => _PasswordLockDialogState();
}

class _PasswordLockDialogState extends State<PasswordLockDialog> {
  final TextEditingController _pinController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Protection des archives'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Cette section est protégée par un code PIN.'),
          const SizedBox(height: 12),
          TextField(
            controller: _pinController,
            decoration: const InputDecoration(
              hintText: 'Code PIN',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _authenticateWithBiometrics,
            icon: const Icon(Icons.fingerprint),
            label: const Text('Utiliser biométrie'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyPin,
          child: _isLoading ? const CircularProgressIndicator(strokeWidth: 2) : const Text('Déverrouiller'),
        ),
      ],
    );
  }

  Future<void> _verifyPin() async {
    final entered = _pinController.text.trim();
    if (entered.isEmpty) return;
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString('archive_pin');
    if (storedPin == entered) {
      widget.onUnlocked();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code incorrect')));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _authenticateWithBiometrics() async {
    final isAvailable = await _localAuth.canCheckBiometrics;
    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biométrie non disponible')));
      return;
    }
    final authenticated = await _localAuth.authenticate(
      localizedReason: 'Authentifiez-vous pour accéder aux archives',
    );
    if (authenticated) {
      widget.onUnlocked();
      Navigator.pop(context);
    }
  }
}
