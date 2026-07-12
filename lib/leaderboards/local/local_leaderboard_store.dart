import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../leaderboard_entry.dart';

abstract class LocalLeaderboardStore {
  Future<List<LeaderboardEntry>> readEntries(String key);

  Future<void> writeEntries(String key, List<LeaderboardEntry> entries);
}

class MemoryLocalLeaderboardStore implements LocalLeaderboardStore {
  MemoryLocalLeaderboardStore({Map<String, String>? seed})
    : _encodedLists = seed ?? {};

  final Map<String, String> _encodedLists;

  Map<String, String> get debugSnapshot => Map.unmodifiable(_encodedLists);

  @override
  Future<List<LeaderboardEntry>> readEntries(String key) async {
    final encoded = _encodedLists[key];
    if (encoded == null || encoded.isEmpty) {
      return <LeaderboardEntry>[];
    }
    final decoded = jsonDecode(encoded) as List<dynamic>;
    return [
      for (final item in decoded)
        LeaderboardEntry.fromJson((item as Map).cast<String, Object?>()),
    ];
  }

  @override
  Future<void> writeEntries(String key, List<LeaderboardEntry> entries) async {
    _encodedLists[key] = jsonEncode([
      for (final entry in entries) entry.toJson(),
    ]);
  }
}

class SharedPreferencesLocalLeaderboardStore implements LocalLeaderboardStore {
  SharedPreferencesLocalLeaderboardStore({required this.prefs});

  static const String _keyPrefix = 'bul_bitir.leaderboards';

  static Future<SharedPreferencesLocalLeaderboardStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesLocalLeaderboardStore(prefs: prefs);
  }

  final SharedPreferences prefs;

  @override
  Future<List<LeaderboardEntry>> readEntries(String key) async {
    final encoded = prefs.getString(_storageKey(key));
    if (encoded == null || encoded.isEmpty) {
      return <LeaderboardEntry>[];
    }
    final decoded = jsonDecode(encoded) as List<dynamic>;
    return [
      for (final item in decoded)
        LeaderboardEntry.fromJson((item as Map).cast<String, Object?>()),
    ];
  }

  @override
  Future<void> writeEntries(String key, List<LeaderboardEntry> entries) async {
    await prefs.setString(
      _storageKey(key),
      jsonEncode([for (final entry in entries) entry.toJson()]),
    );
  }

  String _storageKey(String key) {
    return '$_keyPrefix.$key';
  }
}
