class MemoryGameConfig {
  const MemoryGameConfig({
    this.pairCount = 8,
    this.columns = 4,
    this.mismatchPeek = const Duration(milliseconds: 750),
  }) : assert(pairCount > 0),
       assert(columns > 1);

  final int pairCount;
  final int columns;
  final Duration mismatchPeek;

  int get cardCount => pairCount * 2;
}
