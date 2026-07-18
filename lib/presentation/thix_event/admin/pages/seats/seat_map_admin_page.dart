// lib/presentation/thix_event/admin/pages/seats/seat_map_admin_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/event_seat.dart';
import '../../providers/admin_event_provider.dart';
import '../../services/admin_event_service.dart';
import '../../widgets/admin_app_bar.dart';
import '../../core/admin_constants.dart';
import '../../core/admin_guards.dart';

class SeatMapAdminPage extends StatefulWidget {
  const SeatMapAdminPage({super.key});
  @override State<SeatMapAdminPage> createState() => _SeatMapAdminPageState();
}

class _SeatMapAdminPageState extends State<SeatMapAdminPage> {
  String? _selectedEventId;
  int _rows = 10;
  int _perRow = 10;
  double _basePrice = 5000;
  Map<String, SeatCategory> _categoryByRow = {};
  List<EventSeat> _currentSeats = [];
  bool _isGenerating = false;
  bool _isLoadingSeats = false;

  @override
  void initState() {
    super.initState();
    // Par défaut A-B VIP, C-D GOLD, reste STANDARD
    for (int i=0;i<26;i++) {
      final letter = String.fromCharCode(65+i);
      if (i<2) _categoryByRow[letter] = SeatCategory.vip;
      else if (i<4) _categoryByRow[letter] = SeatCategory.gold;
      else _categoryByRow[letter] = SeatCategory.standard;
    }
  }

  Future<void> _loadSeats() async {
    if (_selectedEventId== null) return;
    setState(()=> _isLoadingSeats = true);
    try {
      _currentSeats = await context.read<AdminEventService>().getSeatMapForAdmin(_selectedEventId!);
    } finally {
      if (mounted) setState(()=> _isLoadingSeats = false);
    }
  }

  Future<void> _generate() async {
    if (_selectedEventId== null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choisis un événement')));
      return;
    }
    final total = _rows * _perRow;
    if (total > AdminConstants.maxSeatGeneration) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Max ${AdminConstants.maxSeatGeneration} sièges')));
      return;
    }

    final role = await AdminGuard.getCurrentRole();
    if (!AdminGuard.canWrite(role)) return;

    setState(()=> _isGenerating = true);
    try {
      final config = _categoryByRow.map((k,v)=> MapEntry(k, v.toString().split('.').last));

      await context.read<AdminEventService>().generateSeatMap(
        eventId: _selectedEventId!,
        rows: _rows,
        seatsPerRow: _perRow,
        categoryConfig: config,
        basePrice: _basePrice,
      );

      await _loadSeats();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ $total sièges générés en batchs de ${AdminConstants.seatsBatchSize}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e')));
    } finally {
      if (mounted) setState(()=> _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = context.watch<AdminEventProvider>().eventsState.items;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: const AdminAppBar(title: 'Plan de Salle • Scalable'),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // SELECT EVENT
        DropdownButtonFormField<String>(
          value: _selectedEventId,
          decoration: _deco('Événement'),
          items: events.map((e)=> DropdownMenuItem(value: e.id, child: Text(e.title, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v){ setState(()=> _selectedEventId = v); _loadSeats(); },
        ),
        const SizedBox(height: 16),
        // CONFIG GENERATION
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Color(0xFFE7EEFC))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Configuration Génération', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _numberField('Lignes (A-Z)', _rows, (v)=> setState(()=> _rows=v))),
            const SizedBox(width: 12),
            Expanded(child: _numberField('Sièges / ligne', _perRow, (v)=> setState(()=> _perRow=v))),
          ]),
          const SizedBox(height: 12),
          TextFormField(initialValue: _basePrice.toString(), decoration: _deco('Prix de base FC'), keyboardType: TextInputType.number, onChanged: (v)=> _basePrice = double.tryParse(v)?? 5000),
          const SizedBox(height: 12),
          const Text('Catégorie par ligne (VIP = x2, GOLD = x3)', style: TextStyle(fontSize: 11, color: Color(0xFF7386A8))),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: List.generate(_rows, (i){
            final letter = String.fromCharCode(65+i);
            return ChoiceChip(
              label: Text('$letter: ${_categoryByRow[letter]!.name}', style: TextStyle(fontSize: 10)),
              selected: true,
              onSelected: (_){
                setState((){
                  final current = _categoryByRow[letter]!;
                  _categoryByRow[letter] = current==SeatCategory.standard? SeatCategory.vip : current==SeatCategory.vip? SeatCategory.gold : SeatCategory.standard;
                });
              },
            );
          })),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _isGenerating? null : _generate,
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0A1F44), padding: EdgeInsets.symmetric(vertical: 14)),
            child: _isGenerating? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('GÉNÉRER ${ _rows*_perRow} SIÈGES (BATCH)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
          )),
        ])),
        const SizedBox(height: 20),
        // VISUALISATION PLAN
        if (_isLoadingSeats) const Center(child: CircularProgressIndicator())
        else if (_currentSeats.isNotEmpty) _buildSeatMap(),
        const SizedBox(height: 12),
        if (_currentSeats.isNotEmpty) _buildLegend(),
      ]),
    );
  }

  Widget _buildSeatMap() {
    // Group by row
    final Map<String, List<EventSeat>> byRow = {};
    for (var s in _currentSeats) { byRow.putIfAbsent(s.row, ()=> []).add(s); }

    return Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Color(0xFFE7EEFC))), child: Column(children: [
      Container(width: 120, height: 8, decoration: BoxDecoration(color: Color(0xFF0A1F44), borderRadius: BorderRadius.circular(10))),
      const SizedBox(height: 4),
      const Text('SCÈNE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF7386A8))),
      const SizedBox(height: 16),
     ...byRow.entries.map((e)=> Row(children: [
        SizedBox(width: 20, child: Text(e.key, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800))),
        Expanded(child: Wrap(spacing: 4, runSpacing: 4, children: e.value.map((seat)=> Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: _colorForStatus(seat),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black12),
          ),
          child: Center(child: Text('${seat.number}', style: TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.w700))),
        )).toList())),
      ])),
    ]));
  }

  Color _colorForStatus(EventSeat s) {
    if (s.status== SeatStatus.sold) return Colors.redAccent;
    if (s.status== SeatStatus.reserved) return Colors.orange;
    switch(s.category) {
      case SeatCategory.vip: return Color(0xFFFFD700);
      case SeatCategory.gold: return Color(0xFFD4AF37);
      case SeatCategory.family: return Color(0xFF2196F3);
      default: return Color(0xFF4CAF50);
    }
  }

  Widget _buildLegend()=> Wrap(spacing: 12, children: [
    _legendDot(Colors.green, 'Disponible'),
    _legendDot(Colors.orange, 'Réservé'),
    _legendDot(Colors.red, 'Vendu'),
    _legendDot(Color(0xFFFFD700), 'VIP'),
  ]);

  Widget _legendDot(Color c, String l)=> Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)), SizedBox(width: 4), Text(l, style: TextStyle(fontSize: 10))]);

  Widget _numberField(String label, int value, Function(int) onChange)=> TextFormField(initialValue: value.toString(), decoration: _deco(label), keyboardType: TextInputType.number, onChanged: (v){ final n=int.tryParse(v); if(n!=null) onChange(n); });

  InputDecoration _deco(String l)=> InputDecoration(labelText: l, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFE7EEFC))), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10));
}
