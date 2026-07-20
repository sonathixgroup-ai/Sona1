import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'controllers/urgent_controller.dart';

class ThixUrgentScreen extends StatefulWidget {
  const ThixUrgentScreen({super.key});
  @override State<ThixUrgentScreen> createState() => _ThixUrgentScreenState();
}

class _ThixUrgentScreenState extends State<ThixUrgentScreen> {
  @override void initState() {
    super.initState();
    Future.microtask(()=> context.read<UrgentController>().loadGardiens());
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<UrgentController>();
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('THIX URGENT • SÉCURISÉ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.settings_rounded, color: Colors.white), onPressed: ()=> _showConfigSecours(context))
        ],
      ),
      body: Column(
        children: [
          // CARTE PROFIL + CONFIG GARDIENS
          Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(children: [
                  CircleAvatar(child: Icon(Icons.person)),
                  SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Mes gardiens', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${ctrl.gardiens.length} contacts configurés', style: TextStyle(fontSize: 12)),
                  ])),
                  TextButton(onPressed: ()=> _showConfigSecours(context), child: Text('CONFIGURER'))
                ]),
                if(ctrl.gardiens.isEmpty)
                  Container(
                    margin: EdgeInsets.only(top:8),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                      SizedBox(width: 6),
                      Expanded(child: Text('Aucun secours configuré. Clique CONFIGURER', style: TextStyle(fontSize: 11)))
                    ]),
                  )
              ],
            ),
          ),

          Spacer(),
          // BOUTON ROUGE
          GestureDetector(
            onLongPress: () async {
              final ok = await ctrl.declencherAlerte();
              if(ok && mounted) {
                context.push('/thix-urgent/chambre-de-crise', extra: {'criseId': ctrl.criseId, 'type': ctrl.selectedType});
              }
            },
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                color: Color(0xFFFF2D2D),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0xFFFF2D2D).withOpacity(0.5), blurRadius: 40, spreadRadius: 10)]
              ),
              child: Icon(Icons.shield_rounded, size: 80, color: Colors.white),
            ),
          ),
          SizedBox(height: 20),
          Text('Maintiens 2s le bouton rouge pour alerter', style: TextStyle(color: Colors.white54)),
          Spacer(),

          // 4 BOUTONS VERTS
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              _buildGreenBtn(Icons.warning_rounded, 'DÉNONCER', EmergencyType.denoncer, ctrl),
              _buildGreenBtn(Icons.car_crash_rounded, 'ACCIDENT', EmergencyType.accident, ctrl),
              _buildGreenBtn(Icons.local_police_rounded, 'POLICE', EmergencyType.police, ctrl),
              _buildGreenBtn(Icons.person_search_rounded, 'PERSONNE', EmergencyType.personne, ctrl),
            ]),
          ),
          SizedBox(height: 8),
          Text('Type sélectionné: ${ctrl.selectedType.name.toUpperCase()} • Maintiens le bouton rouge', style: TextStyle(color: Colors.white38, fontSize: 11)),

          // CHAMBRE DE CRISE
          Container(
            margin: EdgeInsets.all(12),
            width: double.infinity, height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2A2D3A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: ()=> context.push('/thix-urgent/chambre-de-crise', extra: {'criseId': ctrl.criseId, 'type': ctrl.selectedType}),
              icon: Icon(Icons.lock, color: Colors.white),
              label: Text('CHAMBRE DE CRISE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          Text('Salon d\'écoute sécurisé dans THIX CHAT • Gardiens + Police', style: TextStyle(color: Colors.white24, fontSize: 10)),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGreenBtn(IconData icon, String label, EmergencyType type, UrgentController ctrl) {
    final isSelected = ctrl.selectedType == type;
    return Expanded(child: Container(
      margin: EdgeInsets.all(4),
      child: Material(
        color: isSelected ? Color(0xFF22C55E) : Color(0xFF22C55E).withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: ()=> ctrl.selectType(type),
          child: Container(
            height: 80,
            decoration: BoxDecoration(border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2), borderRadius: BorderRadius.circular(20)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: Colors.white),
              SizedBox(height: 4),
              Text(label, style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ),
    ));
  }

  void _showConfigSecours(BuildContext context) {
    showModalBottomSheet(context: context, backgroundColor: Color(0xFF1A1C25), shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (_) {
      return Padding(padding: EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Configurer les secours', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        SizedBox(height: 16),
        ListTile(leading: Icon(Icons.contacts, color: Colors.white), title: Text('Mes gardiens (contacts THIX)', style: TextStyle(color: Colors.white)), subtitle: Text('Ils recevront ton alerte + position live', style: TextStyle(color: Colors.white54)), onTap: (){}),
        ListTile(leading: Icon(Icons.local_police, color: Colors.white), title: Text('Police la plus proche', style: TextStyle(color: Colors.white)), subtitle: Text('Automatique via GPS', style: TextStyle(color: Colors.white54)), onTap: (){}),
        ListTile(leading: Icon(Icons.local_hospital, color: Colors.white), title: Text('Hôpital / Ambulance', style: TextStyle(color: Colors.white)), onTap: (){}),
        ListTile(leading: Icon(Icons.mic, color: Colors.white), title: Text('Enregistrement auto + Sirène', style: TextStyle(color: Colors.white)), trailing: Switch(value: true, onChanged: (v){})),
        SizedBox(height: 20),
      ]));
    });
  }
}
