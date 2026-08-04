// lib/presentation/thix_weeding/pages/staff/budget/expense_form_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class ExpenseFormPage extends StatefulWidget {
  final String weddingId; final String? editExpenseId;
  const ExpenseFormPage({super.key, required this.weddingId, this.editExpenseId});
  @override State<ExpenseFormPage> createState()=> _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  String? _vendorId;
  bool _paid = false;
  bool _loading = false;
  List<Map<String,dynamic>> _vendors = [];

  @override void initState(){ super.initState(); _loadVendors(); if(widget.editExpenseId!=null) _loadEdit(); }
  Future<void> _loadVendors() async {
    final res = await Supabase.instance.client.from('thix_weeding_vendors').select('id,name').eq('wedding_id', widget.weddingId);
    setState(()=> _vendors = List<Map<String,dynamic>>.from(res));
  }
  Future<void> _loadEdit() async {
    final e = await Supabase.instance.client.from('thix_weeding_expenses').select().eq('id', widget.editExpenseId!).single();
    setState((){ _title.text=e['title']; _amount.text=e['amount'].toString(); _vendorId=e['vendor_id']; _paid=e['paid']; });
  }

  Future<void> _save() async {
    if(!_form.currentState!.validate()) return;
    setState(()=> _loading=true);
    try{
      final data = {
        'wedding_id': widget.weddingId,
        'vendor_id': _vendorId,
        'title': _title.text.trim(),
        'amount': double.parse(_amount.text),
        'paid': _paid,
        'paid_at': _paid? DateTime.now().toIso8601String(): null,
      };
      if(widget.editExpenseId==null){
        final inserted = await Supabase.instance.client.from('thix_weeding_expenses').insert(data).select().single();
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dépense créée ID: ${inserted['id']}')));
      } else {
        await Supabase.instance.client.from('thix_weeding_expenses').update(data).eq('id', widget.editExpenseId!);
      }
      if(mounted) context.pop();
    }catch(e){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur $e'))); }
    finally{ if(mounted) setState(()=> _loading=false); }
  }

  @override Widget build(BuildContext context)=> Scaffold(appBar: AppBar(title: Text(widget.editExpenseId==null?'Ajouter dépense':'Modifier dépense')), body: Form(key: _form, child: ListView(padding: const EdgeInsets.all(16), children: [
    TextFormField(controller: _title, decoration: const InputDecoration(labelText:'Titre * ex: Acompte traiteur'), validator: (v)=> v!.isEmpty?'Requis':null),
    const SizedBox(height:12),
    TextFormField(controller: _amount, decoration: const InputDecoration(labelText:'Montant FCFA *'), keyboardType: TextInputType.number, validator: (v)=> v!.isEmpty?'Requis':null),
    const SizedBox(height:12),
    DropdownButtonFormField<String>(value: _vendorId, decoration: const InputDecoration(labelText:'Prestataire lié (optionnel)'), items: _vendors.map((v)=> DropdownMenuItem(value: v['id'] as String, child: Text(v['name']))).toList(), onChanged: (v)=> setState(()=> _vendorId=v)),
    const SizedBox(height:12),
    SwitchListTile(title: const Text('Déjà payé?'), value: _paid, onChanged: (v)=> setState(()=> _paid=v)),
    const SizedBox(height:24),
    FilledButton(onPressed: _loading?null:_save, child: _loading? const CircularProgressIndicator(): Text(widget.editExpenseId==null?'Créer dépense':'Mettre à jour')),
  ])));
}
