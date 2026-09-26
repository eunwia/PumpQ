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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Image.asset('assets/images/pumpq_icon.png', height: 32),
        const SizedBox(width: 8),
        const Text('Hello!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
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
        TextButton(onPressed: () => context.goNamed(AppRoute.stationMap), child: const Text('View Map →')),
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

class _StationTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.background)),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: _brandColor(), borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text(station.fuelBrand.substring(0, 1),
                style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(station.name, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (distanceKm != null)
                      Text('${distanceKm!.toStringAsFixed(1)} km · ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text(station.isOpen ? '✓ Open' : 'Closed',
                        style: TextStyle(color: station.isOpen ? AppColors.success : AppColors.error, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          if (price != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₱${price!.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                const Text('per liter', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
        ],
      ),
    );
  }
}