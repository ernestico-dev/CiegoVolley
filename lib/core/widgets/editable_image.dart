import 'package:flutter/material.dart';

/// Imagen de equipo o de torneo.
///
/// Muestra la foto cuando existe y un respaldo (iniciales o icono) cuando no.
/// Si [onEdit] no es nulo aparece una insignia de cámara para cambiarla, y al
/// mantener pulsada la imagen se abre en grande.
class EditableImage extends StatelessWidget {
  const EditableImage({
    super.key,
    required this.imageUrl,
    required this.fallback,
    this.previewTitle = '',
    this.size,
    this.aspectRatio,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.backgroundColor,
    this.onEdit,
    this.uploading = false,
  }) : assert(size != null || aspectRatio != null, 'Indica size o aspectRatio');

  final String? imageUrl;
  final Widget fallback;
  final String previewTitle;
  final double? size;
  final double? aspectRatio;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onEdit;
  final bool uploading;

  bool get _hasImage {
    final url = imageUrl?.trim();
    return url != null && url.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = imageUrl?.trim();

    Widget content = Container(
      color: backgroundColor ?? theme.colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: _hasImage
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => fallback,
            )
          : fallback,
    );

    if (uploading) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          content,
          ColoredBox(
            color: Colors.black.withValues(alpha: 0.35),
            child: const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
          ),
        ],
      );
    }

    Widget clipped = ClipRRect(borderRadius: borderRadius, child: content);

    if (size != null) {
      clipped = SizedBox(width: size, height: size, child: clipped);
    } else {
      clipped = AspectRatio(aspectRatio: aspectRatio!, child: clipped);
    }

    if (onEdit != null) {
      clipped = Stack(
        children: [
          clipped,
          Positioned(
            right: 6,
            bottom: 6,
            child: _CameraBadge(onTap: uploading ? null : onEdit),
          ),
        ],
      );
    }

    if (onEdit == null && !_hasImage) return clipped;

    return GestureDetector(
      onTap: uploading ? null : (onEdit ?? () => _preview(context)),
      onLongPress: _hasImage && !uploading ? () => _preview(context) : null,
      child: clipped,
    );
  }

  void _preview(BuildContext context) {
    showImagePreview(
      context,
      title: previewTitle,
      imageUrl: imageUrl,
      fallback: fallback,
    );
  }
}

class _CameraBadge extends StatelessWidget {
  const _CameraBadge({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.primary,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            Icons.photo_camera_outlined,
            size: 16,
            color: scheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

/// Muestra una imagen de equipo o torneo en grande.
Future<void> showImagePreview(
  BuildContext context, {
  required String title,
  String? imageUrl,
  Widget? fallback,
}) {
  final url = imageUrl?.trim();
  final hasImage = url != null && url.isNotEmpty;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);

      return Dialog(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: hasImage
                    ? Image.network(
                        url,
                        width: 300,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => SizedBox(
                          width: 300,
                          height: 180,
                          child: Center(child: fallback),
                        ),
                      )
                    : SizedBox(
                        width: 300,
                        height: 180,
                        child: Center(child: fallback),
                      ),
              ),
              if (title.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
