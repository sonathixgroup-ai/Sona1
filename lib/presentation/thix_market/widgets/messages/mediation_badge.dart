import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MediationBadge extends StatefulWidget {
  final String disputeId;
  final String? currentMediatorId;

  const MediationBadge({
    super.key,
    required this.disputeId,
    this.currentMediatorId,
  });

  @override
  State<MediationBadge> createState() => _MediationBadgeState();
}

class _MediationBadgeState extends State<MediationBadge> {
  Map<String, dynamic>? _mediation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMediation();
  }

  Future<void> _loadMediation() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await Supabase.instance.client
          .from('mediations')
          .select('*, mediator:users(name, avatar, rating)')
          .eq('dispute_id', widget.disputeId)
          .maybeSingle();
      
      setState(() {
        _mediation = response;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading mediation: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestMediation() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    
    try {
      await Supabase.instance.client
          .from('mediations')
          .insert({
            'dispute_id': widget.disputeId,
            'status': 'pending',
            'requested_by': userId,
            'requested_at': DateTime.now().toIso8601String(),
          });
      
      await _loadMediation();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande de médiation envoyée')),
        );
      }
    } catch (e) {
      debugPrint('Error requesting mediation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_mediation != null) {
      final status = _mediation!['status'];
      final mediator = _mediation!['mediator'];
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: status == 'accepted' 
                ? [Colors.green, Colors.lightGreen]
                : status == 'pending'
                    ? [Colors.orange, Colors.orangeAccent]
                    : [Colors.blue, Colors.lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.gavel, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status == 'accepted' ? 'Médiation acceptée' :
                  status == 'pending' ? 'Médiation en attente' : 'Médiation en cours',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                if (mediator != null)
                  Text(
                    'Médiateur: ${mediator['name']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            if (status == 'accepted')
              const Icon(Icons.check_circle, size: 16, color: Colors.white),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _requestMediation,
      icon: const Icon(Icons.gavel, size: 16),
      label: const Text('Demander une médiation'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE5592F),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
