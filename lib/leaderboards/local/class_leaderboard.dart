class ClassLeaderboard {
  const ClassLeaderboard({required this.id, required this.name});

  final String id;
  final String name;

  Map<String, Object?> toJson() {
    return {'id': id, 'name': name};
  }

  factory ClassLeaderboard.fromJson(Map<String, Object?> json) {
    return ClassLeaderboard(
      id: (json['id'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
    );
  }
}

const List<ClassLeaderboard> defaultClassLeaderboards = [
  ClassLeaderboard(id: '6-a-turnuva', name: '6-A Turnuvası'),
  ClassLeaderboard(id: '7-b-deneme', name: '7-B Deneme'),
  ClassLeaderboard(id: 'ogretmen-modu', name: 'Öğretmen Modu'),
];
