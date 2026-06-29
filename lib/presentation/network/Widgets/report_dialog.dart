import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportDialog extends StatefulWidget {
  final String contentType; // 'post', 'user', 'comment'
  final String contentId;
  final String? reportedUserId;
  final String? postId;

  const ReportDialog({
    super.key,
    required this.contentType,
    required this.contentId,
    this.reportedUserId,
    this.postId,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String _selectedReason = 'contenu_inapproprié';
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  final Map<String, String> _reasons = {
    'contenu_inapproprié': 'Contenu inapproprié',
    'spam': 'Spam ou publicité',
    'harcelement': 'Harcèlement ou intimidation',
    'fausse_info': 'Fausse information',
    'violence': 'Violence ou incitation à la haine',
    'discrimination': 'Discrimination (race, genre, religion)',
    'droit_auteur': 'Violation des droits d\'auteur',
    'compte_factice': 'Compte factice ou usurpation d\'identité',
    'autre': 'Autre',
  };

  @override
  void initState() {
    super.initState();
    _checkIfSelfReport();
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _checkIfSelfReport() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (widget.reportedUserId != null && widget.reportedUserId == currentUserId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous ne pouvez pas signaler votre propre contenu'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    }
  }

  Future<void> _confirmAndSubmit() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer le signalement'),
        content: const Text('Voulez-vous vraiment signaler ce contenu ? Cette action est anonyme et nous l\'examinerons rapidement.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _submitReport();
    }
  }

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Vous devez être connecté pour signaler');
      }

      await Supabase.instance.client.from('reports').insert({
        'content_type': widget.contentType,
        'content_id': widget.contentId,
        'reported_user_id': widget.reportedUserId,
        'post_id': widget.postId,
        'reporter_id': currentUser.id,
        'reason': _selectedReason,
        'details': _detailsController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merci pour votre signalement. Nous allons l\'examiner.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _getTitle() {
    switch (widget.contentType) {
      case 'post':
        return 'Signaler cette publication';
      case 'user':
        return 'Signaler cet utilisateur';
      case 'comment':
        return 'Signaler ce commentaire';
      default:
        return 'Signaler';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _getTitle(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Pourquoi signalez-vous ce contenu ?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: _reasons.entries.map((entry) => RadioListTile<String>(
                    title: Text(entry.value, style: const TextStyle(fontSize: 14)),
                    value: entry.key,
                    groupValue: _selectedReason,
                    onChanged: (value) {
                      setState(() {
                        _selectedReason = value!;
                      });
                    },
                    activeColor: const Color(0xFFD4AF37),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  )).toList(),
                ),
              ),
            ),
            if (_selectedReason == 'autre') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _detailsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Décrivez le problème...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _confirmAndSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('SIGNALER', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
