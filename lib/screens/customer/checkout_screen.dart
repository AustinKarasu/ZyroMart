import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../services/mock_data.dart';
import '../../theme/app_theme.dart';
import 'order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController(
    text: '78 Residency Road, Sector 22, Noida',
  );
  final _notesController = TextEditingController();
  String _paymentMethod = 'cod';
  bool _isPlacing = false;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery address
            const Text(
              'Delivery Address',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.location_on, color: AppTheme.primaryRed),
                hintText: 'Enter delivery address',
              ),
            ),
            const SizedBox(height: 24),

            // Delivery time
            const Text(
              'Delivery Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.schedule, color: AppTheme.success),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Within 24 Hours',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.success,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Your order will arrive by tomorrow',
                        style: TextStyle(color: AppTheme.textMedium, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Order notes
            const Text(
              'Delivery Instructions (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'E.g., Ring the doorbell, leave at door...',
                prefixIcon: Icon(Icons.note, color: AppTheme.textLight),
              ),
            ),
            const SizedBox(height: 24),

            // Payment method
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildPaymentOption('cod', 'Cash on Delivery', Icons.money),
            _buildPaymentOption('upi', 'UPI Payment', Icons.account_balance),
            _buildPaymentOption('card', 'Credit/Debit Card', Icons.credit_card),
            const SizedBox(height: 24),

            // Order summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.cardShadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ...cart.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.product.name} x${item.quantity}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              '₹${item.totalPrice.toInt()}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal'),
                      Text('₹${cart.totalAmount.toInt()}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delivery Fee'),
                      Text(
                        cart.deliveryFee == 0
                            ? 'FREE'
                            : '₹${cart.deliveryFee.toInt()}',
                        style: TextStyle(
                          color: cart.deliveryFee == 0
                              ? AppTheme.success
                              : null,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '₹${cart.grandTotal.toInt()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.primaryRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isPlacing ? null : () => _placeOrder(context),
            child: _isPlacing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Place Order • ₹${cart.grandTotal.toInt()}',
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String value, String label, IconData icon) {
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _paymentMethod == value
                ? AppTheme.primaryRed
                : AppTheme.divider,
            width: _paymentMethod == value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: _paymentMethod == value
                    ? AppTheme.primaryRed
                    : AppTheme.textLight),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: _paymentMethod == value
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (_paymentMethod == value)
              const Icon(Icons.check_circle, color: AppTheme.primaryRed),
          ],
        ),
      ),
    );
  }

  void _placeOrder(BuildContext context) async {
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a delivery address')),
      );
      return;
    }

    setState(() => _isPlacing = true);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final cart = context.read<CartService>();
    final orderService = context.read<OrderService>();

    final order = orderService.placeOrder(
      items: cart.items,
      totalAmount: cart.totalAmount,
      deliveryAddress: _addressController.text,
      customerLocation: MockData.defaultCustomer.location,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    cart.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => OrderTrackingScreen(orderId: order.id),
      ),
      (route) => route.isFirst,
    );
  }
}
