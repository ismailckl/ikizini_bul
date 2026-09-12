import '../leaderboard_entry.dart';
import '../leaderboard_repository.dart';
import 'local_leaderboard_store.dart';

class LocalLeaderboardRepository implements LeaderboardRepository {
  LocalLeaderboardRepository({LocalLeaderboardStore? store})
    : _store = store ?? MemoryLocalLeaderboardStore();

  final LocalLeaderboardStore _store;

  @override
  Future<List<LeaderboardEntry>> top({
    required LeaderboardMode mode,
    String? listId,
    int limit = 100,
  }) async {
    final entries = await _store.readEntries(_key(mode, listId));
    entries.sort(_compareEntries);
    return entries.take(limit).toList();
  }

  @override
  Future<ScoreSubmitResult> submit(
    LeaderboardEntry entry, {
    String? listId,
  }) async {
    final key = _key(entry.mode, listId);
    final entries = await _store.readEntries(key);
    entries.add(entry);
    entries.sort(_compareEntries);
    await _store.writeEntries(key, entries);
    final rank = entries.indexOf(entry) + 1;
    return ScoreSubmitResult(
      status: ScoreSubmitStatus.accepted,
      rank: rank == 0 ? null : rank,
    );
  }

  Future<bool> deleteEntry(LeaderboardEntry entry, {String? listId}) async {
    final key = _key(entry.mode, listId);
    final entries = await _store.readEntries(key);
    final index = entries.indexWhere(
      (candidate) => _sameEntry(candidate, entry),
    );
    if (index == -1) {
      return false;
    }
    entries.removeAt(index);
    await _store.writeEntries(key, entries);
    return true;
  }

  String _key(LeaderboardMode mode, String? listId) {
    return '${mode.name}:${listId ?? 'default'}';
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

  bool _sameEntry(LeaderboardEntry a, LeaderboardEntry b) {
    return a.playerName == b.playerName &&
        a.teamName == b.teamName &&
        a.score == b.score &&
        a.completionTime == b.completionTime &&
        a.moves == b.moves &&
        a.mode == b.mode &&
        a.createdAt == b.createdAt;
  }
}
