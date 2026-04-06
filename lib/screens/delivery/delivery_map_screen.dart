import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/operator_preferences_service.dart';
import '../../services/order_service.dart';
import '../../services/mock_data.dart';
import '../../theme/app_theme.dart';
import 'delivery_detail_screen.dart';

class DeliveryMapScreen extends StatelessWidget {
  const DeliveryMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Map')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: OperatorPreferencesService.load(
          appVariant: 'delivery',
          userId: context.read<AuthService>().currentUser?.id ?? 'guest',
        ),
        builder: (context, preferenceSnapshot) {
          final preferences = preferenceSnapshot.data ?? const <String, dynamic>{};
          return Consumer<OrderService>(
        builder: (context, orderService, _) {
          final location = context.watch<LocationService>();
          final activeOrders = orderService.orders
              .where((o) =>
                  o.status == OrderStatus.readyForPickup ||
                  o.status == OrderStatus.outForDelivery)
              .toList();
          final shareLiveLocation =
              preferences['share_live_location'] as bool? ?? true;
          final proofChecklist =
              preferences['proof_checklist'] as bool? ?? true;
          final emergencyShortcut =
              preferences['emergency_shortcut'] as bool? ?? true;
          final preferredMapMode =
              (preferences['preferred_map_mode'] ?? 'balanced').toString();
          final handoffTemplate = (preferences['handoff_template'] ??
                  'Delivered to customer after OTP verification.')
              .toString();

          final markers = <Marker>[];

          // Add store markers
          for (final store in MockData.stores) {
            markers.add(Marker(
              point: store.location,
              width: 40,
              height: 40,
              child: const Tooltip(
                message: 'Store',
                child: Icon(Icons.store, color: AppTheme.primaryRed, size: 36),
              ),
            ));
          }

          // Add delivery targets and current positions
          for (final order in activeOrders) {
            markers.add(Marker(
              point: order.customerLocation,
              width: 36,
              height: 36,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DeliveryDetailScreen(order: order),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.info,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.home, color: Colors.white, size: 20),
                ),
              ),
            ));

            if (order.deliveryPersonLocation != null) {
              markers.add(Marker(
                point: order.deliveryPersonLocation!,
                width: 44,
                height: 44,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DeliveryDetailScreen(order: order),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.delivery_dining,
                        color: Colors.white, size: 24),
                  ),
                ),
              ));
            }
          }

          final polylines = <Polyline>[];
          for (final order in activeOrders) {
            if (order.deliveryPersonLocation != null) {
              final polylineColor = switch (preferredMapMode) {
                'fastest' => AppTheme.primaryRed,
                'safer' => AppTheme.info,
                _ => AppTheme.primaryRed.withValues(alpha: 0.6),
              };
              final polylinePattern = switch (preferredMapMode) {
                'fastest' => StrokePattern.solid(),
                'safer' => StrokePattern.dashed(segments: [6, 5]),
                _ => StrokePattern.dotted(),
              };
              polylines.add(Polyline(
                points: [
                  order.storeLocation,
                  order.deliveryPersonLocation!,
                  order.customerLocation,
                ],
                color: polylineColor,
                strokeWidth: 3,
                pattern: polylinePattern,
              ));
            }
          }

          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter:
                      location.currentLocation ?? MockData.deliveryPersons[0].location,
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.zyromart.app',
                  ),
                  PolylineLayer(polylines: polylines),
                  MarkerLayer(markers: markers),
                ],
              ),
              // Legend
              if (!location.hasUsableLocation)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_off_outlined,
                            color: AppTheme.warning),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Enable location to center the map on your live position.',
                            style: TextStyle(
                              color: AppTheme.textMedium,
                              fontSize: 13,
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
                ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${activeOrders.length} Active Deliveries',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      if (proofChecklist)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F9FC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Handoff note: $handoffTemplate',
                            style: const TextStyle(
                              color: AppTheme.textMedium,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      if (emergencyShortcut)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Emergency help shortcut is enabled for active routes.'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.emergency_share_outlined),
                              label: const Text('Emergency help ready'),
                            ),
                          ),
                        ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: !shareLiveLocation || activeOrders.isEmpty
                              ? null
                              : () async {
                                  await location.refreshLocation();
                                  final liveLocation = location.currentLocation;
                                  if (liveLocation == null) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            location.errorMessage ??
                                                'Could not refresh live route.',
                                          ),
                                        ),
                                      );
                                    }
                                    return;
                                  }
                                  for (final order in activeOrders.where(
                                    (item) => item.deliveryPersonId != null,
                                  )) {
                                    await orderService.updateDeliveryLocation(
                                      orderId: order.id,
                                      location: liveLocation,
                                    );
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Live location synced for active deliveries using $preferredMapMode route mode.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.my_location_rounded),
                          label: Text(
                            shareLiveLocation
                                ? 'Sync my live position'
                                : 'Live location disabled',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.store,
                              color: AppTheme.primaryRed, size: 18),
                          const SizedBox(width: 4),
                          const Text('Store',
                              style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 16),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryRed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.delivery_dining,
                                color: Colors.white, size: 12),
                          ),
                          const SizedBox(width: 4),
                          const Text('Delivery',
                              style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 16),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: AppTheme.info,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.home,
                                color: Colors.white, size: 12),
                          ),
                          const SizedBox(width: 4),
                          const Text('Customer',
                              style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
        },
      ),
    );
  }
}
