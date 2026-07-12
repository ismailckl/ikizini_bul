import 'package:flutter/foundation.dart';

import '../game/memory_game_controller.dart';
import 'relay_team_state.dart';

enum RelaySide { left, right }

class RelayRaceController extends ChangeNotifier {
  RelayRaceController({
    required this.leftGame,
    required this.rightGame,
    required RelayTeamState leftTeam,
    required RelayTeamState rightTeam,
    this.maxConsecutiveMistakes = 2,
  }) : _initialLeftTeam = leftTeam,
       _initialRightTeam = rightTeam,
       _leftTeam = leftTeam,
       _rightTeam = rightTeam,
       _lastLeftTurnVersion = leftGame.turnVersion,
       _lastRightTurnVersion = rightGame.turnVersion {
    leftGame.addListener(_onLeftGameChanged);
    rightGame.addListener(_onRightGameChanged);
  }

  final MemoryGameController leftGame;
  final MemoryGameController rightGame;
  final int maxConsecutiveMistakes;

  RelayTeamState _initialLeftTeam;
  RelayTeamState _initialRightTeam;
  RelayTeamState _leftTeam;
  RelayTeamState _rightTeam;
  int _lastLeftTurnVersion;
  int _lastRightTurnVersion;
  RelaySide? _lastHandoffSide;

  RelayTeamState get leftTeam => _leftTeam;
  RelayTeamState get rightTeam => _rightTeam;
  RelaySide? get lastHandoffSide => _lastHandoffSide;

  void resetTeams() {
    _leftTeam = _initialLeftTeam;
    _rightTeam = _initialRightTeam;
    _lastLeftTurnVersion = leftGame.turnVersion;
    _lastRightTurnVersion = rightGame.turnVersion;
    _lastHandoffSide = null;
    notifyListeners();
  }

  void configureTeams({
    required RelayTeamState leftTeam,
    required RelayTeamState rightTeam,
  }) {
    _initialLeftTeam = leftTeam;
    _initialRightTeam = rightTeam;
    resetTeams();
  }

  RelayTeamState teamFor(RelaySide side) {
    return switch (side) {
      RelaySide.left => _leftTeam,
      RelaySide.right => _rightTeam,
    };
  }

  void _onLeftGameChanged() {
    _consumeTurnResult(RelaySide.left, leftGame);
  }

  void _onRightGameChanged() {
    _consumeTurnResult(RelaySide.right, rightGame);
  }

  void _consumeTurnResult(RelaySide side, MemoryGameController game) {
    final lastVersion = switch (side) {
      RelaySide.left => _lastLeftTurnVersion,
      RelaySide.right => _lastRightTurnVersion,
    };
    if (game.turnVersion == lastVersion) {
      return;
    }

    if (side == RelaySide.left) {
      _lastLeftTurnVersion = game.turnVersion;
    } else {
      _lastRightTurnVersion = game.turnVersion;
    }

    final result = game.lastTurnResult;
    if (result == null) {
      return;
    }

    final before = teamFor(side);
    final after = switch (result) {
      MemoryTurnResult.match => before.recordMatchAndAdvance(),
      MemoryTurnResult.mismatch => before.recordMistake(
        maxConsecutiveMistakes: maxConsecutiveMistakes,
      ),
    };

    if (side == RelaySide.left) {
      _leftTeam = after;
    } else {
      _rightTeam = after;
    }

    if (before.activePlayerIndex != after.activePlayerIndex) {
      _lastHandoffSide = side;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    leftGame.removeListener(_onLeftGameChanged);
    rightGame.removeListener(_onRightGameChanged);
    super.dispose();
  }
}
