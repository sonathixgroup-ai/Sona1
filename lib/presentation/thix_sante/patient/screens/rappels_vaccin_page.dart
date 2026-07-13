// lib/presentation/thix_sante/patient/screens/rappels_vaccin_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/thix_sante_colors.dart';

class RappelsVaccinPage extends StatefulWidget {
  const RappelsVaccinPage({super.key});
  @override State<RappelsVaccinPage> createState() => _RappelsVaccinPageState();
}

class _RappelsVaccinPageState extends State<RappelsVaccinPage> {
  final _db = Supabase.instance.client;
  List<Map<String,dynamic>> _vaccins = [];
  bool _loading = true;
  String _filter = 'Tous';

  @override
  void initState(){ super.initState(); _load(); }

  Future<void> _load() async {
    final uid = _db.auth.currentUser?.id;
    if(uid==null){ setState(()=>_loading=false); return; }
    try{
      final res = await _db.from('vaccinations').select('*').eq('patient_id', uid).order('date_prevue', ascending:true);
      setState(()=> _vaccins = List<Map<String,dynamic>>.from(res));
    }catch(e){
      // Si table vide, seed demo local (pas de 12,8,5)
      setState(()=> _vaccins = []);
    }finally{ if(mounted) setState(()=>_loading=false); }
  }

  Future<void> _marquerFait(String id) async {
    await _db.from('vaccinations').update({'statut':'fait','date_realisee':DateTime.now().toIso8601String()}).eq('id', id);
    _load();
  }

  Future<void> _addVaccin() async {
    final nomCtrl = TextEditingController();
    DateTime date = DateTime.now().add(const Duration(days:30));
    await showModalBottomSheet(context:context, isScrollControlled:true, backgroundColor:Colors.white, shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(20))), builder:(c)=> Padding(padding:EdgeInsets.only(bottom:MediaQuery.of(c).viewInsets.bottom, left:16,right:16,top:20), child:Column(mainAxisSize:MainAxisSize.min, children:[
      const Text('Ajouter un vaccin',style:TextStyle(fontWeight:
