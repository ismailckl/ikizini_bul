import 'package:ikizini_bul/team/relay_team_state.dart';
import 'package:ikizini_bul/team/relay_team_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('relay team setup round-trips through memory store', () async {
    final store = MemoryRelayTeamStore();
    final setup = RelayTeamSetup(
      leftTeam: RelayTeamState(teamName: 'A', players: ['Ada', 'Efe']),
      rightTeam: RelayTeamState(teamName: 'B', players: ['Mina', 'Kaan']),
    );

    await store.writeSetup(setup);
    final restored = await store.readSetup();

    expect(restored?.leftTeam.players, ['Ada', 'Efe']);
    expect(restored?.rightTeam.players, ['Mina', 'Kaan']);
  });

  test('relay team setup persists in shared preferences store', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = SharedPreferencesRelayTeamStore(prefs: prefs);

    await store.writeSetup(
      RelayTeamSetup(
        leftTeam: RelayTeamState(teamName: 'A', players: ['Selin']),
        rightTeam: RelayTeamState(teamName: 'B', players: ['Burak']),
      ),
    );

    final restored = await SharedPreferencesRelayTeamStore(
      prefs: prefs,
    ).readSetup();

    expect(restored?.leftTeam.activePlayer, 'Selin');
    expect(restored?.rightTeam.activePlayer, 'Burak');
  });
}
