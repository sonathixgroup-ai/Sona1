import 'package:thix_id/features/thix_sante/domain/models/profile_model.dart';

abstract class ProfileRepository {
  Future<ProfileModel?> fetchMyProfile();
  Future<ProfileModel> upsertMyProfile(ProfileModel profile);
}
