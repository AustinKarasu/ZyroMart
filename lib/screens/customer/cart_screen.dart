import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/cart_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_image.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F2),
      appBar: AppBar(title: const Text('My Cart')),
      body: Consumer<CartService>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 80, color: AppTheme.textLight),
                  SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add a few essentials and they will show up here.',
                    style: TextStyle(color: AppTheme.textMedium),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF8EC),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_rounded,
                              color: Color(0xFF1D8C3A)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              cart.amountForFreeDelivery == 0
                                  ? 'Free delivery unlocked for this basket.'
                                  : 'Add Rs ${cart.amountForFreeDelivery.toInt()} more to unlock free delivery.',
                              style: const TextStyle(
                                color: Color(0xFF196F2A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...cart.items.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            AppImage(
                              imageUrl: item.product.imageUrl,
                              width: 82,
                              height: 82,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.product.unit,
                                    style: const TextStyle(
                                      color: AppTheme.textMedium,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Rs ${item.totalPrice.toInt()}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F9EE),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () => cart.decrementQuantity(
                                            item.product.id),
                                        icon: const Icon(Icons.remove,
                                            color: Color(0xFF1D8C3A)),
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => cart.incrementQuantity(
                                            item.product.id),
                                        icon: const Icon(Icons.add,
                                            color: Color(0xFF1D8C3A)),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => cart.removeItem(item.product.id),
                                  child: const Text(
                                    'Remove',
                                    style: TextStyle(color: AppTheme.primaryRed),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bill details',
                            style:
                                TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 16),
                          _billRow('Item total', 'Rs ${cart.totalAmount.toInt()}'),
                          if (cart.savings > 0)
                            _billRow(
                              'Savings',
                              '-Rs ${cart.savings.toInt()}',
                              valueColor: AppTheme.success,
                            ),
                          _billRow(
                            'Delivery fee',
                            cart.deliveryFee == 0
                                ? 'FREE'
                                : 'Rs ${cart.deliveryFee.toInt()}',
                            valueColor: cart.deliveryFee == 0
                                ? AppTheme.success
                                : null,
                          ),
                          _billRow('Platform fee', 'Rs ${cart.platformFee.toInt()}'),
                          _billRow('Handling fee', 'Rs ${cart.handlingFee.toInt()}'),
                          if (cart.deliveryTip > 0)
                            _billRow(
                                'Delivery tip', 'Rs ${cart.deliveryTip.toInt()}'),
                          if (cart.couponDiscount > 0)
                            _billRow(
                              'Coupon savings',
                              '-Rs ${cart.couponDiscount.toInt()}',
                              valueColor: AppTheme.success,
                            ),
                          const Divider(height: 24),
                          _billRow(
                            'Grand total',
                            'Rs ${cart.grandTotal.toInt()}',
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D8C3A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      'Proceed to checkout • Rs ${cart.grandTotal.toInt()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _billRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? AppTheme.textDark : AppTheme.textMedium,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textDark,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
