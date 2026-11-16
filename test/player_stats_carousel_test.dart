import 'package:ciego_volley/features/matches/domain/match_action.dart';
import 'package:ciego_volley/features/stats/domain/player_stats.dart';
import 'package:ciego_volley/features/stats/presentation/widgets/player_stats_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PlayerStats sample({
  required String id,
  required String name,
  int successes = 8,
  int failures = 2,
  int matchesWon = 1,
  int tournaments = 1,
}) {
  return PlayerStats(
    userId: id,
    name: name,
    successes: successes,
    failures: failures,
    matchesPlayed: 2,
    matchesWon: matchesWon,
    tournaments: tournaments,
    actions: {
      MatchAction.serve: const ActionTally(successes: 2, failures: 1),
      MatchAction.attack: const ActionTally(successes: 4, failures: 1),
      MatchAction.defense: const ActionTally(successes: 2, failures: 0),
    },
  );
}

Future<void> pumpCarousel(
  WidgetTester tester,
  List<PlayerStats> players,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: PlayerStatsCarousel(players: players),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra el jugador en foco y permite buscarlo', (tester) async {
    await pumpCarousel(tester, [
      sample(id: 'a', name: 'Ana Torres'),
      sample(id: 'b', name: 'Beto Ruiz'),
    ]);

    expect(find.text('Ana Torres'), findsOneWidget);
    expect(find.text('1 de 2'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'beto');
    await tester.pumpAndSettle();

    expect(find.text('Beto Ruiz'), findsOneWidget);
    expect(find.text('1 de 1'), findsOneWidget);
  });

  testWidgets('la búsqueda ignora tildes', (tester) async {
    await pumpCarousel(tester, [
      sample(id: 'a', name: 'José Pérez'),
      sample(id: 'b', name: 'Beto Ruiz'),
    ]);

    await tester.enterText(find.byType(TextField), 'jose');
    await tester.pumpAndSettle();

    expect(find.text('1 de 1'), findsOneWidget);
  });

  testWidgets('avanza deslizando y con las flechas', (tester) async {
    await pumpCarousel(tester, [
      sample(id: 'a', name: 'Ana Torres'),
      sample(id: 'b', name: 'Beto Ruiz'),
    ]);

    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();

    expect(find.text('2 de 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Jugador anterior'));
    await tester.pumpAndSettle();

    expect(find.text('1 de 2'), findsOneWidget);
  });

  testWidgets('sin jugadores muestra el aviso', (tester) async {
    await pumpCarousel(tester, const []);

    expect(
      find.text('Aún no hay acciones registradas por jugador.'),
      findsOneWidget,
    );
  });
}
