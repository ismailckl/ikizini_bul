import 'package:ikizini_bul/game/memory_game_config.dart';
import 'package:ikizini_bul/game/memory_game_controller.dart';
import 'package:ikizini_bul/team/relay_race_controller.dart';
import 'package:ikizini_bul/team/relay_team_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('relay advances on a match and after two mistakes', () async {
    final left = MemoryGameController(
      playerName: 'Takim A',
      sideLabel: 'left',
      config: const MemoryGameConfig(
        pairCount: 3,
        columns: 3,
        mismatchPeek: Duration(milliseconds: 1),
      ),
      seed: 12,
    );
    final right = MemoryGameController(
      playerName: 'Takim B',
      sideLabel: 'right',
      config: const MemoryGameConfig(pairCount: 3, columns: 3),
      seed: 13,
    );
    final relay = RelayRaceController(
      leftGame: left,
      rightGame: right,
      leftTeam: RelayTeamState(teamName: 'A', players: ['Ali', 'Ece']),
      rightTeam: RelayTeamState(teamName: 'B', players: ['Can', 'Elif']),
    );

    left.start();
    final matchingPair = left.cards
        .where((card) => card.pairId == left.cards.first.pairId)
        .toList();
    left.revealCard(matchingPair[0].id);
    left.revealCard(matchingPair[1].id);

    expect(relay.leftTeam.activePlayer, 'Ece');
    expect(relay.leftTeam.consecutiveMistakes, 0);

    final firstMismatch = left.cards.firstWhere(
      (card) => card.status.name == 'hidden',
    );
    final secondMismatch = left.cards.firstWhere(
      (card) =>
          card.status.name == 'hidden' && card.pairId != firstMismatch.pairId,
    );
    left.revealCard(firstMismatch.id);
    left.revealCard(secondMismatch.id);

    expect(relay.leftTeam.activePlayer, 'Ece');
    expect(relay.leftTeam.consecutiveMistakes, 1);

    await Future<void>.delayed(const Duration(milliseconds: 5));

    final thirdMismatch = left.cards.firstWhere(
      (card) => card.status.name == 'hidden',
    );
    final fourthMismatch = left.cards.firstWhere(
      (card) =>
          card.status.name == 'hidden' && card.pairId != thirdMismatch.pairId,
    );
    left.revealCard(thirdMismatch.id);
    left.revealCard(fourthMismatch.id);

    expect(relay.leftTeam.activePlayer, 'Ali');
    expect(relay.leftTeam.consecutiveMistakes, 0);

    relay.dispose();
    left.dispose();
    right.dispose();
  });

  test('relay can reconfigure teams and reset active players', () {
    final left = MemoryGameController(
      playerName: 'Takim A',
      sideLabel: 'left',
      config: const MemoryGameConfig(pairCount: 1, columns: 2),
      seed: 1,
    );
    final right = MemoryGameController(
      playerName: 'Takim B',
      sideLabel: 'right',
      config: const MemoryGameConfig(pairCount: 1, columns: 2),
      seed: 2,
    );
    final relay = RelayRaceController(
      leftGame: left,
      rightGame: right,
      leftTeam: RelayTeamState(teamName: 'A', players: ['Ali']),
      rightTeam: RelayTeamState(teamName: 'B', players: ['Can']),
    );

    relay.configureTeams(
      leftTeam: RelayTeamState(teamName: 'A', players: ['Ada', 'Efe']),
      rightTeam: RelayTeamState(teamName: 'B', players: ['Mina', 'Kaan']),
    );

    expect(relay.leftTeam.activePlayer, 'Ada');
    expect(relay.rightTeam.activePlayer, 'Mina');
    expect(relay.leftTeam.players, ['Ada', 'Efe']);

    relay.dispose();
    left.dispose();
    right.dispose();
  });
}
