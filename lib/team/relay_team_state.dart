class RelayTeamState {
  const RelayTeamState({
    required this.teamName,
    required this.players,
    this.activePlayerIndex = 0,
    this.consecutiveMistakes = 0,
  }) : assert(players.length > 0);

  final String teamName;
  final List<String> players;
  final int activePlayerIndex;
  final int consecutiveMistakes;

  String get activePlayer => players[activePlayerIndex];

  Map<String, Object?> toJson() {
    return {
      'teamName': teamName,
      'players': players,
      'activePlayerIndex': activePlayerIndex,
      'consecutiveMistakes': consecutiveMistakes,
    };
  }

  factory RelayTeamState.fromJson(Map<String, Object?> json) {
    return RelayTeamState(
      teamName: json['teamName'] as String,
      players: [
        for (final player in json['players'] as List<dynamic>) player as String,
      ],
      activePlayerIndex: json['activePlayerIndex'] as int? ?? 0,
      consecutiveMistakes: json['consecutiveMistakes'] as int? ?? 0,
    );
  }

  RelayTeamState recordMatchAndAdvance() {
    return copyWith(
      activePlayerIndex: (activePlayerIndex + 1) % players.length,
      consecutiveMistakes: 0,
    );
  }

  RelayTeamState recordMistake({int maxConsecutiveMistakes = 2}) {
    final nextMistakes = consecutiveMistakes + 1;
    if (nextMistakes >= maxConsecutiveMistakes) {
      return copyWith(
        activePlayerIndex: (activePlayerIndex + 1) % players.length,
        consecutiveMistakes: 0,
      );
    }
    return copyWith(consecutiveMistakes: nextMistakes);
  }

  RelayTeamState copyWith({int? activePlayerIndex, int? consecutiveMistakes}) {
    return RelayTeamState(
      teamName: teamName,
      players: players,
      activePlayerIndex: activePlayerIndex ?? this.activePlayerIndex,
      consecutiveMistakes: consecutiveMistakes ?? this.consecutiveMistakes,
    );
  }
}

class RelayTeamSetup {
  const RelayTeamSetup({required this.leftTeam, required this.rightTeam});

  final RelayTeamState leftTeam;
  final RelayTeamState rightTeam;

  Map<String, Object?> toJson() {
    return {'leftTeam': leftTeam.toJson(), 'rightTeam': rightTeam.toJson()};
  }

  factory RelayTeamSetup.fromJson(Map<String, Object?> json) {
    return RelayTeamSetup(
      leftTeam: RelayTeamState.fromJson(
        (json['leftTeam'] as Map).cast<String, Object?>(),
      ),
      rightTeam: RelayTeamState.fromJson(
        (json['rightTeam'] as Map).cast<String, Object?>(),
      ),
    );
  }
}
