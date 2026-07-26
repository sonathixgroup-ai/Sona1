// lib/features/auth/presentation/providers/auth_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/app_user.dart';
import '../../data/auth_repository.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
Stream<dynamic> authUserStream(AuthUserStreamRef ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
}

@Riverpod(keepAlive: true)
class AppUserNotifier extends _$AppUserNotifier {
  @override
  Future<AppUser?> build() async {
    final user = await ref.watch(authUserStreamProvider.future);
    if (user == null) return null;
    final row = await ref.read(authRepositoryProvider).fetchUserRow(user.id);
    if (row == null) return null;
    return AppUser.fromSupabase(row);
  }

  Future<void> refresh() => ref.invalidateSelf();
}

@riverpod
bool isModeratorEnterprise(IsModeratorEnterpriseRef ref) {
  final appUser = ref.watch(appUserNotifierProvider).valueOrNull;
  if (appUser == null) return false;
  final r = (appUser.registrationStatus ?? appUser.occupation ?? '').toLowerCase();
  return r == 'admin' || r == 'moderator' || r == 'moderateur';
}

@riverpod
bool isAuthenticatedEnterprise(IsAuthenticatedEnterpriseRef ref) {
  return ref.watch(authUserStreamProvider).valueOrNull != null;
}
