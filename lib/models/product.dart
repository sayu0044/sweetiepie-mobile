class Product {
  final String id;
  final String name;
  final String image;
  final double price;
  final String categoryId;
  final String description;
  bool isFavorite;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.categoryId,
    required this.description,
    this.isFavorite = false,
  });
}

final List<Product> products = [
  // Cakes
  Product(
    id: '1',
    name: 'Chocolate Ice Cake',
    image: 'https://picsum.photos/200',
    price: 12.99,
    categoryId: 'cake',
    description: 'Delicious chocolate cake with ice cream topping',
  ),
  Product(
    id: '2',
    name: 'Creamy Birthday Cake',
    image: 'https://picsum.photos/201',
    price: 15.99,
    categoryId: 'cake',
    description: 'Special birthday cake with creamy vanilla frosting',
  ),
  Product(
    id: '3',
    name: 'Oreo Chocolate Cake',
    image: 'https://picsum.photos/202',
    price: 13.99,
    categoryId: 'cake',
    description: 'Rich chocolate cake with Oreo cookies',
  ),
  Product(
    id: '4',
    name: 'Lava Dream Cake',
    image: 'https://picsum.photos/203',
    price: 14.99,
    categoryId: 'cake',
    description: 'Warm chocolate cake with molten center',
  ),
  // Donuts
  Product(
    id: '5',
    name: 'Chocolate Glazed Donut',
    image: 'https://picsum.photos/204',
    price: 3.99,
    categoryId: 'donut',
    description: 'Classic donut with rich chocolate glaze',
  ),
  Product(
    id: '6',
    name: 'Strawberry Sprinkle Donut',
    image: 'https://picsum.photos/205',
    price: 4.49,
    categoryId: 'donut',
    description: 'Pink frosted donut with colorful sprinkles',
  ),
  Product(
    id: '7',
    name: 'Boston Cream Donut',
    image: 'https://picsum.photos/206',
    price: 4.99,
    categoryId: 'donut',
    description: 'Filled with vanilla custard and topped with chocolate',
  ),
  Product(
    id: '8',
    name: 'Maple Bacon Donut',
    image: 'https://picsum.photos/207',
    price: 5.49,
    categoryId: 'donut',
    description: 'Sweet and savory with real maple glaze and bacon bits',
  ),
  // Cookies
  Product(
    id: '9',
    name: 'Chocolate Chip Cookie',
    image: 'https://picsum.photos/208',
    price: 2.99,
    categoryId: 'cookies',
    description: 'Classic cookie with premium chocolate chips',
  ),
  Product(
    id: '10',
    name: 'Double Chocolate Cookie',
    image: 'https://picsum.photos/209',
    price: 3.49,
    categoryId: 'cookies',
    description: 'Rich chocolate cookie with chocolate chunks',
  ),
  Product(
    id: '11',
    name: 'Oatmeal Raisin Cookie',
    image: 'https://picsum.photos/210',
    price: 2.99,
    categoryId: 'cookies',
    description: 'Healthy cookie with oats and sweet raisins',
  ),
  Product(
    id: '12',
    name: 'Macadamia Nut Cookie',
    image: 'https://picsum.photos/211',
    price: 3.99,
    categoryId: 'cookies',
    description: 'White chocolate cookie with macadamia nuts',
  ),
];
