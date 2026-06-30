import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class PharmacyInventoryItemPage extends StatefulWidget {
  final String? itemId;
  const PharmacyInventoryItemPage({super.key, this.itemId});

  @override
  State<PharmacyInventoryItemPage> createState() => _PharmacyInventoryItemPageState();
}

class _PharmacyInventoryItemPageState extends State<PharmacyInventoryItemPage> {
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '0');
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.itemId;
    if (id == null || id.isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await SupabaseConfig.client.from('health_inventory_items').select('*').eq('id', id).maybeSingle();
      if (res is Map) {
        final m = res.cast<String, dynamic>();
        _nameCtrl.text = (m['name'] as String?)?.trim() ?? '';
        _skuCtrl.text = (m['sku'] as String?)?.trim() ?? '';
        _qtyCtrl.text = ((m['quantity'] as num?)?.toInt() ?? 0).toString();
      }
    } catch (e, st) {
      debugPrint('PharmacyInventoryItemPage load failed: $e');
      debugPrint(st.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nom requis.')));
      return;
    }
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    setState(() => _loading = true);
    try {
      final payload = {
        'name': name,
        'sku': _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim(),
        'quantity': qty,
      };
      if (widget.itemId == null || widget.itemId!.isEmpty) {
        await SupabaseConfig.client.from('health_inventory_items').insert(payload);
      } else {
        await SupabaseConfig.client.from('health_inventory_items').update(payload).eq('id', widget.itemId!);
      }
      if (!mounted) return;
      context.pop();
    } catch (e, st) {
      debugPrint('PharmacyInventoryItemPage save failed: $e');
      debugPrint(st.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la sauvegarde.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.itemId == null || widget.itemId!.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Nouvel article' : 'Article inventaire'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/pharmacy/inventory'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _nameCtrl, enabled: !_loading, decoration: const InputDecoration(labelText: 'Nom')),
          const SizedBox(height: 12),
          TextField(controller: _skuCtrl, enabled: !_loading, decoration: const InputDecoration(labelText: 'SKU (optionnel)')),
          const SizedBox(height: 12),
          TextField(controller: _qtyCtrl, enabled: !_loading, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantité')),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _save,
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: const Text('Enregistrer'),
          ),
          const SizedBox(height: 8),
          Text(
            "Tables attendues: health_inventory_items (id, name, sku, quantity).",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
