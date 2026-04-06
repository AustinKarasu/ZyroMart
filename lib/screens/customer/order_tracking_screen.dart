import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/slide_to_confirm.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  bool _showingRatingSheet = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F2),
      appBar: AppBar(title: Text('Order #${widget.orderId}')),
      body: Consumer<OrderService>(
        builder: (context, orderService, _) {
          final order = orderService.getOrder(widget.orderId);
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_showingRatingSheet &&
                orderService.shouldPromptCustomerForRating(order.id) &&
                mounted) {
              _showingRatingSheet = true;
              orderService.markCustomerPromptSeen(order.id);
              _showRatingSheet(context, orderService, order).whenComplete(() {
                _showingRatingSheet = false;
              });
            }
          });

          return Column(
            children: [
              Expanded(flex: 3, child: _buildMap(order)),
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatusPanel(context, orderService, order),
                      const SizedBox(height: 14),
                      if (order.status == OrderStatus.outForDelivery)
                        _buildDeliveryOtpCard(orderService, order),
                      if (order.status == OrderStatus.outForDelivery)
                        const SizedBox(height: 14),
                      if (order.deliveryPersonName != null)
                        _buildPartnerCard(order, orderService),
                      if (order.deliveryPersonName != null)
                        const SizedBox(height: 14),
                      _buildAddressCard(order),
                      const SizedBox(height: 14),
                      _buildItemsCard(order),
                      const SizedBox(height: 14),
                      _buildTimelineCard(orderService, order),
                      if (order.status == OrderStatus.delivered)
                        const SizedBox(height: 14),
                      if (order.status == OrderStatus.delivered)
                        _buildProofCard(orderService, order),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(Order order) {
    final markers = <Marker>[
      Marker(
        point: order.storeLocation,
        width: 40,
        height: 40,
        child: const Icon(Icons.store, color: AppTheme.primaryRed, size: 36),
      ),
      Marker(
        point: order.customerLocation,
        width: 40,
        height: 40,
        child: const Icon(Icons.home, color: AppTheme.info, size: 36),
      ),
    ];

    if (order.deliveryPersonLocation != null &&
        order.status == OrderStatus.outForDelivery) {
      markers.add(
        Marker(
          point: order.deliveryPersonLocation!,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryRed,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              Icons.delivery_dining,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: order.deliveryPersonLocation ?? order.storeLocation,
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
              points:
                  order.status == OrderStatus.outForDelivery &&
                      order.deliveryPersonLocation != null
                  ? [
                      order.storeLocation,
                      order.deliveryPersonLocation!,
                      order.customerLocation,
                    ]
                  : [order.storeLocation, order.customerLocation],
              color: AppTheme.primaryRed,
              strokeWidth: 4,
            ),
          ],
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildStatusPanel(
    BuildContext context,
    OrderService orderService,
    Order order,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _statusColor(order.status).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _statusIcon(order.status),
                  color: _statusColor(order.status),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.statusLabel,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _statusColor(order.status),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusDescription(order.status),
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
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: order.statusProgress,
              backgroundColor: const Color(0xFFEAEAEA),
              valueColor: AlwaysStoppedAnimation<Color>(
                _statusColor(order.status),
              ),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Placed', style: TextStyle(color: AppTheme.textLight)),
              Text('Delivered', style: TextStyle(color: AppTheme.textLight)),
            ],
          ),
          if (orderService.canCustomerCancel(order)) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: SlideToConfirm(
                label: 'Slide to cancel order',
                confirmLabel: 'Cancelling...',
                icon: Icons.keyboard_double_arrow_right_rounded,
                backgroundColor: AppTheme.primaryRed,
                onConfirmed: () async {
                  final cancelled = orderService.cancelOrder(order.id);
                  if (!mounted) return cancelled;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        cancelled
                            ? 'Order cancelled within the 5-minute window.'
                            : 'This order can no longer be cancelled.',
                      ),
                    ),
                  );
                  return cancelled;
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartnerCard(Order order, OrderService orderService) {
    final feedback = orderService.feedbackForOrder(order.id);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primaryRed,
                child: Text(
                  order.deliveryPersonName![0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.deliveryPersonName!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const Text(
                      'Delivery partner',
                      style: TextStyle(color: AppTheme.textMedium),
                    ),
                    Text(
                      order.status == OrderStatus.delivered
                          ? 'Delivery completed'
                          : 'Phone verified for order updates',
                      style: const TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.phone_outlined, color: AppTheme.primaryRed),
            ],
          ),
          if (feedback != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF8F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'You rated this delivery ${feedback.rating}/5${feedback.feedback.isEmpty ? '' : ' • ${feedback.feedback}'}',
                style: const TextStyle(
                  color: Color(0xFF196F2A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressCard(Order order) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, color: AppTheme.primaryRed),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Address',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  order.deliveryAddress,
                  style: const TextStyle(
                    color: AppTheme.textMedium,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOtpCard(OrderService orderService, Order order) {
    final code = orderService.deliveryCodeForCustomer(order.id);
    if (code == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery OTP',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Share this 4-digit code with the delivery partner only when your order arrives.',
            style: TextStyle(color: AppTheme.textMedium, height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              code,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                letterSpacing: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(OrderService orderService, Order order) {
    final events = orderService.statusEventsForOrder(order.id);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live order timeline',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const Text(
              'Status changes will appear here as the store and delivery partner update the order.',
              style: TextStyle(color: AppTheme.textMedium),
            )
          else
            ...events.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (event['next_status'] ?? 'updated')
                                .toString()
                                .replaceAll('_', ' '),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (event['notes'] ?? '').toString(),
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
    );
  }

  Widget _buildProofCard(OrderService orderService, Order order) {
    final proof = orderService.proofOfDeliveryForOrder(order.id);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Proof of delivery',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 10),
          Text(
            proof == null
                ? 'Delivery proof will be stored after OTP verification is completed.'
                : 'OTP verified and handed to ${(proof['handed_to_name'] ?? order.customerName).toString()}.',
            style: const TextStyle(color: AppTheme.textMedium, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(Order order) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Items Ordered',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 12),
          ...order.items.map(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total paid',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              Text(
                'Rs ${order.grandTotal.toInt()}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppTheme.primaryRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showRatingSheet(
    BuildContext context,
    OrderService orderService,
    Order order,
  ) async {
    final feedbackController = TextEditingController();
    var rating = 5;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
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
                    'Rate your delivery',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How was ${order.deliveryPersonName ?? 'your delivery partner'} on order ${order.id}?',
                    style: const TextStyle(color: AppTheme.textMedium),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        onPressed: () =>
                            setModalState(() => rating = index + 1),
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFB627),
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: feedbackController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Share quick feedback for the rider',
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        orderService.submitDeliveryFeedback(
                          orderId: order.id,
                          rating: rating,
                          feedback: feedbackController.text,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Submit rating'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return AppTheme.info;
      case OrderStatus.confirmed:
        return Colors.indigo;
      case OrderStatus.preparing:
        return AppTheme.warning;
      case OrderStatus.readyForPickup:
        return Colors.deepPurple;
      case OrderStatus.outForDelivery:
        return AppTheme.primaryRed;
      case OrderStatus.delivered:
        return AppTheme.success;
      case OrderStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _statusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return Icons.receipt_long;
      case OrderStatus.confirmed:
        return Icons.check_circle;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.readyForPickup:
        return Icons.inventory_2_outlined;
      case OrderStatus.outForDelivery:
        return Icons.delivery_dining;
      case OrderStatus.delivered:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String _statusDescription(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Your order is in the store queue.';
      case OrderStatus.confirmed:
        return 'The store has confirmed and accepted the order.';
      case OrderStatus.preparing:
        return 'Your basket is currently being packed.';
      case OrderStatus.readyForPickup:
        return 'Packed and waiting for rider pickup.';
      case OrderStatus.outForDelivery:
        return 'The delivery partner is on the way.';
      case OrderStatus.delivered:
        return 'Delivered successfully. Settlement and rating are now available.';
      case OrderStatus.cancelled:
        return 'This order was cancelled before completion.';
    }
  }
}
