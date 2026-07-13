import 'package:ikizini_bul/main.dart';
import 'package:ikizini_bul/game/memory_game_config.dart';
import 'package:ikizini_bul/game/memory_game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ikizini_bul/leaderboards/local/class_leaderboard_store.dart';
import 'package:ikizini_bul/team/relay_team_state.dart';
import 'package:ikizini_bul/team/relay_team_store.dart';

void main() {
  Future<void> switchToSmartBoard(WidgetTester tester) async {
    await tester.tap(find.text('Akıllı Tahta').first);
    await tester.pumpAndSettle();
  }

  testWidgets('app opens in mobile solo mode first', (tester) async {
    await tester.pumpWidget(const BulBitirApp());

    expect(find.text('İkizini Bul'), findsWidgets);
    expect(find.text('Oyuncu adı'), findsOneWidget);
    expect(find.text('Başla'), findsOneWidget);
    expect(find.text('Skorlarım'), findsOneWidget);
  });

  testWidgets('mobile shell fits narrow phone width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const BulBitirApp());

    expect(find.text('Tahta'), findsOneWidget);
  });

  testWidgets('smart board race screen renders both sides', (tester) async {
    await tester.pumpWidget(const BulBitirApp());
    await switchToSmartBoard(tester);

    expect(find.text('İkizini Bul'), findsWidgets);
    expect(find.text('Takım A'), findsOneWidget);
    expect(find.text('Takım B'), findsOneWidget);
    expect(find.text('Sıra: Ali'), findsOneWidget);
    expect(find.text('Sıra: Deniz'), findsOneWidget);
    expect(find.byIcon(Icons.question_mark), findsWidgets);

    await tester.tap(find.byIcon(Icons.flag));
    await tester.pump();

    expect(find.byIcon(Icons.pause), findsOneWidget);
  });

  testWidgets('smart board can switch card content set', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const BulBitirApp());
    await switchToSmartBoard(tester);

    await tester.tap(find.text('Harfler').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Şekiller').last);
    await tester.pumpAndSettle();

    expect(find.text('Şekiller'), findsWidgets);
  });

  testWidgets('mobile player can enter name and start solo screen', (
    tester,
  ) async {
    await tester.pumpWidget(const BulBitirApp());

    expect(find.text('Adını yaz, kartları eşleştir.'), findsOneWidget);
    expect(find.text('Oyuncu adı'), findsOneWidget);
    expect(find.text('Başla'), findsOneWidget);
    expect(find.text('Skorlarım'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Ismail');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Ismail'), findsOneWidget);
    expect(find.text('Kartları eşleştir'), findsOneWidget);
  });

  testWidgets('teacher can edit relay team players', (tester) async {
    await tester.pumpWidget(const BulBitirApp());
    await switchToSmartBoard(tester);

    await tester.tap(find.byIcon(Icons.groups).first);
    await tester.pumpAndSettle();

    expect(find.text('Takımları Düzenle'), findsOneWidget);

    final leftField = find.byType(TextField).first;
    await tester.enterText(leftField, 'Ada\nEfe');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('Sıra: Ada'), findsOneWidget);
  });

  testWidgets('smart board loads persisted relay team players', (tester) async {
    final teamStore = MemoryRelayTeamStore();
    await teamStore.writeSetup(
      RelayTeamSetup(
        leftTeam: RelayTeamState(teamName: 'Takım A', players: ['Selin']),
        rightTeam: RelayTeamState(teamName: 'Takım B', players: ['Burak']),
      ),
    );

    await tester.pumpWidget(BulBitirApp(relayTeamStore: teamStore));
    await switchToSmartBoard(tester);
    await tester.pumpAndSettle();

    expect(find.text('Sıra: Selin'), findsOneWidget);
    expect(find.text('Sıra: Burak'), findsOneWidget);
  });

  testWidgets('teacher can create a local class tournament list', (
    tester,
  ) async {
    final classStore = MemoryClassLeaderboardStore();

    await tester.pumpWidget(BulBitirApp(classLeaderboardStore: classStore));
    await switchToSmartBoard(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Liste Ekle'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '8-A Turnuvası');
    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    expect(find.text('8-A Turnuvası'), findsOneWidget);

    final storedLists = await classStore.readLists();
    expect(storedLists.map((list) => list.name), contains('8-A Turnuvası'));
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
