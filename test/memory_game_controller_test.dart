import 'package:bul_bitir/game/memory_card.dart';
import 'package:bul_bitir/game/memory_game_config.dart';
import 'package:bul_bitir/game/memory_game_controller.dart';
import 'package:bul_bitir/game/race_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matching two cards records a pair and a move', () {
    final controller = MemoryGameController(
      playerName: 'A',
      sideLabel: 'left',
      config: const MemoryGameConfig(pairCount: 2, columns: 2),
      seed: 7,
    );

    controller.start();
    final pair = controller.cards
        .where((card) => card.pairId == controller.cards.first.pairId)
        .toList();

    controller.revealCard(pair[0].id);
    controller.revealCard(pair[1].id);

    expect(controller.moves, 1);
    expect(controller.matchedPairs, 1);
    expect(controller.lastTurnResult, MemoryTurnResult.match);
    expect(controller.turnVersion, 1);
    expect(
      controller.cards
          .where((card) => card.pairId == pair[0].pairId)
          .every((card) => card.status == MemoryCardStatus.matched),
      isTrue,
    );

    controller.dispose();
  });

  test('mismatched cards are hidden after the peek delay', () async {
    final controller = MemoryGameController(
      playerName: 'A',
      sideLabel: 'left',
      config: const MemoryGameConfig(
        pairCount: 2,
        columns: 2,
        mismatchPeek: Duration(milliseconds: 1),
      ),
      seed: 9,
    );

    controller.start();
    final first = controller.cards.first;
    final second = controller.cards.firstWhere(
      (card) => card.pairId != first.pairId,
    );

    controller.revealCard(first.id);
    controller.revealCard(second.id);

    expect(controller.isBoardLocked, isTrue);
    expect(controller.lastTurnResult, MemoryTurnResult.mismatch);
    expect(controller.turnVersion, 1);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(controller.isBoardLocked, isFalse);
    expect(
      controller.cards
          .where((card) => card.id == first.id || card.id == second.id)
          .every((card) => card.status == MemoryCardStatus.hidden),
      isTrue,
    );

    controller.dispose();
  });

  test('race declares the side that finishes first', () {
    final left = MemoryGameController(
      playerName: 'A',
      sideLabel: 'left',
      config: const MemoryGameConfig(pairCount: 2, columns: 2),
      seed: 11,
    );
    final right = MemoryGameController(
      playerName: 'B',
      sideLabel: 'right',
      config: const MemoryGameConfig(pairCount: 2, columns: 2),
      seed: 11,
    );
    final race = RaceController(left: left, right: right);

    race.startBoth();
    for (final pairId in {for (final card in left.cards) card.pairId}) {
      final pair = left.cards.where((card) => card.pairId == pairId).toList();
      left.revealCard(pair[0].id);
      left.revealCard(pair[1].id);
    }

    expect(left.status, MemoryGameStatus.finished);
    expect(race.winner, RaceSide.left);

    race.dispose();
  });
}
