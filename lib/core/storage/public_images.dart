import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_exception.dart';

/// Extensiones de imagen aceptadas en los buckets públicos.
const Set<String> _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'gif'};

/// Peso máximo de una imagen de equipo o torneo.
const int maxPublicImageBytes = 5 * 1024 * 1024;

/// Devuelve una extensión válida para subir a Storage.
///
/// Si el archivo no trae una conocida se asume JPG.
String normalizeImageExtension(String extension) {
  final clean = extension.toLowerCase().replaceAll('.', '').trim();
  return _allowedExtensions.contains(clean) ? clean : 'jpg';
}

/// Tipo MIME que corresponde a una extensión ya normalizada.
String imageContentType(String extension) {
  return switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    _ => 'image/jpeg',
  };
}

/// Sube una imagen a un bucket público y devuelve su URL pública.
///
/// Se usa un nombre nuevo en cada subida para que el CDN no sirva la imagen
/// anterior. La imagen vieja se borra después de guardar la nueva URL con
/// [removePublicImage].
Future<String> uploadPublicImage({
  required SupabaseClient client,
  required String bucket,
  required String folder,
  required String baseName,
  required Uint8List bytes,
  required String extension,
}) async {
  if (bytes.isEmpty) {
    throw const AppException('No pudimos leer la imagen. Elige otro archivo.');
  }
  if (bytes.lengthInBytes > maxPublicImageBytes) {
    throw const AppException(
      'La imagen pesa más de 5 MB. Elige una más pequeña.',
    );
  }

  final safeExtension = normalizeImageExtension(extension);
  final contentType = imageContentType(safeExtension);
  final path =
      '$folder/$baseName-${DateTime.now().millisecondsSinceEpoch}.$safeExtension';

  try {
    await client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
  } on StorageException catch (error, stackTrace) {
    debugPrint(
      'Imagen: falló la subida de $bucket/$path '
      '(${bytes.lengthInBytes} bytes, $contentType): $error',
    );
    debugPrint('$stackTrace');
    rethrow;
  }

  return client.storage.from(bucket).getPublicUrl(path);
}

/// Borra una imagen anterior del bucket, si la URL es de ese bucket.
Future<void> removePublicImage({
  required SupabaseClient client,
  required String bucket,
  required String? publicUrl,
  String? keepPath,
}) async {
  if (publicUrl == null || publicUrl.isEmpty) return;

  final marker = '/storage/v1/object/public/$bucket/';
  final index = publicUrl.indexOf(marker);
  if (index < 0) return;

  final oldPath = publicUrl.substring(index + marker.length);
  if (oldPath.isEmpty || oldPath == keepPath) return;

  try {
    await client.storage.from(bucket).remove([oldPath]);
  } catch (error) {
    // Si falla el borrado no pasa nada: la imagen nueva ya está guardada.
    debugPrint('Imagen: no se pudo borrar $oldPath: $error');
  }
}
