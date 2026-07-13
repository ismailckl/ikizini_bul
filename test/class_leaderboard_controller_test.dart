import 'package:ikizini_bul/game/memory_game_config.dart';
import 'package:ikizini_bul/game/memory_game_controller.dart';
import 'package:ikizini_bul/leaderboards/local/class_leaderboard_controller.dart';
import 'package:ikizini_bul/leaderboards/local/class_leaderboard_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('smart board results are saved into the selected local list', () async {
    final leaderboard = ClassLeaderboardController();
    await leaderboard.load();

    final game = MemoryGameController(
      playerName: 'Takım A',
      sideLabel: 'left',
      config: const MemoryGameConfig(pairCount: 1, columns: 2),
      seed: 5,
    );
    game.start();
    game.revealCard(game.cards[0].id);
    game.revealCard(game.cards[1].id);

    await leaderboard.saveSmartBoardResult(game);

    expect(leaderboard.entries, hasLength(1));
    expect(leaderboard.entries.single.playerName, 'Takım A');
    expect(leaderboard.entries.single.score, greaterThan(0));

    await leaderboard.selectList('7-b-deneme');

    expect(leaderboard.entries, isEmpty);

    await leaderboard.selectList('6-a-turnuva');

    expect(leaderboard.entries, hasLength(1));

    game.dispose();
    leaderboard.dispose();
  });

  test('class lists can be created selected deleted and persisted', () async {
    final store = MemoryClassLeaderboardStore();
    final firstController = ClassLeaderboardController(listStore: store);
    await firstController.load();

    final created = await firstController.createList('8-A Turnuvası');

    expect(created, isNotNull);
    expect(firstController.selectedList.name, '8-A Turnuvası');
    expect(
      firstController.lists.map((list) => list.name),
      contains('8-A Turnuvası'),
    );

    final secondController = ClassLeaderboardController(listStore: store);
    await secondController.load();

    expect(
      secondController.lists.map((list) => list.name),
      contains('8-A Turnuvası'),
    );

    await secondController.selectList(created!.id);
    expect(secondController.selectedList.name, '8-A Turnuvası');

    final deleted = await secondController.deleteList(created.id);

    expect(deleted, isTrue);
    expect(
      secondController.lists.map((list) => list.name),
      isNot(contains('8-A Turnuvası')),
    );
    expect(secondController.selectedList.id, '6-a-turnuva');

    firstController.dispose();
    secondController.dispose();
  });
}
