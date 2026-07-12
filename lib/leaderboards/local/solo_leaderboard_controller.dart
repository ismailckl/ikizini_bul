import 'package:flutter/foundation.dart';

import '../../game/memory_game_controller.dart';
import '../leaderboard_entry.dart';
import '../leaderboard_repository.dart';
import 'local_leaderboard_repository.dart';

class SoloLeaderboardController extends ChangeNotifier {
  SoloLeaderboardController({
    LocalLeaderboardRepository? repository,
    this.scorePolicy = const ScorePolicy(),
  }) : _repository = repository ?? LocalLeaderboardRepository(),
       super();

  static const String soloListId = 'solo-best-times';

  final LocalLeaderboardRepository _repository;
  final ScorePolicy scorePolicy;

  List<LeaderboardEntry> _entries = const [];
  LeaderboardEntry? _lastSavedEntry;

  List<LeaderboardEntry> get entries => List.unmodifiable(_entries);
  LeaderboardEntry? get lastSavedEntry => _lastSavedEntry;

  Future<void> load() async {
    await _refresh();
  }

  Future<SavedScore> saveSoloResult(MemoryGameController game) async {
    final entry = LeaderboardEntry(
      playerName: game.playerName,
      score: scorePolicy.calculate(
        completionTime: game.elapsed,
        moves: game.moves,
        pairCount: game.pairCount,
      ),
      completionTime: game.elapsed,
      moves: game.moves,
      mode: LeaderboardMode.solo,
      createdAt: DateTime.now(),
    );

    final result = await _repository.submit(entry, listId: soloListId);
    _lastSavedEntry = entry;
    await _refresh();
    return SavedScore(entry: entry, result: result);
  }

  void clearLastSaved() {
    _lastSavedEntry = null;
    notifyListeners();
  }

  Future<void> _refresh() async {
    _entries = await _repository.top(
      mode: LeaderboardMode.solo,
      listId: soloListId,
      limit: 10,
    );
    notifyListeners();
  }
}
