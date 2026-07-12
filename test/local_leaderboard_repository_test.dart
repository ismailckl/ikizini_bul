import 'package:bul_bitir/leaderboards/leaderboard_entry.dart';
import 'package:bul_bitir/leaderboards/local/local_leaderboard_repository.dart';
import 'package:bul_bitir/leaderboards/local/local_leaderboard_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'local repository persists entries through the injected store',
    () async {
      final store = MemoryLocalLeaderboardStore();
      final firstRepository = LocalLeaderboardRepository(store: store);

      await firstRepository.submit(
        _entry(playerName: 'Ali', score: 4200),
        listId: '6-a-turnuva',
      );

      expect(store.debugSnapshot, isNotEmpty);

      final secondRepository = LocalLeaderboardRepository(store: store);
      final entries = await secondRepository.top(
        mode: LeaderboardMode.smartBoardDuel,
        listId: '6-a-turnuva',
      );

      expect(entries, hasLength(1));
      expect(entries.single.playerName, 'Ali');
      expect(entries.single.score, 4200);
    },
  );

  test('leaderboard entry round-trips through json', () {
    final original = _entry(playerName: 'Ece', score: 5100);

    final restored = LeaderboardEntry.fromJson(original.toJson());

    expect(restored.playerName, original.playerName);
    expect(restored.score, original.score);
    expect(restored.completionTime, original.completionTime);
    expect(restored.mode, original.mode);
    expect(restored.createdAt, original.createdAt);
  });

  test(
    'shared preferences store persists encoded leaderboard entries',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPreferencesLocalLeaderboardStore(prefs: prefs);
      final repository = LocalLeaderboardRepository(store: store);

      await repository.submit(
        _entry(playerName: 'Mert', score: 6100),
        listId: 'solo-best-times',
      );

      final nextRepository = LocalLeaderboardRepository(
        store: SharedPreferencesLocalLeaderboardStore(prefs: prefs),
      );
      final entries = await nextRepository.top(
        mode: LeaderboardMode.smartBoardDuel,
        listId: 'solo-best-times',
      );

      expect(entries, hasLength(1));
      expect(entries.single.playerName, 'Mert');
      expect(entries.single.score, 6100);
    },
  );
}

LeaderboardEntry _entry({required String playerName, required int score}) {
  return LeaderboardEntry(
    playerName: playerName,
    score: score,
    completionTime: const Duration(seconds: 42),
    moves: 12,
    mode: LeaderboardMode.smartBoardDuel,
    createdAt: DateTime(2026, 7, 12, 12),
  );
}
