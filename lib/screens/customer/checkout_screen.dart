import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
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
  static const int _maxAddressLength = 250;
  static const int _maxNotesLength = 300;
  final _addressController = TextEditingController(text: '78 Residency Road, Sector 22, Noida');
  final _notesController = TextEditingController();
  final _couponController = TextEditingController();
  String _paymentMethod = 'cod';
  bool _isPlacing = false;

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _couponController.dispose();
    super.dispose();
  }

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
            _buildSectionTitle('Delivery Address'),
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
            _buildEtaCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('Delivery Instructions'),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Gate number, landmark, preferred drop-off...',
                prefixIcon: Icon(Icons.note, color: AppTheme.textLight),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Coupons'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'FREEDEL / SAVE50 / WELCOME100',
                      prefixIcon: Icon(Icons.local_offer_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () {
                      final message = cart.applyCoupon(_couponController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message ?? 'Coupon applied successfully'),
                          backgroundColor: message == null ? AppTheme.success : AppTheme.primaryRed,
                        ),
                      );
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Delivery Tip'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [0, 20, 30, 50].map((tip) {
                final selected = cart.deliveryTip == tip.toDouble();
                final label = tip == 0 ? 'No Tip' : 'Rs $tip';
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => cart.setDeliveryTip(tip.toDouble()),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Payment Method'),
            const SizedBox(height: 12),
            _buildPaymentOption('cod', 'Cash on Delivery', Icons.money),
            _buildPaymentOption('upi', 'UPI Payment', Icons.account_balance_wallet_outlined),
            _buildPaymentOption('card', 'Credit or Debit Card', Icons.credit_card_outlined),
            const SizedBox(height: 24),
            _buildSectionTitle('Bill Summary'),
            const SizedBox(height: 12),
            _buildSummaryCard(cart),
            const SizedBox(height: 90),
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
          height: 52,
          child: ElevatedButton(
            onPressed: _isPlacing ? null : () => _placeOrder(context),
            child: _isPlacing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text('Place Order • Rs ${cart.grandTotal.toInt()}'),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildEtaCard() {
    return Container(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery in 24-32 mins',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success, fontSize: 16),
                ),
                Text(
                  'Live tracking activates as soon as your rider is assigned.',
                  style: TextStyle(color: AppTheme.textMedium, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(CartService cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: AppTheme.cardShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          ...cart.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${item.product.name} x${item.quantity}')),
                    Text('Rs ${item.totalPrice.toInt()}'),
                  ],
                ),
              )),
          const Divider(height: 24),
          _billRow('Subtotal', 'Rs ${cart.totalAmount.toInt()}'),
          _billRow('Delivery Fee', cart.deliveryFee == 0 ? 'FREE' : 'Rs ${cart.deliveryFee.toInt()}'),
          _billRow('Platform Fee', 'Rs ${cart.platformFee.toInt()}'),
          _billRow('Handling Fee', 'Rs ${cart.handlingFee.toInt()}'),
          if (cart.deliveryTip > 0) _billRow('Delivery Tip', 'Rs ${cart.deliveryTip.toInt()}'),
          if (cart.couponDiscount > 0)
            _billRow('Coupon Discount', '-Rs ${cart.couponDiscount.toInt()}', valueColor: AppTheme.success),
          const Divider(height: 24),
          _billRow('Grand Total', 'Rs ${cart.grandTotal.toInt()}', isBold: true),
        ],
      ),
    );
  }

  Widget _billRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
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
            color: _paymentMethod == value ? AppTheme.primaryRed : AppTheme.divider,
            width: _paymentMethod == value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: _paymentMethod == value ? AppTheme.primaryRed : AppTheme.textLight),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(fontWeight: _paymentMethod == value ? FontWeight.bold : FontWeight.normal),
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
    final address = _addressController.text.trim();
    final notes = _notesController.text.trim();
    final cart = context.read<CartService>();
    final auth = context.read<AuthService>();
    final orderService = context.read<OrderService>();
    final navigator = Navigator.of(context);

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your cart is empty')));
      return;
    }

    final customerPhone = auth.currentUser?.phone.trim() ?? '';
    if (customerPhone.isEmpty || customerPhone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A verified phone number is required before placing an order')),
      );
      return;
    }

    if (address.isEmpty || address.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid delivery address')));
      return;
    }

    if (address.length > _maxAddressLength) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivery address is too long')));
      return;
    }

    if (notes.length > _maxNotesLength) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivery instructions are too long')));
      return;
    }

    setState(() => _isPlacing = true);
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    final order = orderService.placeOrder(
      items: cart.items,
      totalAmount: cart.totalAmount + cart.platformFee + cart.handlingFee + cart.deliveryTip - cart.couponDiscount,
      deliveryFee: cart.deliveryFee,
      deliveryAddress: address,
      customerLocation: auth.currentUser?.location ?? MockData.defaultCustomer.location,
      notes: notes.isEmpty ? null : notes,
    );

    cart.clear();
    if (!mounted) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
      (route) => route.isFirst,
    );
  }
}
