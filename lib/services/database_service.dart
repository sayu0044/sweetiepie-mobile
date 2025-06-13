import 'package:pocketbase/pocketbase.dart';
import 'package:get/get.dart';
import 'package:sweetipie/models/category.dart';
import 'package:sweetipie/models/product.dart';

class DatabaseService extends GetxController {
  final PocketBase pb = PocketBase('http://127.0.0.1:8090');

  final RxList<Category> categories = <Category>[].obs;
  final RxList<Product> products = <Product>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    print('DatabaseService initialized');
    // Load static data first to ensure app works
    _loadStaticCategories();
    _loadStaticProducts();

    // Then try to fetch from database in background
    _tryFetchFromDatabase();
  }

  void _loadStaticCategories() {
    categories.addAll([
      Category(id: 'cake', name: 'Cake', icon: '🎂'),
      Category(id: 'donut', name: 'Donut', icon: '🍩'),
      Category(id: 'cookies', name: 'Cookies', icon: '🍪'),
    ]);
    print('Loaded ${categories.length} static categories');
  }

  Future<void> _tryFetchFromDatabase() async {
    try {
      print('Attempting to fetch data from database...');
      await Future.wait([
        fetchCategories(),
        fetchProducts(),
      ]);
    } catch (e) {
      print('Database fetch failed, using static data: $e');
    }
  }

  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;
      print('Fetching categories from database...');
      final records = await pb.collection('category').getFullList();

      categories.clear();
      for (final record in records) {
        categories.add(Category(
          id: record.data['kategori']?.toString().toLowerCase() ?? '',
          name: record.data['kategori'] ?? '',
          icon: _getCategoryIcon(record.data['kategori'] ?? ''),
        ));
      }

      print('Fetched ${categories.length} categories from database');
      for (var cat in categories) {
        print('Category: ${cat.id} - ${cat.name}');
      }

      // If no categories from database, add static ones
      if (categories.isEmpty) {
        print('No categories from database, using static categories');
        categories.addAll([
          Category(id: 'cake', name: 'Cake', icon: '🎂'),
          Category(id: 'donut', name: 'Donut', icon: '🍩'),
          Category(id: 'cookies', name: 'Cookies', icon: '🍪'),
        ]);
      }
    } catch (e) {
      print('Error fetching categories: $e');
      // Fallback to static data if database fails
      categories.addAll([
        Category(id: 'cake', name: 'Cake', icon: '🎂'),
        Category(id: 'donut', name: 'Donut', icon: '🍩'),
        Category(id: 'cookies', name: 'Cookies', icon: '🍪'),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;
      print('Fetching products from database...');

      // Simple fetch without expansion first
      final records = await pb.collection('products').getFullList();

      products.clear();

      if (records.isEmpty) {
        print('No products in database, using static products');
        _loadStaticProducts();
      } else {
        print('Found ${records.length} products in database');

        for (final record in records) {
          // Map the correct field names from database
          final productName =
              record.data['nama_produk']?.toString() ?? 'Product';
          final productPrice =
              double.tryParse(record.data['harga']?.toString() ?? '0') ?? 0.0;
          final productDescription =
              record.data['description']?.toString() ?? '';
          final categoryId = record.data['category_id']?.toString() ?? '';

          // Construct proper image URL for PocketBase
          String productImage = 'https://picsum.photos/200';
          if (record.data['gambar'] != null &&
              record.data['gambar'].toString().isNotEmpty) {
            final imageName = record.data['gambar'].toString();
            productImage =
                '${pb.baseUrl}/api/files/${record.collectionId}/${record.id}/$imageName';
          }

          // Map category ID to category name
          String categoryName = '';

          switch (categoryId) {
            case 'j97cjwzlf0k6y84':
              categoryName = 'cookies';
              break;
            case 'q3j1561862t9651':
              categoryName = 'donut';
              break;
            case '30906b9d1zw177u':
              categoryName = 'cake';
              break;
            default:
              print(
                  'Unknown category ID: $categoryId for product: $productName');
              categoryName = 'unknown';
              break;
          }

          print(
              'Product: $productName, Price: $productPrice, Category: $categoryName');

          products.add(Product(
            id: record.id,
            name: productName,
            image: productImage,
            price: productPrice / 100, // Convert from cents to dollars
            categoryId: categoryName,
            description: productDescription,
            isFavorite: false,
          ));
        }

        // If no products were loaded properly, use static data
        if (products.isEmpty) {
          print('Failed to load products from database, using static products');
          _loadStaticProducts();
        }
      }

      print('Total products loaded: ${products.length}');
      for (var product in products) {
        print(
            'Final Product: ${product.name} - Category: ${product.categoryId} - Price: \$${product.price}');
      }
    } catch (e) {
      print('Error fetching products: $e');
      // Fallback to static data if database fails
      print('Using static products as fallback');
      _loadStaticProducts();
    } finally {
      isLoading.value = false;
    }
  }

  String _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'cake':
        return '🎂';
      case 'donut':
        return '🍩';
      case 'cookies':
        return '🍪';
      default:
        return '🍰';
    }
  }

  void _loadStaticProducts() {
    print('Loading static products...');
    products.addAll([
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
    ]);
    print('Loaded ${products.length} static products');
  }

  List<Product> getProductsByCategory(String categoryId) {
    return products.where((p) => p.categoryId == categoryId).toList();
  }

  // Get product by ID
  Product? getProductById(String productId) {
    try {
      return products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  Future<void> refreshData() async {
    await Future.wait([
      fetchCategories(),
      fetchProducts(),
    ]);
  }
}
