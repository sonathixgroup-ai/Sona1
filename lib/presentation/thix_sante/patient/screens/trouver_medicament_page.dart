// lib/presentation/thix_sante/patient/screens/trouver_medicament_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/thix_sante_colors.dart';

// ================= PROVIDERS =================
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final selectedPharmacyProvider = StateProvider<Map<String,dynamic>?>((ref) => null);

final nearbyPharmaciesProvider = FutureProvider<List<Map<String,dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final query = ref.watch(searchQueryProvider);
  final cat = ref.watch(selectedCategoryProvider);

  var q = supabase.from('thix_pharmacies').select();
  if(query.isNotEmpty) q = q.ilike('nom', '%$query%');
  final res = await q.order('rating', ascending: false).limit(20);
  var list = List<Map<String,dynamic>>.from(res);

  // filtre catégorie si sélectionnée
  if(cat!= null) {
    final meds = await supabase.from('thix_medicines').select('pharmacy_id').eq('categorie', cat);
    final ids = meds.map((e)=> e['pharmacy_id']).toSet();
    list = list.where((p)=> ids.contains(p['id'])).toList();
  }
  return list;
});

final medicinesByPharmacyProvider = FutureProvider.family<List<Map<String,dynamic>>, String>((ref, pharmacyId) async {
  final supabase = Supabase.instance.client;
  final res = await supabase.from('thix_medicines').select().eq('pharmacy_id', pharmacyId).order('nom');
  return List<Map<String,dynamic>>.from(res);
});

final cartProvider = FutureProvider<List<Map<String,dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if(user==null) return [];
  final res = await supabase.from('thix_medicine_cart').select('*, thix_medicines(*)').eq('user_id', user.id);
  return List<Map<String,dynamic>>.from(res);
});

// ================= PAGE PRINCIPALE =================
class TrouverMedicamentPage extends ConsumerStatefulWidget {
  const TrouverMedicamentPage({super.key});
  @override ConsumerState<TrouverMedicamentPage> createState() => _TrouverMedicamentPageState();
}

class _TrouverMedicamentPageState extends ConsumerState<TrouverMedicamentPage> {
  final categories = [
    {'id':'Cough', 'label':'Cough', 'icon': Icons.sick_rounded, 'color': Color(0xFFFFE4E6)},
    {'id':'Pain Relief', 'label':'Pain Relief', 'icon': Icons.healing_rounded, 'color': Color(0xFFDCFCE7)},
    {'id':'Skin Care', 'label':'Skin Care', 'icon': Icons.face_rounded, 'color': Color(0xFFFFF7CC)},
    {'id':'Headache', 'label':'Headache', 'icon': Icons.psychology_rounded, 'color': Color(0xFFDBEAFE)},
    {'id':'Fever', 'label':'Fever', 'icon': Icons.thermostat_rounded, 'color': Color(0xFFE0E7FF)},
    {'id':'Weakness', 'label':'Weakness', 'icon': Icons.battery_0_bar_rounded, 'color': Color(0xFFFEF3C7)},
    {'id':'Digestive', 'label':'Digestive', 'icon': Icons.restaurant_rounded, 'color': Color(0xFFFFE4D6)},
    {'id':'Diabetic', 'label':'Diabetic', 'icon': Icons.bloodtype_rounded, 'color': Color(0xFFD1FAE5)},
    {'id':'Eye Care', 'label':'Eye Care', 'icon': Icons.remove_red_eye_rounded, 'color': Color(0xFFE0F2FE)},
  ];

  @override
  Widget build(BuildContext context) {
    final selectedPharmacy = ref.watch(selectedPharmacyProvider);
    final cart = ref.watch(cartProvider);
    final cartTotal = cart.when(data: (l)=> l.fold<double>(0,(s,e)=> s + ((e['thix_medicines']?['prix']??0)* (e['quantity']??1)), orElse: ()=>0), loading: ()=>0, error: (_,__)=>0);
    final cartCount = cart.when(data: (l)=> l.length, loading: ()=>0, error: (_,__)=>0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: selectedPharmacy == null? _buildStoreList() : _buildPharmacyDetail(selectedPharmacy),
      bottomNavigationBar: cartCount > 0 && selectedPharmacy!= null? _buildCartBar(cartCount, cartTotal) : null,
    );
  }

  Widget _buildStoreList() {
    final searchCtrl = TextEditingController(text: ref.read(searchQueryProvider));
    final nearby = ref.watch(nearbyPharmaciesProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true, backgroundColor: const Color(0xFFE9D5FF),
          expandedHeight: 220,
          leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.black), onPressed: ()=> Navigator.pop(context)),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(children: [
              Positioned(right: 20, top: 40, child: Icon(Icons.medication_rounded, size: 100, color: Colors.white.withOpacity(0.5))),
              Padding(padding: const EdgeInsets.fromLTRB(16, 80, 16, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Medicines', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: (v)=> ref.read(searchQueryProvider.notifier).state = v,
                    decoration: const InputDecoration(hintText: 'Search', prefixIcon: Icon(Icons.search), border: InputBorder.none, contentPadding: EdgeInsets.all(14)),
                  ),
                ),
              ])),
            ]),
          ),
        ),
        SliverPadding(padding: const EdgeInsets.all(16), sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.1),
          delegate: SliverChildBuilderDelegate((_, i){
            final c = categories[i];
            final isSelected = selectedCat == c['id'];
            return GestureDetector(
              onTap: ()=> ref.read(selectedCategoryProvider.notifier).state = isSelected? null : c['id'] as String,
              child: Container(
                decoration: BoxDecoration(color: isSelected? ThixSanteColors.primary : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: isSelected? ThixSanteColors.primary : const Color(0xFFE5E7EB))),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: (c['color'] as Color), shape: BoxShape.circle), child: Icon(c['icon'] as IconData, size: 22, color: Colors.black87)),
                  const SizedBox(height: 6),
                  Text(c['label'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSelected? Colors.white : Colors.black)),
                ]),
              ),
            );
          }, childCount: categories.length),
        )),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: Row(children: [
          const Text('Pharma store near me', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const Spacer(),
          if(selectedCat!=null) TextButton(onPressed: ()=> ref.read(selectedCategoryProvider.notifier).state=null, child: const Text('Clear')),
        ]))),
        nearby.when(
          loading: ()=> const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))),
          error: (e,_)=> SliverToBoxAdapter(child: Center(child: Text('Erreur: $e'))),
          data: (stores)=> SliverList.builder(
            itemCount: stores.length,
            itemBuilder: (_, i){
              final s = stores[i];
              return _storeCard(s, onTap: ()=> ref.read(selectedPharmacyProvider.notifier).state = s);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPharmacyDetail(Map<String,dynamic> pharmacy) {
    final medicinesAsync = ref.watch(medicinesByPharmacyProvider(pharmacy['id']));
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: ()=> ref.read(selectedPharmacyProvider.notifier).state=null),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(pharmacy['nom']??'', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14)),
          Text('${pharmacy['adresse']??'Central Park'} • ${pharmacy['distance']??'1.5 km'}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
      ),
      body: Column(children: [
        Container(color: Colors.white, padding: const EdgeInsets.all(16), child: Row(children: [
          _infoBadge(Icons.star_rounded, '${pharmacy['rating']??'4.0'}', '${pharmacy['total_ratings']??'256'}+ ratings'),
          const Spacer(),
          _infoBadge(Icons.delivery_dining_rounded, 'Delivery in', '${pharmacy['delivery_time_min']??20} mins'),
        ])),
        const SizedBox(height: 8),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
          const Text('Pain Killers', style: TextStyle(fontWeight: FontWeight.w800)),
          const Spacer(),
          const Icon(Icons.keyboard_arrow_down_rounded),
        ])),
        Expanded(child: medicinesAsync.when(
          loading: ()=> const Center(child: CircularProgressIndicator()),
          error: (e,_)=> Center(child: Text('Erreur $e')),
          data: (meds)=> ListView.builder(padding: const EdgeInsets.all(16), itemCount: meds.length, itemBuilder: (_, i){
            final m = meds[i];
            return _medicineTile(m);
          }),
        )),
      ]),
    );
  }

  Widget _storeCard(Map<String,dynamic> s, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: ListTile(
        onTap: onTap,
        leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(s['image_url']??'https://via.placeholder.com/60', width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_,__,___)=> Container(width:60,height:60,color: const Color(0xFFF3F4F6), child: const Icon(Icons.local_pharmacy_rounded)))),
        title: Text(s['nom']??'', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s['adresse']??'Central Park', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.delivery_dining, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text('Delivery in ${s['delivery_time_min']??20} mins', style: const TextStyle(fontSize: 10)),
            const SizedBox(width: 12),
            Text('${s['distance']??'1.5 km'}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF22C55E), borderRadius: BorderRadius.circular(6)), child: Row(children: [const Icon(Icons.star, size: 10, color: Colors.white), const SizedBox(width:2), Text('${s['rating']??'4.0'}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))])),
            const SizedBox(width: 6),
            Text('${s['total_ratings']??'256'} Rated', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
        ]),
      ),
    );
  }

  Widget _medicineTile(Map<String,dynamic> m) {
    final supabase = Supabase.instance.client;
    final cart = ref.watch(cartProvider).value??[];
    final inCart = cart.firstWhere((c)=> c['medicine_id']==m['id'], orElse: ()=> {});
    final qty = inCart.isNotEmpty? inCart['quantity'] as int : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(children: [
        if(m['prescription_requise']==true) const Text('Rx', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w900)),
        const SizedBox(width: 8),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(m['image_url']??'', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___)=> const Icon(Icons.medication_rounded, size: 40, color: Color(0xFF0B63F6)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m['nom']??'', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          Text('\$${m['prix']??'0'}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(height: 4),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(6)), child: Text(m['pack_size']??'Pack of 10', style: const TextStyle(fontSize: 10))),
        ])),
        qty==0? OutlinedButton(onPressed: () async {
          final user = supabase.auth.currentUser;
          if(user==null) return;
          await supabase.from('thix_medicine_cart').upsert({'user_id': user.id, 'medicine_id': m['id'], 'quantity': 1});
          ref.invalidate(cartProvider);
        }, style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF0B63F6)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('Add', style: TextStyle(fontSize: 12)))
        : Container(decoration: BoxDecoration(color: const Color(0xFF0B63F6), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: const Icon(Icons.remove, size: 16, color: Colors.white), onPressed: () async {
            final user = supabase.auth.currentUser; if(user==null) return;
            if(qty<=1) await supabase.from('thix_medicine_cart').delete().eq('user_id', user.id).eq('medicine_id', m['id']);
            else await supabase.from('thix_medicine_cart').update({'quantity': qty-1}).eq('user_id', user.id).eq('medicine_id', m['id']);
            ref.invalidate(cartProvider);
          }),
          Text('$qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.add, size: 16, color: Colors.white), onPressed: () async {
            final user = supabase.auth.currentUser; if(user==null) return;
            await supabase.from('thix_medicine_cart').update({'quantity': qty+1}).eq('user_id', user.id).eq('medicine_id', m['id']);
            ref.invalidate(cartProvider);
          }),
        ])),
      ]),
    );
  }

  Widget _infoBadge(IconData icon, String title, String subtitle) {
    return Row(children: [
      Icon(icon, size: 18, color: const Color(0xFF0B63F6)),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
      ]),
    ]);
  }

  Widget _buildCartBar(int count, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFF0B63F6), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Text('$count Item • \$${total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const Spacer(),
          GestureDetector(
            onTap: ()=> _showCheckout(),
            child: const Row(children: [Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 18), SizedBox(width: 6), Text('View Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))]),
          ),
        ]),
      ),
    );
  }

  void _showCheckout() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (_){
      final cart = ref.watch(cartProvider);
      return Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Order Medicine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        cart.when(data: (items)=> Column(children: items.map((e)=> ListTile(title: Text(e['thix_medicines']['nom']), subtitle: Text('Qty: ${e['quantity']}'), trailing: Text('\$${(e['thix_medicines']['prix']*e['quantity']).toStringAsFixed(2)}'))).toList()), loading: ()=> const CircularProgressIndicator(), error: (_,__)=> const Text('Erreur')),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
          onPressed: () async {
            Navigator.pop(context);
            // CORRECTION ICI: Un point-virgule (;) a été mis au lieu de la virgule (,) !
            showDialog(context: context, builder: (_)=> Dialog(child: Container(height: 500, padding: const EdgeInsets.all(16), child: Column(children: [
              const Text('Deliveryman arriving in 20 mins', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(child: Container(decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(12)), child: const Center(child: Icon(Icons.map_rounded, size: 60, color: Colors.grey)))),
              const SizedBox(height: 12),
              const ListTile(leading: CircleAvatar(), title: Text('Pediatrician'), subtitle: Text('Dr. Olivia Blanton')),
            ])))); 
          },
          child: const Text('CONFIRMER COMMANDE - LIVRAISON 20MIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )),
      ]));
    });
  }
}
