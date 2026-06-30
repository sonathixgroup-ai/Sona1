import 'package:thix_id/features/thix_sante/core/thix_sante_exceptions.dart';
import 'package:thix_id/features/thix_sante/core/thix_sante_tables.dart';
import 'package:thix_id/features/thix_sante/domain/models/profile_model.dart';
import 'package:thix_id/features/thix_sante/domain/repositories/profile_repository.dart';
import 'package:thix_id/supabase/supabase_client.dart';

class SupabaseProfileRepository implements ProfileRepository {
  @override
  Future<ProfileModel?> fetchMyProfile() async {
    final uid = requireUserId();

    try {
      final data = await supabase
          .from(ThixSanteTables.profiles)
          .select('*')
          .eq('user_id', uid)
          .maybeSingle();

      if (data == null) return null;
      return ProfileModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw mapSupabaseError(e, context: 'fetchMyProfile');
    }
  }

  @override
  Future<ProfileModel> upsertMyProfile(ProfileModel profile) async {
    final uid = requireUserId();

    try {
      final payload = profile.copyWith(userId: uid).toJson();
      final res = await supabase
          .from(ThixSanteTables.profiles)
          .upsert(payload, onConflict: 'user_id')
          .select('*')
          .single();

      return ProfileModel.fromJson(Map<String, dynamic>.from(res));
    } catch (e) {
      throw mapSupabaseError(e, context: 'upsertMyProfile');
    }
  }
}
