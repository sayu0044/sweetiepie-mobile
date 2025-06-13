import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sweetipie/controllers/cart_controller.dart';
import 'package:sweetipie/controllers/home_controller.dart';
import 'package:sweetipie/models/category.dart';
import 'package:sweetipie/models/product.dart';
import 'package:sweetipie/theme/app_theme.dart';
import 'package:sweetipie/widgets/bottom_nav_bar.dart';
import 'package:sweetipie/widgets/like_button_widget.dart';
import 'package:sweetipie/services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'cake';
  final CartController cartController = Get.put(CartController());
  final HomeController homeController = Get.put(HomeController());
  final DatabaseService databaseService = Get.find<DatabaseService>();

  // Static data as fallback
  final List<Category> staticCategories = [
    Category(id: 'cake', name: 'Cake', icon: '🎂'),
    Category(id: 'donut', name: 'Donut', icon: '🍩'),
    Category(id: 'cookies', name: 'Cookies', icon: '🍪'),
  ];

  final List<Product> staticProducts = [
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

  @override
  void initState() {
    super.initState();

    // Set default category after categories are loaded
    ever(databaseService.categories, (categories) {
      if (categories.isNotEmpty && selectedCategory == 'cake') {
        // Find cake category or use first available
        final cakeCategory = categories.firstWhere(
          (cat) => cat.name.toLowerCase() == 'cake',
          orElse: () => categories.first,
        );
        setState(() {
          selectedCategory = cakeCategory.name.toLowerCase();
        });
      }
    });

    // Also listen to products changes
    ever(databaseService.products, (products) {
      debugPrint('Products updated: ${products.length}');
    });
  }

  List<Category> get currentCategories {
    return databaseService.categories.isNotEmpty
        ? databaseService.categories.toList()
        : staticCategories;
  }

  List<Product> get currentProducts {
    return databaseService.products.isNotEmpty
        ? databaseService.products
        : staticProducts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Obx(() {
                    final avatarUrl = homeController.userAvatar.value;
                    return CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primaryColor,
                      child: avatarUrl.startsWith('assets/')
                          ? Image.asset(
                              avatarUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            )
                          : avatarUrl.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    avatarUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        HomeController.guestAvatar,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 32,
                                ),
                    );
                  }),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(() => Text(
                              'Hey, ${homeController.userName.value}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            )),
                        Text(
                          'Find and Get Your Favorite Cake',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.tune,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Categories
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Browse By Category',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${currentCategories.length} cats, ${currentProducts.length} products',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: currentCategories.length,
                itemBuilder: (context, index) {
                  final category = currentCategories[index];
                  final isSelected = category.id == selectedCategory ||
                      (selectedCategory == 'cake' &&
                          category.name.toLowerCase() == 'cake') ||
                      (selectedCategory == 'donut' &&
                          category.name.toLowerCase() == 'donut') ||
                      (selectedCategory == 'cookies' &&
                          category.name.toLowerCase() == 'cookies');

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category.name.toLowerCase();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Text(
                              category.icon,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category.name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Products Grid
            Expanded(
              child: Builder(
                builder: (context) {
                  final filteredProducts = currentProducts.where((p) {
                    // More flexible category matching
                    final productCategory = p.categoryId.toLowerCase();
                    final selectedCat = selectedCategory.toLowerCase();

                    return productCategory == selectedCat ||
                        productCategory.contains(selectedCat) ||
                        selectedCat.contains(productCategory);
                  }).toList();

                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_basket_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No products found for this category',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Selected: $selectedCategory',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total products: ${currentProducts.length}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image
                            Expanded(
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: Image.network(
                                      product.image,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          width: double.infinity,
                                          color: Colors.grey[200],
                                          child: Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey[400],
                                            size: 48,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: LikeButtonWidget(
                                        productId: product.id,
                                        iconSize: 20,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    bottom: 8,
                                    child: GestureDetector(
                                      onTap: () async {
                                        debugPrint(
                                            'HomeScreen: Adding product to cart: ${product.id} - ${product.name}');
                                        await cartController.addToCart(product,
                                            quantity: 1);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Product Info
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${product.price.toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}
