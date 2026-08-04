// lib/presentation/thix_weeding/pages/staff/invités/add_guest_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class AddGuestPage extends StatefulWidget {
  final String weddingId; final String? editGuestId;
  const AddGuestPage({super.key, required this.weddingId, this.editGuestId});
  @override State<AddGuestPage> createState()=> _AddGuestPageState();
}

class _AddGuestPageState extends State<AddGuestPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  String _group = 'Amis';
  int _count = 1;
  bool _loading = false;

  @override void initState(){
    super.initState();
    if(widget.editGuestId!=null) _loadEdit();
  }
  Future<void> _loadEdit() async {
    final g = await Supabase.instance.client.from('thix_weeding_guests').select().eq('id', widget.editGuestId!).single();
    setState((){ _name.text=g['name']; _phone.text=g['phone']??''; _email.text=g['email']??''; _group=g['group_name']; _count=g['guests_count']; });
  }

  Future<void> _save() async {
    if(!_form.currentState!.validate()) return;
    setState(()=> _loading=true);
    try{
      if(widget.editGuestId==null){
        final inserted = await Supabase.instance.client.from('thix_weeding_guests').insert({
          'wedding_id': widget.weddingId,
          'name': _name.text.trim(),
          'phone': _phone.text.trim(),
          'email': _email.text.trim(),
          'group_name': _group,
          'guests_count': _count,
        }).select().single(); // <-- ID généré ici
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invité créé ID: ${inserted['id']}')));
      } else {
        await Supabase.instance.client.from('thix_weeding_guests').update({
          'name': _name.text.trim(), 'phone': _phone.text.trim(), 'email': _email.text.trim(), 'group_name': _group, 'guests_count': _count,
        }).eq('id', widget.editGuestId!);
      }
      if(mounted) context.pop();
    }catch(e){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur $e'))); }
    finally{ if(mounted) setState(()=> _loading=false); }
  }

  @override Widget build(BuildContext context)=> Scaffold(appBar: AppBar(title: Text(widget.editGuestId==null?'Ajouter un invité':'Modifier invité')), body: Form(key: _form, child: ListView(padding: const EdgeInsets.all(16), children: [
    TextFormField(controller: _name, decoration: const InputDecoration(labelText:'Nom complet *'), validator: (v)=> v!.length<2?'Min 2 caractères':null),
    const SizedBox(height:12),
    TextFormField(controller: _phone, decoration: const InputDecoration(labelText:'Téléphone'), keyboardType: TextInputType.phone),
    const SizedBox(height:12),
    TextFormField(controller: _email, decoration: const InputDecoration(labelText:'Email'), keyboardType: TextInputType.emailAddress),
    const SizedBox(height:12),
    DropdownButtonFormField(value: _group, items: const [DropdownMenuItem(value:'Famille', child:Text('Famille')), DropdownMenuItem(value:'Amis', child:Text('Amis')), DropdownMenuItem(value:'Collègues', child:Text('Collègues')), DropdownMenuItem(value:'VIP', child:Text('VIP'))], onChanged: (v)=> setState(()=> _group=v!)),
    const SizedBox(height:12),
    Row(children: [const Text('Nombre de personnes:'), const Spacer(), IconButton(onPressed: ()=> setState(()=> _count = (_count>1?_count-1:1)), icon: const Icon(Icons.remove)), Text('$_count', style: const TextStyle(fontWeight: FontWeight.bold)), IconButton(onPressed: ()=> setState(()=> _count++), icon: const Icon(Icons.add))]),
    const SizedBox(height:24),
    FilledButton(onPressed: _loading?null:_save, child: _loading? const CircularProgressIndicator(): Text(widget.editGuestId==null?'Créer invité avec ID unique':'Mettre à jour')),
  ])));
}
