import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pumpq/app/route_names.dart';
import 'package:pumpq/core/constants/app_colors.dart';
import 'package:pumpq/features/pre_order/presentation/order_provider.dart';
import 'package:pumpq/models/order_model.dart';
import 'package:pumpq/features/station_map/presentation/station_provider.dart';
import 'package:pumpq/app/route_names.dart';
import 'package:pumpq/features/pre_order/presentation/pre_order_screen.dart';
import 'package:pumpq/features/price_comparison/presentation/price_provider.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myOrdersProvider.future),
        child: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Could not load orders')),
          data: (orders) {
            if (orders.isEmpty) {
              return const Center(child: Text('No orders yet'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _OrderCard(order: orders[index]),
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
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: Text(
                      (station?.fuelBrand.isNotEmpty ?? false) ? station!.fuelBrand[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${order.liters.toStringAsFixed(1)}L ${order.fuelType}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('₱${order.amount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(order.status.toUpperCase(), style: TextStyle(color: _statusColor(), fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (!canReorder) const Icon(Icons.chevron_right, color: AppColors.textSecondary),
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