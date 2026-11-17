import 'package:ciego_volley/features/matches/domain/match_action.dart';
import 'package:ciego_volley/features/matches/presentation/match_draft_controller.dart';
import 'package:ciego_volley/features/teams/domain/team.dart';
import 'package:ciego_volley/features/teams/domain/team_member.dart';
import 'package:ciego_volley/features/tournaments/domain/tournament.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  late MatchDraftController controller;

  const tournament = Tournament(id: 't1', name: 'Liga', status: 'published');
  const homeTeam = Team(
    id: 'home',
    name: 'Tigres',
    category: 'Senior',
    ownerId: 'u1',
  );
  const awayTeam = Team(
    id: 'away',
    name: 'Leones',
    category: 'Senior',
    ownerId: 'u2',
  );
  const homePlayer = TeamMember(
    userId: 'u1',
    fullName: 'Ana Pérez',
    email: 'ana@example.com',
    role: 'player',
  );
  const awayPlayer = TeamMember(
    userId: 'u2',
    fullName: 'Luis Gómez',
    email: 'luis@example.com',
    role: 'player',
  );

  setUp(() {
    container = ProviderContainer.test();
    controller = container.read(matchDraftProvider.notifier);
    controller.start(
      tournament: tournament,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homePlayers: const [homePlayer],
      awayPlayers: const [awayPlayer],
      setsCount: 3,
    );
  });

  tearDown(() => container.dispose());

  test('el marcador suma y resta sin bajar de cero', () {
    controller.addPoint(home: true);
    controller.addPoint(home: true);
    controller.addPoint(home: false);

    var draft = container.read(matchDraftProvider)!;
    expect(draft.homeScore, 2);
    expect(draft.awayScore, 1);

    controller.removePoint(home: true);
    controller.removePoint(home: true);
    controller.removePoint(home: true);

    draft = container.read(matchDraftProvider)!;
    expect(draft.homeScore, 0);
    expect(draft.awayScore, 1);
  });

  test('registra éxitos y fallos por acción', () {
    controller.register('u1', MatchAction.serve, success: true);
    controller.register('u1', MatchAction.serve, success: true);
    controller.register('u1', MatchAction.serve, success: false);

    final tally = container
        .read(matchDraftProvider)!
        .tallyFor('u1', MatchAction.serve);

    expect(tally.successes, 2);
    expect(tally.failures, 1);
    expect(tally.total, 3);
  });

  test('deshacer quita la acción y borra la clave cuando queda a cero', () {
    controller.register('u2', MatchAction.block, success: true);
    controller.undo('u2', MatchAction.block, success: true);

    final draft = container.read(matchDraftProvider)!;
    expect(draft.tallyFor('u2', MatchAction.block).total, 0);
    expect(draft.tallies, isEmpty);
  });

  test('cada jugador lleva sus propias estadísticas', () {
    controller.register('u1', MatchAction.attack, success: true);
    controller.register('u2', MatchAction.attack, success: false);

    final draft = container.read(matchDraftProvider)!;
    expect(draft.tallyFor('u1', MatchAction.attack).successes, 1);
    expect(draft.tallyFor('u1', MatchAction.attack).failures, 0);
    expect(draft.tallyFor('u2', MatchAction.attack).successes, 0);
    expect(draft.tallyFor('u2', MatchAction.attack).failures, 1);
  });

  test('reiniciar deja el marcador y las estadísticas a cero', () {
    controller.addPoint(home: true);
    controller.register('u1', MatchAction.defense, success: true);

    controller.reset();

    final draft = container.read(matchDraftProvider)!;
    expect(draft.homeScore, 0);
    expect(draft.awayScore, 0);
    expect(draft.tallies, isEmpty);
  });

  test('teamIdOf resuelve el equipo de cada jugador', () {
    final draft = container.read(matchDraftProvider)!;
    expect(draft.teamIdOf('u1'), 'home');
    expect(draft.teamIdOf('u2'), 'away');
  });

  test('el partido se juega al número de sets elegido', () {
    final draft = container.read(matchDraftProvider)!;
    expect(draft.setsCount, 3);
    expect(draft.currentSet, 1);
    expect(draft.allSetsPlayed, isFalse);
  });

  test('cerrar un set guarda su marcador y empieza el siguiente', () {
    controller.addPoint(home: true);
    controller.addPoint(home: true);
    controller.addPoint(home: false);

    expect(controller.closeSet(), isTrue);

    var draft = container.read(matchDraftProvider)!;
    expect(draft.completedSets.length, 1);
    expect(draft.completedSets.single.home, 2);
    expect(draft.completedSets.single.away, 1);
    expect(draft.homeSetsWon, 1);
    expect(draft.awaySetsWon, 0);
    expect(draft.homeScore, 0);
    expect(draft.awayScore, 0);
    expect(draft.currentSet, 2);
  });

  test('no se cierra un set empatado ni a cero', () {
    expect(controller.closeSet(), isFalse);

    controller.addPoint(home: true);
    controller.addPoint(home: false);
    expect(controller.closeSet(), isFalse);

    expect(container.read(matchDraftProvider)!.completedSets, isEmpty);
  });

  test('al cerrar todos los sets el partido queda completo', () {
    for (var i = 0; i < 3; i++) {
      controller.addPoint(home: true);
      expect(controller.closeSet(), isTrue);
    }

    final draft = container.read(matchDraftProvider)!;
    expect(draft.allSetsPlayed, isTrue);
    expect(draft.homeSetsWon, 3);
    expect(controller.closeSet(), isFalse);
  });

  test('deshacer el último set devuelve sus puntos al marcador', () {
    controller.addPoint(home: false);

    expect(controller.closeSet(), isTrue);
    controller.undoLastSet();

    final draft = container.read(matchDraftProvider)!;
    expect(draft.completedSets, isEmpty);
    expect(draft.awayScore, 1);
    expect(draft.currentSet, 1);
  });

  test('reiniciar también borra los sets jugados', () {
    controller.addPoint(home: true);
    controller.closeSet();
    controller.addPoint(home: false);
    controller.closeSet();

    controller.reset();

    final draft = container.read(matchDraftProvider)!;
    expect(draft.completedSets, isEmpty);
    expect(draft.homeSetsWon, 0);
    expect(draft.awaySetsWon, 0);
  });

  test('clear descarta el partido', () {
    controller.clear();
    expect(container.read(matchDraftProvider), isNull);
  });
}
