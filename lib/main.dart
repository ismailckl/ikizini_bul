import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'audio/game_audio_controller.dart';
import 'game/card_content_set.dart';
import 'game/memory_card.dart';
import 'game/memory_game_config.dart';
import 'game/memory_game_controller.dart';
import 'game/race_controller.dart';
import 'leaderboards/leaderboard_entry.dart';
import 'leaderboards/local/class_leaderboard_controller.dart';
import 'leaderboards/local/class_leaderboard_store.dart';
import 'leaderboards/local/local_leaderboard_repository.dart';
import 'leaderboards/local/local_leaderboard_store.dart';
import 'leaderboards/local/solo_leaderboard_controller.dart';
import 'team/relay_race_controller.dart';
import 'team/relay_team_store.dart';
import 'team/relay_team_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localStore = await SharedPreferencesLocalLeaderboardStore.create();
  final relayTeamStore = await SharedPreferencesRelayTeamStore.create();
  final classLeaderboardStore =
      await SharedPreferencesClassLeaderboardStore.create();
  runApp(
    BulBitirApp(
      localStore: localStore,
      relayTeamStore: relayTeamStore,
      classLeaderboardStore: classLeaderboardStore,
    ),
  );
}

class BulBitirApp extends StatelessWidget {
  const BulBitirApp({
    this.localStore,
    this.relayTeamStore,
    this.classLeaderboardStore,
    super.key,
  });

  final LocalLeaderboardStore? localStore;
  final RelayTeamStore? relayTeamStore;
  final ClassLeaderboardStore? classLeaderboardStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'İkizini Bul',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff0f766e),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfff7faf9),
        useMaterial3: true,
      ),
      home: GameModeShell(
        localStore: localStore,
        relayTeamStore: relayTeamStore,
        classLeaderboardStore: classLeaderboardStore,
      ),
    );
  }
}

enum PlayMode { smartBoard, solo }

enum SoloView { menu, game, scores, cards }

class BoardPreset {
  const BoardPreset({
    required this.label,
    required this.pairCount,
    required this.columns,
    required this.slotCount,
  });

  final String label;
  final int pairCount;
  final int columns;
  final int slotCount;
}

const List<BoardPreset> boardPresets = [
  BoardPreset(label: '4x4', pairCount: 8, columns: 4, slotCount: 16),
  BoardPreset(label: '5x5', pairCount: 12, columns: 5, slotCount: 25),
];

String formatGameDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final tenths = (duration.inMilliseconds.remainder(1000) ~/ 100).toString();
  return '$minutes:$seconds.$tenths';
}

class GameModeShell extends StatefulWidget {
  const GameModeShell({
    this.localStore,
    this.relayTeamStore,
    this.classLeaderboardStore,
    super.key,
  });

  final LocalLeaderboardStore? localStore;
  final RelayTeamStore? relayTeamStore;
  final ClassLeaderboardStore? classLeaderboardStore;

  @override
  State<GameModeShell> createState() => _GameModeShellState();
}

class _GameModeShellState extends State<GameModeShell> {
  late final LocalLeaderboardRepository _localRepository;
  PlayMode _selectedMode = PlayMode.solo;

  @override
  void initState() {
    super.initState();
    _localRepository = LocalLeaderboardRepository(store: widget.localStore);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedMode == PlayMode.solo ? 0 : 1,
          children: [
            SoloGameScreen(
              localRepository: _localRepository,
              onOpenSmartBoard: () {
                setState(() => _selectedMode = PlayMode.smartBoard);
              },
            ),
            SmartBoardRaceScreen(
              localRepository: _localRepository,
              relayTeamStore: widget.relayTeamStore,
              classLeaderboardStore: widget.classLeaderboardStore,
              onBackToSolo: () {
                setState(() => _selectedMode = PlayMode.solo);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ModeSwitchBar extends StatelessWidget {
  const ModeSwitchBar({
    required this.selectedMode,
    required this.onModeChanged,
    super.key,
  });

  final PlayMode selectedMode;
  final ValueChanged<PlayMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        final modePicker = SegmentedButton<PlayMode>(
          segments: [
            const ButtonSegment(
              value: PlayMode.solo,
              icon: Icon(Icons.phone_android),
              label: Text('Mobil'),
            ),
            ButtonSegment(
              value: PlayMode.smartBoard,
              icon: const Icon(Icons.dashboard),
              label: Text(compact ? 'Tahta' : 'Akıllı Tahta'),
            ),
          ],
          selected: {selectedMode},
          onSelectionChanged: (selection) {
            onModeChanged(selection.single);
          },
        );

        if (compact) {
          return Container(
            height: 96,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xffffffff),
              border: Border(bottom: BorderSide(color: Color(0xffd9e2df))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    MemoryGameMark(size: 32),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'İkizini Bul',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _CompactModeButton(
                          selected: selectedMode == PlayMode.solo,
                          icon: Icons.phone_android,
                          label: 'Mobil',
                          onTap: () => onModeChanged(PlayMode.solo),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CompactModeButton(
                          selected: selectedMode == PlayMode.smartBoard,
                          icon: Icons.dashboard,
                          label: 'Tahta',
                          onTap: () => onModeChanged(PlayMode.smartBoard),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xffffffff),
            border: Border(bottom: BorderSide(color: Color(0xffd9e2df))),
          ),
          child: Row(
            children: [
              const MemoryGameMark(size: 38),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'İkizini Bul',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              modePicker,
            ],
          ),
        );
      },
    );
  }
}

class _CompactModeButton extends StatelessWidget {
  const _CompactModeButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : const Color(0xff415753);
    return Material(
      color: selected ? const Color(0xff0f766e) : const Color(0xfff3f7f6),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected ? const Color(0xff0f766e) : const Color(0xffd5e1dd),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MemoryGameMark extends StatelessWidget {
  const MemoryGameMark({
    this.size = 88,
    this.accent = const Color(0xff0f766e),
    this.secondary = const Color(0xfff59e0b),
    super.key,
  });

  final double size;
  final Color accent;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final cardWidth = size * 0.44;
    final cardHeight = size * 0.58;
    final badgeSize = size * 0.28;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: size * 0.12,
            top: size * 0.18,
            child: Transform.rotate(
              angle: -0.16,
              child: _MemoryLogoCard(
                width: cardWidth,
                height: cardHeight,
                accent: accent,
                icon: Icons.question_mark,
              ),
            ),
          ),
          Positioned(
            right: size * 0.12,
            top: size * 0.18,
            child: Transform.rotate(
              angle: 0.16,
              child: _MemoryLogoCard(
                width: cardWidth,
                height: cardHeight,
                accent: secondary,
                icon: Icons.extension,
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.06,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: const Color(0xff1f2937),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.bolt,
                color: Colors.white,
                size: badgeSize * 0.62,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryLogoCard extends StatelessWidget {
  const _MemoryLogoCard({
    required this.width,
    required this.height,
    required this.accent,
    required this.icon,
  });

  final double width;
  final double height;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: accent, width: 2.5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, color: accent, size: height * 0.42),
      ),
    );
  }
}

class SmartBoardRaceScreen extends StatefulWidget {
  const SmartBoardRaceScreen({
    required this.localRepository,
    required this.onBackToSolo,
    this.relayTeamStore,
    this.classLeaderboardStore,
    super.key,
  });

  final LocalLeaderboardRepository localRepository;
  final VoidCallback onBackToSolo;
  final RelayTeamStore? relayTeamStore;
  final ClassLeaderboardStore? classLeaderboardStore;

  @override
  State<SmartBoardRaceScreen> createState() => _SmartBoardRaceScreenState();
}

class _SmartBoardRaceScreenState extends State<SmartBoardRaceScreen> {
  late RaceController _race;
  late RelayRaceController _relay;
  late final ClassLeaderboardController _classLeaderboard;
  late final RelayTeamStore _relayTeamStore;
  late final GameAudioController _audio;
  CardContentSet _smartBoardContentSet = CardContentSets.letters;
  int? _savedRaceNumber;
  int _lastLeftAudioTurnVersion = 0;
  int _lastRightAudioTurnVersion = 0;

  @override
  void initState() {
    super.initState();
    _classLeaderboard = ClassLeaderboardController(
      repository: widget.localRepository,
      listStore: widget.classLeaderboardStore,
    );
    unawaited(_classLeaderboard.load());
    _relayTeamStore = widget.relayTeamStore ?? MemoryRelayTeamStore();
    _audio = GameAudioController(backgroundVolume: 0.14, successVolume: 0.55);
    _race = _createRace();
    _relay = _createRelay(
      leftTeam: RelayTeamState(
        teamName: 'Takım A',
        players: ['Ali', 'Zeynep', 'Ece', 'Mert'],
      ),
      rightTeam: RelayTeamState(
        teamName: 'Takım B',
        players: ['Deniz', 'Ayşe', 'Can', 'Elif'],
      ),
    );
    _race.addListener(_saveWinnerIfNeeded);
    _race.addListener(_handleRaceAudio);
    _syncRaceAudioVersions();
    unawaited(_loadStoredTeams());
  }

  RaceController _createRace() {
    final config = MemoryGameConfig(
      pairCount: 8,
      columns: 4,
      contentSet: _smartBoardContentSet,
    );
    return RaceController(
      left: MemoryGameController(
        playerName: 'Takım A',
        sideLabel: 'Sol Alan',
        config: config,
      ),
      right: MemoryGameController(
        playerName: 'Takım B',
        sideLabel: 'Sağ Alan',
        config: config,
      ),
    );
  }

  RelayRaceController _createRelay({
    required RelayTeamState leftTeam,
    required RelayTeamState rightTeam,
  }) {
    return RelayRaceController(
      leftGame: _race.left,
      rightGame: _race.right,
      leftTeam: leftTeam,
      rightTeam: rightTeam,
    );
  }

  @override
  void dispose() {
    _race.removeListener(_saveWinnerIfNeeded);
    _race.removeListener(_handleRaceAudio);
    _audio.setPlaying(false);
    unawaited(_audio.dispose());
    _relay.dispose();
    _race.dispose();
    _classLeaderboard.dispose();
    super.dispose();
  }

  void _saveWinnerIfNeeded() {
    final winner = _race.winner;
    if (winner == null) {
      _savedRaceNumber = null;
      return;
    }
    if (_savedRaceNumber == _race.raceNumber) {
      return;
    }
    _savedRaceNumber = _race.raceNumber;
    _classLeaderboard.saveSmartBoardResult(_race.controllerFor(winner));
  }

  void _handleRaceAudio() {
    _audio.setPlaying(_race.isRunning);
    _playRaceSuccessIfNeeded(_race.left, isLeft: true);
    _playRaceSuccessIfNeeded(_race.right, isLeft: false);
  }

  void _playRaceSuccessIfNeeded(
    MemoryGameController controller, {
    required bool isLeft,
  }) {
    final lastVersion = isLeft
        ? _lastLeftAudioTurnVersion
        : _lastRightAudioTurnVersion;
    if (controller.turnVersion == lastVersion) {
      return;
    }
    if (isLeft) {
      _lastLeftAudioTurnVersion = controller.turnVersion;
    } else {
      _lastRightAudioTurnVersion = controller.turnVersion;
    }
    if (controller.lastTurnResult == MemoryTurnResult.match) {
      _audio.playSuccess();
    }
  }

  void _syncRaceAudioVersions() {
    _lastLeftAudioTurnVersion = _race.left.turnVersion;
    _lastRightAudioTurnVersion = _race.right.turnVersion;
  }

  void _resetRace() {
    _savedRaceNumber = null;
    _race.resetRace();
    _relay.resetTeams();
  }

  void _backToSolo() {
    _race.pauseBoth();
    _audio.setPlaying(false);
    widget.onBackToSolo();
  }

  void _changeSmartBoardContentSet(CardContentSet contentSet) {
    if (_smartBoardContentSet.id == contentSet.id) {
      return;
    }

    final leftTeam = _relay.leftTeam.copyWith(
      activePlayerIndex: 0,
      consecutiveMistakes: 0,
    );
    final rightTeam = _relay.rightTeam.copyWith(
      activePlayerIndex: 0,
      consecutiveMistakes: 0,
    );
    final oldRace = _race;
    final oldRelay = _relay;
    oldRace.removeListener(_saveWinnerIfNeeded);
    oldRace.removeListener(_handleRaceAudio);
    _audio.setPlaying(false);

    setState(() {
      _savedRaceNumber = null;
      _smartBoardContentSet = contentSet;
      _race = _createRace();
      _relay = _createRelay(leftTeam: leftTeam, rightTeam: rightTeam);
      _race.addListener(_saveWinnerIfNeeded);
      _race.addListener(_handleRaceAudio);
      _syncRaceAudioVersions();
    });

    oldRelay.dispose();
    oldRace.dispose();
  }

  Future<void> _loadStoredTeams() async {
    final storedSetup = await _relayTeamStore.readSetup();
    if (storedSetup == null || !mounted) {
      return;
    }
    _relay.configureTeams(
      leftTeam: storedSetup.leftTeam,
      rightTeam: storedSetup.rightTeam,
    );
  }

  Future<void> _editTeams() async {
    final updatedTeams = await showDialog<RelayTeamSetup>(
      context: context,
      builder: (context) {
        return TeamSetupDialog(
          leftTeam: _relay.leftTeam,
          rightTeam: _relay.rightTeam,
        );
      },
    );
    if (updatedTeams == null) {
      return;
    }
    _savedRaceNumber = null;
    _race.resetRace();
    await _relayTeamStore.writeSetup(updatedTeams);
    _relay.configureTeams(
      leftTeam: updatedTeams.leftTeam,
      rightTeam: updatedTeams.rightTeam,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_race, _relay]),
      builder: (context, _) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xffe0f2fe), Color(0xfffff7ed)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              SmartBoardHeader(
                race: _race,
                selectedContentSet: _smartBoardContentSet,
                onResetRace: _resetRace,
                onEditTeams: _editTeams,
                onContentSetChanged: _changeSmartBoardContentSet,
                onBack: _backToSolo,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide =
                          constraints.maxWidth >= 760 ||
                          constraints.maxHeight < 620;
                      if (isWide) {
                        return Row(
                          children: [
                            Expanded(
                              child: GameSidePanel(
                                controller: _race.left,
                                accent: const Color(0xff0f766e),
                                softAccent: const Color(0xffccfbf1),
                                winner: _race.winner == RaceSide.left,
                                relayTeam: _relay.leftTeam,
                                relayAccent: const Color(0xff0f766e),
                              ),
                            ),
                            const TouchBuffer(axis: Axis.vertical),
                            Expanded(
                              child: GameSidePanel(
                                controller: _race.right,
                                accent: const Color(0xffd97706),
                                softAccent: const Color(0xffffedd5),
                                winner: _race.winner == RaceSide.right,
                                relayTeam: _relay.rightTeam,
                                relayAccent: const Color(0xffd97706),
                              ),
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          Expanded(
                            child: GameSidePanel(
                              controller: _race.left,
                              accent: const Color(0xff0f766e),
                              softAccent: const Color(0xffccfbf1),
                              winner: _race.winner == RaceSide.left,
                              relayTeam: _relay.leftTeam,
                              relayAccent: const Color(0xff0f766e),
                            ),
                          ),
                          const TouchBuffer(axis: Axis.horizontal),
                          Expanded(
                            child: GameSidePanel(
                              controller: _race.right,
                              accent: const Color(0xffd97706),
                              softAccent: const Color(0xffffedd5),
                              winner: _race.winner == RaceSide.right,
                              relayTeam: _relay.rightTeam,
                              relayAccent: const Color(0xffd97706),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TeamSetupDialog extends StatefulWidget {
  const TeamSetupDialog({
    required this.leftTeam,
    required this.rightTeam,
    super.key,
  });

  final RelayTeamState leftTeam;
  final RelayTeamState rightTeam;

  @override
  State<TeamSetupDialog> createState() => _TeamSetupDialogState();
}

class _TeamSetupDialogState extends State<TeamSetupDialog> {
  late final TextEditingController _leftController;
  late final TextEditingController _rightController;

  @override
  void initState() {
    super.initState();
    _leftController = TextEditingController(
      text: widget.leftTeam.players.join('\n'),
    );
    _rightController = TextEditingController(
      text: widget.rightTeam.players.join('\n'),
    );
  }

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Takımları Düzenle'),
      content: SizedBox(
        width: 620,
        child: Row(
          children: [
            Expanded(
              child: TeamPlayersField(
                title: widget.leftTeam.teamName,
                controller: _leftController,
                accent: const Color(0xff0f766e),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: TeamPlayersField(
                title: widget.rightTeam.teamName,
                controller: _rightController,
                accent: const Color(0xffb45309),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check),
          label: const Text('Kaydet'),
        ),
      ],
    );
  }

  void _save() {
    final leftPlayers = _parsePlayers(_leftController.text);
    final rightPlayers = _parsePlayers(_rightController.text);
    Navigator.of(context).pop(
      RelayTeamSetup(
        leftTeam: RelayTeamState(
          teamName: widget.leftTeam.teamName,
          players: leftPlayers.isEmpty ? widget.leftTeam.players : leftPlayers,
        ),
        rightTeam: RelayTeamState(
          teamName: widget.rightTeam.teamName,
          players: rightPlayers.isEmpty
              ? widget.rightTeam.players
              : rightPlayers,
        ),
      ),
    );
  }

  List<String> _parsePlayers(String rawValue) {
    return rawValue
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .take(12)
        .toList();
  }
}

class TeamPlayersField extends StatelessWidget {
  const TeamPlayersField({
    required this.title,
    required this.controller,
    required this.accent,
    super.key,
  });

  final String title;
  final TextEditingController controller;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.groups, color: accent),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          minLines: 6,
          maxLines: 8,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Her satıra bir öğrenci',
          ),
        ),
      ],
    );
  }
}

class SoloGameScreen extends StatefulWidget {
  const SoloGameScreen({
    required this.localRepository,
    required this.onOpenSmartBoard,
    super.key,
  });

  final LocalLeaderboardRepository localRepository;
  final VoidCallback onOpenSmartBoard;

  @override
  State<SoloGameScreen> createState() => _SoloGameScreenState();
}

class _SoloGameScreenState extends State<SoloGameScreen> {
  late MemoryGameController _game;
  late final SoloLeaderboardController _leaderboard;
  late final GameAudioController _audio;
  CardContentSet _soloContentSet = CardContentSets.letters;
  BoardPreset _boardPreset = boardPresets.first;
  SoloView _view = SoloView.menu;
  bool _savedCurrentRun = false;
  int _lastSoloAudioTurnVersion = 0;

  @override
  void initState() {
    super.initState();
    _leaderboard = SoloLeaderboardController(repository: widget.localRepository)
      ..load();
    _audio = GameAudioController();
    _game = _createSoloGame('Oyuncu');
    _game.addListener(_saveFinishedRun);
    _game.addListener(_handleSoloAudio);
  }

  @override
  void dispose() {
    _game.removeListener(_saveFinishedRun);
    _game.removeListener(_handleSoloAudio);
    _audio.setPlaying(false);
    unawaited(_audio.dispose());
    _game.dispose();
    _leaderboard.dispose();
    super.dispose();
  }

  void _saveFinishedRun() {
    if (_game.status != MemoryGameStatus.finished || _savedCurrentRun) {
      return;
    }
    _savedCurrentRun = true;
    unawaited(_saveFinishedRunResults());
  }

  void _handleSoloAudio() {
    final running =
        _view == SoloView.game && _game.status == MemoryGameStatus.running;
    _audio.setPlaying(running);

    if (_game.turnVersion == _lastSoloAudioTurnVersion) {
      return;
    }
    _lastSoloAudioTurnVersion = _game.turnVersion;
    if (_game.lastTurnResult == MemoryTurnResult.match) {
      _audio.playSuccess();
    }
  }

  Future<void> _saveFinishedRunResults() async {
    await _leaderboard.saveSoloResult(_game);
  }

  MemoryGameController _createSoloGame(String playerName) {
    final pairCount = math.min(
      _boardPreset.pairCount,
      _soloContentSet.items.length,
    );
    return MemoryGameController(
      playerName: playerName,
      sideLabel: 'Mobil',
      config: MemoryGameConfig(
        pairCount: pairCount,
        columns: _boardPreset.columns,
        contentSet: _soloContentSet,
        slotCount: _boardPreset.slotCount,
      ),
    );
  }

  void _joinSolo(String rawName) {
    final playerName = rawName.trim().isEmpty ? 'Oyuncu' : rawName.trim();
    _replaceSoloGame(playerName);
    setState(() {
      _view = SoloView.game;
    });
  }

  void _goHome() {
    _resetSolo();
    setState(() {
      _view = SoloView.menu;
    });
  }

  void _changeSoloContentSet(CardContentSet contentSet) {
    if (_soloContentSet.id == contentSet.id) {
      return;
    }
    final playerName = _game.playerName;
    _soloContentSet = contentSet;
    _replaceSoloGame(playerName);
    setState(() {});
  }

  void _changeBoardPreset(BoardPreset preset) {
    if (_boardPreset.label == preset.label) {
      return;
    }
    final playerName = _game.playerName;
    _boardPreset = preset;
    _replaceSoloGame(playerName);
    setState(() {});
  }

  void _openScores() {
    setState(() => _view = SoloView.scores);
  }

  void _openCards() {
    setState(() => _view = SoloView.cards);
  }

  void _openMenu() {
    setState(() => _view = SoloView.menu);
  }

  void _replaceSoloGame(String playerName) {
    _game.removeListener(_saveFinishedRun);
    _game.removeListener(_handleSoloAudio);
    _audio.setPlaying(false);
    _game.dispose();
    _game = _createSoloGame(playerName);
    _game.addListener(_saveFinishedRun);
    _game.addListener(_handleSoloAudio);
    _lastSoloAudioTurnVersion = _game.turnVersion;
    _savedCurrentRun = false;
    _leaderboard.clearLastSaved();
  }

  void _resetSolo() {
    _savedCurrentRun = false;
    _leaderboard.clearLastSaved();
    _game.reset();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_game, _leaderboard]),
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xffe9f7f4),
                    Color(0xfffff8e7),
                    Color(0xffeef2ff),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(18),
              child: switch (_view) {
                SoloView.menu => SoloNameEntry(
                  selectedPreset: _boardPreset,
                  selectedContentSet: _soloContentSet,
                  onPresetChanged: _changeBoardPreset,
                  onJoin: _joinSolo,
                  onOpenCards: _openCards,
                  onOpenScores: _openScores,
                  onOpenSmartBoard: widget.onOpenSmartBoard,
                ),
                SoloView.game => SoloPlayScreen(
                  controller: _game,
                  onStart: _game.start,
                  onPause: _game.pause,
                  onResume: _game.resume,
                  onReset: _resetSolo,
                  onHome: _goHome,
                ),
                SoloView.scores => SoloScoresScreen(
                  localController: _leaderboard,
                  onBack: _openMenu,
                ),
                SoloView.cards => SoloCardsScreen(
                  selectedContentSet: _soloContentSet,
                  onChanged: _changeSoloContentSet,
                  onBack: _openMenu,
                ),
              },
            );
          },
        );
      },
    );
  }
}

class SoloNameEntry extends StatefulWidget {
  const SoloNameEntry({
    required this.selectedPreset,
    required this.selectedContentSet,
    required this.onPresetChanged,
    required this.onJoin,
    required this.onOpenCards,
    required this.onOpenScores,
    required this.onOpenSmartBoard,
    super.key,
  });

  final BoardPreset selectedPreset;
  final CardContentSet selectedContentSet;
  final ValueChanged<BoardPreset> onPresetChanged;
  final ValueChanged<String> onJoin;
  final VoidCallback onOpenCards;
  final VoidCallback onOpenScores;
  final VoidCallback onOpenSmartBoard;

  @override
  State<SoloNameEntry> createState() => _SoloNameEntryState();
}

class _SoloNameEntryState extends State<SoloNameEntry> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xfff0c453), width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1f000000),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 390;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton.filledTonal(
                      tooltip: 'Akıllı Tahta',
                      onPressed: widget.onOpenSmartBoard,
                      icon: const Icon(Icons.dashboard_customize),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(child: MemoryGameMark(size: 108)),
                  const SizedBox(height: 12),
                  const Text(
                    'İKİZİNİ\nBUL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xff1f2937),
                      fontSize: 34,
                      height: 0.92,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _nameController,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Oyuncu adı',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    onSubmitted: _submit,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 58,
                    child: FilledButton.icon(
                      onPressed: () => _submit(_nameController.text),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text(
                        'Başla',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  BoardPresetSelector(
                    selectedPreset: widget.selectedPreset,
                    onChanged: widget.onPresetChanged,
                  ),
                  const SizedBox(height: 18),
                  if (compact)
                    Column(
                      children: [
                        MenuFooterButton(
                          icon: Icons.style,
                          label: 'Kart Listesi',
                          onPressed: widget.onOpenCards,
                        ),
                        const SizedBox(height: 10),
                        MenuFooterButton(
                          icon: Icons.leaderboard,
                          label: 'Puan Tablosu',
                          onPressed: widget.onOpenScores,
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: MenuFooterButton(
                            icon: Icons.style,
                            label: 'Kart Listesi',
                            onPressed: widget.onOpenCards,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MenuFooterButton(
                            icon: Icons.leaderboard,
                            label: 'Puan Tablosu',
                            onPressed: widget.onOpenScores,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      widget.selectedContentSet.name,
                      style: const TextStyle(
                        color: Color(0xff64748b),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _submit(String value) {
    final name = value.trim();
    if (name.isEmpty) {
      return;
    }
    widget.onJoin(name);
  }
}

class BoardPresetSelector extends StatelessWidget {
  const BoardPresetSelector({
    required this.selectedPreset,
    required this.onChanged,
    super.key,
  });

  final BoardPreset selectedPreset;
  final ValueChanged<BoardPreset> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final preset in boardPresets) ...[
          Expanded(
            child: ChoiceChip(
              selected: selectedPreset.label == preset.label,
              label: SizedBox(
                height: 40,
                child: Center(
                  child: Text(
                    preset.label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              onSelected: (_) => onChanged(preset),
            ),
          ),
          if (preset != boardPresets.last) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class MenuFooterButton extends StatelessWidget {
  const MenuFooterButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class SoloPlayScreen extends StatelessWidget {
  const SoloPlayScreen({
    required this.controller,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onReset,
    required this.onHome,
    super.key,
  });

  final MemoryGameController controller;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReset;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final actionLabel = switch (controller.status) {
      MemoryGameStatus.ready => 'Başla',
      MemoryGameStatus.running => 'Duraklat',
      MemoryGameStatus.paused => 'Devam',
      MemoryGameStatus.finished => 'Tekrar',
    };
    final actionIcon = switch (controller.status) {
      MemoryGameStatus.running => Icons.pause,
      MemoryGameStatus.finished => Icons.refresh,
      _ => Icons.play_arrow,
    };

    return Column(
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              tooltip: 'Ana Menü',
              onPressed: onHome,
              icon: const Icon(Icons.home),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                controller.playerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xff1f2937),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton.outlined(
              tooltip: 'Sıfırla',
              onPressed: onReset,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(child: SoloBoard(controller: controller)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: MiniMetric(
                icon: Icons.timer,
                label: 'Süre',
                value: formatGameDuration(controller.elapsed),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MiniMetric(
                icon: Icons.emoji_events,
                label: 'Puan',
                value: '${controller.matchedPairs * 100}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: 96,
          height: 96,
          child: FilledButton(
            onPressed: () {
              switch (controller.status) {
                case MemoryGameStatus.ready:
                  onStart();
                case MemoryGameStatus.running:
                  onPause();
                case MemoryGameStatus.paused:
                  onResume();
                case MemoryGameStatus.finished:
                  onReset();
                  onStart();
              }
            },
            style: FilledButton.styleFrom(shape: const CircleBorder()),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(actionIcon),
                const SizedBox(height: 4),
                FittedBox(
                  child: Text(
                    actionLabel,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class MiniMetric extends StatelessWidget {
  const MiniMetric({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffd5e1dd)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff0f766e)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff64748b),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff1f2937),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SoloScoresScreen extends StatelessWidget {
  const SoloScoresScreen({
    required this.localController,
    required this.onBack,
    super.key,
  });

  final SoloLeaderboardController localController;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final entries = localController.entries;
    return SimplePageShell(
      title: 'Puan Tablosu',
      icon: Icons.leaderboard,
      onBack: onBack,
      child: entries.isEmpty
          ? const Center(
              child: Text(
                'Henüz puan yok',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            )
          : ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return ScoreListTile(rank: index + 1, entry: entry);
              },
            ),
    );
  }
}

class ScoreListTile extends StatelessWidget {
  const ScoreListTile({required this.rank, required this.entry, super.key});

  final int rank;
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffd5e1dd)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '$rank',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              entry.playerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            '${entry.score}',
            style: const TextStyle(
              color: Color(0xff0f766e),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class SoloCardsScreen extends StatelessWidget {
  const SoloCardsScreen({
    required this.selectedContentSet,
    required this.onChanged,
    required this.onBack,
    super.key,
  });

  final CardContentSet selectedContentSet;
  final ValueChanged<CardContentSet> onChanged;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SimplePageShell(
      title: 'Kart Listesi',
      icon: Icons.style,
      onBack: onBack,
      child: ListView.separated(
        itemCount: CardContentSets.all.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final contentSet = CardContentSets.all[index];
          return CardSetChoice(
            contentSet: contentSet,
            selected: contentSet.id == selectedContentSet.id,
            onTap: () => onChanged(contentSet),
          );
        },
      ),
    );
  }
}

class CardSetChoice extends StatelessWidget {
  const CardSetChoice({
    required this.contentSet,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final CardContentSet contentSet;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final previews = contentSet.items.take(4).toList();
    return Material(
      color: selected ? const Color(0xffd9f4ef) : Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected ? const Color(0xff0f766e) : const Color(0xffd5e1dd),
          width: selected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: const Color(0xff0f766e),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  contentSet.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Wrap(
                spacing: 6,
                children: [
                  for (final item in previews)
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xffd5e1dd)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.visual == CardVisualKind.text ? item.label : '●',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SimplePageShell extends StatelessWidget {
  const SimplePageShell({
    required this.title,
    required this.icon,
    required this.onBack,
    required this.child,
    super.key,
  });

  final String title;
  final IconData icon;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfffffbeb),
        border: Border.all(color: const Color(0xfff0c453), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'Geri',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: const Color(0xff0f766e)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class SoloTopBar extends StatelessWidget {
  const SoloTopBar({
    required this.controller,
    required this.selectedContentSet,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onReset,
    required this.onChangePlayer,
    required this.onContentSetChanged,
    super.key,
  });

  final MemoryGameController controller;
  final CardContentSet selectedContentSet;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReset;
  final VoidCallback onChangePlayer;
  final ValueChanged<CardContentSet> onContentSetChanged;

  @override
  Widget build(BuildContext context) {
    final canResume = controller.status == MemoryGameStatus.paused;
    final canPause = controller.status == MemoryGameStatus.running;
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffd5e1dd)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 690;
          final identity = Row(
            children: [
              const MemoryGameMark(size: 58),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      controller.playerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff0f766e),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'Kartları eşleştir',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xff536763),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final controls = [
            if (compact)
              ContentSetMenuButton(
                selectedContentSet: selectedContentSet,
                onChanged: onContentSetChanged,
              )
            else
              SizedBox(
                width: 144,
                child: ContentSetDropdown(
                  selectedContentSet: selectedContentSet,
                  onChanged: onContentSetChanged,
                ),
              ),
            SizedBox(
              width: 116,
              child: StatPill(
                icon: Icons.timer,
                label: formatGameDuration(controller.elapsed),
              ),
            ),
            SizedBox(
              width: 92,
              child: StatPill(
                icon: Icons.grid_view,
                label: '${controller.matchedPairs}/${controller.pairCount}',
              ),
            ),
            Tooltip(
              message: canResume ? 'Devam' : 'Başlat',
              child: IconButton.filled(
                onPressed: canResume ? onResume : onStart,
                icon: Icon(canResume ? Icons.play_arrow : Icons.flag),
              ),
            ),
            Tooltip(
              message: 'Duraklat',
              child: IconButton.outlined(
                onPressed: canPause ? onPause : null,
                icon: const Icon(Icons.pause),
              ),
            ),
            Tooltip(
              message: 'Sıfırla',
              child: IconButton.outlined(
                onPressed: onReset,
                icon: const Icon(Icons.refresh),
              ),
            ),
            Tooltip(
              message: 'Oyuncu Değiştir',
              child: IconButton.outlined(
                onPressed: onChangePlayer,
                icon: const Icon(Icons.person_outline),
              ),
            ),
          ];

          if (compact) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                identity,
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: controls,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: controls,
              ),
            ],
          );
        },
      ),
    );
  }
}

class SoloBoard extends StatelessWidget {
  const SoloBoard({required this.controller, super.key});

  final MemoryGameController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xffd9f4ef),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: MemoryCardGrid(
          controller: controller,
          accent: const Color(0xff0f766e),
        ),
      ),
    );
  }
}

class SoloLeaderboardPanel extends StatelessWidget {
  const SoloLeaderboardPanel({required this.localController, super.key});

  final SoloLeaderboardController localController;

  @override
  Widget build(BuildContext context) {
    final localEntries = localController.entries.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffd5e1dd)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.leaderboard, color: Color(0xff415753)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Skorlarım',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CompactLeaderboardColumn(
              title: 'En İyi Skorlar',
              emptyLabel: 'Henüz skor yok',
              entries: localEntries,
            ),
          ),
        ],
      ),
    );
  }
}

class CompactLeaderboardColumn extends StatelessWidget {
  const CompactLeaderboardColumn({
    required this.title,
    required this.emptyLabel,
    required this.entries,
    super.key,
  });

  final String title;
  final String emptyLabel;
  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xfff8fbfa),
        border: Border.all(color: const Color(0xffd5e1dd)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xff415753),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        emptyLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xff60736f),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        return CompactScoreRow(
                          rank: index + 1,
                          entry: entries[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompactScoreRow extends StatelessWidget {
  const CompactScoreRow({required this.rank, required this.entry, super.key});

  final int rank;
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$rank.', style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            entry.playerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${entry.score}',
          style: const TextStyle(
            color: Color(0xff0f766e),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class TournamentScoreStrip extends StatelessWidget {
  const TournamentScoreStrip({required this.controller, super.key});

  final ClassLeaderboardController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final topEntries = controller.entries.take(3).toList();
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final listActions = ClassListActions(controller: controller);
            final scorePreview = topEntries.isEmpty
                ? Text(
                    'Henüz skor yok',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: const Color(0xff60736f),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Row(
                    children: [
                      for (var i = 0; i < topEntries.length; i++) ...[
                        Expanded(
                          child: LeaderboardMiniEntry(
                            rank: i + 1,
                            entry: topEntries[i],
                          ),
                        ),
                        if (i != topEntries.length - 1)
                          const SizedBox(width: 10),
                      ],
                    ],
                  );

            return Container(
              height: compact ? 128 : 72,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xfffdfefe),
                border: Border(
                  bottom: BorderSide(color: Color(0xffd9e2df), width: 1.5),
                ),
              ),
              child: compact
                  ? Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.leaderboard,
                              color: Color(0xff415753),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ClassListDropdown(controller: controller),
                            ),
                            const SizedBox(width: 4),
                            listActions,
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: scorePreview),
                              const SizedBox(width: 12),
                              LastSavedScore(
                                entry: controller.lastSavedEntry,
                                compact: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(Icons.leaderboard, color: Color(0xff415753)),
                        const SizedBox(width: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: ClassListDropdown(controller: controller),
                        ),
                        const SizedBox(width: 4),
                        listActions,
                        const SizedBox(width: 18),
                        Expanded(child: scorePreview),
                        const SizedBox(width: 18),
                        LastSavedScore(entry: controller.lastSavedEntry),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}

class ClassListDropdown extends StatelessWidget {
  const ClassListDropdown({required this.controller, super.key});

  final ClassLeaderboardController controller;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: controller.selectedListId,
        isExpanded: true,
        items: [
          for (final list in controller.lists)
            DropdownMenuItem(
              value: list.id,
              child: Text(
                list.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (value) {
          if (value != null) {
            controller.selectList(value);
          }
        },
      ),
    );
  }
}

class ClassListActions extends StatelessWidget {
  const ClassListActions({required this.controller, super.key});

  final ClassLeaderboardController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Liste Ekle',
          icon: const Icon(Icons.playlist_add),
          onPressed: () => _showCreateListDialog(context),
        ),
        IconButton(
          tooltip: 'Liste Sil',
          icon: const Icon(Icons.delete_outline),
          onPressed: controller.canDeleteSelectedList
              ? () => _showDeleteListDialog(context)
              : null,
        ),
      ],
    );
  }

  Future<void> _showCreateListDialog(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const CreateClassListDialog(),
    );

    if (name != null) {
      await controller.createList(name);
    }
  }

  Future<void> _showDeleteListDialog(BuildContext context) async {
    final list = controller.selectedList;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Liste Sil'),
          content: Text('${list.name} silinsin mi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      await controller.deleteList(list.id);
    }
  }
}

class CreateClassListDialog extends StatefulWidget {
  const CreateClassListDialog({super.key});

  @override
  State<CreateClassListDialog> createState() => _CreateClassListDialogState();
}

class _CreateClassListDialogState extends State<CreateClassListDialog> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Liste Oluştur'),
      content: TextField(
        controller: _textController,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(labelText: 'Liste adı'),
        onSubmitted: _submit,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => _submit(_textController.text),
          child: const Text('Oluştur'),
        ),
      ],
    );
  }

  void _submit(String value) {
    final name = value.trim();
    if (name.isNotEmpty) {
      Navigator.of(context).pop(name);
    }
  }
}

class LeaderboardMiniEntry extends StatelessWidget {
  const LeaderboardMiniEntry({
    required this.rank,
    required this.entry,
    super.key,
  });

  final int rank;
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xfff3f7f6),
        border: Border.all(color: const Color(0xffd5e1dd)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '$rank.',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.playerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.score}',
            style: const TextStyle(
              color: Color(0xff0f766e),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class LastSavedScore extends StatelessWidget {
  const LastSavedScore({required this.entry, this.compact = false, super.key});

  final LeaderboardEntry? entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final saved = entry;
    return Container(
      width: compact ? 148 : 180,
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: saved == null
            ? const Color(0xfff3f7f6)
            : const Color(0xffe8f8ee),
        border: Border.all(
          color: saved == null
              ? const Color(0xffd5e1dd)
              : const Color(0xff86d39c),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            saved == null ? Icons.save_outlined : Icons.check_circle,
            size: 20,
            color: saved == null
                ? const Color(0xff60736f)
                : const Color(0xff15803d),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              saved == null
                  ? 'Kayıt bekliyor'
                  : '${saved.playerName} kaydedildi',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class SmartBoardHeader extends StatelessWidget {
  const SmartBoardHeader({
    required this.race,
    required this.selectedContentSet,
    required this.onResetRace,
    required this.onEditTeams,
    required this.onContentSetChanged,
    required this.onBack,
    super.key,
  });

  final RaceController race;
  final CardContentSet selectedContentSet;
  final VoidCallback onResetRace;
  final VoidCallback onEditTeams;
  final ValueChanged<CardContentSet> onContentSetChanged;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final canResume =
        race.left.status == MemoryGameStatus.paused ||
        race.right.status == MemoryGameStatus.paused;
    final winnerLabel = switch (race.winner) {
      RaceSide.left => 'Takım A kazandı',
      RaceSide.right => 'Takım B kazandı',
      null => 'Akıllı Tahta',
    };

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xffd9e2df))),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Geri',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              winnerLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          ContentSetMenuButton(
            selectedContentSet: selectedContentSet,
            onChanged: onContentSetChanged,
          ),
          IconButton.filled(
            tooltip: canResume ? 'Devam' : 'Başlat',
            onPressed: canResume ? race.resumeBoth : race.startBoth,
            icon: Icon(canResume ? Icons.play_arrow : Icons.flag),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: 'Duraklat',
            onPressed: race.isRunning ? race.pauseBoth : null,
            icon: const Icon(Icons.pause),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: 'Takımlar',
            onPressed: onEditTeams,
            icon: const Icon(Icons.groups),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: 'Sıfırla',
            onPressed: onResetRace,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class TeacherRaceBar extends StatelessWidget {
  const TeacherRaceBar({
    required this.race,
    required this.selectedContentSet,
    required this.onResetRace,
    required this.onEditTeams,
    required this.onContentSetChanged,
    super.key,
  });

  final RaceController race;
  final CardContentSet selectedContentSet;
  final VoidCallback onResetRace;
  final VoidCallback onEditTeams;
  final ValueChanged<CardContentSet> onContentSetChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canResume =
        race.left.status == MemoryGameStatus.paused ||
        race.right.status == MemoryGameStatus.paused;
    final winnerLabel = switch (race.winner) {
      RaceSide.left => 'Kazanan: Takım A',
      RaceSide.right => 'Kazanan: Takım B',
      null => '6-A Turnuvası',
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        return Container(
          height: 88,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xffffffff),
            border: Border(
              bottom: BorderSide(color: Color(0xffd9e2df), width: 1.5),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.dashboard_customize, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'İkizini Bul',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      winnerLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xff4b635e),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (compact)
                CompactRaceActions(
                  race: race,
                  selectedContentSet: selectedContentSet,
                  canResume: canResume,
                  onResetRace: onResetRace,
                  onEditTeams: onEditTeams,
                  onContentSetChanged: onContentSetChanged,
                )
              else
                FullRaceActions(
                  race: race,
                  selectedContentSet: selectedContentSet,
                  canResume: canResume,
                  onResetRace: onResetRace,
                  onEditTeams: onEditTeams,
                  onContentSetChanged: onContentSetChanged,
                ),
            ],
          ),
        );
      },
    );
  }
}

class FullRaceActions extends StatelessWidget {
  const FullRaceActions({
    required this.race,
    required this.selectedContentSet,
    required this.canResume,
    required this.onResetRace,
    required this.onEditTeams,
    required this.onContentSetChanged,
    super.key,
  });

  final RaceController race;
  final CardContentSet selectedContentSet;
  final bool canResume;
  final VoidCallback onResetRace;
  final VoidCallback onEditTeams;
  final ValueChanged<CardContentSet> onContentSetChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 144,
          child: ContentSetDropdown(
            selectedContentSet: selectedContentSet,
            onChanged: onContentSetChanged,
          ),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: canResume ? race.resumeBoth : race.startBoth,
          icon: Icon(canResume ? Icons.play_arrow : Icons.flag),
          label: Text(canResume ? 'Devam' : 'Başlat'),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: race.isRunning ? race.pauseBoth : null,
          icon: const Icon(Icons.pause),
          label: const Text('Duraklat'),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: onEditTeams,
          icon: const Icon(Icons.groups),
          label: const Text('Takımlar'),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: onResetRace,
          icon: const Icon(Icons.refresh),
          label: const Text('Sıfırla'),
        ),
      ],
    );
  }
}

class CompactRaceActions extends StatelessWidget {
  const CompactRaceActions({
    required this.race,
    required this.selectedContentSet,
    required this.canResume,
    required this.onResetRace,
    required this.onEditTeams,
    required this.onContentSetChanged,
    super.key,
  });

  final RaceController race;
  final CardContentSet selectedContentSet;
  final bool canResume;
  final VoidCallback onResetRace;
  final VoidCallback onEditTeams;
  final ValueChanged<CardContentSet> onContentSetChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ContentSetMenuButton(
          selectedContentSet: selectedContentSet,
          onChanged: onContentSetChanged,
        ),
        Tooltip(
          message: canResume ? 'Devam' : 'Başlat',
          child: IconButton.filled(
            onPressed: canResume ? race.resumeBoth : race.startBoth,
            icon: Icon(canResume ? Icons.play_arrow : Icons.flag),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Duraklat',
          child: IconButton.outlined(
            onPressed: race.isRunning ? race.pauseBoth : null,
            icon: const Icon(Icons.pause),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Sıfırla',
          child: IconButton.outlined(
            onPressed: onResetRace,
            icon: const Icon(Icons.refresh),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Takımlar',
          child: IconButton.outlined(
            onPressed: onEditTeams,
            icon: const Icon(Icons.groups),
          ),
        ),
      ],
    );
  }
}

class ContentSetDropdown extends StatelessWidget {
  const ContentSetDropdown({
    required this.selectedContentSet,
    required this.onChanged,
    super.key,
  });

  final CardContentSet selectedContentSet;
  final ValueChanged<CardContentSet> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xfff3f7f6),
        border: Border.all(color: const Color(0xffd5e1dd)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CardContentSet>(
          value: selectedContentSet,
          isExpanded: true,
          icon: const Icon(Icons.expand_more),
          items: [
            for (final contentSet in CardContentSets.all)
              DropdownMenuItem(
                value: contentSet,
                child: Text(
                  contentSet.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}

class ContentSetMenuButton extends StatelessWidget {
  const ContentSetMenuButton({
    required this.selectedContentSet,
    required this.onChanged,
    super.key,
  });

  final CardContentSet selectedContentSet;
  final ValueChanged<CardContentSet> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CardContentSet>(
      tooltip: 'Kart Seti',
      initialValue: selectedContentSet,
      icon: const Icon(Icons.style),
      onSelected: onChanged,
      itemBuilder: (context) {
        return [
          for (final contentSet in CardContentSets.all)
            PopupMenuItem(
              value: contentSet,
              child: Row(
                children: [
                  Icon(
                    contentSet.id == selectedContentSet.id
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    size: 18,
                    color: const Color(0xff0f766e),
                  ),
                  const SizedBox(width: 10),
                  Text(contentSet.name),
                ],
              ),
            ),
        ];
      },
    );
  }
}

class TouchBuffer extends StatelessWidget {
  const TouchBuffer({required this.axis, super.key});

  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final isVertical = axis == Axis.vertical;
    return SizedBox(
      width: isVertical ? 16 : double.infinity,
      height: isVertical ? double.infinity : 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.symmetric(
            vertical: isVertical
                ? const BorderSide(color: Color(0x33000000), width: 1)
                : BorderSide.none,
            horizontal: isVertical
                ? BorderSide.none
                : const BorderSide(color: Color(0x33000000), width: 1),
          ),
        ),
      ),
    );
  }
}

class GameSidePanel extends StatelessWidget {
  const GameSidePanel({
    required this.controller,
    required this.accent,
    required this.softAccent,
    required this.winner,
    this.relayTeam,
    this.relayAccent,
    super.key,
  });

  final MemoryGameController controller;
  final Color accent;
  final Color softAccent;
  final bool winner;
  final RelayTeamState? relayTeam;
  final Color? relayAccent;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: softAccent,
            border: Border.all(
              color: winner ? accent : Colors.white,
              width: winner ? 4 : 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.playerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (winner) Icon(Icons.emoji_events, color: accent, size: 32),
                ],
              ),
              const SizedBox(height: 10),
              if (relayTeam case final team?) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sıra: ${team.activePlayer}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: relayAccent ?? accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: MemoryCardGrid(controller: controller, accent: accent),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MiniMetric(
                      icon: Icons.timer,
                      label: 'Süre',
                      value: formatGameDuration(controller.elapsed),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MiniMetric(
                      icon: Icons.emoji_events,
                      label: 'Puan',
                      value: '${controller.matchedPairs * 100}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class RelayStatusStrip extends StatelessWidget {
  const RelayStatusStrip({required this.team, required this.accent, super.key});

  final RelayTeamState team;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffd5e1dd)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.sync_alt, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sıra: ${team.activePlayer}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Yanlış: ${team.consecutiveMistakes}/2',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff536763),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class PlayerHeader extends StatelessWidget {
  const PlayerHeader({
    required this.controller,
    required this.accent,
    required this.winner,
    super.key,
  });

  final MemoryGameController controller;
  final Color accent;
  final bool winner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: winner ? accent : const Color(0xffd5e1dd),
          width: winner ? 3 : 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final identity = Row(
            children: [
              CircleAvatar(
                radius: compact ? 22 : 28,
                backgroundColor: accent,
                child: Text(
                  controller.playerName.substring(
                    controller.playerName.length - 1,
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 20 : 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      controller.playerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: accent,
                        fontSize: compact ? 20 : null,
                      ),
                    ),
                    Text(
                      controller.sideLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xff536763),
                        fontWeight: FontWeight.w600,
                        fontSize: compact ? 13 : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final stats = Row(
            children: [
              Expanded(
                child: StatPill(
                  icon: Icons.timer,
                  label: formatGameDuration(controller.elapsed),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatPill(
                  icon: Icons.grid_view,
                  label: '${controller.matchedPairs}/${controller.pairCount}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatPill(
                  icon: Icons.touch_app,
                  label: '${controller.moves}',
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [identity, const SizedBox(height: 12), stats],
            );
          }

          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 12),
              SizedBox(width: 304, child: stats),
            ],
          );
        },
      ),
    );
  }
}

class StatPill extends StatelessWidget {
  const StatPill({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 84, minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xfff3f7f6),
        border: Border.all(color: const Color(0xffd5e1dd)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: const Color(0xff415753)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class MemoryCardGrid extends StatelessWidget {
  const MemoryCardGrid({
    required this.controller,
    required this.accent,
    super.key,
  });

  final MemoryGameController controller;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = controller.columns;
        final rows = (controller.boardSlotCount / columns).ceil();
        final tight = constraints.maxWidth < 420 || constraints.maxHeight < 420;
        final spacing = tight ? 8.0 : 14.0;
        final usableWidth = constraints.maxWidth - (spacing * (columns - 1));
        final usableHeight = constraints.maxHeight - (spacing * (rows - 1));
        final cardSize = math.max(
          1.0,
          math.min(usableWidth / columns, usableHeight / rows),
        );
        final boardWidth = (cardSize * columns) + (spacing * (columns - 1));
        final boardHeight = (cardSize * rows) + (spacing * (rows - 1));

        return Center(
          child: SizedBox(
            width: boardWidth,
            height: boardHeight,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: controller.boardSlotCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
              ),
              itemBuilder: (context, index) {
                final card = controller.cards[index];
                return MemoryCardTile(
                  key: ValueKey('${controller.sideLabel}-${card.id}'),
                  card: card,
                  accent: accent,
                  enabled:
                      controller.status == MemoryGameStatus.running &&
                      !controller.isBoardLocked,
                  onTap: () => controller.revealCard(card.id),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class MemoryCardTile extends StatelessWidget {
  const MemoryCardTile({
    required this.card,
    required this.accent,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final MemoryCard card;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isMatched = card.status == MemoryCardStatus.matched;
    if (isMatched) {
      return const AnimatedOpacity(
        opacity: 0,
        duration: Duration(milliseconds: 180),
        child: SizedBox.expand(),
      );
    }
    final isFaceUp = card.isFaceUp;
    final borderColor = isFaceUp ? accent : const Color(0xffbdd0cb);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled && !isFaceUp ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isFaceUp ? Colors.white : const Color(0xff243b36),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: isFaceUp ? 3 : 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isFaceUp ? 34 : 22),
                blurRadius: isFaceUp ? 16 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: isFaceUp
                    ? FittedBox(
                        key: ValueKey('face-${card.id}-${card.status.name}'),
                        fit: BoxFit.scaleDown,
                        child: CardFace(
                          label: card.label,
                          visual: card.visual,
                          accent: accent,
                          matched: isMatched,
                        ),
                      )
                    : const FittedBox(
                        key: ValueKey('back'),
                        fit: BoxFit.scaleDown,
                        child: Icon(
                          Icons.question_mark,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CardFace extends StatelessWidget {
  const CardFace({
    required this.label,
    required this.visual,
    required this.accent,
    required this.matched,
    super.key,
  });

  final String label;
  final CardVisualKind visual;
  final Color accent;
  final bool matched;

  @override
  Widget build(BuildContext context) {
    final color = matched ? const Color(0xff15803d) : accent;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: visual == CardVisualKind.text
          ? [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 64,
                ),
              ),
            ]
          : [
              ShapeGlyph(visual: visual, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
            ],
    );
  }
}

class ShapeGlyph extends StatelessWidget {
  const ShapeGlyph({required this.visual, required this.color, super.key});

  final CardVisualKind visual;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: ShapeGlyphPainter(visual: visual, color: color),
      ),
    );
  }
}

class ShapeGlyphPainter extends CustomPainter {
  const ShapeGlyphPainter({required this.visual, required this.color});

  final CardVisualKind visual;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.38;

    switch (visual) {
      case CardVisualKind.circle:
        canvas.drawCircle(center, radius, paint);
      case CardVisualKind.triangle:
        canvas.drawPath(
          Path()
            ..moveTo(center.dx, center.dy - radius)
            ..lineTo(center.dx + radius, center.dy + radius)
            ..lineTo(center.dx - radius, center.dy + radius)
            ..close(),
          paint,
        );
      case CardVisualKind.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center,
              width: radius * 1.75,
              height: radius * 1.75,
            ),
            Radius.circular(radius * 0.18),
          ),
          paint,
        );
      case CardVisualKind.star:
        canvas.drawPath(_starPath(center, radius), paint);
      case CardVisualKind.heart:
        canvas.drawPath(_heartPath(size), paint);
      case CardVisualKind.diamond:
        canvas.drawPath(
          Path()
            ..moveTo(center.dx, center.dy - radius)
            ..lineTo(center.dx + radius, center.dy)
            ..lineTo(center.dx, center.dy + radius)
            ..lineTo(center.dx - radius, center.dy)
            ..close(),
          paint,
        );
      case CardVisualKind.plus:
        canvas.drawPath(_plusPath(center, radius), paint);
      case CardVisualKind.oval:
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: radius * 1.95,
            height: radius * 1.2,
          ),
          paint,
        );
      case CardVisualKind.text:
        break;
    }
  }

  Path _starPath(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final pointRadius = i.isEven ? radius : radius * 0.45;
      final point = Offset(
        center.dx + math.cos(angle) * pointRadius,
        center.dy + math.sin(angle) * pointRadius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  Path _heartPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, h * 0.82)
      ..cubicTo(w * 0.08, h * 0.52, w * 0.16, h * 0.18, w * 0.38, h * 0.22)
      ..cubicTo(w * 0.46, h * 0.23, w * 0.5, h * 0.3, w * 0.5, h * 0.34)
      ..cubicTo(w * 0.5, h * 0.3, w * 0.54, h * 0.23, w * 0.62, h * 0.22)
      ..cubicTo(w * 0.84, h * 0.18, w * 0.92, h * 0.52, w * 0.5, h * 0.82)
      ..close();
  }

  Path _plusPath(Offset center, double radius) {
    final arm = radius * 0.38;
    final length = radius * 1.05;
    return Path()
      ..moveTo(center.dx - arm, center.dy - length)
      ..lineTo(center.dx + arm, center.dy - length)
      ..lineTo(center.dx + arm, center.dy - arm)
      ..lineTo(center.dx + length, center.dy - arm)
      ..lineTo(center.dx + length, center.dy + arm)
      ..lineTo(center.dx + arm, center.dy + arm)
      ..lineTo(center.dx + arm, center.dy + length)
      ..lineTo(center.dx - arm, center.dy + length)
      ..lineTo(center.dx - arm, center.dy + arm)
      ..lineTo(center.dx - length, center.dy + arm)
      ..lineTo(center.dx - length, center.dy - arm)
      ..lineTo(center.dx - arm, center.dy - arm)
      ..close();
  }

  @override
  bool shouldRepaint(covariant ShapeGlyphPainter oldDelegate) {
    return oldDelegate.visual != visual || oldDelegate.color != color;
  }
}
