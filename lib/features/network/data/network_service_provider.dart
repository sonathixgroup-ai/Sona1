import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/services/network_service.dart';
part 'network_service_provider.g.dart';

@riverpod
SupabaseClient supabaseClient(SupabaseClientRef ref) => Supabase.instance.client;

@riverpod
NetworkService networkService(NetworkServiceRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return NetworkService(client);
}
