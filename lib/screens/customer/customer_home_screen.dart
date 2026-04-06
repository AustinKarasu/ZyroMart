import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/app_telemetry_service.dart';
import '../../services/cart_service.dart';
import '../../services/catalog_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_image.dart';
import '../../widgets/product_card.dart';
import 'cart_screen.dart';
import 'category_products_screen.dart';
import 'product_detail_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _dietFilters = {};

  @override
  void initState() {
    super.initState();
    AppTelemetryService.trackFeatureUse(
      eventName: 'customer_home_opened',
      appVariant: 'storefront',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = context.watch<CartService>();
    final catalog = context.watch<CatalogService>();
    final orderService = context.watch<OrderService>();
    final freeDeliveryLeft = cart.amountForFreeDelivery;
    final products = catalog.products;
    final categories = catalog.categories;
    final filteredProducts = catalog.smartSearch(
      _searchQuery,
      dietFilters: _dietFilters,
    );
    final spotlightProducts = catalog.recommendedProducts(
      limit: 4,
      dietFilters: _dietFilters,
    );
    final trendingProducts = _buildTrendingProducts(
      products: products,
      orderService: orderService,
      dietFilters: _dietFilters,
    );
    final recommendationProducts = _buildSmartBasketSuggestions(
      products: products,
      cart: cart,
      orderService: orderService,
      dietFilters: _dietFilters,
    );

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF111315)
          : const Color(0xFFF6F7F2),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            backgroundColor: isDark
                ? const Color(0xFF171A1E)
                : const Color(0xFFF7F4E8),
            expandedHeight: 212,
            toolbarHeight: 84,
            elevation: 0,
            titleSpacing: 16,
            title: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F8A36),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.flash_on_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Delivery under 24hr',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111111),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        freeDeliveryLeft == 0
                            ? 'Free delivery unlocked on this cart'
                            : 'Add Rs ${freeDeliveryLeft.toInt()} more for free delivery',
                        style: const TextStyle(
                          color: AppTheme.textMedium,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(
                        Icons.shopping_bag_outlined,
                        color: Color(0xFF161616),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      ),
                    ),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: -2,
                        top: -1,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1D8C3A),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${cart.itemCount}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? const [Color(0xFF171A1E), Color(0xFF111315)]
                        : const [Color(0xFFF7F4E8), Color(0xFFF6F7F2)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 58,
                      left: -28,
                      child: Container(
                        width: 138,
                        height: 138,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFFF1D77B,
                          ).withValues(alpha: 0.33),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 76,
                      right: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFD5F0D8).withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search atta, chips, fruits, dairy, beauty',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.textLight,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1B1F23)
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Color(0xFF1D8C3A),
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _dietChip(context, 'Vegetarian'),
                          _dietChip(context, 'Vegan'),
                          _dietChip(context, 'High-Protein'),
                          _dietChip(context, 'Snacks'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: _HeroCommerceBanner(
                  products: spotlightProducts,
                  isDark: isDark,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _PromoRail(isDark: isDark),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Shop by category',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              _AllCategoriesScreen(categories: categories),
                        ),
                      ),
                      child: const Text(
                        'See all',
                        style: TextStyle(
                          color: Color(0xFF1D8C3A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 112,
                  childAspectRatio: 0.88,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final category = categories[index];
                  return _CategoryTile(category: category, isDark: isDark);
                }, childCount: categories.length),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Trending this evening',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                    ),
                    if (catalog.isLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 214,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: trendingProducts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final product = trendingProducts[index];
                    return _CompactTrendingProductCard(
                      product: product,
                      isDark: isDark,
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Smart basket suggestions',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF1D8C3A),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 214,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: recommendationProducts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final product = recommendationProducts[index];
                    return _CompactTrendingProductCard(
                      product: product,
                      isDark: isDark,
                    );
                  },
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'Bestsellers for your basket'
                          : 'Search results',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                  ),
                  Text(
                    '${filteredProducts.length} items',
                    style: const TextStyle(
                      color: AppTheme.textMedium,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final product = filteredProducts[index];
                return ProductCard(
                  product: product,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: product),
                    ),
                  ),
                );
              }, childCount: filteredProducts.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 104)),
        ],
      ),
      bottomSheet: cart.itemCount > 0 ? _cartBar(context, cart) : null,
    );
  }

  Widget _cartBar(BuildContext context, CartService cart) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CartScreen()),
      ),
      child: Container(
        margin: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E8D39), Color(0xFF44B34F)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E8D39).withValues(alpha: 0.26),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cart.itemCount} items',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Checkout total Rs ${cart.grandTotal.toInt()}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Row(
              children: [
                Text(
                  'View Cart',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dietChip(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _dietFilters.contains(label);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected
                ? (isDark ? const Color(0xFFD6FFE0) : const Color(0xFF116E2A))
                : (isDark ? Colors.white70 : const Color(0xFF2A3138)),
          ),
        ),
        onSelected: (value) {
          setState(() {
            if (value) {
              _dietFilters.add(label);
            } else {
              _dietFilters.remove(label);
            }
          });
        },
        showCheckmark: false,
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        backgroundColor: isDark ? const Color(0xFF1B2026) : Colors.white,
        selectedColor: isDark
            ? const Color(0xFF204F2D)
            : const Color(0xFFD9F0DF),
        checkmarkColor: const Color(0xFF1D8C3A),
        side: BorderSide(
          color: selected
              ? const Color(0xFF1D8C3A)
              : (isDark ? const Color(0xFF2C353F) : const Color(0xFFE4E8EC)),
        ),
      ),
    );
  }

  List<Product> _buildTrendingProducts({
    required List<Product> products,
    required OrderService orderService,
    required Set<String> dietFilters,
  }) {
    final orderedProductCounts = <String, int>{};
    for (final order in orderService.orders) {
      for (final item in order.items) {
        orderedProductCounts.update(
          item.product.id,
          (value) => value + item.quantity,
          ifAbsent: () => item.quantity,
        );
      }
    }

    final candidates =
        products
            .where(
              (product) =>
                  dietFilters.isEmpty ||
                  _passesDietFilters(product, dietFilters),
            )
            .toList()
          ..sort((a, b) {
            final scoreA =
                (orderedProductCounts[a.id] ?? 0) * 65 +
                (a.reviewCount * 0.7) +
                (a.rating * 24);
            final scoreB =
                (orderedProductCounts[b.id] ?? 0) * 65 +
                (b.reviewCount * 0.7) +
                (b.rating * 24);
            return scoreB.compareTo(scoreA);
          });
    return candidates.take(6).toList();
  }

  List<Product> _buildSmartBasketSuggestions({
    required List<Product> products,
    required CartService cart,
    required OrderService orderService,
    required Set<String> dietFilters,
  }) {
    final recentOrders = orderService.orders
        .where(
          (order) => DateTime.now().difference(order.placedAt).inDays <= 60,
        )
        .toList();
    final productFrequency = <String, int>{};
    final categoryFrequency = <String, int>{};
    final hourFrequency = <int, int>{};
    for (final order in recentOrders) {
      hourFrequency.update(
        order.placedAt.hour,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      for (final item in order.items) {
        productFrequency.update(
          item.product.id,
          (value) => value + item.quantity,
          ifAbsent: () => item.quantity,
        );
        categoryFrequency.update(
          item.product.categoryId,
          (value) => value + item.quantity,
          ifAbsent: () => item.quantity,
        );
      }
    }

    final nowHour = DateTime.now().hour;
    final hasCurrentWindowDemand =
        (hourFrequency[nowHour] ?? 0) > 0 ||
        (hourFrequency[nowHour - 1] ?? 0) > 0 ||
        (hourFrequency[nowHour + 1] ?? 0) > 0;

    final cartProductIds = cart.items.map((item) => item.product.id).toSet();
    final candidates =
        products
            .where((product) => !cartProductIds.contains(product.id))
            .where(
              (product) =>
                  dietFilters.isEmpty ||
                  _passesDietFilters(product, dietFilters),
            )
            .toList()
          ..sort((a, b) {
            final scoreA =
                (productFrequency[a.id] ?? 0) * 90 +
                (categoryFrequency[a.categoryId] ?? 0) * 28 +
                (hasCurrentWindowDemand ? 12 : 0) +
                (a.rating * 18) +
                (a.reviewCount * 0.45);
            final scoreB =
                (productFrequency[b.id] ?? 0) * 90 +
                (categoryFrequency[b.categoryId] ?? 0) * 28 +
                (hasCurrentWindowDemand ? 12 : 0) +
                (b.rating * 18) +
                (b.reviewCount * 0.45);
            return scoreB.compareTo(scoreA);
          });

    if (candidates.isEmpty) {
      return context.read<CatalogService>().recommendedProducts(
        limit: 6,
        dietFilters: dietFilters,
      );
    }
    return candidates.take(6).toList();
  }

  bool _passesDietFilters(Product product, Set<String> dietFilters) {
    if (dietFilters.isEmpty) return true;
    final text = '${product.name} ${product.description}'.toLowerCase();
    for (final filter in dietFilters.map((value) => value.toLowerCase())) {
      if (filter == 'vegetarian') {
        if (['chicken', 'meat', 'fish', 'egg'].any(text.contains)) {
          return false;
        }
        continue;
      }
      if (filter == 'vegan') {
        if (![
          'banana',
          'apple',
          'spinach',
          'tomato',
          'onion',
          'potato',
          'lentil',
          'almond',
        ].any(text.contains)) {
          return false;
        }
        continue;
      }
      if (filter == 'high-protein') {
        if (![
          'egg',
          'milk',
          'paneer',
          'chicken',
          'fish',
          'nuts',
          'protein',
        ].any(text.contains)) {
          return false;
        }
        continue;
      }
      if (filter == 'snacks') {
        if (![
          'chips',
          'cookie',
          'chocolate',
          'namkeen',
          'snack',
        ].any(text.contains)) {
          return false;
        }
        continue;
      }
    }
    return true;
  }
}

class _HeroCommerceBanner extends StatelessWidget {
  const _HeroCommerceBanner({required this.products, required this.isDark});

  final List<Product> products;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final leadImage = products.isNotEmpty ? products.first.imageUrl : '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B8F38), Color(0xFF7BCB58), Color(0xFFF3E799)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Freshly restocked',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Groceries curated for tonight',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Smart baskets, premium produce, household essentials, and snack-ready deals in one scroll.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF114E22),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Open 24 hours',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 98,
            height: 132,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(28),
            ),
            child: leadImage.isNotEmpty
                ? AppImage(
                    imageUrl: leadImage,
                    borderRadius: BorderRadius.circular(28),
                    fit: BoxFit.cover,
                  )
                : const Icon(
                    Icons.local_grocery_store_rounded,
                    color: Colors.white,
                    size: 52,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PromoRail extends StatelessWidget {
  const _PromoRail({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final offers = const [
      (
        'STORE OFFERS',
        'Coupons are issued only by verified stores',
        Color(0xFFE8F7E9),
      ),
      (
        'PLATFORM DEALS',
        'Admin-managed campaigns appear here when active',
        Color(0xFFFFF0D8),
      ),
      (
        'REAL INVENTORY',
        'Product pricing and availability now follow live store flows',
        Color(0xFFFFECEA),
      ),
    ];

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: offers.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final offer = offers[index];
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 380 + (index * 120)),
            tween: Tween(begin: 0.92, end: 1),
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              width: 244,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1D2127) : offer.$3,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    offer.$1,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF79CF85)
                          : const Color(0xFF156F2E),
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    offer.$2,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppTheme.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.isDark});

  final Category category;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryProductsScreen(category: category),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1F24) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: category.imageUrl.isNotEmpty
                  ? AppImage(
                      imageUrl: category.imageUrl,
                      width: 52,
                      height: 52,
                      borderRadius: BorderRadius.circular(18),
                    )
                  : Icon(category.icon, color: category.color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _TrendingProductCard extends StatelessWidget {
  const _TrendingProductCard({required this.product, required this.isDark});

  final Product product;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Container(
        width: 162,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1F24) : Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                child: AppImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs ${product.price.toInt()} • ${product.unit}',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppTheme.textMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _AllProductsScreen extends StatelessWidget {
  const _AllProductsScreen();

  @override
  Widget build(BuildContext context) {
    final products = context.watch<CatalogService>().products;
    return Scaffold(
      appBar: AppBar(title: const Text('All products')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            product: product,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AllCategoriesScreen extends StatelessWidget {
  const _AllCategoriesScreen({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('All categories')),
      backgroundColor: isDark
          ? const Color(0xFF0F1418)
          : const Color(0xFFF6F7F2),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 120,
          childAspectRatio: 0.9,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _CategoryTile(category: category, isDark: isDark);
        },
      ),
    );
  }
}

class _CompactTrendingProductCard extends StatelessWidget {
  const _CompactTrendingProductCard({
    required this.product,
    required this.isDark,
  });

  final Product product;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Container(
        width: 162,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1F24) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: AppImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs ${product.price.toInt()} | ${product.unit}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppTheme.textMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
