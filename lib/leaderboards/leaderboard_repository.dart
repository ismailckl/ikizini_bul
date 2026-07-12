import 'leaderboard_entry.dart';

enum ScoreSubmitStatus { accepted, rejectedBelowThreshold, queuedOffline }

class ScoreSubmitResult {
  const ScoreSubmitResult({required this.status, this.rank});

  final ScoreSubmitStatus status;
  final int? rank;
}

class SavedScore {
  const SavedScore({required this.entry, required this.result});

  final LeaderboardEntry entry;
  final ScoreSubmitResult result;
}

abstract class LeaderboardRepository {
  Future<List<LeaderboardEntry>> top({
    required LeaderboardMode mode,
    String? listId,
    int limit = 100,
  });

  Future<ScoreSubmitResult> submit(LeaderboardEntry entry, {String? listId});
}
