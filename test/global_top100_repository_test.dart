import 'package:ikizini_bul/leaderboards/global/global_top100_repository.dart';
import 'package:ikizini_bul/leaderboards/leaderboard_entry.dart';
import 'package:ikizini_bul/leaderboards/leaderboard_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'global repository keeps only top 100 and rejects below threshold',
    () async {
      final repository = GlobalTop100Repository(
        seedEntries: [
          for (var i = 0; i < 100; i++)
            _entry(playerName: 'Seed $i', score: 1000 + i),
        ],
      );

      final rejected = await repository.submit(
        _entry(playerName: 'Below', score: 999),
      );

      expect(rejected.status, ScoreSubmitStatus.rejectedBelowThreshold);
      expect(await repository.top(mode: LeaderboardMode.solo), hasLength(100));

      final accepted = await repository.submit(
        _entry(playerName: 'Champion', score: 2500),
      );
      final top = await repository.top(mode: LeaderboardMode.solo);

      expect(accepted.status, ScoreSubmitStatus.accepted);
      expect(accepted.rank, 1);
      expect(top, hasLength(100));
      expect(top.first.playerName, 'Champion');
      expect(top.any((entry) => entry.playerName == 'Below'), isFalse);
    },
  );
}

LeaderboardEntry _entry({required String playerName, required int score}) {
  return LeaderboardEntry(
    playerName: playerName,
    score: score,
    completionTime: Duration(milliseconds: 100000 - score),
    moves: 10,
    mode: LeaderboardMode.solo,
    createdAt: DateTime(2026),
  );
}
