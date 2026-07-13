// lib/presentation/thix_sante/patient/screens/prendre_rdv_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/thix_sante_colors.dart';

class PrendreRdvPage extends ConsumerStatefulWidget {
  const PrendreRdvPage({super.key});
  @override
  ConsumerState<PrendreRdvPage> createState() => _PrendreRdvPageState();
}

class _PrendreRdvPageState extends ConsumerState<PrendreRdvPage> {
  String _type = 'Cabinet';
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String _creneau = '09:00';
  final _motifCtrl = TextEditingController();
  bool _loading = false;

  final _types = ['Cabinet', 'Téléconsultation', 'Domicile'];
  final _creneaux = ['08:00','08:30','09:00','09:30','10:00','10:30','11:00','14:30','15:00','15:30','16:00'];

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDate: _date,
      builder: (c, child) => Theme(data: ThemeData(colorScheme: const ColorScheme.light(primary: ThixSanteColors.primary)), child: child!),
    );
    if (d!= null) setState(()=> _date = d);
  }

  Future<void> _confirmer() async {
    if (_motifCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajoute un motif')));
      return;
    }
    setState(()=> _loading = true);
    await Future.delayed(const Duration(seconds: 1)); // TODO: supabase.from('appointments').insert({...})
    if (!mounted) return;
    setState(()=> _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('RDV confirmé le ${_date.day}/${_date.month} à $_creneau'), backgroundColor: ThixSanteColors.success));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThixSanteColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: ThixSanteColors.ink), onPressed: ()=>Navigator.pop(context)),
        title: const Text('Prendre RDV', style: TextStyle(color: ThixSanteColors.ink, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: ThixSanteColors.primarySurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: ThixSanteColors.primaryLight)),
            child: Row(children: [
              const CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Text('👨‍⚕️', style: TextStyle(fontSize: 28))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Dr. Médecin Traitant', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text('Médecin généraliste • Disponible', style: TextStyle(color: ThixSanteColors.inkLight, fontSize: 12)),
                const SizedBox(height: 4),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: ThixSanteColors.success.withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: const Text('● Créneaux ouverts', style: TextStyle(color: ThixSanteColors.success, fontSize: 11, fontWeight: FontWeight.w700))),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Type de consultation', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: _types.map((t){
            final sel = _type==t;
            return ChoiceChip(
              label: Text(t),
              selected: sel,
              selectedColor: ThixSanteColors.primary,
              labelStyle: TextStyle(color: sel? Colors.white : ThixSanteColors.inkLight, fontWeight: FontWeight.w700),
              onSelected: (_)=> setState(()=> _type=t),
            );
          }).toList()),
          const SizedBox(height: 20),
          const Text('Date', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          InkWell(onTap: _pickDate, child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: ThixSanteColors.border)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${_date.day.toString().padLeft(2,'0')}/${_date.month.toString().padLeft(2,'0')}/${_date.year}', style: const TextStyle(fontWeight: FontWeight.w700)), const Icon(Icons.calendar_today_outlined)]))),
          const SizedBox(height: 20),
          const Text('Créneau', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _creneaux.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.6, crossAxisSpacing: 8, mainAxisSpacing: 8), itemBuilder: (_, i){
            final c = _creneaux[i];
            final sel = _creneau==c;
            return InkWell(onTap: ()=>setState(()=>_creneau=c), child: Container(alignment: Alignment.center, decoration: BoxDecoration(color: sel? ThixSanteColors.primary : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: sel? ThixSanteColors.primary : ThixSanteColors.border)), child: Text(c, style: TextStyle(color: sel? Colors.white: ThixSanteColors.ink, fontWeight: FontWeight.w700))));
          }),
          const SizedBox(height: 20),
          const Text('Motif', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(controller: _motifCtrl, maxLines: 3, decoration: InputDecoration(hintText: 'Ex: fièvre, toux depuis 2 jours...', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ThixSanteColors.border)))),
        ],
      ),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: ElevatedButton(onPressed: _loading? null : _confirmer, style: ElevatedButton.styleFrom(backgroundColor: ThixSanteColors.primary, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: _loading? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Confirmer RDV • $_creneau')))),
    );
  }
}
