import 'package:ciego_volley/features/matches/domain/match_action.dart';
import 'package:ciego_volley/features/stats/domain/action_leader.dart';
import 'package:ciego_volley/features/stats/domain/player_stats.dart';
import 'package:flutter_test/flutter_test.dart';

PlayerStats player({
  String id = 'u1',
  String name = 'Ana',
  int successes = 0,
  int failures = 0,
  int matchesWon = 0,
  int tournaments = 1,
}) {
  return PlayerStats(
    userId: id,
    name: name,
    successes: successes,
    failures: failures,
    matchesPlayed: matchesWon,
    matchesWon: matchesWon,
    tournaments: tournaments,
  );
}

void main() {
  group('PlayerStats', () {
    test('calcula el porcentaje de aciertos', () {
      final ana = player(successes: 3, failures: 1);
      expect(ana.attempts, 4);
      expect(ana.successPercent, 75);
    });

    test('sin intentos el porcentaje es cero', () {
      expect(player().successPercent, 0);
    });

    test('ordena por porcentaje y desempata por partidos ganados', () {
      final list = [
        player(id: 'a', name: 'Ana', successes: 5, failures: 5, matchesWon: 1),
        player(id: 'b', name: 'Beto', successes: 9, failures: 1, matchesWon: 0),
        player(
          id: 'c',
          name: 'Caro',
          successes: 18,
          failures: 2,
          matchesWon: 3,
        ),
      ]..sort(PlayerStats.compare);

      expect(list.map((p) => p.name).toList(), ['Caro', 'Beto', 'Ana']);
    });

    test('quien no llega al mínimo de intentos va al final', () {
      final list = [
        player(id: 'a', name: 'Ana', successes: 1, failures: 0),
        player(id: 'b', name: 'Beto', successes: 4, failures: 6),
      ]..sort(PlayerStats.compare);

      expect(list.first.name, 'Beto');
    });

    test('elige como mejor fundamento el de mayor porcentaje', () {
      const stats = PlayerStats(
        userId: 'u1',
        name: 'Ana',
        successes: 8,
        failures: 2,
        matchesPlayed: 2,
        matchesWon: 1,
        tournaments: 1,
        actions: {
          MatchAction.serve: ActionTally(successes: 1, failures: 1),
          MatchAction.attack: ActionTally(successes: 4, failures: 1),
          MatchAction.defense: ActionTally(successes: 3, failures: 0),
        },
      );

      expect(stats.bestAction, MatchAction.defense);
      expect(stats.tallyFor(MatchAction.attack).successPercent, 80);
      expect(stats.tallyFor(MatchAction.block).total, 0);
    });
  });

  group('ActionLeader', () {
    test('ordena por porcentaje y luego por aciertos', () {
      final list = [
        const ActionLeader(
          action: MatchAction.serve,
          userId: 'a',
          name: 'Ana',
          successes: 4,
          failures: 1,
        ),
        const ActionLeader(
          action: MatchAction.serve,
          userId: 'b',
          name: 'Beto',
          successes: 7,
          failures: 3,
        ),
        const ActionLeader(
          action: MatchAction.serve,
          userId: 'c',
          name: 'Caro',
          successes: 9,
          failures: 1,
        ),
      ]..sort(ActionLeader.compare);

      expect(list.map((l) => l.name).toList(), ['Caro', 'Ana', 'Beto']);
    });
  });
}
