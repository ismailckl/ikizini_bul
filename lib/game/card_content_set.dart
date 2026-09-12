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
    name: 'Sayılar',
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
    name: 'Şekiller',
    items: [
      CardContentItem(label: '🔴'),
      CardContentItem(label: '🔺'),
      CardContentItem(label: '🟦'),
      CardContentItem(label: '⭐'),
      CardContentItem(label: '❤️'),
      CardContentItem(label: '🔶'),
      CardContentItem(label: '➕'),
      CardContentItem(label: '🟣'),
      CardContentItem(label: '🌙'),
      CardContentItem(label: '☀️'),
      CardContentItem(label: '☁️'),
      CardContentItem(label: '⚡'),
    ],
  );

  static const fruits = CardContentSet(
    id: 'fruits',
    name: 'Meyveler',
    items: [
      CardContentItem(label: '🍎'),
      CardContentItem(label: '🍐'),
      CardContentItem(label: '🍌'),
      CardContentItem(label: '🍓'),
      CardContentItem(label: '🍒'),
      CardContentItem(label: '🍇'),
      CardContentItem(label: '🍊'),
      CardContentItem(label: '🍉'),
      CardContentItem(label: '🍍'),
      CardContentItem(label: '🍋'),
      CardContentItem(label: '🍑'),
      CardContentItem(label: '🥝'),
    ],
  );

  static const vehicles = CardContentSet(
    id: 'vehicles',
    name: 'Araçlar',
    items: [
      CardContentItem(label: '🚗'),
      CardContentItem(label: '🚌'),
      CardContentItem(label: '🚂'),
      CardContentItem(label: '🚢'),
      CardContentItem(label: '✈️'),
      CardContentItem(label: '🚁'),
      CardContentItem(label: '🚜'),
      CardContentItem(label: '🚒'),
      CardContentItem(label: '🚑'),
      CardContentItem(label: '🚓'),
      CardContentItem(label: '🏍️'),
      CardContentItem(label: '🚲'),
    ],
  );

  static const all = [letters, numbers, shapes, fruits, vehicles];

  static CardContentSet byId(String id) {
    return all.firstWhere((set) => set.id == id, orElse: () => letters);
  }
}
