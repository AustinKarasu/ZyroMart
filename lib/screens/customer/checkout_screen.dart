import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/location_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/slide_to_confirm.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      backgroundColor: isDark ? const Color(0xFF0F1418) : const Color(0xFFF6F7F2),
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
                  color: isDark ? const Color(0xFF3A2D1D) : const Color(0xFFFFF0D8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_off_outlined,
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Enable location for better nearby-store matching and delivery tracking.',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : AppTheme.textDark,
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
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: AppTheme.primaryRed,
                      ),
                      hintText: 'Enter delivery address',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isPlacing
                            ? null
                            : () => _useCurrentLocation(context),
                        icon: const Icon(Icons.my_location_outlined),
                        label: const Text('Use current location'),
                      ),
                    ],
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
                        final message = cart.applyCoupon(
                          _couponController.text,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              message ?? 'Coupon applied successfully',
                            ),
                            backgroundColor: message == null
                                ? AppTheme.success
                                : AppTheme.primaryRed,
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
                    'cod',
                    'Cash on delivery',
                    'Collected only after successful handoff. Order settlement and payout release happen only after delivery completion.',
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
                            child: Text(
                              '${item.product.name} x${item.quantity}',
                            ),
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
          color: isDark ? const Color(0xFF12191E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SlideToConfirm(
            label: 'Slide to place order | Rs ${cart.grandTotal.toInt()}',
            confirmLabel: 'Placing order...',
            onConfirmed: _isPlacing ? () async => false : () => _placeOrder(context),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161D22) : Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _etaCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF173424) : const Color(0xFFEAF8EC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: Color(0xFF1D8C3A)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery under 24hr',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D8C3A),
                  ),
                ),
                Text(
                  'Store radius, assignment, and rider ETA update after the store accepts the order.',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppTheme.textMedium,
                    fontSize: 12,
                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF1F3E2C) : const Color(0xFFF1FAF2))
              : (isDark ? const Color(0xFF1A2127) : const Color(0xFFF8F8F8)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xFF1D8C3A)
                : (isDark ? const Color(0xFF2A343E) : AppTheme.divider),
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF1D8C3A) : AppTheme.textMedium,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? const Color(0xFF1D8C3A)
                          : (isDark ? Colors.white : AppTheme.textDark),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppTheme.textMedium,
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

  Widget _billRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              color: isBold
                  ? (isDark ? Colors.white : AppTheme.textDark)
                  : (isDark ? Colors.white70 : AppTheme.textMedium),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: valueColor ??
                  (isDark ? Colors.white : AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _useCurrentLocation(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final location = context.read<LocationService>();
    final auth = context.read<AuthService>();
    await location.refreshLocation();
    if (!mounted) return;
    final latLng = location.currentLocation;
    if (latLng == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            location.errorMessage ??
                'Could not fetch location. Please allow permission and retry.',
          ),
        ),
      );
      return;
    }
    final resolvedAddress =
        'Current location (${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)})';
    setState(() {
      _addressController.text = resolvedAddress;
    });
    final user = auth.currentUser;
    if (user != null) {
      await auth.updateProfile(
        name: user.name,
        address: resolvedAddress,
        phone: user.phone,
        role: user.role,
        profileImageUrl: user.profileImageUrl,
        location: latLng,
      );
    }
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Current location applied to delivery address.')),
    );
  }

  Future<bool> _placeOrder(BuildContext context) async {
    final address = _addressController.text.trim();
    final notes = _notesController.text.trim();
    final cart = context.read<CartService>();
    final auth = context.read<AuthService>();
    final location = context.read<LocationService>();
    final orderService = context.read<OrderService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (cart.items.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return false;
    }

    if (!cart.meetsMinimumOrderRequirement) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Add at least 3 products before placing an order'),
        ),
      );
      return false;
    }

    final customerPhone = auth.currentUser?.phone.trim() ?? '';
    if (customerPhone.isEmpty || customerPhone.length < 10) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'A verified phone number is required before placing an order',
          ),
        ),
      );
      return false;
    }

    if (address.isEmpty || address.length < 10) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter a valid delivery address')),
      );
      return false;
    }

    if (address.length > _maxAddressLength) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Delivery address is too long')),
      );
      return false;
    }

    if (notes.length > _maxNotesLength) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Delivery instructions are too long')),
      );
      return false;
    }

    setState(() => _isPlacing = true);
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return false;
    Order order;
    try {
      order = orderService.placeOrder(
        items: cart.items,
        totalAmount: cart.totalAmount,
        deliveryFee: cart.deliveryFee,
        deliveryAddress: address,
        customerLocation:
            location.currentLocation ??
            auth.currentUser?.location ??
            const LatLng(20.5937, 78.9629),
        platformFee: cart.platformFee,
        handlingFee: cart.handlingFee,
        deliveryTip: cart.deliveryTip,
        couponDiscount: cart.couponDiscount,
        notes: notes.isEmpty ? null : notes,
        paymentMethod: _paymentMethod,
      );
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
      setState(() => _isPlacing = false);
      return false;
    }

    cart.clear();
    if (!mounted) return false;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
      (route) => route.isFirst,
    );
    return true;
  }
}
