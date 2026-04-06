import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/location_service.dart';
import '../../services/order_service.dart';
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

  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _couponController = TextEditingController();
  String _paymentMethod = 'upi_gpay';
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
    final location = context.watch<LocationService>();
    final auth = context.watch<AuthService>();

    if (location.hasUsableLocation &&
        auth.currentUser != null &&
        auth.currentUser!.location != location.currentLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        auth.updateProfile(
          name: auth.currentUser!.name,
          address: _addressController.text.trim().isEmpty
              ? auth.currentUser!.address
              : _addressController.text.trim(),
          phone: auth.currentUser!.phone,
          role: auth.currentUser!.role,
          profileImageUrl: auth.currentUser!.profileImageUrl,
          location: location.currentLocation,
        );
      });
    }

    if (_addressController.text.isEmpty &&
        (auth.currentUser?.address.isNotEmpty ?? false)) {
      _addressController.text = auth.currentUser!.address;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F2),
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!location.hasUsableLocation)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0D8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_off_outlined,
                        color: AppTheme.warning),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Enable location for better nearby-store matching and delivery tracking.',
                        style: TextStyle(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: location.refreshLocation,
                      child: const Text('Enable'),
                    ),
                  ],
                ),
              ),
            _sectionCard(
              title: 'Delivery address',
              child: Column(
                children: [
                  TextField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      prefixIcon:
                          Icon(Icons.location_on_outlined, color: AppTheme.primaryRed),
                      hintText: 'Enter delivery address',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _etaCard(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Delivery instructions',
              child: TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Landmark, gate number, or rider note',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Coupons',
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'Enter a verified store or platform coupon',
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
                            content: Text(
                              message ?? 'Coupon applied successfully',
                            ),
                            backgroundColor:
                                message == null ? AppTheme.success : AppTheme.primaryRed,
                          ),
                        );
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Delivery tip',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tips are released to the assigned delivery partner only after a successful delivery.',
                    style: TextStyle(color: AppTheme.textMedium, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [0, 20, 30, 50].map((tip) {
                      final selected = cart.deliveryTip == tip.toDouble();
                      final label = tip == 0 ? 'No tip' : 'Rs $tip';
                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) => cart.setDeliveryTip(tip.toDouble()),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Payment method',
              child: Column(
                children: [
                  _paymentOption(
                    'upi_gpay',
                    'GPay / UPI',
                    'UPI-first checkout flow. App-side foundation only; real bank-verification and automated split settlement require a dedicated payment backend.',
                    Icons.account_balance_wallet_outlined,
                  ),
                  const SizedBox(height: 10),
                  _paymentOption(
                    'cod',
                    'Cash on delivery',
                    'Collected on handoff. Store and rider settlement still release only after delivery completion.',
                    Icons.payments_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Bill summary',
              child: Column(
                children: [
                  ...cart.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('${item.product.name} x${item.quantity}'),
                          ),
                          Text(
                            'Rs ${item.totalPrice.toInt()}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  _billRow('Subtotal', 'Rs ${cart.totalAmount.toInt()}'),
                  _billRow(
                    'Delivery fee',
                    cart.deliveryFee == 0
                        ? 'FREE'
                        : 'Rs ${cart.deliveryFee.toInt()}',
                  ),
                  _billRow('Platform fee', 'Rs ${cart.platformFee.toInt()}'),
                  _billRow('Handling fee', 'Rs ${cart.handlingFee.toInt()}'),
                  if (cart.deliveryTip > 0)
                    _billRow('Delivery tip', 'Rs ${cart.deliveryTip.toInt()}'),
                  if (cart.couponDiscount > 0)
                    _billRow(
                      'Coupon discount',
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
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isPlacing ? null : () => _placeOrder(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D8C3A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
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
                    'Place order â€¢ Rs ${cart.grandTotal.toInt()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _etaCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8EC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.schedule_rounded, color: Color(0xFF1D8C3A)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery under 24hr',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D8C3A),
                  ),
                ),
                Text(
                  'Store radius, assignment, and rider ETA update after the store accepts the order.',
                  style: TextStyle(color: AppTheme.textMedium, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final selected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1FAF2) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF1D8C3A) : AppTheme.divider,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? const Color(0xFF1D8C3A) : AppTheme.textMedium),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: selected ? const Color(0xFF1D8C3A) : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textMedium,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFF1D8C3A)),
          ],
        ),
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
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              color: isBold ? AppTheme.textDark : AppTheme.textMedium,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: valueColor ?? AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context) async {
    final address = _addressController.text.trim();
    final notes = _notesController.text.trim();
    final cart = context.read<CartService>();
    final auth = context.read<AuthService>();
    final location = context.read<LocationService>();
    final orderService = context.read<OrderService>();
    final navigator = Navigator.of(context);

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    if (!cart.meetsMinimumOrderRequirement) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least 3 products before placing an order'),
        ),
      );
      return;
    }

    final customerPhone = auth.currentUser?.phone.trim() ?? '';
    if (customerPhone.isEmpty || customerPhone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('A verified phone number is required before placing an order'),
        ),
      );
      return;
    }

    if (address.isEmpty || address.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid delivery address')),
      );
      return;
    }

    if (address.length > _maxAddressLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery address is too long')),
      );
      return;
    }

    if (notes.length > _maxNotesLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery instructions are too long')),
      );
      return;
    }

    setState(() => _isPlacing = true);
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    final order = orderService.placeOrder(
      items: cart.items,
      totalAmount: cart.totalAmount,
      deliveryFee: cart.deliveryFee,
      deliveryAddress: address,
      customerLocation:
          location.currentLocation ?? auth.currentUser?.location ?? const LatLng(28.6139, 77.2090),
      platformFee: cart.platformFee,
      handlingFee: cart.handlingFee,
      deliveryTip: cart.deliveryTip,
      couponDiscount: cart.couponDiscount,
      notes: notes.isEmpty ? null : notes,
      paymentMethod: _paymentMethod,
    );

    cart.clear();
    if (!mounted) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => OrderTrackingScreen(orderId: order.id),
      ),
      (route) => route.isFirst,
    );
  }
}

