import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'relay_team_state.dart';

abstract class RelayTeamStore {
  Future<RelayTeamSetup?> readSetup();

  Future<void> writeSetup(RelayTeamSetup setup);
}

class MemoryRelayTeamStore implements RelayTeamStore {
  MemoryRelayTeamStore({String? seed}) : _encodedSetup = seed;

  String? _encodedSetup;

  String? get debugSnapshot => _encodedSetup;

  @override
  Future<RelayTeamSetup?> readSetup() async {
    final encoded = _encodedSetup;
    if (encoded == null || encoded.isEmpty) {
      return null;
    }
    return RelayTeamSetup.fromJson(
      (jsonDecode(encoded) as Map).cast<String, Object?>(),
    );
  }

  @override
  Future<void> writeSetup(RelayTeamSetup setup) async {
    _encodedSetup = jsonEncode(setup.toJson());
  }
}

class SharedPreferencesRelayTeamStore implements RelayTeamStore {
  SharedPreferencesRelayTeamStore({required this.prefs});

  static const String _storageKey = 'ikizini_bul.relay_teams';

  static Future<SharedPreferencesRelayTeamStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesRelayTeamStore(prefs: prefs);
  }

  final SharedPreferences prefs;

  @override
  Future<RelayTeamSetup?> readSetup() async {
    final encoded = prefs.getString(_storageKey);
    if (encoded == null || encoded.isEmpty) {
      return null;
    }
    return RelayTeamSetup.fromJson(
      (jsonDecode(encoded) as Map).cast<String, Object?>(),
    );
  }

  @override
  Future<void> writeSetup(RelayTeamSetup setup) async {
    await prefs.setString(_storageKey, jsonEncode(setup.toJson()));
  }
}
