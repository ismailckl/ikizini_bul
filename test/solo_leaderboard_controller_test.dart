import 'package:ikizini_bul/game/memory_game_config.dart';
import 'package:ikizini_bul/game/memory_game_controller.dart';
import 'package:ikizini_bul/leaderboards/local/solo_leaderboard_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('solo results are isolated in solo leaderboard', () async {
    final leaderboard = SoloLeaderboardController();
    await leaderboard.load();

    final game = MemoryGameController(
      playerName: 'Oyuncu',
      sideLabel: 'solo',
      config: const MemoryGameConfig(pairCount: 1, columns: 2),
      seed: 2,
    );
    game.start();
    game.revealCard(game.cards[0].id);
    game.revealCard(game.cards[1].id);

    await leaderboard.saveSoloResult(game);

    expect(leaderboard.entries, hasLength(1));
    expect(leaderboard.entries.single.playerName, 'Oyuncu');
    expect(leaderboard.entries.single.score, greaterThan(0));

    leaderboard.clearLastSaved();

    expect(leaderboard.lastSavedEntry, isNull);

    game.dispose();
    leaderboard.dispose();
  });
}
