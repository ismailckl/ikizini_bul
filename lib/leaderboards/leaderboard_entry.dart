enum LeaderboardMode { solo, smartBoardDuel, teamRelay }

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.playerName,
    required this.score,
    required this.completionTime,
    required this.moves,
    required this.mode,
    required this.createdAt,
    this.teamName,
  });

  final String playerName;
  final String? teamName;
  final int score;
  final Duration completionTime;
  final int moves;
  final LeaderboardMode mode;
  final DateTime createdAt;

  Map<String, Object?> toJson() {
    return {
      'playerName': playerName,
      'teamName': teamName,
      'score': score,
      'completionTimeMs': completionTime.inMilliseconds,
      'moves': moves,
      'mode': mode.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LeaderboardEntry.fromJson(Map<String, Object?> json) {
    return LeaderboardEntry(
      playerName: json['playerName'] as String,
      teamName: json['teamName'] as String?,
      score: json['score'] as int,
      completionTime: Duration(milliseconds: json['completionTimeMs'] as int),
      moves: json['moves'] as int,
      mode: LeaderboardMode.values.byName(json['mode'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ScorePolicy {
  const ScorePolicy();

  int calculate({
    required Duration completionTime,
    required int moves,
    required int pairCount,
  }) {
    final speedBonus = (120000 - completionTime.inMilliseconds).clamp(
      0,
      120000,
    );
    final accuracyPenalty = moves * 35;
    final pairBonus = pairCount * 1000;
    return (pairBonus + speedBonus ~/ 20 - accuracyPenalty).clamp(0, 999999);
  }
}
