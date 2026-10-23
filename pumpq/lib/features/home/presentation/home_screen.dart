import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:pumpq/app/route_names.dart';
import 'package:pumpq/core/constants/app_colors.dart';
import 'package:pumpq/features/loyalty_rewards/presentation/loyalty_provider.dart';
import 'package:pumpq/features/price_comparison/presentation/price_provider.dart';
import 'package:pumpq/features/station_map/presentation/station_provider.dart';
import 'package:pumpq/features/wallet/presentation/wallet_provider.dart';
import 'package:pumpq/features/notifications/presentation/notifications_provider.dart';
import 'package:pumpq/models/fuel_posting_model.dart';
import 'package:pumpq/models/station_model.dart';

final userPositionProvider = FutureProvider<Position?>((ref) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      return await Geolocator.getCurrentPosition();
    }
  } catch (_) {}
  return null;
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(walletProvider);
            ref.invalidate(loyaltyProvider);
            ref.invalidate(nearbyStationsProvider);
            ref.invalidate(fuelPricesProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              const _HeaderRow(),
              const SizedBox(height: 16),
              const _BalanceCard(),
              const SizedBox(height: 20),
              const _QuickAccessGrid(),
              const SizedBox(height: 24),
              const _NearbyStationsHeader(),
              const SizedBox(height: 12),
              const _NearbyStationsList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends ConsumerWidget {
  const _HeaderRow();

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showNotificationsSheet(BuildContext context, WidgetRef ref) {
    ref.read(notificationsProvider.notifier).load();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final notifications = ref.watch(notificationsProvider);
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (notifications.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${notifications.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        if (notifications.isNotEmpty)
                          TextButton(
                            onPressed: () => ref.read(notificationsProvider.notifier).clearAll(),
                            child: const Text('Clear all', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (notifications.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.notifications_none, size: 36, color: AppColors.textSecondary),
                        SizedBox(height: 10),
                        Text(
                          'No notifications yet',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Price alerts, station updates, and refuel reminders will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        final isPrice = item.title.contains('Price') || item.title.contains('⛽');
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isPrice ? Colors.orange.shade50 : AppColors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isPrice ? Icons.local_gas_station : Icons.notifications_active_outlined,
                                  color: isPrice ? Colors.orange.shade800 : AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                        Text(
                                          _timeAgo(item.receivedAt),
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.body,
                                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => ref.read(notificationsProvider.notifier).removeNotification(item.id),
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return Row(
      children: [
        Image.asset('assets/images/pumpq_icon.png', height: 32),
        const SizedBox(width: 8),
        const Text('Hello!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => _showNotificationsSheet(context, ref),
            ),
            if (notifications.isNotEmpty)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AVAILABLE BALANCE', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              walletAsync.when(
                data: (w) => Text('₱${w.balance.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                loading: () => const SizedBox(
                  height: 28, width: 28,
                  child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                ),
                error: (_, __) => const Text('—', style: TextStyle(color: AppColors.white, fontSize: 26)),
              ),
              SizedBox(
                width: 110,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => context.goNamed(AppRoute.wallet),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Cash In', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid();

  static const _items = [
    (icon: Icons.local_gas_station, label: 'Order Fuel', route: AppRoute.stationMap),
    (icon: Icons.receipt_long, label: 'My Orders', route: AppRoute.myOrders),
    (icon: Icons.map, label: 'Station Map', route: AppRoute.stationMap),
    (icon: Icons.price_change, label: 'Prices', route: AppRoute.priceComparison),
    (icon: Icons.card_giftcard, label: 'Rewards', route: AppRoute.loyaltyRewards),
    (icon: Icons.insights, label: 'Insights', route: AppRoute.insights),
    (icon: Icons.account_balance_wallet, label: 'Wallet', route: AppRoute.wallet),
    (icon: Icons.local_offer, label: 'Promotions', route: AppRoute.promotions),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 8,
      childAspectRatio: 0.8,
      children: _items.map((item) {
        return GestureDetector(
          onTap: () => context.pushNamed(item.route),
          child: Column(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
                child: Icon(item.icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(height: 6),
              Text(item.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _NearbyStationsHeader extends StatelessWidget {
  const _NearbyStationsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Nearby Stations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        InkWell(
          onTap: () => context.goNamed(AppRoute.stationMap),
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View Map',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NearbyStationsList extends ConsumerWidget {
  const _NearbyStationsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationsAsync = ref.watch(nearbyStationsProvider);
    final pricesAsync = ref.watch(fuelPricesProvider);
    final positionAsync = ref.watch(userPositionProvider);

    return stationsAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
      error: (_, __) => const Text('Could not load stations'),
      data: (stations) {
        return pricesAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (prices) {
            final position = positionAsync.asData?.value;
            final items = stations.map((s) {
              final stationPrices = prices.where((p) => p.stationId == s.stationId).toList();
              final cheapest = stationPrices.isEmpty ? null : stationPrices.reduce((a, b) => a.price < b.price ? a : b);
              double? distanceKm;
              if (position != null) {
                distanceKm = Geolocator.distanceBetween(position.latitude, position.longitude, s.latitude, s.longitude) / 1000;
              }
              return (station: s, price: cheapest, distanceKm: distanceKm);
            }).toList()
              ..sort((a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));

            return Column(
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StationTile(station: item.station, price: item.price, distanceKm: item.distanceKm),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _StationTile extends ConsumerWidget {
  const _StationTile({required this.station, required this.price, required this.distanceKm});
  final StationModel station;
  final FuelPostingModel? price;
  final double? distanceKm;

  Color _brandColor() {
    switch (station.fuelBrand.toLowerCase()) {
      case 'shell': return const Color(0xFFFFD100);
      case 'petron': return const Color(0xFF003DA5);
      case 'caltex': return const Color(0xFFD8232A);
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        ref.read(selectedStationProvider.notifier).select(station);
        context.goNamed(AppRoute.stationMap);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.background)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44, height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _brandColor(), borderRadius: BorderRadius.circular(10)),
              child: Text(
                station.fuelBrand.isNotEmpty ? station.fuelBrand.substring(0, 1) : 'P',
                style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(station.name, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 4,
                    children: [
                      if (distanceKm != null)
                        Text('${distanceKm!.toStringAsFixed(1)} km ·', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text(station.isOpen ? '✓ Open' : 'Closed',
                          style: TextStyle(color: station.isOpen ? AppColors.success : AppColors.error, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (price != null)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₱${price!.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const Text('per liter', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _InsightsBanner extends StatelessWidget {
  const _InsightsBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed(AppRoute.insights),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.textPrimary, borderRadius: BorderRadius.circular(16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 42, height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.insights, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Smart Insights', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('Budget tracking & refuel predictions', style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}