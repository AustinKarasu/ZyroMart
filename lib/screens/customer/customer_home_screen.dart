import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/cart_service.dart';
import '../../services/catalog_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final catalog = context.watch<CatalogService>();
    final freeDeliveryLeft = cart.amountForFreeDelivery;
    final products = catalog.products;
    final categories = catalog.categories;
    final filteredProducts = _searchQuery.isEmpty
        ? products
        : products.where((p) {
            final query = _searchQuery.toLowerCase();
            return p.name.toLowerCase().contains(query) || p.description.toLowerCase().contains(query);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 82,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ZyroMart', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            Text(
              freeDeliveryLeft == 0 ? 'Free delivery unlocked for this cart' : 'Add Rs ${freeDeliveryLeft.toInt()} more for free delivery',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.88)),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 6,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(color: AppTheme.accentGold, shape: BoxShape.circle),
                    child: Text('${cart.itemCount}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search fruits, dairy, bakery and essentials',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textLight),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            SliverToBoxAdapter(child: _buildHeroBanner()),
            SliverToBoxAdapter(child: _buildOfferStrip()),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Text('Shop by category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 138,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryProductsScreen(category: category))),
                      child: Container(
                        width: 102,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            Container(
                              width: 78,
                              height: 78,
                              decoration: BoxDecoration(
                                color: category.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: category.imageUrl.isNotEmpty
                                  ? AppImage(imageUrl: category.imageUrl, width: 78, height: 78, borderRadius: BorderRadius.circular(22))
                                  : Icon(category.icon, color: category.color, size: 30),
                            ),
                            const SizedBox(height: 8),
                            Text(category.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_searchQuery.isEmpty ? 'Top picks for tonight' : 'Search results', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  if (catalog.isLoading)
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
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
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = filteredProducts[index];
                  return ProductCard(product: product, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))));
                },
                childCount: filteredProducts.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 84)),
        ],
      ),
      bottomSheet: cart.itemCount > 0 ? _cartBar(context, cart) : null,
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFA11414), Color(0xFFE03A34), Color(0xFFFFC06A)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Storefront open, day and night', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
          SizedBox(height: 8),
          Text('Fresh produce, dairy, bakery, snacks and home care with delivery windows that feel dependable around the clock.', style: TextStyle(color: Colors.white, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildOfferStrip() {
    final offers = const [
      ('FREEDEL', 'Free delivery over eligible carts'),
      ('SAVE50', 'Rs 50 off on larger baskets'),
      ('WELCOME100', 'First-time high-value cart reward'),
    ];
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        itemBuilder: (context, index) {
          final offer = offers[index];
          return Container(
            width: 216,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: AppTheme.cardShadow, blurRadius: 8)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(offer.$1, style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryRed)),
              Text(offer.$2, style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
            ]),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemCount: offers.length,
      ),
    );
  }

  Widget _cartBar(BuildContext context, CartService cart) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppTheme.primaryRedDark, AppTheme.primaryRed]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppTheme.primaryRed.withValues(alpha: 0.38), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${cart.itemCount} items', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Checkout total Rs ${cart.grandTotal.toInt()}', style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 12)),
              ],
            ),
            const Row(
              children: [
                Text('View Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
