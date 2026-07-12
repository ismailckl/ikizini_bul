import '../leaderboard_entry.dart';
import '../leaderboard_repository.dart';

class GlobalTop100Repository implements LeaderboardRepository {
  GlobalTop100Repository({List<LeaderboardEntry>? seedEntries})
    : _entries = seedEntries ?? [];

  final List<LeaderboardEntry> _entries;

  @override
  Future<List<LeaderboardEntry>> top({
    required LeaderboardMode mode,
    String? listId,
    int limit = 100,
  }) async {
    final filtered = _entries.where((entry) => entry.mode == mode).toList()
      ..sort(_compareEntries);
    return filtered.take(limit).toList();
  }

  @override
  Future<ScoreSubmitResult> submit(
    LeaderboardEntry entry, {
    String? listId,
  }) async {
    final currentTop = await top(mode: entry.mode);
    if (currentTop.length >= 100) {
      final threshold = currentTop.last;
      if (_compareEntries(entry, threshold) >= 0) {
        return const ScoreSubmitResult(
          status: ScoreSubmitStatus.rejectedBelowThreshold,
        );
      }
    }

    _entries.add(entry);
    final sorted = await top(mode: entry.mode, limit: _entries.length);
    _entries
      ..removeWhere((candidate) => candidate.mode == entry.mode)
      ..addAll(sorted.take(100));
    final rank = sorted.indexOf(entry) + 1;
    return ScoreSubmitResult(
      status: ScoreSubmitStatus.accepted,
      rank: rank == 0 ? null : rank,
    );
  }

  int _compareEntries(LeaderboardEntry a, LeaderboardEntry b) {
    final scoreCompare = b.score.compareTo(a.score);
    if (scoreCompare != 0) {
      return scoreCompare;
    }
    final timeCompare = a.completionTime.compareTo(b.completionTime);
    if (timeCompare != 0) {
      return timeCompare;
    }
    return a.moves.compareTo(b.moves);
  }
}
