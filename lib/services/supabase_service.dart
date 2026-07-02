import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Singleton
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  // Méthodes statiques pour un appel simple
  static Future<List<Map<String, dynamic>>> select(
    String table, {
    String select = '*',
    String? orderBy,
    bool ascending = false,
    int limit = 200,
    Map<String, dynamic>? filters,
  }) {
    return _instance._select(
      table,
      select: select,
      orderBy: orderBy,
      ascending: ascending,
      limit: limit,
      filters: filters,
    );
  }

  static Future<void> insert(String table, Map<String, dynamic> data) {
    return _instance._insert(table, data);
  }

  static Future<void> update(
    String table,
    Map<String, dynamic> data, {
    required Map<String, dynamic> filters,
  }) {
    return _instance._update(table, data, filters: filters);
  }

  static Future<void> delete(
    String table, {
    required Map<String, dynamic> filters,
  }) {
    return _instance._delete(table, filters: filters);
  }

  // Implémentations privées
  Future<List<Map<String, dynamic>>> _select(
    String table, {
    String select = '*',
    String? orderBy,
    bool ascending = false,
    int limit = 200,
    Map<String, dynamic>? filters,
  }) async {
    var query = client.from(table).select(select);
    if (filters != null) {
      filters.forEach((key, value) {
        query = query.match({key: value});
      });
    }
    if (orderBy != null) {
      query = query.order(orderBy, ascending: ascending);
    }
    query = query.limit(limit);
    final response = await query;
    return response.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> _insert(String table, Map<String, dynamic> data) async {
    await client.from(table).insert(data);
  }

  Future<void> _update(
    String table,
    Map<String, dynamic> data, {
    required Map<String, dynamic> filters,
  }) async {
    var query = client.from(table).update(data);
    filters.forEach((key, value) {
      query = query.match({key: value});
    });
    await query;
  }

  Future<void> _delete(
    String table, {
    required Map<String, dynamic> filters,
  }) async {
    var query = client.from(table).delete();
    filters.forEach((key, value) {
      query = query.match({key: value});
    });
    await query;
  }
}
