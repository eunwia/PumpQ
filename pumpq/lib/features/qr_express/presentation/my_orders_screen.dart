import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pumpq/app/route_names.dart';
import 'package:pumpq/core/constants/app_colors.dart';
import 'package:pumpq/features/pre_order/presentation/order_provider.dart';
import 'package:pumpq/features/pre_order/presentation/pre_order_screen.dart';
import 'package:pumpq/features/price_comparison/presentation/price_provider.dart';
import 'package:pumpq/features/station_map/presentation/station_provider.dart';
import 'package:pumpq/models/order_model.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  String _filter = 'All';

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
  Widget build(BuildContext context) {
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
            final filtered = orders.where((o) {
              if (_filter == 'All') return true;
              return o.status == _filter.toLowerCase();
            }).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            final Map<String, List<OrderModel>> grouped = {};
            for (final o in filtered) {
              grouped.putIfAbsent(_sectionLabel(o.createdAt), () => []).add(o);
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['All', 'Pending', 'Completed', 'Cancelled'].map((f) {
                        final selected = _filter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: selected,
                            onSelected: (_) => setState(() => _filter = f),
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(color: selected ? AppColors.white : AppColors.textPrimary, fontSize: 12),
                            backgroundColor: AppColors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: orders.isEmpty
                      ? const Center(child: Text('No orders yet', style: TextStyle(color: AppColors.textSecondary)))
                      : filtered.isEmpty
                          ? const Center(child: Text('No orders match this filter', style: TextStyle(color: AppColors.textSecondary)))
                          : ListView(
                              padding: const EdgeInsets.all(20),
                              children: grouped.entries.expand((entry) {
                                return [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13)),
                                  ),
                                  ...entry.value.map((o) => Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _OrderCard(order: o),
                                      )),
                                ];
                              }).toList(),
                            ),
                ),
              ],
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
      default: return const Color(0xFFF5A623);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stations = ref.watch(nearbyStationsProvider).asData?.value ?? [];
    final station = stations.where((s) => s.stationId == order.stationId).firstOrNull;
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Order #${order.orderId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Text('${months[order.createdAt.month - 1]} ${order.createdAt.day}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          _row('Station', station?.name ?? '—'),
          _row('Fuel Type', '${order.liters.toStringAsFixed(1)}L ${order.fuelType}'),
          _row('Total Amount', '₱${order.amount.toStringAsFixed(2)}'),
          _row(
            'Payment',
            order.paymentStatus == 'unpaid' ? 'Unpaid' : order.paymentStatus == 'paid_wallet' ? 'Paid (Wallet)' : 'Pay at Station',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _statusColor().withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Text(order.status.toUpperCase(), style: TextStyle(color: _statusColor(), fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              const Spacer(),
              _ActionButtons(order: order, station: station, ref: ref),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.order, required this.station, required this.ref});
  final OrderModel order;
  final dynamic station;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (order.status == 'pending') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(0, 32),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        onPressed: () => context.pushNamed(AppRoute.orderDetail, pathParameters: {'orderId': order.orderId.toString()}),
        child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      );
    }

    return SizedBox(
      height: 32,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
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
              fuelType: order.fuelType,
              pricePerLiter: posting.price,
              stationName: station.name,
            ),
          );
        },
        child: const Text('Order Again', style: TextStyle(fontSize: 12)),
      ),
    );
  }
}