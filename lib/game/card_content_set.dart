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

  static const all = [fruits, vehicles, shapes];

  static CardContentSet byId(String id) {
    return all.firstWhere((set) => set.id == id, orElse: () => fruits);
  }
}
