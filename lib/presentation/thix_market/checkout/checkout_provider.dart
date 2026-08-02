// ========== CRÉATION COMMANDE (avec validation stock) ==========
  Future<Map<String, dynamic>> createOrderOnly({
    required double total,
    required List<Map<String, dynamic>> items,
  }) async {
    final db = ref.read(supabaseClientProvider);
    final userId = db.auth.currentUser?.id;
    if (userId == null) throw Exception('Non connecté');
    if (state.selectedAddress == null) throw Exception('Adresse requise');
    if (state.selectedShipping == null) throw Exception('Mode livraison requis');
    if (state.selectedPayment == null) throw Exception('Paiement requis');
    if (items.isEmpty) throw Exception('Panier vide');

    state = state.copyWith(isProcessing: true);

    try {
      // ===== 1. VALIDATION STOCK =====
      for (final item in items) {
        final productId = item['product_id'] ??
            (item['product'] is Map ? (item['product'] as Map)['id'] : null);
        final qty = (item['quantity'] as num?)?.toInt() ?? 1;

        if (productId == null) continue;

        final product = await db
            .from('products')
            .select('stock, title')
            .eq('id', productId)
            .maybeSingle();

        if (product == null) {
          throw Exception('Produit introuvable');
        }

        final stock = (product['stock'] as num?)?.toInt() ?? 0;
        final title = product['title']?.toString() ?? 'Produit';

        if (stock <= 0) {
          throw Exception('Rupture de stock : $title');
        }
        if (qty > stock) {
          throw Exception('Stock insuffisant pour $title (dispo: $stock)');
        }
      }

      // ===== 2. CRÉATION COMMANDE =====
      String? shopId;
      if (items.isNotEmpty) {
        final first = items.first;
        if (first['product'] is Map &&
            (first['product'] as Map)['shop_id'] != null) {
          shopId = (first['product'] as Map)['shop_id'].toString();
        } else if (first['shop_id'] != null) {
          shopId = first['shop_id'].toString();
        }
      }

      final orderData = {
        'user_id': userId,
        'shop_id': shopId,
        'address_id': state.selectedAddress!['id'],
        'shipping_method': state.selectedShipping!['id'],
        'shipping_cost': state.selectedShipping!['price'] ?? 0.0,
        'total': total,
        'status': 'pending',
        'payment_status': 'awaiting_payment',
        'created_at': DateTime.now().toIso8601String(),
      };

      final orderRes =
          await db.from('orders').insert(orderData).select().single();

      for (var item in items) {
        String prodTitle = item['product_name']?.toString() ?? 'Produit';
        if (item['product'] is Map &&
            (item['product'] as Map)['title'] != null) {
          prodTitle = (item['product'] as Map)['title'].toString();
        }

        final productId = item['product_id'] ??
            (item['product'] is Map ? (item['product'] as Map)['id'] : null);
        final qty = (item['quantity'] as num?)?.toInt() ?? 1;

        await db.from('order_items').insert({
          'order_id': orderRes['id'],
          'product_id': productId,
          'quantity': qty,
          'price': item['price'] ?? 0,
          'product_name': prodTitle,
          'product_image': item['image_url'],
          'title_snapshot': prodTitle,
        });

        // Décrémenter le stock
        if (productId != null) {
          try {
            await db.rpc('decrement_product_stock', params: {
              'p_product_id': productId,
              'p_quantity': qty,
            });
          } catch (_) {
            // Fallback si RPC absente
            final p = await db
                .from('products')
                .select.select('stock')
                .eq('id', productId)
                .maybeSingle();
            if (p != null) {
              final currentStock = (p['stock'] as num?)?.toInt() ?? 0;
              final newStock = (currentStock - qty).clamp(0, currentStock);
              await db.from('products').update({
                'stock': newStock,
                if (newStock <= 0) 'status': 'sold_out',
              }).eq('id', productId);
            }
          }
        }
      }

      state = state.copyWith(createdOrder: orderRes, isProcessing: false);
      return orderRes;
    } catch (e) {
      state = state.copyWith(isProcessing: false);
      rethrow;
    }
  }

  // ========== PROCESS ORDER + PAIEMENT ==========
  Future<Map<String, dynamic>> processOrder({
    required double total,
    required List<Map<String, dynamic>> items,
    String? phoneNumber,
  }) async {
    // 1. Créer la commande (avec validation stock dedans)
    final order = await createOrderOnly(total: total, items: items);
    final orderId = order['id'].toString();

    // 2. Initier le paiement
    final paymentService =
        MarketPaymentService(ref.read(supabaseClientProvider));
    final method = state.selectedPayment!['id'] as String;

    final result = await paymentService.initiatePayment(
      orderId: orderId,
      amount: total,
      currency: 'CDF',
      paymentMethod: method,
      phoneNumber: phoneNumber ?? state.userInfo['phone']?.toString(),
    );

    if (result['success'] != true) {
      // Annuler la commande si le paiement échoue immédiatement
      try {
        await ref
            .read(supabaseClientProvider)
            .from('orders')
            .delete()
            .eq('id', orderId);
      } catch (_) {}
      throw Exception(result['error'] ?? 'Paiement échoué');
    }

    // 3. Mettre à jour le status
    final paymentStatus = result['payment_status'] ?? 'awaiting_payment';
    await ref.read(supabaseClientProvider).from('orders').update({
      'payment_status': paymentStatus,
      if (paymentStatus == 'paid' || paymentStatus == 'pending_delivery')
        'status': 'processing',
    }).eq('id', orderId);

    // 4. Vider le panier si paiement immédiat
    if (result['needs_waiting'] != true) {
      await ref.read(cartProvider.notifier).clearCart();
      final updated = await ref
          .read(supabaseClientProvider)
          .from('orders')
          .select()
          .eq('id', orderId)
          .single();
      state = state.copyWith(createdOrder: updated);
    }

    return {
      ...result,
      'order': order,
      'order_id': orderId,
    };
  }
