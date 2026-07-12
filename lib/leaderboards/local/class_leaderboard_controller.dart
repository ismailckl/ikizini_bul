import 'package:flutter/foundation.dart';

import '../../game/memory_game_controller.dart';
import '../leaderboard_entry.dart';
import '../leaderboard_repository.dart';
import 'class_leaderboard.dart';
import 'class_leaderboard_store.dart';
import 'local_leaderboard_repository.dart';

class ClassLeaderboardController extends ChangeNotifier {
  ClassLeaderboardController({
    LocalLeaderboardRepository? repository,
    ClassLeaderboardStore? listStore,
    this.scorePolicy = const ScorePolicy(),
  }) : _repository = repository ?? LocalLeaderboardRepository(),
       _listStore = listStore ?? MemoryClassLeaderboardStore(),
       super();

  final LocalLeaderboardRepository _repository;
  final ClassLeaderboardStore _listStore;
  final ScorePolicy scorePolicy;

  String _selectedListId = '6-a-turnuva';
  List<ClassLeaderboard> _lists = defaultClassLeaderboards;
  List<LeaderboardEntry> _entries = const [];
  LeaderboardEntry? _lastSavedEntry;

  String get selectedListId => _selectedListId;
  List<ClassLeaderboard> get lists => List.unmodifiable(_lists);
  List<LeaderboardEntry> get entries => List.unmodifiable(_entries);
  LeaderboardEntry? get lastSavedEntry => _lastSavedEntry;
  bool get canDeleteSelectedList => _lists.length > 1;

  ClassLeaderboard get selectedList {
    return _lists.firstWhere((list) => list.id == _selectedListId);
  }

  Future<void> load() async {
    final storedLists = await _listStore.readLists();
    _lists = storedLists.isEmpty ? defaultClassLeaderboards : storedLists;
    if (storedLists.isEmpty) {
      await _persistLists();
    }
    _ensureSelectedList();
    await _refresh();
  }

  Future<void> selectList(String listId) async {
    if (!_lists.any((list) => list.id == listId)) {
      return;
    }
    if (_selectedListId == listId) {
      return;
    }
    _selectedListId = listId;
    _lastSavedEntry = null;
    await _refresh();
  }

  Future<ClassLeaderboard?> createList(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) {
      return null;
    }

    for (final list in _lists) {
      if (list.name.toLowerCase() == name.toLowerCase()) {
        await selectList(list.id);
        return list;
      }
    }

    final created = ClassLeaderboard(id: _createListId(name), name: name);
    _lists = [..._lists, created];
    await _persistLists();
    await selectList(created.id);
    return created;
  }

  Future<bool> renameList(String listId, String rawName) async {
    final name = rawName.trim();
    final index = _lists.indexWhere((list) => list.id == listId);
    if (name.isEmpty || index == -1) {
      return false;
    }

    _lists = [
      for (var i = 0; i < _lists.length; i++)
        if (i == index) ClassLeaderboard(id: listId, name: name) else _lists[i],
    ];
    await _persistLists();
    notifyListeners();
    return true;
  }

  Future<bool> deleteList(String listId) async {
    if (_lists.length <= 1 || !_lists.any((list) => list.id == listId)) {
      return false;
    }

    final wasSelected = _selectedListId == listId;
    _lists = [
      for (final list in _lists)
        if (list.id != listId) list,
    ];
    await _persistLists();

    if (wasSelected) {
      _selectedListId = _lists.first.id;
      _lastSavedEntry = null;
      await _refresh();
    } else {
      notifyListeners();
    }
    return true;
  }

  Future<ScoreSubmitResult> saveSmartBoardResult(
    MemoryGameController game,
  ) async {
    final entry = LeaderboardEntry(
      playerName: game.playerName,
      score: scorePolicy.calculate(
        completionTime: game.elapsed,
        moves: game.moves,
        pairCount: game.pairCount,
      ),
      completionTime: game.elapsed,
      moves: game.moves,
      mode: LeaderboardMode.smartBoardDuel,
      createdAt: DateTime.now(),
    );

    final result = await _repository.submit(entry, listId: _selectedListId);
    _lastSavedEntry = entry;
    await _refresh();
    return result;
  }

  Future<void> _refresh() async {
    _ensureSelectedList();
    _entries = await _repository.top(
      mode: LeaderboardMode.smartBoardDuel,
      listId: _selectedListId,
      limit: 10,
    );
    notifyListeners();
  }

  Future<void> _persistLists() async {
    await _listStore.writeLists(_lists);
  }

  void _ensureSelectedList() {
    if (_lists.isEmpty) {
      _lists = defaultClassLeaderboards;
    }
    if (!_lists.any((list) => list.id == _selectedListId)) {
      _selectedListId = _lists.first.id;
    }
  }

  String _createListId(String name) {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final prefix = slug.isEmpty ? 'liste' : slug;
    final suffix = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return '$prefix-$suffix';
  }
}
