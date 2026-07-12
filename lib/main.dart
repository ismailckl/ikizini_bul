import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game/memory_card.dart';
import 'game/memory_game_config.dart';
import 'game/memory_game_controller.dart';
import 'game/race_controller.dart';
import 'leaderboards/global/global_leaderboard_controller.dart';
import 'leaderboards/global/global_top100_repository.dart';
import 'leaderboards/leaderboard_entry.dart';
import 'leaderboards/leaderboard_repository.dart';
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
      title: 'Bul Bitir',
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
  final GlobalTop100Repository _globalRepository = GlobalTop100Repository();
  PlayMode _selectedMode = PlayMode.smartBoard;

  @override
  void initState() {
    super.initState();
    _localRepository = LocalLeaderboardRepository(store: widget.localStore);
  }

  @override
  Widget build(BuildContext context) {
    final modeIndex = switch (_selectedMode) {
      PlayMode.smartBoard => 0,
      PlayMode.solo => 1,
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ModeSwitchBar(
              selectedMode: _selectedMode,
              onModeChanged: (mode) {
                setState(() => _selectedMode = mode);
              },
            ),
            Expanded(
              child: IndexedStack(
                index: modeIndex,
                children: [
                  SmartBoardRaceScreen(
                    localRepository: _localRepository,
                    relayTeamStore: widget.relayTeamStore,
                    classLeaderboardStore: widget.classLeaderboardStore,
                  ),
                  SoloGameScreen(
                    localRepository: _localRepository,
                    globalRepository: _globalRepository,
                  ),
                ],
              ),
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
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xffffffff),
        border: Border(bottom: BorderSide(color: Color(0xffd9e2df))),
      ),
      child: Row(
        children: [
          const Icon(Icons.apps, color: Color(0xff415753)),
          const SizedBox(width: 12),
          const Text(
            'Bul Bitir',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          const Spacer(),
          SegmentedButton<PlayMode>(
            segments: const [
              ButtonSegment(
                value: PlayMode.smartBoard,
                icon: Icon(Icons.dashboard),
                label: Text('Akilli Tahta'),
              ),
              ButtonSegment(
                value: PlayMode.solo,
                icon: Icon(Icons.phone_android),
                label: Text('Solo'),
              ),
            ],
            selected: {selectedMode},
            onSelectionChanged: (selection) {
              onModeChanged(selection.single);
            },
          ),
        ],
      ),
    );
  }
}

class SmartBoardRaceScreen extends StatefulWidget {
  const SmartBoardRaceScreen({
    required this.localRepository,
    this.relayTeamStore,
    this.classLeaderboardStore,
    super.key,
  });

  final LocalLeaderboardRepository localRepository;
  final RelayTeamStore? relayTeamStore;
  final ClassLeaderboardStore? classLeaderboardStore;

  @override
  State<SmartBoardRaceScreen> createState() => _SmartBoardRaceScreenState();
}

class _SmartBoardRaceScreenState extends State<SmartBoardRaceScreen> {
  late final RaceController _race;
  late final RelayRaceController _relay;
  late final ClassLeaderboardController _classLeaderboard;
  late final RelayTeamStore _relayTeamStore;
  int? _savedRaceNumber;

  @override
  void initState() {
    super.initState();
    const config = MemoryGameConfig(pairCount: 8, columns: 4);
    _classLeaderboard = ClassLeaderboardController(
      repository: widget.localRepository,
      listStore: widget.classLeaderboardStore,
    );
    unawaited(_classLeaderboard.load());
    _relayTeamStore = widget.relayTeamStore ?? MemoryRelayTeamStore();
    _race = RaceController(
      left: MemoryGameController(
        playerName: 'Takim A',
        sideLabel: 'Sol Alan',
        config: config,
        seed: 2026,
      ),
      right: MemoryGameController(
        playerName: 'Takim B',
        sideLabel: 'Sag Alan',
        config: config,
        seed: 2026,
      ),
    );
    _relay = RelayRaceController(
      leftGame: _race.left,
      rightGame: _race.right,
      leftTeam: RelayTeamState(
        teamName: 'Takim A',
        players: ['Ali', 'Zeynep', 'Ece', 'Mert'],
      ),
      rightTeam: RelayTeamState(
        teamName: 'Takim B',
        players: ['Deniz', 'Ayse', 'Can', 'Elif'],
      ),
    );
    _race.addListener(_saveWinnerIfNeeded);
    unawaited(_loadStoredTeams());
  }

  @override
  void dispose() {
    _race.removeListener(_saveWinnerIfNeeded);
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

  void _resetRace() {
    _savedRaceNumber = null;
    _race.resetRace();
    _relay.resetTeams();
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
        return Column(
          children: [
            TeacherRaceBar(
              race: _race,
              onResetRace: _resetRace,
              onEditTeams: _editTeams,
            ),
            TournamentScoreStrip(controller: _classLeaderboard),
            Expanded(
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
                            softAccent: const Color(0xffd9f4ef),
                            winner: _race.winner == RaceSide.left,
                            relayTeam: _relay.leftTeam,
                            relayAccent: const Color(0xff0f766e),
                          ),
                        ),
                        const TouchBuffer(axis: Axis.vertical),
                        Expanded(
                          child: GameSidePanel(
                            controller: _race.right,
                            accent: const Color(0xffb45309),
                            softAccent: const Color(0xffffecd1),
                            winner: _race.winner == RaceSide.right,
                            relayTeam: _relay.rightTeam,
                            relayAccent: const Color(0xffb45309),
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
                          softAccent: const Color(0xffd9f4ef),
                          winner: _race.winner == RaceSide.left,
                          relayTeam: _relay.leftTeam,
                          relayAccent: const Color(0xff0f766e),
                        ),
                      ),
                      const TouchBuffer(axis: Axis.horizontal),
                      Expanded(
                        child: GameSidePanel(
                          controller: _race.right,
                          accent: const Color(0xffb45309),
                          softAccent: const Color(0xffffecd1),
                          winner: _race.winner == RaceSide.right,
                          relayTeam: _relay.rightTeam,
                          relayAccent: const Color(0xffb45309),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
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
      title: const Text('Takimlari Duzenle'),
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
          child: const Text('Vazgec'),
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
            hintText: 'Her satira bir ogrenci',
          ),
        ),
      ],
    );
  }
}

class SoloGameScreen extends StatefulWidget {
  const SoloGameScreen({
    required this.localRepository,
    required this.globalRepository,
    super.key,
  });

  final LocalLeaderboardRepository localRepository;
  final GlobalTop100Repository globalRepository;

  @override
  State<SoloGameScreen> createState() => _SoloGameScreenState();
}

class _SoloGameScreenState extends State<SoloGameScreen> {
  late MemoryGameController _game;
  late final SoloLeaderboardController _leaderboard;
  late final GlobalLeaderboardController _globalLeaderboard;
  bool _savedCurrentRun = false;
  bool _hasSoloPlayer = false;

  @override
  void initState() {
    super.initState();
    _leaderboard = SoloLeaderboardController(repository: widget.localRepository)
      ..load();
    _globalLeaderboard = GlobalLeaderboardController(
      repository: widget.globalRepository,
    )..load();
    _game = _createSoloGame('Oyuncu');
    _game.addListener(_saveFinishedRun);
  }

  @override
  void dispose() {
    _game.removeListener(_saveFinishedRun);
    _game.dispose();
    _leaderboard.dispose();
    _globalLeaderboard.dispose();
    super.dispose();
  }

  void _saveFinishedRun() {
    if (_game.status != MemoryGameStatus.finished || _savedCurrentRun) {
      return;
    }
    _savedCurrentRun = true;
    unawaited(_saveFinishedRunResults());
  }

  Future<void> _saveFinishedRunResults() async {
    final savedScore = await _leaderboard.saveSoloResult(_game);
    await _globalLeaderboard.submit(savedScore.entry);
  }

  MemoryGameController _createSoloGame(String playerName) {
    return MemoryGameController(
      playerName: playerName,
      sideLabel: 'Mobil Solo',
      config: const MemoryGameConfig(pairCount: 6, columns: 3),
      seed: 404,
    );
  }

  void _joinSolo(String rawName) {
    final playerName = rawName.trim().isEmpty ? 'Oyuncu' : rawName.trim();
    _replaceSoloGame(playerName);
    setState(() {
      _hasSoloPlayer = true;
    });
  }

  void _changeSoloPlayer() {
    _resetSolo();
    setState(() {
      _hasSoloPlayer = false;
    });
  }

  void _replaceSoloGame(String playerName) {
    _game.removeListener(_saveFinishedRun);
    _game.dispose();
    _game = _createSoloGame(playerName);
    _game.addListener(_saveFinishedRun);
    _savedCurrentRun = false;
    _leaderboard.clearLastSaved();
    _globalLeaderboard.clearLastSubmit();
  }

  void _resetSolo() {
    _savedCurrentRun = false;
    _leaderboard.clearLastSaved();
    _globalLeaderboard.clearLastSubmit();
    _game.reset();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_game, _leaderboard, _globalLeaderboard]),
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            final board = SoloBoard(controller: _game);
            final leaderboard = SoloLeaderboardPanel(
              localController: _leaderboard,
              globalController: _globalLeaderboard,
            );

            return Container(
              color: const Color(0xffedf7f4),
              padding: const EdgeInsets.all(18),
              child: _hasSoloPlayer
                  ? Column(
                      children: [
                        SoloTopBar(
                          controller: _game,
                          onStart: _game.start,
                          onPause: _game.pause,
                          onResume: _game.resume,
                          onReset: _resetSolo,
                          onChangePlayer: _changeSoloPlayer,
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: wide
                              ? Row(
                                  children: [
                                    Expanded(flex: 3, child: board),
                                    const SizedBox(width: 16),
                                    SizedBox(width: 320, child: leaderboard),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Expanded(child: board),
                                    const SizedBox(height: 14),
                                    SizedBox(height: 168, child: leaderboard),
                                  ],
                                ),
                        ),
                      ],
                    )
                  : SoloNameEntry(
                      leaderboard: leaderboard,
                      wide: wide,
                      onJoin: _joinSolo,
                    ),
            );
          },
        );
      },
    );
  }
}

class SoloNameEntry extends StatefulWidget {
  const SoloNameEntry({
    required this.leaderboard,
    required this.wide,
    required this.onJoin,
    super.key,
  });

  final Widget leaderboard;
  final bool wide;
  final ValueChanged<String> onJoin;

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
    final entryPanel = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffd5e1dd)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: Color(0xff0f766e),
                    child: Icon(Icons.person, color: Colors.white, size: 34),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Solo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xff0f766e),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Zamana karsi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xff536763),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _nameController,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Oyuncu adi',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    onSubmitted: _submit,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _submit(_nameController.text),
                    icon: const Icon(Icons.login),
                    label: const Text('Oyuna Gir'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (widget.wide) {
      return Row(
        children: [
          Expanded(flex: 3, child: entryPanel),
          const SizedBox(width: 16),
          SizedBox(width: 320, child: widget.leaderboard),
        ],
      );
    }

    return Column(
      children: [
        Expanded(child: entryPanel),
        const SizedBox(height: 14),
        SizedBox(height: 168, child: widget.leaderboard),
      ],
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

class SoloTopBar extends StatelessWidget {
  const SoloTopBar({
    required this.controller,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onReset,
    required this.onChangePlayer,
    super.key,
  });

  final MemoryGameController controller;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReset;
  final VoidCallback onChangePlayer;

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
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xff0f766e),
                child: Icon(Icons.phone_android, color: Colors.white),
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
                      style: const TextStyle(
                        color: Color(0xff0f766e),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'Solo - Zamana karsi',
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
              message: canResume ? 'Devam' : 'Baslat',
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
              message: 'Sifirla',
              child: IconButton.outlined(
                onPressed: onReset,
                icon: const Icon(Icons.refresh),
              ),
            ),
            Tooltip(
              message: 'Oyuncu Degistir',
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
  const SoloLeaderboardPanel({
    required this.localController,
    required this.globalController,
    super.key,
  });

  final SoloLeaderboardController localController;
  final GlobalLeaderboardController globalController;

  @override
  Widget build(BuildContext context) {
    final localEntries = localController.entries.take(5).toList();
    final globalEntries = globalController.entries.take(5).toList();
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
                  'Solo Skorlar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
              GlobalSubmitChip(result: globalController.lastSubmitResult),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: CompactLeaderboardColumn(
                    title: 'Yerel',
                    emptyLabel: 'Yerel skor yok',
                    entries: localEntries,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CompactLeaderboardColumn(
                    title: 'Global Top 100',
                    emptyLabel: 'Global skor yok',
                    entries: globalEntries,
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

class GlobalSubmitChip extends StatelessWidget {
  const GlobalSubmitChip({required this.result, super.key});

  final ScoreSubmitResult? result;

  @override
  Widget build(BuildContext context) {
    final status = result?.status;
    final label = switch (status) {
      ScoreSubmitStatus.accepted =>
        result?.rank == null ? 'Global kabul' : 'Global #${result!.rank}',
      ScoreSubmitStatus.rejectedBelowThreshold => 'Top 100 disi',
      ScoreSubmitStatus.queuedOffline => 'Global kuyrukta',
      null => 'Global bekliyor',
    };
    final color = switch (status) {
      ScoreSubmitStatus.accepted => const Color(0xff15803d),
      ScoreSubmitStatus.rejectedBelowThreshold => const Color(0xffb45309),
      ScoreSubmitStatus.queuedOffline => const Color(0xff2563eb),
      null => const Color(0xff60736f),
    };

    return Container(
      constraints: const BoxConstraints(minHeight: 36, maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        border: Border.all(color: color.withAlpha(90)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.public, size: 18, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
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
                    'Henuz skor yok',
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
              child: const Text('Vazgec'),
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
      title: const Text('Liste Olustur'),
      content: TextField(
        controller: _textController,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(labelText: 'Liste adi'),
        onSubmitted: _submit,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgec'),
        ),
        FilledButton(
          onPressed: () => _submit(_textController.text),
          child: const Text('Olustur'),
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
                  ? 'Kayit bekliyor'
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

class TeacherRaceBar extends StatelessWidget {
  const TeacherRaceBar({
    required this.race,
    required this.onResetRace,
    required this.onEditTeams,
    super.key,
  });

  final RaceController race;
  final VoidCallback onResetRace;
  final VoidCallback onEditTeams;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canResume =
        race.left.status == MemoryGameStatus.paused ||
        race.right.status == MemoryGameStatus.paused;
    final winnerLabel = switch (race.winner) {
      RaceSide.left => 'Kazanan: Takim A',
      RaceSide.right => 'Kazanan: Takim B',
      null => '6-A Turnuvasi',
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
                      'Bul Bitir',
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
                  canResume: canResume,
                  onResetRace: onResetRace,
                  onEditTeams: onEditTeams,
                )
              else
                FullRaceActions(
                  race: race,
                  canResume: canResume,
                  onResetRace: onResetRace,
                  onEditTeams: onEditTeams,
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
    required this.canResume,
    required this.onResetRace,
    required this.onEditTeams,
    super.key,
  });

  final RaceController race;
  final bool canResume;
  final VoidCallback onResetRace;
  final VoidCallback onEditTeams;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          onPressed: canResume ? race.resumeBoth : race.startBoth,
          icon: Icon(canResume ? Icons.play_arrow : Icons.flag),
          label: Text(canResume ? 'Devam' : 'Baslat'),
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
          label: const Text('Takimlar'),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: onResetRace,
          icon: const Icon(Icons.refresh),
          label: const Text('Sifirla'),
        ),
      ],
    );
  }
}

class CompactRaceActions extends StatelessWidget {
  const CompactRaceActions({
    required this.race,
    required this.canResume,
    required this.onResetRace,
    required this.onEditTeams,
    super.key,
  });

  final RaceController race;
  final bool canResume;
  final VoidCallback onResetRace;
  final VoidCallback onEditTeams;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: canResume ? 'Devam' : 'Baslat',
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
          message: 'Sifirla',
          child: IconButton.outlined(
            onPressed: onResetRace,
            icon: const Icon(Icons.refresh),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Takimlar',
          child: IconButton.outlined(
            onPressed: onEditTeams,
            icon: const Icon(Icons.groups),
          ),
        ),
      ],
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
      width: isVertical ? 56 : double.infinity,
      height: isVertical ? double.infinity : 36,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xffecf2f0),
          border: Border.symmetric(
            vertical: isVertical
                ? const BorderSide(color: Color(0xffcbd9d5), width: 1.5)
                : BorderSide.none,
            horizontal: isVertical
                ? BorderSide.none
                : const BorderSide(color: Color(0xffcbd9d5), width: 1.5),
          ),
        ),
        child: Center(
          child: Icon(
            isVertical ? Icons.drag_indicator : Icons.more_horiz,
            color: const Color(0xff7b918c),
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
          color: softAccent.withAlpha(115),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            children: [
              PlayerHeader(
                controller: controller,
                accent: accent,
                winner: winner,
              ),
              const SizedBox(height: 18),
              if (relayTeam case final team?) ...[
                RelayStatusStrip(team: team, accent: relayAccent ?? accent),
                const SizedBox(height: 14),
              ],
              Expanded(
                child: MemoryCardGrid(controller: controller, accent: accent),
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
              'Sira: ${team.activePlayer}',
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
            'Yanlis: ${team.consecutiveMistakes}/2',
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
        final rows = (controller.cards.length / columns).ceil();
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
              itemCount: controller.cards.length,
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
    final isFaceUp = card.isFaceUp;
    final borderColor = isMatched
        ? const Color(0xff16a34a)
        : isFaceUp
        ? accent
        : const Color(0xffbdd0cb);

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
                          pairId: card.pairId,
                          label: card.label,
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
    required this.pairId,
    required this.label,
    required this.accent,
    required this.matched,
    super.key,
  });

  final int pairId;
  final String label;
  final Color accent;
  final bool matched;

  @override
  Widget build(BuildContext context) {
    final color = matched ? const Color(0xff15803d) : accent;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(_iconForPair(pairId), size: 44, color: color),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 28,
          ),
        ),
      ],
    );
  }

  IconData _iconForPair(int pairId) {
    const icons = [
      Icons.auto_awesome,
      Icons.bolt,
      Icons.favorite,
      Icons.lightbulb,
      Icons.rocket_launch,
      Icons.eco,
      Icons.psychology,
      Icons.palette,
      Icons.science,
      Icons.school,
      Icons.extension,
      Icons.sports_esports,
    ];
    return icons[pairId % icons.length];
  }
}
