import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order.dart';
import '../../services/location_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';

class DeliveryDetailScreen extends StatelessWidget {
  final Order order;

  const DeliveryDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final otpController = TextEditingController();
    final recipientController = TextEditingController();
    final proofNotesController = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: Text('Delivery #${order.id}')),
      body: Consumer<OrderService>(
        builder: (context, orderService, _) {
          final currentOrder = orderService.getOrder(order.id) ?? order;
          final routeUpdates = orderService.routeUpdatesForOrder(order.id);
          final proof = orderService.proofOfDeliveryForOrder(order.id);
          final locationService = context.watch<LocationService>();
          return Column(
            children: [
              // Map
              Expanded(
                flex: 2,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: currentOrder.storeLocation,
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.zyromart.app',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [
                            currentOrder.storeLocation,
                            if (currentOrder.deliveryPersonLocation != null)
                              currentOrder.deliveryPersonLocation!,
                            currentOrder.customerLocation,
                          ],
                          color: AppTheme.primaryRed,
                          strokeWidth: 3,
                          pattern: const StrokePattern.dotted(),
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: currentOrder.storeLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.store, color: AppTheme.primaryRed, size: 36),
                        ),
                        Marker(
                          point: currentOrder.customerLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.home, color: AppTheme.info, size: 36),
                        ),
                        if (currentOrder.deliveryPersonLocation != null)
                          Marker(
                            point: currentOrder.deliveryPersonLocation!,
                            width: 44,
                            height: 44,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primaryRed,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: const Icon(Icons.delivery_dining, color: Colors.white, size: 24),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Order info
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: AppTheme.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('#${currentOrder.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                Text(currentOrder.statusLabel,
                                    style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 24),
                            // Pickup
                            _buildLocationRow(
                              Icons.store,
                              'Pickup from',
                              currentOrder.storeName,
                              '123 Main Street, Sector 15',
                              AppTheme.primaryRed,
                            ),
                            const SizedBox(height: 16),
                            // Drop-off
                            _buildLocationRow(
                              Icons.location_on,
                              'Deliver to',
                              currentOrder.customerName,
                              currentOrder.deliveryAddress,
                              AppTheme.info,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Items
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order Items (${currentOrder.itemCount})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 12),
                            ...currentOrder.items.map((item) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${item.product.name} x${item.quantity}'),
                                      Text('₹${item.totalPrice.toInt()}'),
                                    ],
                                  ),
                                )),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('₹${currentOrder.grandTotal.toInt()}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryRed)),
                              ],
                            ),
                            if (currentOrder.notes != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.note, color: AppTheme.warning, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(currentOrder.notes!, style: const TextStyle(fontSize: 13))),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF4FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.route_rounded,
                                      color: AppTheme.info, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      locationService.hasUsableLocation
                                          ? 'Live rider GPS is available. Tap update below to refresh the route.'
                                          : 'Enable device location to publish live route updates for this order.',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Customer contact
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primaryRed,
                              child: Text(currentOrder.customerName[0], style: const TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(currentOrder.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(currentOrder.customerPhone, style: const TextStyle(color: AppTheme.textMedium, fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone, color: AppTheme.primaryRed),
                              onPressed: () => _launchContactAction(
                                context,
                                Uri.parse('tel:${currentOrder.customerPhone}'),
                                'Could not open phone dialer.',
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.message, color: AppTheme.primaryRed),
                              onPressed: () => _launchContactAction(
                                context,
                                Uri.parse('sms:${currentOrder.customerPhone}'),
                                'Could not open messaging app.',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Route activity',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (routeUpdates.isEmpty)
                              const Text(
                                'Route updates will appear here once live location sharing starts.',
                                style: TextStyle(
                                  color: AppTheme.textMedium,
                                  height: 1.4,
                                ),
                              )
                            else
                              ...routeUpdates.take(4).map(
                                (update) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEAF4FF),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.route_rounded,
                                          color: AppTheme.info,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _routeHeadline(update),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _routeSubtitle(update),
                                              style: const TextStyle(
                                                color: AppTheme.textMedium,
                                                height: 1.35,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Proof checkpoint',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              proof == null
                                  ? 'The final handoff record will be attached here after OTP verification is completed.'
                                  : 'Delivered to ${(proof['handed_to_name'] ?? currentOrder.customerName).toString()} • ${(proof['notes'] ?? 'No delivery notes').toString()}',
                              style: const TextStyle(
                                color: AppTheme.textMedium,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<OrderService>(
        builder: (context, orderService, _) {
          final currentOrder = orderService.getOrder(order.id) ?? order;
          final locationService = context.read<LocationService>();
          if (currentOrder.status == OrderStatus.delivered ||
              currentOrder.status == OrderStatus.cancelled) {
            return const SizedBox.shrink();
          }
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: SizedBox(
              height: 50,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await locationService.refreshLocation();
                        final liveLocation = locationService.currentLocation;
                        if (liveLocation == null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  locationService.errorMessage ??
                                      'Could not update live location.',
                                ),
                                backgroundColor: AppTheme.primaryRed,
                              ),
                            );
                          }
                          return;
                        }
                        await orderService.updateDeliveryLocation(
                          orderId: currentOrder.id,
                          location: liveLocation,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Live route updated for this delivery.'),
                              backgroundColor: AppTheme.info,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.my_location_rounded),
                      label: const Text('Update'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (currentOrder.status == OrderStatus.readyForPickup) {
                          orderService.updateOrderStatus(
                            currentOrder.id,
                            OrderStatus.outForDelivery,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Order picked up. Collect the customer OTP at handoff to complete delivery.',
                              ),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                          return;
                        }

                        final verified = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => Padding(
                            padding: EdgeInsets.only(
                              left: 20,
                              right: 20,
                              top: 20,
                              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Verify customer OTP',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Ask the customer for the 4-digit delivery code shown in their order tracking screen.',
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'Delivery OTP',
                                    prefixIcon: Icon(Icons.pin_outlined),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: recipientController,
                                  decoration: const InputDecoration(
                                    labelText: 'Received by',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: proofNotesController,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'Delivery notes',
                                    prefixIcon: Icon(Icons.note_alt_outlined),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final success = orderService.completeDeliveryWithCode(
                                        currentOrder.id,
                                        otpController.text,
                                        handedToName: recipientController.text,
                                        proofNotes: proofNotesController.text,
                                      );
                                      Navigator.pop(context, success);
                                    },
                                    child: const Text('Verify and complete'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                        if (verified == true) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Order delivered successfully.'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          }
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Incorrect delivery OTP.'),
                              backgroundColor: AppTheme.primaryRed,
                            ),
                          );
                        }
                      },
                      child: Text(
                        currentOrder.status == OrderStatus.readyForPickup
                            ? 'Pick Up Order'
                            : 'Mark as Delivered',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationRow(
      IconData icon, String label, String name, String address, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(address, style: TextStyle(color: AppTheme.textMedium, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  static Future<void> _launchContactAction(
    BuildContext context,
    Uri uri,
    String fallbackMessage,
  ) async {
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(fallbackMessage),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }

  String _routeHeadline(Map<String, dynamic> update) {
    final etaMinutes = (update['eta_minutes'] as num?)?.round();
    if (etaMinutes == null) {
      return 'Location ping received';
    }
    return 'ETA updated to $etaMinutes min';
  }

  String _routeSubtitle(Map<String, dynamic> update) {
    final capturedAt =
        DateTime.tryParse((update['captured_at'] ?? '').toString());
    final speed = (update['speed_kmph'] as num?)?.toDouble();
    final pieces = <String>[
      if (capturedAt != null) DateFormat('dd MMM, hh:mm a').format(capturedAt),
      if (speed != null) '${speed.toStringAsFixed(1)} km/h',
      'Lat ${(update['latitude'] as num?)?.toStringAsFixed(4) ?? '--'}',
      'Lng ${(update['longitude'] as num?)?.toStringAsFixed(4) ?? '--'}',
    ];
    return pieces.join(' • ');
  }
}
