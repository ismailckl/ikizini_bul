import 'card_content_set.dart';

class MemoryGameConfig {
  const MemoryGameConfig({
    this.pairCount = 8,
    this.columns = 4,
    this.contentSet = CardContentSets.letters,
    this.mismatchPeek = const Duration(milliseconds: 750),
    this.slotCount,
  }) : assert(pairCount > 0),
       assert(columns > 1),
       assert(slotCount == null || slotCount >= pairCount * 2);

  final int pairCount;
  final int columns;
  final CardContentSet contentSet;
  final Duration mismatchPeek;
  final int? slotCount;

  int get cardCount => pairCount * 2;
  int get boardSlotCount => slotCount ?? cardCount;

  MemoryGameConfig copyWith({
    int? pairCount,
    int? columns,
    CardContentSet? contentSet,
    Duration? mismatchPeek,
    int? slotCount,
  }) {
    return MemoryGameConfig(
      pairCount: pairCount ?? this.pairCount,
      columns: columns ?? this.columns,
      contentSet: contentSet ?? this.contentSet,
      mismatchPeek: mismatchPeek ?? this.mismatchPeek,
      slotCount: slotCount ?? this.slotCount,
    );
  }
}
