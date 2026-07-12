import 'package:bul_bitir/leaderboards/local/class_leaderboard.dart';
import 'package:bul_bitir/leaderboards/local/class_leaderboard_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('class leaderboard lists round-trip through memory store', () async {
    final store = MemoryClassLeaderboardStore();

    await store.writeLists(const [
      ClassLeaderboard(id: '8-a-turnuva', name: '8-A Turnuvasi'),
    ]);

    final restored = await store.readLists();

    expect(restored, hasLength(1));
    expect(restored.single.id, '8-a-turnuva');
    expect(restored.single.name, '8-A Turnuvasi');
  });

  test('class leaderboard lists persist in shared preferences store', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = SharedPreferencesClassLeaderboardStore(prefs: prefs);

    await store.writeLists(const [
      ClassLeaderboard(id: '6-b-final', name: '6-B Final'),
    ]);

    final restored = await SharedPreferencesClassLeaderboardStore(
      prefs: prefs,
    ).readLists();

    expect(restored.single.id, '6-b-final');
    expect(restored.single.name, '6-B Final');
  });
}
