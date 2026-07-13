import 'card_content_set.dart';

enum MemoryCardStatus { hidden, revealed, matched }

class MemoryCard {
  const MemoryCard({
    required this.id,
    required this.pairId,
    required this.label,
    this.visual = CardVisualKind.text,
    this.status = MemoryCardStatus.hidden,
    this.isBonus = false,
  });

  final String id;
  final int pairId;
  final String label;
  final CardVisualKind visual;
  final MemoryCardStatus status;
  final bool isBonus;

  bool get isFaceUp =>
      status == MemoryCardStatus.revealed || status == MemoryCardStatus.matched;

  MemoryCard copyWith({MemoryCardStatus? status}) {
    return MemoryCard(
      id: id,
      pairId: pairId,
      label: label,
      visual: visual,
      status: status ?? this.status,
      isBonus: isBonus,
    );
  }
}
