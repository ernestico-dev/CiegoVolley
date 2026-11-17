import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Imagen elegida de la galería, lista para subir a Storage.
class PickedImage {
  const PickedImage({required this.bytes, required this.extension});

  final Uint8List bytes;
  final String extension;
}

/// Abre la galería y devuelve la imagen elegida.
///
/// Devuelve `null` si el usuario cancela. La imagen se reduce de tamaño para
/// que la subida sea rápida y quepa en el límite del bucket.
Future<PickedImage?> pickImageFromGallery({int maxSide = 1280}) async {
  final picker = ImagePicker();
  final file = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: maxSide.toDouble(),
    maxHeight: maxSide.toDouble(),
    imageQuality: 85,
  );
  if (file == null) return null;

  final bytes = await file.readAsBytes();
  return PickedImage(
    bytes: bytes,
    extension: extensionOfImage(file.name, file.mimeType),
  );
}

/// Extensión del archivo, con el tipo MIME como respaldo.
String extensionOfImage(String name, String? mimeType) {
  final dot = name.lastIndexOf('.');
  if (dot >= 0 && dot < name.length - 1) {
    return name.substring(dot + 1).toLowerCase();
  }

  return switch (mimeType?.toLowerCase()) {
    'image/png' => 'png',
    'image/webp' => 'webp',
    'image/gif' => 'gif',
    _ => 'jpg',
  };
}
