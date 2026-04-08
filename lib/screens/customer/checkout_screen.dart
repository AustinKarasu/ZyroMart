import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/order.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/location_service.dart';
import '../../services/order_service.dart';
import '../../services/supabase_service.dart';
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
  final _upiController = TextEditingController();

  String _paymentMethod = 'cod';
  bool _isPlacing = false;
  bool _hydratedDefaults = false;
  bool _loadingAccountState = false;
  List<_CheckoutSavedAddress> _savedAddresses = const [];
  Map<String, dynamic> _paymentSettings = const {};
  String? _selectedAddressId;

  bool get _codEnabled =>
      (_paymentSettings['cash_on_delivery_enabled'] as bool?) ?? true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateCheckoutDefaults();
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _couponController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _hydrateCheckoutDefaults() async {
    if (_hydratedDefaults || !mounted) return;
    _hydratedDefaults = true;

    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() {
      _loadingAccountState = true;
    });

    final accountState = await _loadAccountState(user.id);
    final addresses = _decodeAddresses(
      accountState['addresses'],
      fallbackAddress: user.address,
    );
    final paymentSettings =
        _decodePaymentSettings(accountState['payment_settings']);

    final primaryAddress = _pickPrimaryAddress(addresses);
    if (_addressController.text.trim().isEmpty &&
        primaryAddress.address.trim().isNotEmpty) {
      _addressController.text = primaryAddress.address.trim();
      _selectedAddressId = primaryAddress.id;
    } else if (_addressController.text.trim().isEmpty &&
        user.address.trim().isNotEmpty) {
      _addressController.text = user.address.trim();
    }

    final preferredMethod = _normalizePaymentMethod(
      paymentSettings['preferred_method']?.toString(),
    );
    if (preferredMethod == 'upi' || preferredMethod == 'cod') {
      _paymentMethod = preferredMethod;
    }
    _upiController.text = (paymentSettings['upi_id'] ?? '').toString().trim();

    if (_paymentMethod == 'cod' && !_codEnabled) {
      _paymentMethod = _upiController.text.contains('@') ? 'upi' : 'cod';
    }

    if (!mounted) return;
    setState(() {
      _savedAddresses = addresses;
      _paymentSettings = paymentSettings;
      _loadingAccountState = false;
    });
  }

  Future<Map<String, dynamic>> _loadAccountState(String userId) async {
    try {
      if (SupabaseService.isInitialized) {
        final remote = await SupabaseService.getUserAccountState();
        if (remote != null && remote.isNotEmpty) {
          return remote;
        }
      }
    } catch (_) {
      // Fall back to local cache.
    }

    final prefs = await SharedPreferences.getInstance();
    final addressesRaw = prefs.getStringList('account::$userId::addresses');
    final paymentRaw = prefs.getString('account::$userId::payment_methods');
    return {
      'addresses': addressesRaw
          ?.map(
            (entry) => Map<String, dynamic>.from(
              jsonDecode(entry) as Map<String, dynamic>,
            ),
          )
          .toList(),
      'payment_settings': paymentRaw == null
          ? null
          : Map<String, dynamic>.from(
              jsonDecode(paymentRaw) as Map<String, dynamic>,
            ),
    };
  }

  List<_CheckoutSavedAddress> _decodeAddresses(
    dynamic raw, {
    required String fallbackAddress,
  }) {
    final result = <_CheckoutSavedAddress>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final address = (map['address'] ?? '').toString().trim();
        if (address.isEmpty) continue;
        result.add(
          _CheckoutSavedAddress(
            id: (map['id'] ?? '').toString(),
            label: (map['label'] ?? 'Saved address').toString(),
            address: address,
            isDefault: map['is_default'] == true,
          ),
        );
      }
    }

    if (result.isEmpty && fallbackAddress.trim().isNotEmpty) {
      result.add(
        _CheckoutSavedAddress(
          id: 'fallback-primary',
          label: 'Primary',
          address: fallbackAddress.trim(),
          isDefault: true,
        ),
      );
    }
    return result;
  }

  Map<String, dynamic> _decodePaymentSettings(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const {};
  }

  _CheckoutSavedAddress _pickPrimaryAddress(List<_CheckoutSavedAddress> list) {
    if (list.isEmpty) {
      return const _CheckoutSavedAddress(
        id: '',
        label: '',
        address: '',
        isDefault: false,
      );
    }
    return list.firstWhere(
      (entry) => entry.isDefault,
      orElse: () => list.first,
    );
  }

  String _normalizePaymentMethod(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'cash_on_delivery':
      case 'cod':
        return 'cod';
      case 'upi':
        return 'upi';
      default:
        return 'cod';
    }
  }

  Future<void> _useCurrentLocation() async {
    final location = context.read<LocationService>();
    final auth = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);
    await location.refreshLocation();
    final current = location.currentLocation;
    if (!mounted) return;
    if (current == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            location.errorMessage ?? 'Could not fetch current location.',
          ),
        ),
      );
      return;
    }
    final placeName = await location.reverseGeocode(current);
    final formatted = placeName == null
        ? 'Current location (${current.latitude.toStringAsFixed(6)}, ${current.longitude.toStringAsFixed(6)})'
        : '$placeName (${current.latitude.toStringAsFixed(5)}, ${current.longitude.toStringAsFixed(5)})';
    setState(() {
      _addressController.text = formatted;
      _selectedAddressId = null;
    });
    final user = auth.currentUser;
    if (user != null) {
      await auth.updateProfile(
        name: user.name,
        address: formatted,
        phone: user.phone,
        role: user.role,
        profileImageUrl: user.profileImageUrl,
        location: current,
      );
    }
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
                    const Icon(
                      Icons.location_off_outlined,
                      color: AppTheme.warning,
                    ),
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
                  if (_loadingAccountState)
                    const LinearProgressIndicator(minHeight: 2),
                  if (_savedAddresses.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedAddressId,
                      decoration: const InputDecoration(
                        labelText: 'Saved addresses',
                        prefixIcon: Icon(Icons.bookmark_outline),
                      ),
                      items: _savedAddresses
                          .map(
                            (entry) => DropdownMenuItem<String>(
                              value: entry.id,
                              child: Text(
                                '${entry.label}${entry.isDefault ? ' (Primary)' : ''}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        final match = _savedAddresses.where((e) => e.id == value);
                        if (match.isEmpty) return;
                        setState(() {
                          _selectedAddressId = value;
                          _addressController.text = match.first.address;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
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
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _useCurrentLocation,
                          icon: const Icon(Icons.my_location_rounded),
                          label: const Text('Get current location'),
                        ),
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
                    _codEnabled
                        ? 'Collected only after successful handoff. Order settlement and payout release happen only after delivery completion.'
                        : 'Disabled from your saved payment preferences.',
                    Icons.payments_outlined,
                    enabled: _codEnabled,
                  ),
                  const SizedBox(height: 10),
                  _paymentOption(
                    'upi',
                    'UPI',
                    'Secure UPI collect request will be used at order confirmation.',
                    Icons.account_balance_wallet_outlined,
                  ),
                  if (_paymentMethod == 'upi') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _upiController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'UPI ID',
                        hintText: 'name@bank',
                        prefixIcon: Icon(Icons.alternate_email_outlined),
                      ),
                    ),
                  ],
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
          child: SlideToConfirm(
            label: 'Swipe to pay - Rs ${cart.grandTotal.toInt()}',
            confirmLabel: 'Processing order...',
            onConfirmed: () => _placeOrder(context),
            backgroundColor: const Color(0xFF1D8C3A),
            knobColor: Colors.white,
            textColor: Colors.white,
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
    IconData icon, {
    bool enabled = true,
  }) {
    final selected = _paymentMethod == value;
    return GestureDetector(
      onTap: enabled ? () => setState(() => _paymentMethod = value) : null,
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
            Icon(
              icon,
              color: enabled
                  ? (selected ? const Color(0xFF1D8C3A) : AppTheme.textMedium)
                  : AppTheme.textLight,
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
                      color: enabled
                          ? (selected
                              ? const Color(0xFF1D8C3A)
                              : AppTheme.textDark)
                          : AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: enabled ? AppTheme.textMedium : AppTheme.textLight,
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

    if (_paymentMethod == 'cod' && !_codEnabled) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Cash on delivery is disabled for your account')),
      );
      return false;
    }

    if (_paymentMethod == 'upi') {
      final upiId = _upiController.text.trim();
      if (!upiId.contains('@')) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Enter a valid UPI ID to continue')),
        );
        return false;
      }
    }

    if (_isPlacing) {
      return false;
    }

    setState(() => _isPlacing = true);
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return false;
    Order order;
    try {
      final composedNotes = _paymentMethod == 'upi'
          ? [
              if (notes.isNotEmpty) notes,
              'UPI: ${_upiController.text.trim()}',
            ].join(' | ')
          : notes;

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
        notes: composedNotes.isEmpty ? null : composedNotes,
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
    if (!mounted) return true;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
      (route) => route.isFirst,
    );
    return true;
  }
}

class _CheckoutSavedAddress {
  final String id;
  final String label;
  final String address;
  final bool isDefault;

  const _CheckoutSavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.isDefault,
  });
}
