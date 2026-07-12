import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'class_leaderboard.dart';

abstract class ClassLeaderboardStore {
  Future<List<ClassLeaderboard>> readLists();

  Future<void> writeLists(List<ClassLeaderboard> lists);
}

class MemoryClassLeaderboardStore implements ClassLeaderboardStore {
  MemoryClassLeaderboardStore({String? seed}) : _encodedLists = seed;

  String? _encodedLists;

  String? get debugSnapshot => _encodedLists;

  @override
  Future<List<ClassLeaderboard>> readLists() async {
    return _decodeLists(_encodedLists);
  }

  @override
  Future<void> writeLists(List<ClassLeaderboard> lists) async {
    _encodedLists = jsonEncode([for (final list in lists) list.toJson()]);
  }
}

class SharedPreferencesClassLeaderboardStore implements ClassLeaderboardStore {
  SharedPreferencesClassLeaderboardStore({required this.prefs});

  static const String _storageKey = 'ikizini_bul.class_leaderboards';

  static Future<SharedPreferencesClassLeaderboardStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesClassLeaderboardStore(prefs: prefs);
  }

  final SharedPreferences prefs;

  @override
  Future<List<ClassLeaderboard>> readLists() async {
    return _decodeLists(prefs.getString(_storageKey));
  }

  @override
  Future<void> writeLists(List<ClassLeaderboard> lists) async {
    await prefs.setString(
      _storageKey,
      jsonEncode([for (final list in lists) list.toJson()]),
    );
  }
}

List<ClassLeaderboard> _decodeLists(String? encoded) {
  if (encoded == null || encoded.isEmpty) {
    return <ClassLeaderboard>[];
  }

  final decoded = jsonDecode(encoded);
  if (decoded is! List<dynamic>) {
    return <ClassLeaderboard>[];
  }

  final lists = <ClassLeaderboard>[];
  for (final item in decoded) {
    if (item is! Map) {
      continue;
    }
    final list = ClassLeaderboard.fromJson(item.cast<String, Object?>());
    if (list.id.isNotEmpty && list.name.isNotEmpty) {
      lists.add(list);
    }
  }
  return lists;
}
