enum MemoryCardStatus { hidden, revealed, matched }

class MemoryCard {
  const MemoryCard({
    required this.id,
    required this.pairId,
    required this.label,
    this.status = MemoryCardStatus.hidden,
  });

  final String id;
  final int pairId;
  final String label;
  final MemoryCardStatus status;

  bool get isFaceUp =>
      status == MemoryCardStatus.revealed || status == MemoryCardStatus.matched;

  MemoryCard copyWith({MemoryCardStatus? status}) {
    return MemoryCard(
      id: id,
      pairId: pairId,
      label: label,
      status: status ?? this.status,
    );
  }
}
