import 'package:flutter/foundation.dart';

import 'memory_game_controller.dart';

enum RaceSide { left, right }

class RaceController extends ChangeNotifier {
  RaceController({required this.left, required this.right}) {
    left.addListener(_onSideChanged);
    right.addListener(_onSideChanged);
  }

  final MemoryGameController left;
  final MemoryGameController right;
  RaceSide? _winner;
  int _raceNumber = 0;

  RaceSide? get winner => _winner;
  int get raceNumber => _raceNumber;

  bool get isRunning =>
      left.status == MemoryGameStatus.running ||
      right.status == MemoryGameStatus.running;

  void startBoth() {
    left.start();
    right.start();
    notifyListeners();
  }

  void pauseBoth() {
    left.pause();
    right.pause();
    notifyListeners();
  }

  void resumeBoth() {
    left.resume();
    right.resume();
    notifyListeners();
  }

  void resetRace() {
    _winner = null;
    _raceNumber++;
    left.reset();
    right.reset();
    notifyListeners();
  }

  MemoryGameController controllerFor(RaceSide side) {
    return switch (side) {
      RaceSide.left => left,
      RaceSide.right => right,
    };
  }

  void _onSideChanged() {
    if (_winner == null && left.isFinished) {
      _winner = RaceSide.left;
    } else if (_winner == null && right.isFinished) {
      _winner = RaceSide.right;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    left.removeListener(_onSideChanged);
    right.removeListener(_onSideChanged);
    left.dispose();
    right.dispose();
    super.dispose();
  }
}
