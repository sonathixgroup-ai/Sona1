// lib/presentation/thix_sante/patient/services/medicament_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicamentService {
  final _db = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> searchMedicaments({
    String query = '',
    String orderBy = 'nom',
    bool ascending = true,
    int limit = 80,
  }) async {
    var req = _db
        .from('pharmacy_stock')
        .select('id,nom,dci,prix,quantite,is_available,pharmacy_id,pharmacies(id,nom,adresse,latitude,longitude,telephone)')
        .eq('is_available', true);

    if (query.trim().isNotEmpty) {
      final q = query.trim();
      req = req.or('nom.ilike.%$q%,dci.ilike.%$q%');
    }

    final res = await req.order(orderBy, ascending: ascending).limit(limit);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<Map<String, dynamic>?> getStockById(String id) async {
    final res = await _db.from('pharmacy_stock').select('*, pharmacies(*)').eq('id', id).maybeSingle();
    return res;
  }

  Future<void> reserverMedicament({required String stockId, required int quantite}) async {
    final uid = _db.auth.currentUser!.id;
    await _db.from('pharmacy_orders').insert({
      'stock_id': stockId,
      'patient_id': uid,
      'quantite': quantite,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
    // Décrémente pas ici, le trigger SQL s'en charge
  }
}
