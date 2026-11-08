import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Se muestra cuando la app arranca sin credenciales de Supabase.
class MissingConfigScreen extends StatelessWidget {
  const MissingConfigScreen({super.key});

  static const String _exampleJson = '''
{
  "SUPABASE_URL": "https://tu-proyecto.supabase.co",
  "SUPABASE_KEY": "tu-anon-o-publishable-key"
}''';

  static const String _command =
      'flutter run --dart-define-from-file=dart_defines/dev.json';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.settings_suggest_outlined,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Falta configurar Supabase',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea el archivo dart_defines/dev.json con las claves de tu '
                    'proyecto y vuelve a ejecutar la app.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  _CodeBlock(code: _exampleJson),
                  const SizedBox(height: 16),
                  _CodeBlock(code: _command),
                  const SizedBox(height: 8),
                  Text(
                    'Puedes copiar el ejemplo desde dart_defines/example.json. '
                    'La URL y la key están en el panel de Supabase, en '
                    'Project Settings > API.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copiar',
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copiado al portapapeles')),
              );
            },
          ),
        ],
      ),
    );
  }
}
