import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PriceAlert extends StatefulWidget {
  final String productId;
  final String productTitle;
  final double currentPrice;

  const PriceAlert({
    super.key,
    required this.productId,
    required this.productTitle,
    required this.currentPrice,
  });

  @override
  State<PriceAlert> createState() => _PriceAlertState();
}

class _PriceAlertState extends State<PriceAlert> {
  final TextEditingController _targetPriceController = TextEditingController();
  bool _isLoading = false;
  bool _hasAlert = false;
  Map<String, dynamic>? _existingAlert;

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
        const SnackBar(content: Text('Le prix cible doit être inférieur au prix actuel')),
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
          const SnackBar(content: Text('Alerte de prix créée')),
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
          const SnackBar(content: Text('Alerte supprimée')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error deleting alert: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showLoginRequired() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text('Veuillez vous connecter pour créer une alerte de prix'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5592F),
            ),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAlertDialog(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _hasAlert ? Colors.green.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hasAlert ? Colors.green : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_active,
              size: 16,
              color: _hasAlert ? Colors.green : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              _hasAlert ? 'Alerte active' : 'Alerte prix',
              style: TextStyle(
                fontSize: 12,
                color: _hasAlert ? Colors.green : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlertDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_hasAlert ? 'Gérer l\'alerte' : 'Créer une alerte de prix'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Produit: ${widget.productTitle}'),
            const SizedBox(height: 8),
            Text('Prix actuel: ${widget.currentPrice.toInt()} FCFA'),
            const SizedBox(height: 16),
            if (!_hasAlert) ...[
              const Text(
                'Recevez une notification quand le prix descend en dessous de:',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _targetPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Prix cible',
                  suffixText: 'FCFA',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ] else ...[
              Text('Prix cible: ${_existingAlert?['target_price']} FCFA'),
              const SizedBox(height: 8),
              Text('Créée le: ${_formatDate(_existingAlert?['created_at'])}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          if (_hasAlert)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteAlert();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          if (!_hasAlert)
            ElevatedButton(
              onPressed: _createAlert,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5592F),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Créer'),
            ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year}';
  }
}
