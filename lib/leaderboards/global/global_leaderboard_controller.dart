import 'package:flutter/foundation.dart';

import '../leaderboard_entry.dart';
import '../leaderboard_repository.dart';
import 'global_top100_repository.dart';

class GlobalLeaderboardController extends ChangeNotifier {
  GlobalLeaderboardController({GlobalTop100Repository? repository})
    : _repository = repository ?? GlobalTop100Repository(),
      super();

  final GlobalTop100Repository _repository;

  List<LeaderboardEntry> _entries = const [];
  ScoreSubmitResult? _lastSubmitResult;
  LeaderboardEntry? _lastSubmittedEntry;

  List<LeaderboardEntry> get entries => List.unmodifiable(_entries);
  ScoreSubmitResult? get lastSubmitResult => _lastSubmitResult;
  LeaderboardEntry? get lastSubmittedEntry => _lastSubmittedEntry;

  Future<void> load({LeaderboardMode mode = LeaderboardMode.solo}) async {
    await _refresh(mode: mode);
  }

  Future<ScoreSubmitResult> submit(LeaderboardEntry entry) async {
    final result = await _repository.submit(entry);
    _lastSubmittedEntry = entry;
    _lastSubmitResult = result;
    await _refresh(mode: entry.mode);
    return result;
  }

  void clearLastSubmit() {
    _lastSubmittedEntry = null;
    _lastSubmitResult = null;
    notifyListeners();
  }

  Future<void> _refresh({required LeaderboardMode mode}) async {
    _entries = await _repository.top(mode: mode, limit: 100);
    notifyListeners();
  }
}
