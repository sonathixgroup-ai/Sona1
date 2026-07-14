// lib/presentation/thix_sante/patient/screens/trouver_medicament_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/thix_sante_colors.dart';
import '../providers/medicament_provider.dart';

class TrouverMedicamentDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> stock;
  const TrouverMedicamentDetailPage({super.key, required this.stock});
  @override
  ConsumerState<TrouverMedicamentDetailPage> createState() => _State();
}

class _State extends ConsumerState<TrouverMedicamentDetailPage> {
  int qty = 1;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.stock;
    final ph = m['pharmacies'] as Map?;
    final maxQty = (m['quantite'] as num).toInt();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(backgroundColor: Colors.white, elevation:0, leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: ()=> Navigator.pop(context)), title: Text(m['nom'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize:14))),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16), color: Colors.white,
        child: Row(children:[
          Container(decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(12)), child: Row(children:[
            IconButton(onPressed: qty>1? ()=> setState(()=> qty--):null, icon: const Icon(Icons.remove_rounded)),
            Text('$qty', style: const TextStyle(fontWeight: FontWeight.w800)),
            IconButton(onPressed: qty<maxQty? ()=> setState(()=> qty++):null, icon: const Icon(Icons.add_rounded)),
          ])),
          const SizedBox(width:12),
          Expanded(child: ElevatedButton(
            onPressed: loading? null : () async {
              setState(()=> loading=true);
              try{
                await ref.read(medicamentServiceProvider).reserverMedicament(stockId: m['id'], quantite: qty);
                if(mounted){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Réservation envoyée à la pharmacie'), backgroundColor: Color(0xFF16A34A))); Navigator.pop(context); }
              }catch(e){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red)); }
              setState(()=> loading=false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B63F6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical:14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(loading? '...' : 'Réserver • ${((m['prix'] as num)*qty)} FC'),
          )),
        ]),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children:[
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Row(children:[Container(width:56,height:56,decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.medication_rounded, color: Color(0xFF0B63F6), size:28)), const SizedBox(width:12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(m['nom'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize:16)), if(m['dci']!=null) Text('DCI: ${m['dci']}', style: const TextStyle(color: Color(0xFF6B7280), fontSize:12)), Text('${m['forme']??''} ${m['dosage']??''}', style: const TextStyle(fontSize:12))]))]),
          const Divider(height:24),
          _row('Prix unitaire', '${m['prix']} FC'), _row('Stock disponible', '$maxQty unités', color: maxQty<=5? const Color(0xFFD97706) : const Color(0xFF16A34A)), if(m['laboratoire']!=null) _row('Laboratoire', m['laboratoire']), if(m['date_peremption']!=null) _row('Péremption', m['date_peremption'].toString().substring(0,10)),
        ])),
        const SizedBox(height:12),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          const Text('Pharmacie', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height:8),
          Text(ph?['nom']??'', style: const TextStyle(fontWeight: FontWeight.w700)), Text(ph?['adresse']??'', style: const TextStyle(fontSize:12, color: Color(0xFF6B7280))),
          const SizedBox(height:10),
          Row(children:[
            Expanded(child: OutlinedButton.icon(onPressed: () async { final uri=Uri.parse('tel:${ph?['telephone']}'); if(await canLaunchUrl(uri)) await launchUrl(uri); }, icon: const Icon(Icons.call_rounded, size:16), label: const Text('Appeler'))),
            const SizedBox(width:8),
            Expanded(child: OutlinedButton.icon(onPressed: () async { final lat=ph?['latitude']; final lng=ph?['longitude']; final uri=Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'); if(await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication); }, icon: const Icon(Icons.map_rounded, size:16), label: const Text('Voir carte'))),
          ])
        ])),
      ]),
    );
  }
  Widget _row(String k,String v,{Color? color})=> Padding(padding: const EdgeInsets.symmetric(vertical:4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text(k, style: const TextStyle(fontSize:12, color: Color(0xFF6B7280))), Text(v, style: TextStyle(fontSize:12, fontWeight: FontWeight.w700, color: color))]));
}
