import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pumpq/app/route_names.dart';
import 'package:pumpq/core/constants/app_colors.dart';
import 'package:pumpq/features/pre_order/presentation/order_provider.dart';
import 'package:pumpq/features/price_comparison/presentation/price_provider.dart';
import 'package:pumpq/features/station_map/presentation/station_provider.dart';
import 'package:pumpq/models/order_model.dart';
import 'package:pumpq/features/pre_order/presentation/pre_order_screen.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  String _sectionLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0, title: const Text('My Orders')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myOrdersProvider.future),
        child: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Could not load orders')),
          data: (orders) {
            if (orders.isEmpty) {
              return const Center(child: Text('No orders yet', style: TextStyle(color: AppColors.textSecondary)));
            }

            final sorted = [...orders]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            final Map<String, List<OrderModel>> grouped = {};
            for (final o in sorted) {
              final label = _sectionLabel(o.createdAt);
              grouped.putIfAbsent(label, () => []).add(o);
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: grouped.entries.expand((entry) {
                return [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 10),
                    child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13)),
                  ),
                  ...entry.value.map((o) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OrderCard(order: o),
                      )),
                ];
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});
  final OrderModel order;

  Color _statusColor() {
    switch (order.status) {
      case 'completed': return AppColors.success;
      case 'cancelled': return AppColors.error;
      default: return AppColors.primary;
    }
  }

  IconData _statusIcon() {
    switch (order.status) {
      case 'completed': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      default: return Icons.access_time_filled;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stations = ref.watch(nearbyStationsProvider).asData?.value ?? [];
    final station = stations.where((s) => s.stationId == order.stationId).firstOrNull;
    final canReorder = order.status == 'completed' || order.status == 'cancelled';

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.pushNamed(AppRoute.orderDetail, pathParameters: {'orderId': order.orderId.toString()}),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44, height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      (station?.fuelBrand.isNotEmpty ?? false) ? station!.fuelBrand[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station?.name ?? '${order.fuelType} order',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text('${order.liters.toStringAsFixed(1)}L ${order.fuelType}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₱${order.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon(), color: _statusColor(), size: 12),
                          const SizedBox(width: 4),
                          Text(order.status.toUpperCase(), style: TextStyle(color: _statusColor(), fontWeight: FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (canReorder) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      if (station == null) return;
                      final prices = ref.read(fuelPricesProvider).asData?.value ?? [];
                      final posting = prices.where((p) => p.stationId == station.stationId && p.fuelType == order.fuelType).firstOrNull;
                      if (posting == null || !posting.availability) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('This fuel type is currently unavailable at this station')),
                        );
                        return;
                      }
                      context.pushNamed(
                        AppRoute.preOrder,
                        extra: PreOrderArgs(
                          stationId: station.stationId,
                          stationName: station.name,
                          fuelType: order.fuelType,
                          pricePerLiter: posting.price,
                        ),
                      );
                    },
                    child: const Text('Order Again'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}