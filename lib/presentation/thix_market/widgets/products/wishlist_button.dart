import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WishlistButton extends StatefulWidget {
  final String productId;
  final bool initialIsFavorite;
  final Function(bool)? onChanged;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const WishlistButton({
    super.key,
    required this.productId,
    this.initialIsFavorite = false,
    this.onChanged,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends State<WishlistButton>
    with SingleTickerProviderStateMixin {
  late bool _isFavorite;
  bool _isLoading = false;

  // Animation pour le tap
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.initialIsFavorite;

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _toggleWishlist() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      _showLoginRequired();
      return;
    }

    // Animation au tap
    _scaleController.forward().then((_) => _scaleController.reverse());

    setState(() => _isLoading = true);

    try {
      if (_isFavorite) {
        // Supprimer des favoris
        await Supabase.instance.client
            .from('wishlist')
            .delete()
            .match({
              'user_id': userId,
              'product_id': widget.productId,
            });
      } else {
        // Ajouter aux favoris
        await Supabase.instance.client
            .from('wishlist')
            .insert({
              'user_id': userId,
              'product_id': widget.productId,
              'created_at': DateTime.now().toIso8601String(),
            });
      }

      setState(() {
        _isFavorite = !_isFavorite;
        _isLoading = false;
      });

      widget.onChanged?.call(_isFavorite);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? 'Ajouté aux favoris' : 'Retiré des favoris'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling wishlist: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Une erreur est survenue')),
        );
      }
    }
  }

  void _showLoginRequired() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text('Veuillez vous connecter pour ajouter des produits à vos favoris'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigation GoRouter
              context.go('/login');
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
      onTap: _toggleWishlist,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          child: _isLoading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: widget.size,
                  height: widget.size,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _isFavorite
                        ? (widget.activeColor ?? Colors.red)
                        : Colors.grey,
                  ),
                )
              : Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey(_isFavorite),
                  size: widget.size,
                  color: _isFavorite
                      ? (widget.activeColor ?? Colors.red)
                      : (widget.inactiveColor ?? Colors.grey),
                ),
        ),
      ),
    );
  }
}
