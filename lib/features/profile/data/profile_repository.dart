import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/profile_summary.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/utils/app_exception.dart';

/// Tamaño máximo aceptado para una foto de perfil.
const int _maxAvatarBytes = 5 * 1024 * 1024;

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
    if (bytes.isEmpty) {
      throw const AppException(
        'No pudimos leer la imagen. Elige otra foto de la galería.',
      );
    }
    if (bytes.lengthInBytes > _maxAvatarBytes) {
      throw const AppException(
        'La imagen pesa más de 5 MB. Elige una foto más pequeña.',
      );
    }

    final cleanExtension = extension.toLowerCase().replaceAll('.', '');
    final safeExtension =
        const {'jpg', 'jpeg', 'png', 'webp', 'gif'}.contains(cleanExtension)
        ? cleanExtension
        : 'jpg';

    final path =
        '$userId/avatar-${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
    final contentType = safeExtension == 'png'
        ? 'image/png'
        : safeExtension == 'webp'
        ? 'image/webp'
        : safeExtension == 'gif'
        ? 'image/gif'
        : 'image/jpeg';

    try {
      await _client.storage
          .from('avatars')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );
    } on StorageException catch (error, stackTrace) {
      // El mensaje real del servidor es la única pista útil para saber si
      // falta el bucket, las políticas o la sesión.
      debugPrint(
        'Avatar: falló la subida de $path '
        '(${bytes.lengthInBytes} bytes, $contentType): $error',
      );
      debugPrint('$stackTrace');
      rethrow;
    }

    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);

    await _client
        .from('profiles')
        .update({'avatar_url': publicUrl})
        .eq('id', userId);

    await _removePrevious(previousUrl, path);

    return publicUrl;
  }

  /// Borra el avatar anterior del bucket, si era nuestro.
  Future<void> _removePrevious(String? previousUrl, String currentPath) async {
    if (previousUrl == null || previousUrl.isEmpty) return;

    final marker = '/storage/v1/object/public/avatars/';
    final index = previousUrl.indexOf(marker);
    if (index < 0) return;

    final oldPath = previousUrl.substring(index + marker.length);
    if (oldPath.isEmpty || oldPath == currentPath) return;

    try {
      await _client.storage.from('avatars').remove([oldPath]);
    } catch (_) {
      // Si falla el borrado no pasa nada: la imagen nueva ya está guardada.
    }
  }
}
