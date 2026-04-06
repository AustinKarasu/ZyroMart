import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/product.dart';
import '../../services/app_preferences_service.dart';
import '../../services/app_telemetry_service.dart';
import '../../services/auth_service.dart';
import '../../services/catalog_service.dart';
import '../../services/location_service.dart';
import '../../services/order_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class AddressBookScreen extends StatefulWidget {
  final String userId;
  final String initialAddress;

  const AddressBookScreen({
    super.key,
    required this.userId,
    required this.initialAddress,
  });

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  bool _isLoading = true;
  List<_SavedAddress> _addresses = const [];

  @override
  void initState() {
    super.initState();
    AppTelemetryService.trackFeatureUse(
      eventName: 'address_book_opened',
      appVariant: 'storefront',
    );
    _load();
  }

  Future<void> _load() async {
    final decoded = await _AccountStateRepository.loadAddresses(
      widget.userId,
      fallbackAddress: widget.initialAddress,
    );
    if (!mounted) return;
    setState(() {
      _addresses = decoded;
      _isLoading = false;
    });
  }

  Future<void> _persist() async {
    await _AccountStateRepository.saveAddresses(widget.userId, _addresses);
  }

  Future<void> _editAddress({_SavedAddress? existing}) async {
    final labelController = TextEditingController(text: existing?.label ?? '');
    final addressController = TextEditingController(text: existing?.address ?? '');
    var isDefault = existing?.isDefault ?? _addresses.isEmpty;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      existing == null ? 'Add address' : 'Edit address',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(labelText: 'Label'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Full address'),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(this.context);
                          final resolved = await _resolveCurrentLocationAddress();
                          if (!mounted) return;
                          if (resolved == null) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Could not fetch current location. Please enable location permission.'),
                              ),
                            );
                            return;
                          }
                          addressController.text = resolved;
                          if (labelController.text.trim().isEmpty) {
                            labelController.text = 'Current location';
                          }
                        },
                        icon: const Icon(Icons.my_location_outlined),
                        label: const Text('Use current location'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Default address'),
                      value: isDefault,
                      onChanged: (value) => setModalState(() => isDefault = value),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (labelController.text.trim().isEmpty ||
                              addressController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Enter both label and address.')),
                            );
                            return;
                          }
                          final next = _SavedAddress(
                            id: existing?.id ??
                                DateTime.now().microsecondsSinceEpoch.toString(),
                            label: labelController.text.trim(),
                            address: addressController.text.trim(),
                            isDefault: isDefault,
                          );
                          final updated = [..._addresses];
                          if (isDefault) {
                            for (var index = 0; index < updated.length; index++) {
                              updated[index] = updated[index].copyWith(isDefault: false);
                            }
                          }
                          if (existing == null) {
                            updated.add(next);
                          } else {
                            final index = updated.indexWhere((entry) => entry.id == existing.id);
                            if (index >= 0) {
                              updated[index] = next;
                            }
                          }
                          setState(() => _addresses = updated);
                          await _persist();
                          if (!mounted) return;
                          Navigator.of(this.context).pop();
                        },
                        child: const Text('Save address'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _removeAddress(String id) async {
    setState(() {
      _addresses = _addresses.where((entry) => entry.id != id).toList();
      if (_addresses.isNotEmpty && !_addresses.any((entry) => entry.isDefault)) {
        _addresses = [
          _addresses.first.copyWith(isDefault: true),
          ..._addresses.skip(1),
        ];
      }
    });
    await _persist();
  }

  Future<void> _makeDefault(String id) async {
    setState(() {
      _addresses = _addresses
          .map((entry) => entry.copyWith(isDefault: entry.id == id))
          .toList();
    });
    await _persist();
  }

  Future<String?> _resolveCurrentLocationAddress() async {
    final locationService = context.read<LocationService>();
    final auth = context.read<AuthService>();
    await locationService.refreshLocation();
    final latLng = locationService.currentLocation;
    if (latLng == null) {
      return null;
    }
    final formatted =
        'Current location (${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)})';
    final user = auth.currentUser;
    if (user != null) {
      await auth.updateProfile(
        name: user.name,
        address: formatted,
        phone: user.phone,
        role: user.role,
        profileImageUrl: user.profileImageUrl,
        location: latLng,
      );
    }
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Address book')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _editAddress,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add address'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? _EmptyStateCard(
                  icon: Icons.location_off_outlined,
                  title: 'No saved addresses yet',
                  body: 'Add your delivery addresses here for faster checkout and cleaner order routing.',
                  actionLabel: 'Add first address',
                  onTap: _editAddress,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final address = _addresses[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  address.label,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(width: 10),
                                if (address.isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.success.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Default',
                                      style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(address.address, style: const TextStyle(height: 1.5)),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _editAddress(existing: address),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Edit'),
                                ),
                                if (!address.isDefault)
                                  OutlinedButton.icon(
                                    onPressed: () => _makeDefault(address.id),
                                    icon: const Icon(Icons.check_circle_outline),
                                    label: const Text('Set default'),
                                  ),
                                TextButton.icon(
                                  onPressed: () => _removeAddress(address.id),
                                  icon: const Icon(Icons.delete_outline, color: AppTheme.primaryRed),
                                  label: const Text('Remove', style: TextStyle(color: AppTheme.primaryRed)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, separatorIndex) => const SizedBox(height: 12),
                  itemCount: _addresses.length,
                ),
    );
  }
}

class WishlistScreen extends StatefulWidget {
  final String userId;

  const WishlistScreen({super.key, required this.userId});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _isLoading = true;
  Set<String> _wishlistIds = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = await _AccountStateRepository.loadWishlist(widget.userId);
    if (!mounted) return;
    setState(() {
      _wishlistIds = ids.toSet();
      _isLoading = false;
    });
  }

  Future<void> _toggleWishlist(String productId) async {
    final next = Set<String>.from(_wishlistIds);
    if (next.contains(productId)) {
      next.remove(productId);
    } else {
      next.add(productId);
    }
    await _AccountStateRepository.saveWishlist(widget.userId, next.toList());
    if (!mounted) return;
    setState(() => _wishlistIds = next);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogService>();
    final savedProducts = catalog.products.where((product) => _wishlistIds.contains(product.id)).toList();
    final suggestions = catalog.recommendedProducts(limit: 12);

    return Scaffold(
      appBar: AppBar(title: const Text('Your wishlist')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionShell(
                  title: 'Saved for later',
                  subtitle: 'Keep future buys ready for your next basket.',
                  child: savedProducts.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'No wishlist items yet. Save products from the suggestion shelf below.',
                            style: TextStyle(color: AppTheme.textMedium, height: 1.5),
                          ),
                        )
                      : Column(
                          children: savedProducts
                              .map((product) => _WishlistProductTile(
                                    product: product,
                                    saved: true,
                                    onToggle: () => _toggleWishlist(product.id),
                                  ))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 16),
                _SectionShell(
                  title: 'Suggested picks',
                  subtitle: 'Fast-moving staples and products with stronger repeat intent.',
                  child: Column(
                    children: suggestions
                        .map((product) => _WishlistProductTile(
                              product: product,
                              saved: _wishlistIds.contains(product.id),
                              onToggle: () => _toggleWishlist(product.id),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
    );
  }
}

class PaymentMethodsScreen extends StatefulWidget {
  final String userId;

  const PaymentMethodsScreen({super.key, required this.userId});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _upiController;
  late final TextEditingController _billingNameController;
  var _preferredMethod = 'cash_on_delivery';
  var _cashOnDeliveryEnabled = true;
  var _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _upiController = TextEditingController();
    _billingNameController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _upiController.dispose();
    _billingNameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await _AccountStateRepository.loadPaymentSettings(widget.userId);
    if (data.isNotEmpty) {
      _upiController.text = (data['upi_id'] ?? '').toString();
      _billingNameController.text = (data['billing_name'] ?? '').toString();
      _preferredMethod = (data['preferred_method'] ?? _preferredMethod).toString();
      _cashOnDeliveryEnabled = data['cash_on_delivery_enabled'] as bool? ?? true;
    }
    if (!mounted) return;
    setState(() => _isLoaded = true);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await _AccountStateRepository.savePaymentSettings(
      widget.userId,
      {
        'upi_id': _upiController.text.trim(),
        'billing_name': _billingNameController.text.trim(),
        'preferred_method': _preferredMethod,
        'cash_on_delivery_enabled': _cashOnDeliveryEnabled,
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment preferences saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Payment methods')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionShell(
              title: 'Default payment setup',
              subtitle: 'Save your preferred checkout path for faster future orders.',
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _preferredMethod,
                    decoration: const InputDecoration(labelText: 'Preferred method'),
                    items: const [
                      DropdownMenuItem(value: 'cash_on_delivery', child: Text('Cash on delivery')),
                      DropdownMenuItem(value: 'upi', child: Text('UPI')),
                    ],
                    onChanged: (value) => setState(() => _preferredMethod = value ?? 'cash_on_delivery'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _billingNameController,
                    decoration: const InputDecoration(labelText: 'Billing name'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Enter billing name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _upiController,
                    decoration: const InputDecoration(labelText: 'UPI ID'),
                    validator: (value) {
                      if (_preferredMethod != 'upi') return null;
                      if (value == null || !value.contains('@')) return 'Enter a valid UPI ID';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Allow cash on delivery'),
                    subtitle: const Text('Keep COD available when stores support it.'),
                    value: _cashOnDeliveryEnabled,
                    onChanged: (value) => setState(() => _cashOnDeliveryEnabled = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save payment settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class GstDetailsScreen extends StatefulWidget {
  final String userId;

  const GstDetailsScreen({super.key, required this.userId});

  @override
  State<GstDetailsScreen> createState() => _GstDetailsScreenState();
}

class _GstDetailsScreenState extends State<GstDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _businessNameController;
  late final TextEditingController _gstNumberController;
  late final TextEditingController _businessAddressController;
  var _active = false;
  var _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _gstNumberController = TextEditingController();
    _businessAddressController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _gstNumberController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await _AccountStateRepository.loadGstProfile(widget.userId);
    if (data.isNotEmpty) {
      _businessNameController.text = (data['business_name'] ?? '').toString();
      _gstNumberController.text = (data['gst_number'] ?? '').toString();
      _businessAddressController.text = (data['business_address'] ?? '').toString();
      _active = data['active'] as bool? ?? false;
    }
    if (!mounted) return;
    setState(() => _isLoaded = true);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await _AccountStateRepository.saveGstProfile(
      widget.userId,
      {
        'business_name': _businessNameController.text.trim(),
        'gst_number': _gstNumberController.text.trim().toUpperCase(),
        'business_address': _businessAddressController.text.trim(),
        'active': _active,
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GST details saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('GST details')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionShell(
              title: 'Business invoice details',
              subtitle: 'Use these saved business details for GST-ready invoices on eligible orders.',
              child: Column(
                children: [
                  TextFormField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(labelText: 'Business name'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Enter business name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _gstNumberController,
                    decoration: const InputDecoration(labelText: 'GST number'),
                    validator: (value) => value == null || value.trim().length < 8 ? 'Enter a valid GST number' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _businessAddressController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Business address'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Enter business address' : null,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Use GST details by default'),
                    subtitle: const Text('Apply these invoice details whenever GST billing is needed.'),
                    value: _active,
                    onChanged: (value) => setState(() => _active = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save GST details'),
            ),
          ],
        ),
      ),
    );
  }
}

class PromoCodesScreen extends StatelessWidget {
  final String userId;

  const PromoCodesScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promo codes')),
      body: FutureBuilder<List<String>>(
        future: _AccountStateRepository.loadPromoCodes(userId),
        builder: (context, snapshot) {
          final codes = snapshot.data ?? const [];
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (codes.isEmpty) {
            return _EmptyStateCard(
              icon: Icons.sell_outlined,
              title: 'No verified coupons available',
              body: 'Only approved platform or store-issued promo codes appear here. Once a valid coupon is issued to your account, it will surface in this section.',
              actionLabel: 'Copy support email',
              onTap: () async {
                await Clipboard.setData(const ClipboardData(text: 'support@zyromart.in'));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Support email copied')),
                );
              },
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final code = codes[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.sell_outlined, color: AppTheme.success),
                  title: Text(code, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Verified coupon ready for checkout'),
                ),
              );
            },
            separatorBuilder: (_, separatorIndex) => const SizedBox(height: 12),
            itemCount: codes.length,
          );
        },
      ),
    );
  }
}

class GiftCardScreen extends StatefulWidget {
  final String userId;

  const GiftCardScreen({super.key, required this.userId});

  @override
  State<GiftCardScreen> createState() => _GiftCardScreenState();
}

class _GiftCardScreenState extends State<GiftCardScreen> {
  final _controller = TextEditingController();
  double _balance = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _balance = await _AccountStateRepository.loadGiftBalance(widget.userId);
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _redeem() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid gift code')),
      );
      return;
    }
    final credit = ((code.codeUnits.fold<int>(0, (sum, value) => sum + value) % 400) + 100).toDouble();
    _balance += credit;
    await _AccountStateRepository.saveGiftBalance(widget.userId, _balance);
    _controller.clear();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gift balance updated by Rs ${credit.toInt()}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Claim gift card')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionShell(
            title: 'Available gift balance',
            subtitle: 'Apply valid store credit or gift vouchers against future orders.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rs ${_balance.toInt()}',
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Gift card code',
                    hintText: 'Enter issued code',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _redeem,
                    child: const Text('Redeem gift code'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RewardsScreen extends StatelessWidget {
  final String userId;

  const RewardsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderService>().pastOrders.where((order) => order.customerId == userId).toList();
    final completed = orders.where((order) => order.status.name == 'delivered').toList();
    final spend = completed.fold<double>(0, (sum, order) => sum + order.grandTotal);
    final points = (spend / 100).floor() * 2;
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Collected rewards')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionShell(
            title: 'Your loyalty overview',
            subtitle: 'Rewards build from completed orders and successful repeat purchases.',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MetricBlock(label: 'Points', value: '$points'),
                _MetricBlock(label: 'Completed', value: '${completed.length}'),
                _MetricBlock(label: 'Spend', value: formatter.format(spend)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionShell(
            title: 'Recent completed orders',
            subtitle: 'Rewards are tied to finished customer deliveries.',
            child: completed.isEmpty
                ? const Text(
                    'No completed orders yet. Rewards will begin accumulating after your first completed delivery.',
                    style: TextStyle(color: AppTheme.textMedium, height: 1.5),
                  )
                : Column(
                    children: completed
                        .take(8)
                        .map(
                          (order) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFFDF0D8),
                              child: Icon(Icons.workspace_premium_outlined, color: AppTheme.warning),
                            ),
                            title: Text(order.storeName),
                            subtitle: Text('Order ${order.id}'),
                            trailing: Text('+${(order.grandTotal / 100).floor() * 2} pts'),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<AppPreferencesService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Account privacy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionShell(
            title: 'Privacy controls',
            subtitle: 'Tune how much of your account data is surfaced across the browsing and delivery experience.',
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hide sensitive items'),
                  subtitle: const Text('Remove restricted categories from browse surfaces.'),
                  value: preferences.hideSensitiveItems,
                  onChanged: preferences.setHideSensitiveItems,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Marketing updates'),
                  subtitle: const Text('Allow campaign offers and rewards reminders.'),
                  value: preferences.marketingNotifications,
                  onChanged: preferences.setMarketingNotifications,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Two-factor verification'),
                  subtitle: const Text('Require an extra verification step for sensitive account changes.'),
                  value: preferences.twoFactorEnabled,
                  onChanged: preferences.setTwoFactorEnabled,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PasswordLoginSettingsScreen extends StatefulWidget {
  const PasswordLoginSettingsScreen({super.key});

  @override
  State<PasswordLoginSettingsScreen> createState() => _PasswordLoginSettingsScreenState();
}

class _PasswordLoginSettingsScreenState extends State<PasswordLoginSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    _emailController.text = _emailController.text.isEmpty ? auth.currentUser?.email ?? '' : _emailController.text;

    return Scaffold(
      appBar: AppBar(title: const Text('Password login')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionShell(
              title: 'Email and password access',
              subtitle: 'Set up a durable password login on top of your OTP-backed account so future sign-ins can use either method.',
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) => value == null || value.trim().length < 8 ? 'Minimum 8 characters' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm password'),
                    validator: (value) => value != _passwordController.text ? 'Passwords do not match' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final success = await auth.setupEmailPassword(
                  email: _emailController.text.trim(),
                  password: _passwordController.text,
                );
                if (!context.mounted) return;
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password login saved')),
                  );
                  return;
                }
                final errorMessage =
                    auth.errorMessage ?? 'Could not save password login.';
                if (errorMessage.toLowerCase().contains('already')) {
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Email already in use'),
                      content: const Text(
                        'This email is already linked with another account. Use a different email for this account, or sign in directly using that existing email.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(errorMessage)),
                );
              },
              child: const Text('Save password login'),
            ),
          ],
        ),
      ),
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _launch(BuildContext context, Uri uri, String fallback) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched || !context.mounted) return;
    await Clipboard.setData(ClipboardData(text: fallback));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$fallback copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help and support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionShell(
            title: 'Support options',
            subtitle: 'Use the fastest route depending on whether your issue is with delivery, billing, or account access.',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email support'),
                  subtitle: const Text('support@zyromart.in'),
                  onTap: () => _launch(
                    context,
                    Uri.parse('mailto:support@zyromart.in?subject=ZyroMart%20Support'),
                    'support@zyromart.in',
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.call_outlined),
                  title: const Text('Call support'),
                  subtitle: const Text('+91 1800 572 1111'),
                  onTap: () => _launch(context, Uri.parse('tel:+9118005721111'), '+91 1800 572 1111'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.question_answer_outlined),
                  title: const Text('Issue reporting'),
                  subtitle: const Text('Share order ID, store name, and the problem for faster routing.'),
                  onTap: () async {
                    await Clipboard.setData(
                      const ClipboardData(
                        text: 'Issue report template:\nOrder ID:\nStore:\nProblem:\nExpected resolution:',
                      ),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Issue template copied')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShareAppScreen extends StatelessWidget {
  const ShareAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const link = 'https://github.com/AustinKarasu/ZyroMart/releases/latest';
    return Scaffold(
      appBar: AppBar(title: const Text('Share the app')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _SectionShell(
          title: 'Invite someone to ZyroMart',
          subtitle: 'Use the release link below to share the latest Android build directly.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SelectableText(link, style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(const ClipboardData(text: link));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Release link copied')),
                    );
                  },
                  icon: const Icon(Icons.copy_all_outlined),
                  label: const Text('Copy latest release link'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AboutZyroMartScreen extends StatelessWidget {
  const AboutZyroMartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About ZyroMart')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SectionShell(
            title: 'Platform overview',
            subtitle: 'Quick-commerce storefront, store operations, delivery routing, and admin oversight are designed to stay connected through one shared order lifecycle.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('App family: customer, store owner, delivery, and admin'),
                SizedBox(height: 8),
                Text('Release train: phased architecture with live Supabase-backed ordering, tracking, notifications, and payout-state foundations'),
                SizedBox(height: 8),
                Text('Current public release line: v1.4.x'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WishlistProductTile extends StatelessWidget {
  final Product product;
  final bool saved;
  final VoidCallback onToggle;

  const _WishlistProductTile({
    required this.product,
    required this.saved,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFF3F6F7),
        backgroundImage: product.imageUrl.isNotEmpty ? NetworkImage(product.imageUrl) : null,
        child: product.imageUrl.isEmpty ? const Icon(Icons.shopping_bag_outlined) : null,
      ),
      title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('Rs ${product.price.toStringAsFixed(0)} | ${product.unit}'),
      trailing: IconButton(
        onPressed: onToggle,
        icon: Icon(saved ? Icons.favorite : Icons.favorite_border, color: AppTheme.primaryRed),
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: AppTheme.textMedium, height: 1.4)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  final String label;
  final String value;

  const _MetricBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: AppTheme.textMedium)),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onTap;

  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 52, color: AppTheme.primaryRed),
                const SizedBox(height: 16),
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(body, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMedium, height: 1.5)),
                const SizedBox(height: 18),
                ElevatedButton(onPressed: onTap, child: Text(actionLabel)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountStateRepository {
  static Future<Map<String, dynamic>> _loadRemoteState() async {
    if (!SupabaseService.isInitialized) return const {};
    return await SupabaseService.getUserAccountState() ?? const {};
  }

  static Future<List<_SavedAddress>> loadAddresses(
    String userId, {
    required String fallbackAddress,
  }) async {
    final remote = await _loadRemoteState();
    final remoteAddresses = remote['addresses'];
    if (remoteAddresses is List) {
      final addresses = remoteAddresses
          .map((entry) => _SavedAddress.fromJson(Map<String, dynamic>.from(entry as Map)))
          .toList();
      if (addresses.isNotEmpty) {
        return addresses;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final key = _ScopedAccountStore.addressesKey(userId);
    final stored = prefs.getStringList(key) ?? const [];
    final decoded = stored
        .map((entry) => _SavedAddress.fromJson(jsonDecode(entry) as Map<String, dynamic>))
        .toList();
    if (decoded.isEmpty && fallbackAddress.trim().isNotEmpty) {
      decoded.add(
        _SavedAddress(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          label: 'Primary',
          address: fallbackAddress.trim(),
          isDefault: true,
        ),
      );
      await prefs.setStringList(
        key,
        decoded.map((entry) => jsonEncode(entry.toJson())).toList(),
      );
    }
    if (decoded.isNotEmpty && SupabaseService.isInitialized) {
      await SupabaseService.upsertUserAccountState({
        'addresses': decoded.map((entry) => entry.toJson()).toList(),
      });
    }
    return decoded;
  }

  static Future<void> saveAddresses(String userId, List<_SavedAddress> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _ScopedAccountStore.addressesKey(userId),
      addresses.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
    if (SupabaseService.isInitialized) {
      await SupabaseService.upsertUserAccountState({
        'addresses': addresses.map((entry) => entry.toJson()).toList(),
      });
    }
  }

  static Future<List<String>> loadWishlist(String userId) async {
    final remote = await _loadRemoteState();
    final remoteIds = remote['wishlist_product_ids'];
    if (remoteIds is List && remoteIds.isNotEmpty) {
      return remoteIds.map((entry) => entry.toString()).toList();
    }
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_ScopedAccountStore.wishlistKey(userId)) ?? const [];
    if (ids.isNotEmpty && SupabaseService.isInitialized) {
      await SupabaseService.upsertUserAccountState({
        'wishlist_product_ids': ids,
      });
    }
    return ids;
  }

  static Future<void> saveWishlist(String userId, List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_ScopedAccountStore.wishlistKey(userId), ids);
    if (SupabaseService.isInitialized) {
      await SupabaseService.upsertUserAccountState({
        'wishlist_product_ids': ids,
      });
    }
  }

  static Future<Map<String, dynamic>> loadPaymentSettings(String userId) async {
    final remote = await _loadRemoteState();
    final remoteSettings = remote['payment_settings'];
    if (remoteSettings is Map && remoteSettings.isNotEmpty) {
      return Map<String, dynamic>.from(remoteSettings);
    }
    final prefs = await SharedPreferences.getInstance();
    final payload = prefs.getString(_ScopedAccountStore.paymentMethodsKey(userId));
    if (payload == null) return const {};
    final decoded = Map<String, dynamic>.from(jsonDecode(payload) as Map<String, dynamic>);
    if (SupabaseService.isInitialized) {
      await SupabaseService.upsertUserAccountState({'payment_settings': decoded});
    }
    return decoded;
  }

  static Future<void> savePaymentSettings(String userId, Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ScopedAccountStore.paymentMethodsKey(userId), jsonEncode(settings));
    if (SupabaseService.isInitialized) {
      await SupabaseService.upsertUserAccountState({'payment_settings': settings});
    }
  }

  static Future<Map<String, dynamic>> loadGstProfile(String userId) async {
    final remote = await _loadRemoteState();
    final remoteProfile = remote['gst_profile'];
    if (remoteProfile is Map && remoteProfile.isNotEmpty) {
      return Map<String, dynamic>.from(remoteProfile);
    }
    final prefs = await SharedPreferences.getInstance();
    final payload = prefs.getString(_ScopedAccountStore.gstKey(userId));
    if (payload == null) return const {};
    final decoded = Map<String, dynamic>.from(jsonDecode(payload) as Map<String, dynamic>);
    if (SupabaseService.isInitialized) {
      await SupabaseService.upsertUserAccountState({'gst_profile': decoded});
    }
    return decoded;
  }

  static Future<void> saveGstProfile(String userId, Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ScopedAccountStore.gstKey(userId), jsonEncode(profile));
    if (SupabaseService.isInitialized) {
      await SupabaseService.upsertUserAccountState({'gst_profile': profile});
    }
  }

  static Future<List<String>> loadPromoCodes(String userId) async {
    final remote = await _loadRemoteState();
    final remoteCodes = remote['promo_codes'];
    if (remoteCodes is List) {
      return remoteCodes.map((entry) => entry.toString()).toList();
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_ScopedAccountStore.promoCodesKey(userId)) ?? const [];
  }

  static Future<double> loadGiftBalance(String userId) async {
    final remote = await _loadRemoteState();
    final remoteBalance = remote['gift_balance'];
    if (remoteBalance is num) {
      return remoteBalance.toDouble();
    }
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getDouble(_ScopedAccountStore.giftBalanceKey(userId)) ?? 0;
    if (value > 0 && SupabaseService.isInitialized) {
      await SupabaseService.upsertUserAccountState({'gift_balance': value});
    }
    return value;
  }

  static Future<void> saveGiftBalance(String userId, double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_ScopedAccountStore.giftBalanceKey(userId), balance);
    if (SupabaseService.isInitialized) {
      await SupabaseService.upsertUserAccountState({'gift_balance': balance});
    }
  }
}

class _ScopedAccountStore {
  static String addressesKey(String userId) => 'account::$userId::addresses';
  static String wishlistKey(String userId) => 'account::$userId::wishlist';
  static String paymentMethodsKey(String userId) => 'account::$userId::payment_methods';
  static String gstKey(String userId) => 'account::$userId::gst';
  static String promoCodesKey(String userId) => 'account::$userId::promo_codes';
  static String giftBalanceKey(String userId) => 'account::$userId::gift_balance';
}

class _SavedAddress {
  final String id;
  final String label;
  final String address;
  final bool isDefault;

  const _SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.isDefault,
  });

  _SavedAddress copyWith({
    String? id,
    String? label,
    String? address,
    bool? isDefault,
  }) {
    return _SavedAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'address': address,
        'is_default': isDefault,
      };

  factory _SavedAddress.fromJson(Map<String, dynamic> json) {
    return _SavedAddress(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      isDefault: json['is_default'] as bool? ?? false,
    );
  }
}
