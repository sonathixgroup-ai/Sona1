import 'package:supabase_flutter/supabase_flutter.dart';

class StatusRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> updateStatus(String userId, String status, {String? customStatus}) async {
    await _supabase
        .from('thix_presence')
        .upsert({
          'user_id': userId,
          'status': status,
          'custom_status': customStatus,
          'updated_at': DateTime.now().toIso8601String(),
        });
  }

  Future<Map<String, dynamic>> getStatus(String userId) async {
    final response = await _supabase
        .from('thix_presence')
        .select('*')
        .eq('user_id', userId)
        .maybeSingle();

    return response ?? {};
  }

  Future<List<Map<String, dynamic>>> getOnlineUsers() async {
    final response = await _supabase
        .from('thix_presence')
        .select('*')
        .eq('status', 'online')
        .order('updated_at', ascending: false);

    return response;
  }
}
