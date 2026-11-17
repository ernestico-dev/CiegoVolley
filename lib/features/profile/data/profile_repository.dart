import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/profile_summary.dart';
import '../../../core/storage/public_images.dart';
import '../../../core/supabase/supabase_providers.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(supabaseClientProvider)),
);

/// Perfil del usuario con sesión iniciada (incluye su rol y preferencias).
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
    try {
      final row = await _client
          .from('profiles')
          .select(
            'id, full_name, email, role, avatar_url, notifications_enabled',
          )
          .eq('id', userId)
          .maybeSingle();

      return row == null ? null : ProfileSummary.fromMap(row);
    } on PostgrestException {
      // Si todavía no se ejecutó la migración de notificaciones, seguimos
      // funcionando sin esa preferencia.
      final row = await _client
          .from('profiles')
          .select('id, full_name, email, role, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      return row == null ? null : ProfileSummary.fromMap(row);
    }
  }

  Future<void> setNotificationsEnabled(String userId, bool enabled) async {
    await _client
        .from('profiles')
        .update({'notifications_enabled': enabled})
        .eq('id', userId);
  }

  /// Sube el avatar a `avatars/<userId>/…` y guarda la URL pública.
  ///
  /// Se usa un nombre nuevo en cada subida para que el CDN no sirva la
  /// imagen anterior.
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
    String? previousUrl,
  }) async {
    final publicUrl = await uploadPublicImage(
      client: _client,
      bucket: 'avatars',
      folder: userId,
      baseName: 'avatar',
      bytes: bytes,
      extension: extension,
    );

    await _client
        .from('profiles')
        .update({'avatar_url': publicUrl})
        .eq('id', userId);

    await removePublicImage(
      client: _client,
      bucket: 'avatars',
      publicUrl: previousUrl,
    );

    return publicUrl;
  }
}
