import 'package:ikizini_bul/game/card_content_set.dart';
import 'package:ikizini_bul/game/memory_card.dart';
import 'package:ikizini_bul/game/memory_game_config.dart';
import 'package:ikizini_bul/game/memory_game_controller.dart';
import 'package:ikizini_bul/game/race_controller.dart';
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

  test('selected content set builds the matching deck labels and visuals', () {
    final numbers = MemoryGameController(
      playerName: 'A',
      sideLabel: 'numbers',
      config: const MemoryGameConfig(
        pairCount: 3,
        columns: 3,
        contentSet: CardContentSets.numbers,
      ),
      seed: 3,
    );

    expect({for (final card in numbers.cards) card.label}, {'1', '2', '3'});
    expect(
      numbers.cards.every((card) => card.visual == CardVisualKind.text),
      isTrue,
    );

    final shapes = MemoryGameController(
      playerName: 'A',
      sideLabel: 'shapes',
      config: const MemoryGameConfig(
        pairCount: 3,
        columns: 3,
        contentSet: CardContentSets.shapes,
      ),
      seed: 4,
    );

    expect(
      {for (final card in shapes.cards) card.label},
      {'Daire', 'Üçgen', 'Kare'},
    );
    expect(
      shapes.cards.any((card) => card.visual != CardVisualKind.text),
      isTrue,
    );

    numbers.dispose();
    shapes.dispose();
  });

  test('slot count adds a bonus card for odd boards', () {
    final controller = MemoryGameController(
      playerName: 'A',
      sideLabel: 'bonus',
      config: const MemoryGameConfig(pairCount: 2, columns: 5, slotCount: 5),
      seed: 14,
    );

    expect(controller.boardSlotCount, 5);
    expect(controller.cards, hasLength(5));
    expect(controller.cards.where((card) => card.isBonus), hasLength(1));

    controller.start();
    final bonus = controller.cards.singleWhere((card) => card.isBonus);
    controller.revealCard(bonus.id);

    expect(
      controller.cards.singleWhere((card) => card.id == bonus.id).status,
      MemoryCardStatus.matched,
    );

    for (final pairId in {
      for (final card in controller.cards.where((card) => !card.isBonus))
        card.pairId,
    }) {
      final pair = controller.cards.where((card) => card.pairId == pairId);
      controller.revealCard(pair.first.id);
      controller.revealCard(pair.last.id);
    }

    expect(controller.status, MemoryGameStatus.finished);

    controller.dispose();
  });

  test('unseeded reset reshuffles the board', () {
    final controller = MemoryGameController(
      playerName: 'A',
      sideLabel: 'random',
      config: const MemoryGameConfig(pairCount: 8, columns: 4),
    );

    final firstOrder = controller.cards.map((card) => card.id).join(',');
    final orders = <String>{firstOrder};
    for (var i = 0; i < 4; i++) {
      controller.reset();
      orders.add(controller.cards.map((card) => card.id).join(','));
    }

    expect(orders.length, greaterThan(1));

    controller.dispose();
  });
}
