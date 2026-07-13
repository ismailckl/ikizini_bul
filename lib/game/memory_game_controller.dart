import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'memory_card.dart';
import 'memory_game_config.dart';

enum MemoryGameStatus { ready, running, paused, finished }

enum MemoryTurnResult { match, mismatch }

class MemoryGameController extends ChangeNotifier {
  MemoryGameController({
    required this.playerName,
    required this.sideLabel,
    this.config = const MemoryGameConfig(),
    this.seed,
  }) {
    reset();
  }

  final String playerName;
  final String sideLabel;
  final MemoryGameConfig config;
  final int? seed;
  final Random _random = Random();
  final Stopwatch _stopwatch = Stopwatch();

  Timer? _ticker;
  Timer? _mismatchTimer;
  List<MemoryCard> _cards = const [];
  MemoryGameStatus _status = MemoryGameStatus.ready;
  String? _firstOpenCardId;
  String? _secondOpenCardId;
  bool _boardLocked = false;
  int _moves = 0;
  int _matchedPairs = 0;
  int _turnVersion = 0;
  MemoryTurnResult? _lastTurnResult;

  List<MemoryCard> get cards => List.unmodifiable(_cards);
  MemoryGameStatus get status => _status;
  Duration get elapsed => _stopwatch.elapsed;
  int get moves => _moves;
  int get matchedPairs => _matchedPairs;
  int get pairCount => config.pairCount;
  int get columns => config.columns;
  int get boardSlotCount => config.boardSlotCount;
  int get turnVersion => _turnVersion;
  MemoryTurnResult? get lastTurnResult => _lastTurnResult;
  bool get isFinished => _status == MemoryGameStatus.finished;
  bool get isBoardLocked => _boardLocked;

  void start() {
    if (_status == MemoryGameStatus.running) {
      return;
    }
    _status = MemoryGameStatus.running;
    _stopwatch.start();
    _startTicker();
    notifyListeners();
  }

  void pause() {
    if (_status != MemoryGameStatus.running) {
      return;
    }
    _status = MemoryGameStatus.paused;
    _stopwatch.stop();
    _stopTicker();
    notifyListeners();
  }

  void resume() {
    if (_status != MemoryGameStatus.paused) {
      return;
    }
    start();
  }

  void reset() {
    _mismatchTimer?.cancel();
    _stopTicker();
    _stopwatch
      ..stop()
      ..reset();
    _cards = _buildDeck();
    _status = MemoryGameStatus.ready;
    _firstOpenCardId = null;
    _secondOpenCardId = null;
    _boardLocked = false;
    _moves = 0;
    _matchedPairs = 0;
    _turnVersion = 0;
    _lastTurnResult = null;
    notifyListeners();
  }

  void revealCard(String cardId) {
    if (_status != MemoryGameStatus.running || _boardLocked) {
      return;
    }

    final cardIndex = _cards.indexWhere((card) => card.id == cardId);
    if (cardIndex == -1) {
      return;
    }

    final selected = _cards[cardIndex];
    if (selected.status != MemoryCardStatus.hidden) {
      return;
    }

    if (selected.isBonus) {
      _clearBonusCard(selected.id);
      return;
    }

    _cards = [
      for (final card in _cards)
        if (card.id == cardId)
          card.copyWith(status: MemoryCardStatus.revealed)
        else
          card,
    ];

    if (_firstOpenCardId == null) {
      _firstOpenCardId = cardId;
      notifyListeners();
      return;
    }

    _secondOpenCardId = cardId;
    _moves++;
    _resolveOpenPair();
  }

  void _resolveOpenPair() {
    final first = _cardById(_firstOpenCardId);
    final second = _cardById(_secondOpenCardId);
    if (first == null || second == null) {
      _clearOpenCards();
      notifyListeners();
      return;
    }

    if (first.pairId == second.pairId) {
      _cards = [
        for (final card in _cards)
          if (card.id == first.id || card.id == second.id)
            card.copyWith(status: MemoryCardStatus.matched)
          else
            card,
      ];
      _matchedPairs++;
      _recordTurnResult(MemoryTurnResult.match);
      _clearOpenCards();

      if (_allCardsCleared) {
        _finish();
      } else {
        notifyListeners();
      }
      return;
    }

    _boardLocked = true;
    _recordTurnResult(MemoryTurnResult.mismatch);
    notifyListeners();
    _mismatchTimer?.cancel();
    _mismatchTimer = Timer(config.mismatchPeek, () {
      _cards = [
        for (final card in _cards)
          if (card.id == first.id || card.id == second.id)
            card.copyWith(status: MemoryCardStatus.hidden)
          else
            card,
      ];
      _clearOpenCards();
      _boardLocked = false;
      notifyListeners();
    });
  }

  void _clearBonusCard(String cardId) {
    _moves++;
    final openCardId = _firstOpenCardId;
    _cards = [
      for (final card in _cards)
        if (card.id == cardId)
          card.copyWith(status: MemoryCardStatus.matched)
        else if (card.id == openCardId)
          card.copyWith(status: MemoryCardStatus.hidden)
        else
          card,
    ];
    _recordTurnResult(MemoryTurnResult.match);
    _clearOpenCards();

    if (_allCardsCleared) {
      _finish();
    } else {
      notifyListeners();
    }
  }

  bool get _allCardsCleared =>
      _cards.every((card) => card.status == MemoryCardStatus.matched);

  MemoryCard? _cardById(String? cardId) {
    if (cardId == null) {
      return null;
    }
    for (final card in _cards) {
      if (card.id == cardId) {
        return card;
      }
    }
    return null;
  }

  void _clearOpenCards() {
    _firstOpenCardId = null;
    _secondOpenCardId = null;
  }

  void _recordTurnResult(MemoryTurnResult result) {
    _lastTurnResult = result;
    _turnVersion++;
  }

  void _finish() {
    _status = MemoryGameStatus.finished;
    _stopwatch.stop();
    _stopTicker();
    notifyListeners();
  }

  List<MemoryCard> _buildDeck() {
    final items = config.contentSet.items;
    assert(config.pairCount <= items.length);
    final deck = <MemoryCard>[];
    for (var pairIndex = 0; pairIndex < config.pairCount; pairIndex++) {
      final item = items[pairIndex];
      for (var copy = 0; copy < 2; copy++) {
        deck.add(
          MemoryCard(
            id: 'pair-$pairIndex-$copy',
            pairId: pairIndex,
            label: item.label,
            visual: item.visual,
          ),
        );
      }
    }
    final bonusCardCount = config.boardSlotCount - config.cardCount;
    for (var bonusIndex = 0; bonusIndex < bonusCardCount; bonusIndex++) {
      deck.add(
        MemoryCard(
          id: 'bonus-$bonusIndex',
          pairId: -bonusIndex - 1,
          label: '★',
          isBonus: true,
        ),
      );
    }
    final random = seed == null ? _random : Random(seed);
    deck.shuffle(random);
    return deck;
  }

  void _startTicker() {
    _ticker ??= Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_status == MemoryGameStatus.running) {
        notifyListeners();
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _mismatchTimer?.cancel();
    _stopTicker();
    super.dispose();
  }
}
