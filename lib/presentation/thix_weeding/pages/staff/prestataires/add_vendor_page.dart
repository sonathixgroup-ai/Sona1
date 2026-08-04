// lib/presentation/thix_weeding/pages/staff/prestataires/add_vendor_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class AddVendorPage extends StatefulWidget {
  final String weddingId; final String? editVendorId;
  const AddVendorPage({super.key, required this.weddingId, this.editVendorId});
  @override State<AddVendorPage> createState()=> _AddVendorPageState();
}

class _AddVendorPageState extends State<AddVendorPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _price = TextEditingController();
  final _notes = TextEditingController();
  String _category = 'Traiteur';
  String _status = 'pending';
  bool _loading = false;

  @override void initState(){
    super.initState();
    if(widget.editVendorId!=null) _load();
  }
  Future<void> _load() async {
    final v = await Supabase.instance.client.from('thix_weeding_vendors').select().eq('id', widget.editVendorId!).single();
    setState((){ _name.text=v['name']; _contact.text=v['contact_name']??''; _phone.text=v['phone']??''; _email.text=v['email']??''; _price.text=v['price']?.toString()??''; _notes.text=v['notes']??''; _category=v['category']; _status=v['status']; });
  }

  Future<void> _save() async {
    if(!_form.currentState!.validate()) return;
    setState(()=> _loading=true);
    try{
      final data = {
        'wedding_id': widget.weddingId,
        'name': _name.text.trim(),
        'category': _category,
        'contact_name': _contact.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'price': double.tryParse(_price.text)??0,
        'status': _status,
        'notes': _notes.text.trim(),
      };
      if(widget.editVendorId==null){
        final inserted = await Supabase.instance.client.from('thix_weeding_vendors').insert(data).select().single();
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Prestataire créé ID: ${inserted['id']}')));
      } else {
        await Supabase.instance.client.from('thix_weeding_vendors').update(data).eq('id', widget.editVendorId!);
      }
      if(mounted) context.pop();
    }catch(e){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur $e'))); }
    finally{ if(mounted) setState(()=> _loading=false); }
  }

  @override Widget build(BuildContext context)=> Scaffold(appBar: AppBar(title: Text(widget.editVendorId==null?'Ajouter prestataire':'Modifier prestataire')), body: Form(key: _form, child: ListView(padding: const EdgeInsets.all(16), children: [
    TextFormField(controller: _name, decoration: const InputDecoration(labelText:'Nom entreprise *'), validator: (v)=> v!.length<2?'Requis':null),
    const SizedBox(height:12),
    DropdownButtonFormField(value: _category, decoration: const InputDecoration(labelText:'Catégorie'), items: const [DropdownMenuItem(value:'Traiteur', child:Text('Traiteur')), DropdownMenuItem(value:'Photographe', child:Text('Photographe')), DropdownMenuItem(value:'DJ', child:Text('DJ / Musique')), DropdownMenuItem(value:'Décoration', child:Text('Décoration')), DropdownMenuItem(value:'Salle', child:Text('Salle')), DropdownMenuItem(value:'Autre', child:Text('Autre'))], onChanged: (v)=> setState(()=> _category=v!)),
    const SizedBox(height:12),
    TextFormField(controller: _contact, decoration: const InputDecoration(labelText:'Nom contact')),
    TextFormField(controller: _phone, decoration: const InputDecoration(labelText:'Téléphone'), keyboardType: TextInputType.phone),
    TextFormField(controller: _email, decoration: const InputDecoration(labelText:'Email')),
    TextFormField(controller: _price, decoration: const InputDecoration(labelText:'Prix convenu FCFA'), keyboardType: TextInputType.number),
    const SizedBox(height:12),
    DropdownButtonFormField(value: _status, decoration: const InputDecoration(labelText:'Statut'), items: const [DropdownMenuItem(value:'pending', child:Text('En attente')), DropdownMenuItem(value:'contacted', child:Text('Contacté')), DropdownMenuItem(value:'booked', child:Text('Réservé')), DropdownMenuItem(value:'paid', child:Text('Payé')), DropdownMenuItem(value:'cancelled', child:Text('Annulé'))], onChanged: (v)=> setState(()=> _status=v!)),
    TextFormField(controller: _notes, decoration: const InputDecoration(labelText:'Notes'), maxLines: 3),
    const SizedBox(height:24),
    FilledButton(onPressed: _loading?null:_save, child: _loading? const CircularProgressIndicator(): Text(widget.editVendorId==null?'Créer avec ID unique':'Mettre à jour')),
  ])));
}
