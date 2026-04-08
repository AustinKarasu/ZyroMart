import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../services/catalog_service.dart';
import '../../services/error_message_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class RestockSubscriptionsScreen extends StatefulWidget {
  const RestockSubscriptionsScreen({super.key});

  @override
  State<RestockSubscriptionsScreen> createState() =>
      _RestockSubscriptionsScreenState();
}

class _RestockSubscriptionsScreenState
    extends State<RestockSubscriptionsScreen> {
  final Map<String, _RestockPlan> _plansByProductId = <String, _RestockPlan>{};
  final TextEditingController _searchController = TextEditingController();
  bool _loading = false;
  bool _activeOnly = false;
  String? _errorMessage;
  bool _usingAccountStateFallback = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptions() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _plansByProductId.clear();
      _usingAccountStateFallback = false;
    });

    if (!SupabaseService.isInitialized) {
      setState(() {
        _loading = false;
        _errorMessage = SupabaseService.backendStatusMessage;
      });
      return;
    }

    try {
      final rows = await SupabaseService.getRestockSubscriptions();
      for (final row in rows) {
        final plan = _RestockPlan.fromRemoteRow(row);
        _plansByProductId[plan.productId] = plan;
      }
    } catch (error) {
      if (_looksLikeMissingRestockTable(error)) {
        final remoteState = await SupabaseService.getUserAccountState();
        final appPreferences = remoteState?['app_preferences'];
        final payload = appPreferences is Map
            ? appPreferences['restock_subscriptions']
            : null;
        if (payload is List) {
          for (final entry in payload) {
            if (entry is! Map) continue;
            final plan = _RestockPlan.fromFallbackMap(
              Map<String, dynamic>.from(entry),
            );
            _plansByProductId[plan.productId] = plan;
          }
        }
        _usingAccountStateFallback = true;
      } else {
        _errorMessage = ErrorMessageService.from(error, fallback: 'Could not load live restock subscriptions right now. Please try again.');
      }
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  bool _looksLikeMissingRestockTable(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('user_restock_subscriptions') ||
        text.contains('pgrst205');
  }

  Future<void> _savePlan(_RestockPlan plan) async {
    try {
      await SupabaseService.upsertRestockSubscription(plan.toRemotePayload());
      if (mounted) {
        setState(() {
          _usingAccountStateFallback = false;
        });
      }
      return;
    } catch (error) {
      if (!_looksLikeMissingRestockTable(error)) {
        rethrow;
      }
    }

    final remoteState = await SupabaseService.getUserAccountState();
    final appPreferences = Map<String, dynamic>.from(
      (remoteState?['app_preferences'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
    final mergedPlans = Map<String, _RestockPlan>.from(_plansByProductId)
      ..[plan.productId] = plan;
    appPreferences['restock_subscriptions'] = mergedPlans.values
        .map((entry) => entry.toFallbackPayload())
        .toList();
    await SupabaseService.upsertUserAccountState({
      'app_preferences': appPreferences,
    });
    if (mounted) {
      setState(() {
        _usingAccountStateFallback = true;
      });
    }
  }

  Future<void> _togglePlan(Product product, bool enabled) async {
    final current = _plansByProductId[product.id] ??
        _RestockPlan.initial(productId: product.id, productName: product.name);
    final updated = current.copyWith(productName: product.name, isActive: enabled);
    final previous = _plansByProductId[product.id];
    setState(() {
      _plansByProductId[product.id] = updated;
    });
    try {
      await _savePlan(updated);
      _showMessage(
        enabled
            ? 'Auto-restock saved for ${product.name}.'
            : 'Auto-restock paused for ${product.name}.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (previous == null) {
          _plansByProductId.remove(product.id);
        } else {
          _plansByProductId[product.id] = previous;
        }
      });
      _showMessage(
        'Could not save live restock subscription. $error',
        isError: true,
      );
    }
  }

  Future<void> _updatePlan(
    Product product, {
    String? cadence,
    int? quantity,
    TimeOfDay? time,
  }) async {
    final current = _plansByProductId[product.id] ??
        _RestockPlan.initial(productId: product.id, productName: product.name);
    final updated = current.copyWith(
      productName: product.name,
      cadence: cadence,
      quantity: quantity,
      reminderTime: time,
      isActive: true,
    );
    final previous = _plansByProductId[product.id];
    setState(() {
      _plansByProductId[product.id] = updated;
    });
    try {
      await _savePlan(updated);
      _showMessage('Restock plan updated for ${product.name}.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (previous == null) {
          _plansByProductId.remove(product.id);
        } else {
          _plansByProductId[product.id] = previous;
        }
      });
      _showMessage(
        'Could not save live restock subscription. $error',
        isError: true,
      );
    }
  }

  Future<void> _pickTime(Product product) async {
    final current = _plansByProductId[product.id] ??
        _RestockPlan.initial(productId: product.id, productName: product.name);
    final picked = await showTimePicker(
      context: context,
      initialTime: current.reminderTime,
    );
    if (picked == null) return;
    await _updatePlan(product, time: picked);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogService>();
    final query = _searchController.text.trim().toLowerCase();
    final activePlans = _plansByProductId.values.where((plan) => plan.isActive).toList()
      ..sort((a, b) => a.nextRunAt.compareTo(b.nextRunAt));
    final filteredProducts = catalog.products.where((product) {
      final matchesQuery = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.unit.toLowerCase().contains(query);
      final matchesActive =
          !_activeOnly || (_plansByProductId[product.id]?.isActive ?? false);
      return matchesQuery && matchesActive;
    }).take(24).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Auto-restock')),
      body: _loading && _plansByProductId.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _heroPanel(),
                const SizedBox(height: 18),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search milk, atta, bread, eggs, snacks',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show active plans only'),
                  subtitle: const Text(
                    'Focus on essentials that already have a cadence and reminder time.',
                  ),
                  value: _activeOnly,
                  onChanged: (value) => setState(() {
                    _activeOnly = value;
                  }),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _RestockStateCard(
                    icon: Icons.cloud_off_rounded,
                    title: 'Live restock subscriptions need attention',
                    subtitle: _errorMessage!,
                    actionLabel: 'Retry',
                    onAction: _loadSubscriptions,
                    tone: const Color(0xFFFDEBE8),
                  ),
                ],
                if (_usingAccountStateFallback) ...[
                  const SizedBox(height: 12),
                  const _RestockStateCard(
                    icon: Icons.sync_problem_rounded,
                    title: 'Using account-state backup',
                    subtitle: 'The live restock table is missing in this backend right now. Plans are being stored in your account state until the schema is applied.',
                    tone: Color(0xFFFFF3E1),
                  ),
                ],
                if (activePlans.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'Scheduled next',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  ...activePlans.take(3).map(_activePlanTile),
                ],
                const SizedBox(height: 18),
                const Text(
                  'Build your restock plan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                if (filteredProducts.isEmpty)
                  _RestockStateCard(
                    icon: Icons.search_off_rounded,
                    title: 'No products match this search',
                    subtitle: 'Try another keyword or clear the active-only filter.',
                    actionLabel: 'Clear filters',
                    onAction: () async {
                      _searchController.clear();
                      setState(() {
                        _activeOnly = false;
                      });
                    },
                  )
                else
                  ...filteredProducts.map(_productTile),
              ],
            ),
    );
  }

  Widget _heroPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF173321), Color(0xFF244832)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Restock essentials on your schedule',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Search an item, pick daily, weekly, or monthly, choose quantity and reminder time, and keep the plan synced to your account.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activePlanTile(_RestockPlan plan) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE9F5EC),
          child: Icon(Icons.autorenew_rounded, color: Color(0xFF1D8C3A)),
        ),
        title: Text(plan.productName, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          '${plan.cadenceLabel} • ${plan.quantity} unit${plan.quantity == 1 ? '' : 's'} • ${_formatTime(plan.reminderTime)}',
        ),
        trailing: Text(
          plan.nextRunLabel,
          style: const TextStyle(
            color: AppTheme.textMedium,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _productTile(Product product) {
    final plan = _plansByProductId[product.id] ??
        _RestockPlan.initial(productId: product.id, productName: product.name);
    final active = plan.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rs ${product.price.toStringAsFixed(0)} • ${product.unit}',
                        style: const TextStyle(
                          color: AppTheme.textMedium,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: active,
                  onChanged: (value) => _togglePlan(product, value),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: plan.cadence,
                    decoration: const InputDecoration(labelText: 'Cadence'),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    ],
                    onChanged: active
                        ? (value) {
                            if (value == null) return;
                            _updatePlan(product, cadence: value);
                          }
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: plan.quantity,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    items: const [1, 2, 3, 4, 5]
                        .map(
                          (value) => DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value unit${value == 1 ? '' : 's'}'),
                          ),
                        )
                        .toList(),
                    onChanged: active
                        ? (value) {
                            if (value == null) return;
                            _updatePlan(product, quantity: value);
                          }
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: active ? () => _pickTime(product) : null,
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(
                      active
                          ? _formatTime(plan.reminderTime)
                          : 'Pick reminder time',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _togglePlan(product, true),
                    icon: const Icon(Icons.autorenew_rounded),
                    label: Text(active ? 'Update plan' : 'Start auto-restock'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.primaryRed : AppTheme.success,
      ),
    );
  }
}

class _RestockPlan {
  const _RestockPlan({
    required this.productId,
    required this.productName,
    required this.cadence,
    required this.quantity,
    required this.reminderTime,
    required this.isActive,
  });

  final String productId;
  final String productName;
  final String cadence;
  final int quantity;
  final TimeOfDay reminderTime;
  final bool isActive;

  factory _RestockPlan.initial({
    required String productId,
    required String productName,
  }) {
    return _RestockPlan(
      productId: productId,
      productName: productName,
      cadence: 'weekly',
      quantity: 1,
      reminderTime: const TimeOfDay(hour: 9, minute: 0),
      isActive: false,
    );
  }

  factory _RestockPlan.fromRemoteRow(Map<String, dynamic> row) {
    final nextRun = DateTime.tryParse((row['next_run_at'] ?? '').toString()) ??
        DateTime.now().add(const Duration(days: 7));
    final product = row['products'];
    final productName = product is Map
        ? (product['name'] ?? 'Product').toString()
        : 'Product';
    return _RestockPlan(
      productId: (row['product_id'] ?? '').toString(),
      productName: productName,
      cadence: (row['cadence'] ?? 'weekly').toString(),
      quantity: (row['quantity'] ?? 1) as int,
      reminderTime: TimeOfDay(hour: nextRun.hour, minute: nextRun.minute),
      isActive: row['is_active'] != false,
    );
  }

  factory _RestockPlan.fromFallbackMap(Map<String, dynamic> map) {
    return _RestockPlan(
      productId: (map['product_id'] ?? '').toString(),
      productName: (map['product_name'] ?? 'Product').toString(),
      cadence: (map['cadence'] ?? 'weekly').toString(),
      quantity: (map['quantity'] ?? 1) as int,
      reminderTime: TimeOfDay(
        hour: (map['reminder_hour'] ?? 9) as int,
        minute: (map['reminder_minute'] ?? 0) as int,
      ),
      isActive: map['is_active'] != false,
    );
  }

  _RestockPlan copyWith({
    String? productName,
    String? cadence,
    int? quantity,
    TimeOfDay? reminderTime,
    bool? isActive,
  }) {
    return _RestockPlan(
      productId: productId,
      productName: productName ?? this.productName,
      cadence: cadence ?? this.cadence,
      quantity: quantity ?? this.quantity,
      reminderTime: reminderTime ?? this.reminderTime,
      isActive: isActive ?? this.isActive,
    );
  }

  String get cadenceLabel =>
      '${cadence[0].toUpperCase()}${cadence.substring(1)}';

  DateTime get nextRunAt {
    final now = DateTime.now();
    var next = DateTime(
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
    );
    if (!next.isAfter(now)) {
      switch (cadence) {
        case 'daily':
          next = next.add(const Duration(days: 1));
          break;
        case 'monthly':
          next = DateTime(
            next.year,
            next.month + 1,
            next.day,
            next.hour,
            next.minute,
          );
          break;
        default:
          next = next.add(const Duration(days: 7));
      }
    }
    return next;
  }

  String get nextRunLabel {
    final difference = nextRunAt.difference(DateTime.now()).inDays;
    if (difference <= 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    return 'In $difference days';
  }

  Map<String, dynamic> toRemotePayload() {
    return {
      'product_id': productId,
      'cadence': cadence,
      'quantity': quantity,
      'is_active': isActive,
      'next_run_at': nextRunAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFallbackPayload() {
    return {
      'product_id': productId,
      'product_name': productName,
      'cadence': cadence,
      'quantity': quantity,
      'is_active': isActive,
      'reminder_hour': reminderTime.hour,
      'reminder_minute': reminderTime.minute,
      'next_run_at': nextRunAt.toIso8601String(),
    };
  }
}

class _RestockStateCard extends StatelessWidget {
  const _RestockStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.tone = Colors.white,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final Future<void> Function()? onAction;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppTheme.textMedium),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textMedium, height: 1.45),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => onAction!.call(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

