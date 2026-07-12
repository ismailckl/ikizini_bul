import 'card_content_set.dart';

enum MemoryCardStatus { hidden, revealed, matched }

class MemoryCard {
  const MemoryCard({
    required this.id,
    required this.pairId,
    required this.label,
    this.visual = CardVisualKind.text,
    this.status = MemoryCardStatus.hidden,
  });

  final String id;
  final int pairId;
  final String label;
  final CardVisualKind visual;
  final MemoryCardStatus status;

  bool get isFaceUp =>
      status == MemoryCardStatus.revealed || status == MemoryCardStatus.matched;

  MemoryCard copyWith({MemoryCardStatus? status}) {
    return MemoryCard(
      id: id,
      pairId: pairId,
      label: label,
      visual: visual,
      status: status ?? this.status,
    );
  }
}
