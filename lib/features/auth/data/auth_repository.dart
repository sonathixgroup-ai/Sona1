// lib/features/auth/data/auth_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/app_user.dart';

part 'auth_repository.g.dart';

@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(SupabaseClientRef ref) => Supabase.instance.client;

@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
}

class AuthRepository {
  final SupabaseClient _client;
  AuthRepository(this._client);

  Stream<User?> authStateChanges() => _client.auth.onAuthStateChange.map((e) => e.session?.user);

  Future<Map<String, dynamic>?> fetchUserRow(String id) async {
    return await _client.from('users').select().eq('id', id).maybeSingle();
  }

  Future<void> signOut() => _client.auth.signOut();
}
