import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pumpq/app/route_names.dart';
import 'package:pumpq/core/constants/app_colors.dart';
import 'package:pumpq/features/pre_order/presentation/order_provider.dart';
import 'package:pumpq/features/promotions/presentation/promotion_provider.dart';
import 'package:pumpq/features/station_map/presentation/station_provider.dart';
import 'package:pumpq/models/order_model.dart';
import 'package:pumpq/models/station_model.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final int orderId;

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref, int orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this pre-order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(orderRepositoryProvider).cancelOrder(orderId);
      ref.invalidate(myOrdersProvider);
      if (context.mounted) context.pop();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not cancel order')),
        );
      }
    }
  }

  Future<void> _pay(BuildContext context, WidgetRef ref, int orderId, String method) async {
    await ref.read(payOrderProvider.notifier).pay(orderId, method);
    if (!context.mounted) return;
    final state = ref.read(payOrderProvider);
    if (state.success) {
      ref.read(payOrderProvider.notifier).reset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(method == 'wallet' ? 'Paid via wallet' : 'Set to pay at station')),
      );
    } else if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
    }
  }

  void _showCouponDialog(BuildContext context, WidgetRef ref, int orderId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Coupon'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Enter coupon code')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(applyCouponProvider.notifier).apply(orderId, controller.text.trim());
              if (context.mounted) {
                final state = ref.read(applyCouponProvider);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.success ? 'Coupon applied!' : (state.error ?? 'Failed'))),
                );
                ref.read(applyCouponProvider.notifier).reset();
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);
    final stationsAsync = ref.watch(nearbyStationsProvider);
    final payState = ref.watch(payOrderProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load order')),
        data: (orders) {
          final order = orders.where((o) => o.orderId == orderId).firstOrNull;
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return stationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Could not load station')),
            data: (stations) {
              final station = stations.where((s) => s.stationId == order.stationId).firstOrNull;

              return ListView(
                children: [
                  if (station != null) _StationMapPreview(station: station),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (station != null) ...[
                          Text(station.name, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(station.location, style: const TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: 20),
                        ],
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.background),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _detailRow('Order #', '${order.orderId}'),
                              _detailRow('Fuel Type', order.fuelType),
                              _detailRow('Liters', '${order.liters.toStringAsFixed(1)} L'),
                              _detailRow('Amount', '₱${order.amount.toStringAsFixed(2)}'),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Status', style: TextStyle(color: AppColors.textSecondary)),
                                  Text(
                                    order.status.toUpperCase(),
                                    style: TextStyle(color: _statusColor(order.status), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Payment', style: TextStyle(color: AppColors.textSecondary)),
                                  Text(
                                    order.paymentStatus == 'unpaid'
                                        ? 'UNPAID'
                                        : order.paymentStatus == 'paid_wallet'
                                            ? 'PAID (WALLET)'
                                            : 'PAY AT STATION',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (order.status == 'pending' && order.paymentStatus == 'unpaid') ...[
                          TextButton.icon(
                            onPressed: () => _showCouponDialog(context, ref, order.orderId),
                            icon: const Icon(Icons.local_offer_outlined, size: 18),
                            label: const Text('Have a coupon?'),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (order.status == 'pending') ...[
                          if (order.paymentStatus == 'unpaid') ...[
                            const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: payState.isLoading
                                        ? null
                                        : () => _pay(context, ref, order.orderId, 'wallet'),
                                    icon: const Icon(Icons.account_balance_wallet, size: 18),
                                    label: const Text('Pay via Wallet'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: payState.isLoading
                                        ? null
                                        : () => _pay(context, ref, order.orderId, 'offline'),
                                    icon: const Icon(Icons.storefront, size: 18),
                                    label: const Text('Pay at Station'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => context.pushNamed(
                                AppRoute.qrExpress,
                                pathParameters: {'orderId': order.orderId.toString()},
                              ),
                              icon: const Icon(Icons.qr_code),
                              label: const Text('Generate QR Code'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => _confirmCancel(context, ref, order.orderId),
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                              child: const Text('Cancel Order'),
                            ),
                          ),
                        ],
                      ],
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StationMapPreview extends StatelessWidget {
  const _StationMapPreview({required this.station});
  final StationModel station;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(station.latitude, station.longitude),
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: MarkerId(station.stationId.toString()),
            position: LatLng(station.latitude, station.longitude),
          ),
        },
        zoomControlsEnabled: false,
        scrollGesturesEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
      ),
    );
  }
}