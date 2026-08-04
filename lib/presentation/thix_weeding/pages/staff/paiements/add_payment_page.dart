// lib/presentation/thix_weeding/pages/staff/paiements/add_payment_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class AddPaymentPage extends StatefulWidget {
  final String weddingId;
  const AddPaymentPage({super.key, required this.weddingId});
  @override State<AddPaymentPage> createState()=> _AddPaymentPageState();
}

class _AddPaymentPageState extends State<AddPaymentPage> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _refCode = TextEditingController();
  String _method = 'mobile_money';
  String _status = 'pending';
  String? _vendorId; String? _expenseId;
  List<Map<String,dynamic>> _vendors=[], _expenses=[];
  bool _loading=false;

  @override void initState(){ super.initState(); _loadLists(); }
  Future<void> _loadLists() async {
    final v = await Supabase.instance.client.from('thix_weeding_vendors').select('id,name').eq('wedding_id', widget.weddingId);
    final e = await Supabase.instance.client.from('thix_weeding_expenses').select('id,title').eq('wedding_id', widget.weddingId);
    setState((){ _vendors=List<Map<String,dynamic>>.from(v); _expenses=List<Map<String,dynamic>>.from(e); });
  }

  Future<void> _save() async {
    if(!_form.currentState!.validate()) return;
    setState(()=> _loading=true);
    try{
      final inserted = await Supabase.instance.client.from('thix_weeding_payments').insert({
        'wedding_id': widget.weddingId,
        'vendor_id': _vendorId,
        'expense_id': _expenseId,
        'amount': double.parse(_amount.text),
        'method': _method,
        'status': _status,
        'reference_code': _refCode.text.trim(),
      }).select().single();
      if(mounted){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Paiement créé ID: ${inserted['id']}'))); context.pop(); }
    }catch(e){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur $e'))); }
    finally{ if(mounted) setState(()=> _loading=false); }
  }

  @override Widget build(BuildContext context)=> Scaffold(appBar: AppBar(title: const Text('Nouveau paiement')), body: Form(key: _form, child: ListView(padding: const EdgeInsets.all(16), children: [
    TextFormField(controller: _amount, decoration: const InputDecoration(labelText:'Montant FCFA *'), keyboardType: TextInputType.number, validator: (v)=> v!.isEmpty?'Requis':null),
    const SizedBox(height:12),
    DropdownButtonFormField<String>(value: _vendorId, decoration: const InputDecoration(labelText:'Prestataire (optionnel)'), items: _vendors.map((v)=> DropdownMenuItem(value: v['id'] as String, child: Text(v['name']))).toList(), onChanged: (v)=> setState(()=> _vendorId=v)),
    DropdownButtonFormField<String>(value: _expenseId, decoration: const InputDecoration(labelText:'Dépense liée (optionnel)'), items: _expenses.map((e)=> DropdownMenuItem(value: e['id'] as String, child: Text(e['title']))).toList(), onChanged: (v)=> setState(()=> _expenseId=v)),
    const SizedBox(height:12),
    DropdownButtonFormField(value: _method, decoration: const InputDecoration(labelText:'Méthode'), items: const [DropdownMenuItem(value:'mobile_money', child:Text('Mobile Money')), DropdownMenuItem(value:'cash', child:Text('Cash')), DropdownMenuItem(value:'bank', child:Text('Virement bancaire')), DropdownMenuItem(value:'card', child:Text('Carte'))], onChanged: (v)=> setState(()=> _method=v!)),
    DropdownButtonFormField(value: _status, decoration: const InputDecoration(labelText:'Statut'), items: const [DropdownMenuItem(value:'pending', child:Text('En attente')), DropdownMenuItem(value:'completed', child:Text('Complété')), DropdownMenuItem(value:'failed', child:Text('Échoué'))], onChanged: (v)=> setState(()=> _status=v!)),
    TextFormField(controller: _refCode, decoration: const InputDecoration(labelText:'Référence / Code transaction')),
    const SizedBox(height:24),
    FilledButton(onPressed: _loading?null:_save, child: _loading? const CircularProgressIndicator(): const Text('Créer paiement avec ID unique')),
  ])));
}
