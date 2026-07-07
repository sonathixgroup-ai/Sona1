// lib/presentation/thix_market/pages/price_alert.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PriceAlert extends StatefulWidget {
  final String productId;
  final String productTitle;
  final double currentPrice;
  final String? currency; // ✅ ajout de la devise

  const PriceAlert({
    super.key,
    required this.productId,
    required this.productTitle,
    required this.currentPrice,
    this.currency,
  });

  @override
  State<PriceAlert> createState() => _PriceAlertState();
}

class _PriceAlertState extends State<PriceAlert> {
  final TextEditingController _targetPriceController = TextEditingController();
  bool _isLoading = false;
  bool _hasAlert = false;
  Map<String, dynamic>? _existingAlert;

  // ─── Palette Élite ──────────────────────────────────────────────
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color softBlue = Color(0xFFEFF5FF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);
  static const Color gold = Color(0xFFE3B23C);
  static const Color danger = Color(0xFFFF5B3D);

  @override
  void initState() {
    super.initState();
    _checkExistingAlert();
  }

  @override
  void dispose() {
    _targetPriceController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingAlert() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('price_alerts')
          .select()
          .match({
            'user_id': userId,
            'product_id': widget.productId,
            'is_active': true,
          })
          .maybeSingle();

      if (response != null) {
        setState(() {
          _existingAlert = response;
          _hasAlert = true;
          _targetPriceController.text = (response['target_price'] as num).toString();
        });
      }
    } catch (e) {
      debugPrint('Error checking alert: $e');
    }
  }

  Future<void> _createAlert() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      _showLoginRequired();
      return;
    }

    final targetPrice = double.tryParse(_targetPriceController.text);
    if (targetPrice == null || targetPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un prix valide')),
      );
      return;
    }

    if (targetPrice >= widget.currentPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le prix cible doit être inférieur au prix actuel'),
          backgroundColor: danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client
          .from('price_alerts')
          .insert({
            'user_id': userId,
            'product_id': widget.productId,
            'product_title': widget.productTitle,
            'current_price': widget.currentPrice,
            'target_price': targetPrice,
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
          });

      setState(() {
        _hasAlert = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerte de prix créée'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error creating alert: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la création')),
      );
    }
  }

  Future<void> _deleteAlert() async {
    if (_existingAlert == null) return;

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client
          .from('price_alerts')
          .update({'is_active': false})
          .eq('id', _existingAlert!['id']);

      setState(() {
        _hasAlert = false;
        _existingAlert = null;
        _targetPriceController.clear();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerte supprimée'), backgroundColor: Colors.grey),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error deleting alert: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la suppression')),
      );
    }
  }

  void _showLoginRequired() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Connexion requise', style: TextStyle(color: darkText)),
        content: const Text('Veuillez vous connecter pour créer une alerte de prix'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: mutedText)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: pureWhite,
            ),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final symbol = widget.currency == 'USD' ? '\$' : 'FC';

    return GestureDetector(
      onTap: _showAlertDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _hasAlert ? Colors.green.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hasAlert ? Colors.green : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_active_rounded,
              size: 16,
              color: _hasAlert ? Colors.green : mutedText,
            ),
            const SizedBox(width: 4),
            Text(
              _hasAlert ? 'Alerte active' : 'Alerte prix',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _hasAlert ? Colors.green : mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlertDialog() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _showLoginRequired();
      return;
    }

    final symbol = widget.currency == 'USD' ? '\$' : 'FC';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _hasAlert ? 'Gérer l\'alerte' : 'Créer une alerte de prix',
          style: const TextStyle(
            color: darkText,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Produit: ${widget.productTitle}',
              style: const TextStyle(fontWeight: FontWeight.w600, color: darkText),
            ),
            const SizedBox(height: 4),
            Text(
              'Prix actuel: ${widget.currentPrice.toInt()} $symbol',
              style: TextStyle(color: mutedText, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (!_hasAlert) ...[
              const Text(
                'Recevez une notification quand le prix descend en dessous de :',
                style: TextStyle(fontSize: 13, color: darkText),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _targetPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Prix cible',
                  suffixText: symbol,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryBlue, width: 2),
                  ),
                ),
              ),
            ] else ...[
              _buildInfoRow('Prix cible', '${_existingAlert?['target_price']} $symbol'),
              const SizedBox(height: 6),
              _buildInfoRow('Créée le', _formatDate(_existingAlert?['created_at'])),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: mutedText)),
          ),
          if (_hasAlert)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteAlert();
              },
              style: TextButton.styleFrom(foregroundColor: danger),
              child: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          if (!_hasAlert)
            ElevatedButton(
              onPressed: _isLoading ? null : _createAlert,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: pureWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Créer', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: mutedText),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: darkText),
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} à ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}
