import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';

/// Sección de torneos. Base para implementar calendario, cuadros y actas.
class TournamentsScreen extends StatelessWidget {
  const TournamentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Torneos')),
      body: EmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'Torneos, en camino',
        message:
            'Esta sección está preparada para el calendario, los grupos y '
            'las actas de cada jornada. Sigue el mismo patrón de Equipos: '
            'repositorio, provider y pantalla.',
        action: FilledButton.tonalIcon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Muy pronto disponible')),
            );
          },
          icon: const Icon(Icons.notifications_outlined),
          label: const Text('Avísame'),
        ),
      ),
    );
  }
}
