import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/app_telemetry_service.dart';
import '../../services/cart_service.dart';
import '../../services/catalog_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _dietFilters = <String>{};
  Set<String> _wishlistIds = <String>{};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    AppTelemetryService.trackFeatureUse(
      eventName: 'customer_home_opened',
      appVariant: 'storefront',
    );
    _loadWishlist();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWishlist() async {
    if (!SupabaseService.isInitialized) return;
    try {
      final remote = await SupabaseService.getUserAccountState();
      final ids = remote?['wishlist_product_ids'];
      if (!mounted || ids is! List) return;
      setState(() {
        _wishlistIds = ids.map((entry) => entry.toString()).toSet();
      });
    } catch (_) {}
  }

  Future<void> _toggleWishlist(Product product) async {
    if (!SupabaseService.isInitialized) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(SupabaseService.backendStatusMessage),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
      return;
    }

    final previous = Set<String>.from(_wishlistIds);
    final next = Set<String>.from(_wishlistIds);
    final wasSaved = next.contains(product.id);
    if (wasSaved) {
      next.remove(product.id);
    } else {
      next.add(product.id);
    }

    setState(() {
      _wishlistIds = next;
    });

    try {
      await SupabaseService.upsertUserAccountState({
        'wishlist_product_ids': next.toList(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasSaved
                ? '${product.name} removed from wishlist.'
                : '${product.name} saved to wishlist.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _wishlistIds = previous;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update wishlist. $error'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catalog = context.watch<CatalogService>();
    final cart = context.watch<CartService>();
    final filteredProducts = catalog.smartSearch(
      _searchQuery,
      dietFilters: _dietFilters,
    );
    final featuredProducts = catalog.recommendedProducts(
      limit: 6,
      dietFilters: _dietFilters,
    );
    final categoryList = catalog.categories.take(8).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111315) : const Color(0xFFF4F6F1),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 190,
            backgroundColor: isDark ? const Color(0xFF171A1E) : const Color(0xFFF7F4E8),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF161616),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      ),
                      icon: const Icon(Icons.shopping_bag_outlined),
                    ),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1D8C3A),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${cart.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [Color(0xFF18211B), Color(0xFF111315)]
                        : const [Color(0xFFE9F5E8), Color(0xFFF5F8EF)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F8A36),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.flash_on_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delivery under 24hr',
                                    style: TextStyle(
                                      color: isDark ? Colors.white : const Color(0xFF111111),
                                      fontSize: 21,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cart.amountForFreeDelivery == 0
                                        ? 'Free delivery unlocked on this cart'
                                        : 'Add Rs ${cart.amountForFreeDelivery.toInt()} more for free delivery',
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : AppTheme.textMedium,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search atta, chips, fruits, dairy, beverages',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _dietChip('Vegetarian'),
                      _dietChip('High protein'),
                      _dietChip('Fast delivery'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _heroCard(isDark),
                  const SizedBox(height: 24),
                  _sectionHeader('Shop by category', 'Browse faster'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 116,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categoryList.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final category = categoryList[index];
                        return _CategoryTile(category: category, isDark: isDark);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionHeader('Picked for tonight', 'Saved and trending products'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 274,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: featuredProducts.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final product = featuredProducts[index];
                        return SizedBox(
                          width: 192,
                          child: ProductCard(
                            product: product,
                            isFavorite: _wishlistIds.contains(product.id),
                            onFavoriteTap: () => _toggleWishlist(product),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(product: product),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionHeader('Everything for your basket', '${filteredProducts.length} items'),
                  const SizedBox(height: 12),
                  GridView.builder(
                    itemCount: filteredProducts.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.68,
                    ),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return ProductCard(
                        product: product,
                        isFavorite: _wishlistIds.contains(product.id),
                        onFavoriteTap: () => _toggleWishlist(product),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(product: product),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dietChip(String label) {
    final selected = _dietFilters.contains(label);
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: (value) {
        setState(() {
          if (value) {
            _dietFilters.add(label);
          } else {
            _dietFilters.remove(label);
          }
        });
      },
    );
  }

  Widget _heroCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF35B44B), Color(0xFFCDE667)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
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
          const SizedBox(height: 18),
          const Text(
            'Groceries curated for tonight',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Search faster, save to wishlist from home, and build repeat baskets with cleaner store data.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.textMedium,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.isDark});

  final Category category;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryProductsScreen(category: category),
        ),
      ),
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F24) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? const Color(0xFF273038) : const Color(0xFFE8ECEE),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(category.icon, color: category.color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              category.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.textDark,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

