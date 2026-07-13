import 'package:ikizini_bul/main.dart';
import 'package:ikizini_bul/game/memory_game_config.dart';
import 'package:ikizini_bul/game/memory_game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ikizini_bul/team/relay_team_state.dart';
import 'package:ikizini_bul/team/relay_team_store.dart';

void main() {
  Future<void> switchToSmartBoard(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Akıllı Tahta'));
    await tester.pumpAndSettle();
  }

  testWidgets('app opens in mobile solo mode first', (tester) async {
    await tester.pumpWidget(const BulBitirApp());

    expect(find.text('İKİZİNİ\nBUL'), findsOneWidget);
    expect(find.text('Oyuncu adı'), findsOneWidget);
    expect(find.text('Başla'), findsOneWidget);
    expect(find.text('4x4'), findsOneWidget);
    expect(find.text('5x5'), findsOneWidget);
    expect(find.text('Kart Listesi'), findsOneWidget);
    expect(find.text('Puan Tablosu'), findsOneWidget);
  });

  testWidgets('mobile shell fits narrow phone width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const BulBitirApp());

    expect(tester.takeException(), isNull);
    expect(find.text('Kart Listesi'), findsOneWidget);
  });

  testWidgets('smart board race screen renders both sides', (tester) async {
    await tester.pumpWidget(const BulBitirApp());
    await switchToSmartBoard(tester);

    expect(find.text('Akıllı Tahta'), findsOneWidget);
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

    await tester.tap(find.byTooltip('Kart Seti'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Şekiller').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Kart Seti'));
    await tester.pumpAndSettle();

    expect(find.text('Şekiller'), findsWidgets);
  });

  testWidgets('mobile player can enter name and start solo screen', (
    tester,
  ) async {
    await tester.pumpWidget(const BulBitirApp());

    expect(find.text('Oyuncu adı'), findsOneWidget);
    expect(find.text('Başla'), findsOneWidget);
    expect(find.text('Puan Tablosu'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Ismail');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Ismail'), findsOneWidget);
    expect(find.text('Süre'), findsOneWidget);
    expect(find.text('Puan'), findsOneWidget);
  });

  testWidgets('teacher can edit relay team players', (tester) async {
    await tester.pumpWidget(const BulBitirApp());
    await switchToSmartBoard(tester);

    await tester.tap(find.byTooltip('Takımlar'));
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

  testWidgets('mobile can open score and card list screens', (tester) async {
    await tester.pumpWidget(const BulBitirApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Puan Tablosu'));
    await tester.pumpAndSettle();

    expect(find.text('Henüz puan yok'), findsOneWidget);

    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kart Listesi'));
    await tester.pumpAndSettle();

    expect(find.text('Harfler'), findsOneWidget);
    expect(find.text('Sayılar'), findsOneWidget);
    expect(find.text('Şekiller'), findsOneWidget);
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
