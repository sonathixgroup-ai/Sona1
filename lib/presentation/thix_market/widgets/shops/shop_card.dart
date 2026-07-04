import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShopCard extends StatefulWidget {
  final Map<String, dynamic> shop;
  final bool isOwner;
  final Function(Map<String, dynamic>)? onTap;
  final Function(String)? onFollow;
  final Function(String)? onUnfollow;
  final Function(String)? onShare;

  const ShopCard({
    super.key,
    required this.shop,
    this.isOwner = false,
    this.onTap,
    this.onFollow,
    this.onUnfollow,
    this.onShare,
  });

  @override
  State<ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<ShopCard> {
  bool _isFollowing = false;
  bool _isLoading = false;
  int _followersCount = 0;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.shop['is_followed'] ?? false;
    _followersCount = widget.shop['followers_count'] ?? 0;
  }

  Future<void> _toggleFollow() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      if (_isFollowing) {
        // Unfollow
        await Supabase.instance.client
            .from('shop_followers')
            .delete()
            .match({
              'shop_id': widget.shop['id'],
              'user_id': Supabase.instance.client.auth.currentUser!.id,
            });
        
        setState(() {
          _isFollowing = false;
          _followersCount--;
        });
        widget.onUnfollow?.call(widget.shop['id']);
      } else {
        // Follow
        await Supabase.instance.client
            .from('shop_followers')
            .insert({
              'shop_id': widget.shop['id'],
              'user_id': Supabase.instance.client.auth.currentUser!.id,
            });
        
        setState(() {
          _isFollowing = true;
          _followersCount++;
        });
        widget.onFollow?.call(widget.shop['id']);
      }
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}k';
    return num.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onTap?.call(widget.shop),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Logo
                  Stack(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: widget.shop['logo_url'] != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.shop['logo_url'],
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: Colors.grey[100],
                                    child: const Icon(Icons.store),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: Colors.grey[100],
                                    child: const Icon(Icons.store),
                                  ),
                                )
                              : Container(
                                  color: const Color(0xFFE5592F).withOpacity(0.1),
                                  child: const Icon(
                                    Icons.store,
                                    size: 30,
                                    color: Color(0xFFE5592F),
                                  ),
                                ),
                        ),
                      ),
                      if (widget.shop['is_verified'] == true)
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  
                  // Infos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.shop['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!widget.isOwner)
                              IconButton(
                                onPressed: _toggleFollow,
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Icon(
                                        _isFollowing
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        size: 20,
                                        color: _isFollowing
                                            ? Colors.red
                                            : Colors.grey[400],
                                      ),
                              ),
                            if (widget.onShare != null)
                              IconButton(
                                onPressed: () => widget.onShare?.call(widget.shop['id']),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(Icons.share, size: 18, color: Colors.grey[400]),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        RatingBar.builder(
                          initialRating: (widget.shop['rating'] ?? 0).toDouble(),
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: 14,
                          ignoreGestures: true,
                          itemBuilder: (_, __) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (_) {},
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.shop['products_count'] ?? 0} produits · ${_formatNumber(_followersCount)} abonnés',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (widget.shop['description'] != null) ...[
                const SizedBox(height: 12),
                Text(
                  widget.shop['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
              
              if (widget.isOwner && widget.shop['status'] != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.shop['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(widget.shop['status']),
                        size: 16,
                        color: _getStatusColor(widget.shop['status']),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getStatusText(widget.shop['status']),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(widget.shop['status']),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Gérer',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active': return Colors.green;
      case 'pending': return Colors.orange;
      case 'suspended': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'active': return Icons.check_circle;
      case 'pending': return Icons.hourglass_empty;
      case 'suspended': return Icons.warning;
      default: return Icons.info;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active': return 'Boutique active';
      case 'pending': return 'En attente de validation';
      case 'suspended': return 'Boutique suspendue';
      default: return 'Statut inconnu';
    }
  }
}
