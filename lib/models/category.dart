class Category {
  final String id;
  final String name;
  final String icon;

  Category({
    required this.id,
    required this.name,
    required this.icon,
  });
}

final List<Category> categories = [
  Category(
    id: 'cake',
    name: 'Cake',
    icon: '🎂',
  ),
  Category(
    id: 'donut',
    name: 'Donut',
    icon: '🍩',
  ),
  Category(
    id: 'cookies',
    name: 'Cookies',
    icon: '🍪',
  ),
];
