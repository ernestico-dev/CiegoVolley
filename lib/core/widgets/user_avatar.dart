import 'package:flutter/material.dart';

/// Bola de usuario: muestra el avatar o las iniciales.
///
/// Al mantener pulsada la imagen se abre una vista ampliada.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
    this.onTap,
    this.enlargeOnLongPress = true,
  });

  final String name;
  final String? avatarUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onTap;
  final bool enlargeOnLongPress;

  static String initialsOf(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2);
    final letters = parts.map((part) => part[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = avatarUrl?.trim();
    final hasImage = url != null && url.isNotEmpty;

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? theme.colorScheme.primaryContainer,
      foregroundColor: foregroundColor ?? theme.colorScheme.onPrimaryContainer,
      backgroundImage: hasImage ? NetworkImage(url) : null,
      onBackgroundImageError: hasImage ? (error, stackTrace) {} : null,
      child: hasImage
          ? null
          : Text(
              initialsOf(name),
              style: TextStyle(
                fontSize: radius * 0.72,
                fontWeight: FontWeight.w700,
              ),
            ),
    );

    if (onTap == null && !enlargeOnLongPress) return avatar;

    return GestureDetector(
      onTap: onTap,
      onLongPress: enlargeOnLongPress
          ? () => showAvatarPreview(context, name: name, avatarUrl: url)
          : null,
      child: avatar,
    );
  }
}

/// Muestra la foto ampliada de un usuario.
Future<void> showAvatarPreview(
  BuildContext context, {
  required String name,
  String? avatarUrl,
}) {
  final url = avatarUrl?.trim();
  final hasImage = url != null && url.isNotEmpty;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);

      return Dialog(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasImage)
                ClipOval(
                  child: Image.network(
                    url,
                    width: 220,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _LargeInitials(name: name),
                  ),
                )
              else
                _LargeInitials(name: name),
              const SizedBox(height: 16),
              Text(
                name,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
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

class _LargeInitials extends StatelessWidget {
  const _LargeInitials({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CircleAvatar(
      radius: 110,
      backgroundColor: theme.colorScheme.primaryContainer,
      foregroundColor: theme.colorScheme.onPrimaryContainer,
      child: Text(
        UserAvatar.initialsOf(name),
        style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w700),
      ),
    );
  }
}
