import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/profile_summary.dart';
import '../../../core/supabase/supabase_providers.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(supabaseClientProvider)),
);

/// Perfil del usuario con sesión iniciada (incluye su rol).
final myProfileProvider = FutureProvider.autoDispose<ProfileSummary?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  return ref.watch(profileRepositoryProvider).fetchProfile(user.id);
}, retry: noRetry);

/// `true` cuando el usuario actual es administrador del club.
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(myProfileProvider).asData?.value?.isAdmin ?? false;
});

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<ProfileSummary?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select('id, full_name, email, role')
        .eq('id', userId)
        .maybeSingle();

    return row == null ? null : ProfileSummary.fromMap(row);
  }
}
