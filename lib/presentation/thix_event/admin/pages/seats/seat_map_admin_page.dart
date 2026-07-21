// lib/presentation/thix_event/admin/pages/seats/seat_map_admin_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/models/event_seat.dart';
import '../../providers/admin_event_provider.dart';
import '../../services/admin_event_service.dart';
import '../../widgets/admin_app_bar.dart';
import '../../core/admin_constants.dart';
import '../../core/admin_guards.dart';

class SeatMapAdminPage extends StatefulWidget {
  const SeatMapAdminPage({super.key});
  @override 
  State<SeatMapAdminPage> createState() => _SeatMapAdminPageState();
}

class _SeatMapAdminPageState extends State<SeatMapAdminPage> {
  String? _selectedEventId;
  int _rows = 10;
  int _perRow = 10;
  
  // 🟢 NOUVEAU : Configuration dynamique des prix par catégorie
  final Map<SeatCategory, double> _categoryPrices = {
    SeatCategory.standard: 10.0,
    SeatCategory.vip: 50.0,
    SeatCategory.gold: 100.0,
    SeatCategory.family: 25.0,
  };

  // 🟢 NOUVEAU : Forme de la salle (Couloir central)
  bool _hasCenterAisle = true;

  Map<String, SeatCategory> _categoryByRow = {};
  List<EventSeat> _currentSeats = [];
  bool _isGenerating = false;
  bool _isLoadingSeats = false;

  // Couleurs officielles THIX pour l'Admin
  static const Color _colStandard = Color(0xFF10B981);
  static const Color _colVip = Color(0xFF8B5CF6);
  static const Color _colGold = Color(0xFFD4AF37);
  static const Color _colFamily = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _initRowCategories();
  }

  void _initRowCategories() {
    _categoryByRow.clear();
    for (int i = 0; i < _rows; i++) {
      final letter = String.fromCharCode(65 + i);
      if (i < 2) {
        _categoryByRow[letter] = SeatCategory.vip; // Les premiers rangs proches de la scène
      } else if (i < 4) {
        _categoryByRow[letter] = SeatCategory.gold;
      } else {
        _categoryByRow[letter] = SeatCategory.standard;
      }
    }
  }

  Future<void> _loadSeats() async {
    if (_selectedEventId == null) return;
    setState(() => _isLoadingSeats = true);
    try {
      _currentSeats = await context.read<AdminEventService>().getSeatMapForAdmin(_selectedEventId!);
    } finally {
      if (mounted) setState(() => _isLoadingSeats = false);
    }
  }

  Future<void> _generate() async {
    if (_selectedEventId == null) {
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

    setState(() => _isGenerating = true);
    try {
      final config = _categoryByRow.map((k, v) => MapEntry(k, v.toString().split('.').last));
      final prices = _categoryPrices.map((k, v) => MapEntry(k.toString().split('.').last, v));

      // ⚠️ Assurez-vous que votre AdminEventService accepte ces nouveaux paramètres (categoryPrices et hasCenterAisle)
      await context.read<AdminEventService>().generateSeatMap(
        eventId: _selectedEventId!,
        rows: _rows,
        seatsPerRow: _perRow,
        categoryConfig: config,
        categoryPrices: prices, // Injection des prix dynamiques
        hasCenterAisle: _hasCenterAisle, // Forme de la salle
      );

      await _loadSeats();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ $total sièges générés avec succès !', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = context.watch<AdminEventProvider>().eventsState.items;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: const AdminAppBar(title: 'Plan de Salle & Tarifs'),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // SELECT EVENT
        DropdownButtonFormField<String>(
          value: _selectedEventId,
          decoration: _deco('Événement cible'),
          items: events.map((e) => DropdownMenuItem(value: e.id, child: Text(e.title, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) { 
            setState(() => _selectedEventId = v); 
            _loadSeats(); 
          },
        ),
        const SizedBox(height: 16),
        
        // CONFIGURATION TARIFS
        Container(
          padding: const EdgeInsets.all(16), 
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EEFC))), 
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(
              children: [
                Icon(Icons.monetization_on_rounded, color: Color(0xFF0A1F44), size: 18),
                SizedBox(width: 8),
                Text('Tarification Dynamique', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0A1F44))),
              ],
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _priceField('Standard', _categoryPrices[SeatCategory.standard]!, (v) => _categoryPrices[SeatCategory.standard] = v)),
              const SizedBox(width: 12),
              Expanded(child: _priceField('VIP', _categoryPrices[SeatCategory.vip]!, (v) => _categoryPrices[SeatCategory.vip] = v)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _priceField('GOLD', _categoryPrices[SeatCategory.gold]!, (v) => _categoryPrices[SeatCategory.gold] = v)),
              const SizedBox(width: 12),
              Expanded(child: _priceField('Family', _categoryPrices[SeatCategory.family]!, (v) => _categoryPrices[SeatCategory.family] = v)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // CONFIG GENERATION (Forme & Rangs)
        Container(
          padding: const EdgeInsets.all(16), 
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EEFC))), 
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(
              children: [
                Icon(Icons.event_seat_rounded, color: Color(0xFF0A1F44), size: 18),
                SizedBox(width: 8),
                Text('Forme et Disposition', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0A1F44))),
              ],
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _numberField('Lignes (Rangs)', _rows, (v) {
                setState(() {
                  _rows = v;
                  _initRowCategories();
                });
              })),
              const SizedBox(width: 12),
              Expanded(child: _numberField('Sièges / ligne', _perRow, (v) => setState(() => _perRow = v))),
            ]),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Couloir central (Séparation)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('Crée un espace vide au milieu des rangées', style: TextStyle(fontSize: 11, color: Color(0xFF7386A8))),
              activeColor: const Color(0xFF0A1F44),
              value: _hasCenterAisle,
              onChanged: (v) => setState(() => _hasCenterAisle = v),
            ),
            const Divider(height: 24, color: Color(0xFFE7EEFC)),
            const Text('Attribution des catégories par rangée', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0A1F44))),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: List.generate(_rows, (i) {
              final letter = String.fromCharCode(65 + i);
              final cat = _categoryByRow[letter] ?? SeatCategory.standard;
              return InkWell(
                onTap: () {
                  setState(() {
                    if (cat == SeatCategory.standard) _categoryByRow[letter] = SeatCategory.vip;
                    else if (cat == SeatCategory.vip) _categoryByRow[letter] = SeatCategory.gold;
                    else if (cat == SeatCategory.gold) _categoryByRow[letter] = SeatCategory.family;
                    else _categoryByRow[letter] = SeatCategory.standard;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getColorForCategory(cat).withOpacity(0.15),
                    border: Border.all(color: _getColorForCategory(cat), width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$letter : ${cat.name.toUpperCase()}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getColorForCategory(cat))),
                ),
              );
            })),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, 
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generate,
                icon: _isGenerating 
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.precision_manufacturing_rounded, size: 18),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A1F44), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                label: Text(
                  _isGenerating ? 'GÉNÉRATION...' : 'GÉNÉRER ${_rows * _perRow} SIÈGES', 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)
                ),
              )
            ),
        ])),
        const SizedBox(height: 24),

        // VISUALISATION PLAN
        const Text('Aperçu du plan actuel', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0A1F44))),
        const SizedBox(height: 12),
        if (_isLoadingSeats) const Center(child: CircularProgressIndicator())
        else if (_currentSeats.isNotEmpty) ...[
          _buildSeatMap(),
          const SizedBox(height: 16),
          _buildLegend(),
        ] else
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Text('Aucun siège généré pour cet événement.', style: TextStyle(color: Color(0xFF7386A8))),
          ),
      ]),
    );
  }

  Widget _buildSeatMap() {
    // Group by row & sort
    final Map<String, List<EventSeat>> byRow = {};
    for (var s in _currentSeats) { 
      byRow.putIfAbsent(s.row, () => []).add(s); 
    }
    final sortedRows = byRow.keys.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EEFC))), 
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // SCÈNE
            Container(
              width: 250, 
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF0A1F44).withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF0A1F44).withOpacity(0.2))),
              child: const Center(child: Text('SCÈNE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 4, color: Color(0xFF0A1F44)))),
            ),
            const SizedBox(height: 30),
            
            // RANGÉES DE SIÈGES
            ...sortedRows.map((rowKey) {
              final seatsInRow = byRow[rowKey]!..sort((a, b) => a.number.compareTo(b.number));
              final halfPoint = seatsInRow.length ~/ 2;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 24, child: Text(rowKey, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0A1F44)))),
                    
                    // Génération des chaises avec gestion du couloir central
                    Row(
                      children: List.generate(seatsInRow.length, (index) {
                        final seat = seatsInRow[index];
                        final seatWidget = Container(
                          width: 24, height: 24,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: _colorForStatus(seat).withOpacity(seat.isAvailable ? 0.2 : 1.0),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _colorForStatus(seat), width: 1.5),
                          ),
                          child: Center(child: Text('${seat.number}', style: TextStyle(fontSize: 8, color: seat.isAvailable ? _colorForStatus(seat) : Colors.white, fontWeight: FontWeight.w800))),
                        );

                        // Insertion visuelle du couloir central
                        if (_hasCenterAisle && index == halfPoint - 1) {
                          return Row(children: [seatWidget, const SizedBox(width: 30)]);
                        }
                        return seatWidget;
                      }),
                    ),
                  ],
                ),
              );
            }),
          ]
        ),
      )
    );
  }

  Color _getColorForCategory(SeatCategory cat) {
    switch(cat) {
      case SeatCategory.vip: return _colVip;
      case SeatCategory.gold: return _colGold;
      case SeatCategory.family: return _colFamily;
      default: return _colStandard;
    }
  }

  Color _colorForStatus(EventSeat s) {
    if (s.status == SeatStatus.sold) return const Color(0xFFEF4444);
    if (s.status == SeatStatus.reserved) return const Color(0xFFF59E0B);
    return _getColorForCategory(s.category);
  }

  Widget _buildLegend() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE7EEFC))),
    child: Wrap(spacing: 16, runSpacing: 8, children: [
      _legendDot(_colStandard, 'Standard'),
      _legendDot(_colVip, 'VIP'),
      _legendDot(_colGold, 'GOLD'),
      _legendDot(const Color(0xFFF59E0B), 'Réservé (Panier)'),
      _legendDot(const Color(0xFFEF4444), 'Vendu'),
    ]),
  );

  Widget _legendDot(Color c, String l) => Row(
    mainAxisSize: MainAxisSize.min, 
    children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))), 
      const SizedBox(width: 6), 
      Text(l, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0A1F44)))
    ]
  );

  Widget _numberField(String label, int value, Function(int) onChange) => TextFormField(
    initialValue: value.toString(), 
    decoration: _deco(label), 
    keyboardType: TextInputType.number, 
    onChanged: (v) { 
      final n = int.tryParse(v); 
      if (n != null) onChange(n); 
    }
  );

  Widget _priceField(String label, double value, Function(double) onChange) => TextFormField(
    initialValue: value.toString(), 
    decoration: _deco(label, prefix: '\$ '), 
    keyboardType: TextInputType.number, 
    onChanged: (v) { 
      final n = double.tryParse(v); 
      if (n != null) onChange(n); 
    }
  );

  InputDecoration _deco(String l, {String? prefix}) => InputDecoration(
    labelText: l, 
    prefixText: prefix,
    prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A1F44)),
    labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF7386A8)),
    filled: true, 
    fillColor: const Color(0xFFF7FAFF), 
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), 
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0A1F44), width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
  );
}
