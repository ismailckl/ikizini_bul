enum CardVisualKind {
  text,
  circle,
  triangle,
  square,
  star,
  heart,
  diamond,
  plus,
  oval,
}

class CardContentItem {
  const CardContentItem({
    required this.label,
    this.visual = CardVisualKind.text,
  });

  final String label;
  final CardVisualKind visual;
}

class CardContentSet {
  const CardContentSet({
    required this.id,
    required this.name,
    required this.items,
  });

  final String id;
  final String name;
  final List<CardContentItem> items;

  bool get usesTextOnly =>
      items.every((item) => item.visual == CardVisualKind.text);
}

abstract final class CardContentSets {
  static const letters = CardContentSet(
    id: 'letters',
    name: 'Harfler',
    items: [
      CardContentItem(label: 'A'),
      CardContentItem(label: 'B'),
      CardContentItem(label: 'C'),
      CardContentItem(label: 'D'),
      CardContentItem(label: 'E'),
      CardContentItem(label: 'F'),
      CardContentItem(label: 'G'),
      CardContentItem(label: 'H'),
      CardContentItem(label: 'I'),
      CardContentItem(label: 'J'),
      CardContentItem(label: 'K'),
      CardContentItem(label: 'L'),
    ],
  );

  static const numbers = CardContentSet(
    id: 'numbers',
    name: 'Sayilar',
    items: [
      CardContentItem(label: '1'),
      CardContentItem(label: '2'),
      CardContentItem(label: '3'),
      CardContentItem(label: '4'),
      CardContentItem(label: '5'),
      CardContentItem(label: '6'),
      CardContentItem(label: '7'),
      CardContentItem(label: '8'),
      CardContentItem(label: '9'),
      CardContentItem(label: '10'),
      CardContentItem(label: '11'),
      CardContentItem(label: '12'),
    ],
  );

  static const shapes = CardContentSet(
    id: 'shapes',
    name: 'Sekiller',
    items: [
      CardContentItem(label: 'Daire', visual: CardVisualKind.circle),
      CardContentItem(label: 'Ucgen', visual: CardVisualKind.triangle),
      CardContentItem(label: 'Kare', visual: CardVisualKind.square),
      CardContentItem(label: 'Yildiz', visual: CardVisualKind.star),
      CardContentItem(label: 'Kalp', visual: CardVisualKind.heart),
      CardContentItem(label: 'Elmas', visual: CardVisualKind.diamond),
      CardContentItem(label: 'Arti', visual: CardVisualKind.plus),
      CardContentItem(label: 'Oval', visual: CardVisualKind.oval),
    ],
  );

  static const all = [letters, numbers, shapes];

  static CardContentSet byId(String id) {
    return all.firstWhere((set) => set.id == id, orElse: () => letters);
  }
}
