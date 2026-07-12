import 'package:ikizini_bul/main.dart';
import 'package:ikizini_bul/game/memory_game_config.dart';
import 'package:ikizini_bul/game/memory_game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ikizini_bul/leaderboards/local/class_leaderboard_store.dart';
import 'package:ikizini_bul/team/relay_team_state.dart';
import 'package:ikizini_bul/team/relay_team_store.dart';

void main() {
  testWidgets('smart board race screen renders both sides', (tester) async {
    await tester.pumpWidget(const BulBitirApp());

    expect(find.text('Ikizini Bul'), findsWidgets);
    expect(find.text('Takim A'), findsOneWidget);
    expect(find.text('Takim B'), findsOneWidget);
    expect(find.text('Sira: Ali'), findsOneWidget);
    expect(find.text('Sira: Deniz'), findsOneWidget);
    expect(find.byIcon(Icons.question_mark), findsWidgets);

    await tester.tap(find.byIcon(Icons.flag));
    await tester.pump();

    expect(find.byIcon(Icons.pause), findsOneWidget);
  });

  testWidgets('smart board can switch card content set', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const BulBitirApp());

    await tester.tap(find.text('Harfler').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sekiller').last);
    await tester.pumpAndSettle();

    expect(find.text('Sekiller'), findsWidgets);
  });

  testWidgets('mode switch opens solo game screen', (tester) async {
    await tester.pumpWidget(const BulBitirApp());

    await tester.tap(find.text('Solo').first);
    await tester.pumpAndSettle();

    expect(find.text('Zamana karsi'), findsOneWidget);
    expect(find.text('Oyuncu adi'), findsOneWidget);
    expect(find.text('Oyuna Gir'), findsOneWidget);
    expect(find.text('Solo Skorlar'), findsOneWidget);
    expect(find.text('Global Top 100'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Ismail');
    await tester.tap(find.text('Oyuna Gir'));
    await tester.pumpAndSettle();

    expect(find.text('Ismail'), findsOneWidget);
    expect(find.byIcon(Icons.phone_android), findsWidgets);
  });

  testWidgets('teacher can edit relay team players', (tester) async {
    await tester.pumpWidget(const BulBitirApp());

    await tester.tap(find.byIcon(Icons.groups).first);
    await tester.pumpAndSettle();

    expect(find.text('Takimlari Duzenle'), findsOneWidget);

    final leftField = find.byType(TextField).first;
    await tester.enterText(leftField, 'Ada\nEfe');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('Sira: Ada'), findsOneWidget);
  });

  testWidgets('smart board loads persisted relay team players', (tester) async {
    final teamStore = MemoryRelayTeamStore();
    await teamStore.writeSetup(
      RelayTeamSetup(
        leftTeam: RelayTeamState(teamName: 'Takim A', players: ['Selin']),
        rightTeam: RelayTeamState(teamName: 'Takim B', players: ['Burak']),
      ),
    );

    await tester.pumpWidget(BulBitirApp(relayTeamStore: teamStore));
    await tester.pumpAndSettle();

    expect(find.text('Sira: Selin'), findsOneWidget);
    expect(find.text('Sira: Burak'), findsOneWidget);
  });

  testWidgets('teacher can create a local class tournament list', (
    tester,
  ) async {
    final classStore = MemoryClassLeaderboardStore();

    await tester.pumpWidget(BulBitirApp(classLeaderboardStore: classStore));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Liste Ekle'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '8-A Turnuvasi');
    await tester.tap(find.text('Olustur'));
    await tester.pumpAndSettle();

    expect(find.text('8-A Turnuvasi'), findsOneWidget);

    final storedLists = await classStore.readLists();
    expect(storedLists.map((list) => list.name), contains('8-A Turnuvasi'));
  });

  testWidgets('memory card grid scales into compact bounds', (tester) async {
    final controller = MemoryGameController(
      playerName: 'Test',
      sideLabel: 'Compact',
      config: const MemoryGameConfig(pairCount: 8, columns: 4),
      seed: 11,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              height: 180,
              child: MemoryCardGrid(
                controller: controller,
                accent: const Color(0xff0f766e),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.question_mark), findsWidgets);

    controller.dispose();
  });
}
