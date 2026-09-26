import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pumpq/app/route_names.dart';
import 'package:pumpq/core/constants/app_colors.dart';
import 'package:pumpq/features/pre_order/presentation/pre_order_screen.dart';
import 'package:pumpq/features/price_comparison/presentation/price_provider.dart';
import 'package:pumpq/models/fuel_posting_model.dart';

class PriceComparisonScreen extends ConsumerWidget {
  const PriceComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricesAsync = ref.watch(filteredFuelPricesProvider);
    final selectedFilter = ref.watch(fuelTypeFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Compare Prices')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<FuelTypeFilter>(
              segments: const [
                ButtonSegment(value: FuelTypeFilter.all, label: Text('All')),
                ButtonSegment(value: FuelTypeFilter.diesel, label: Text('Diesel')),
                ButtonSegment(value: FuelTypeFilter.ron95, label: Text('RON 95')),
              ],
              selected: {selectedFilter},
              onSelectionChanged: (selection) {
                ref.read(fuelTypeFilterProvider.notifier).select(selection.first);
              },
            ),
          ),
          Expanded(
            child: pricesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Could not load prices')),
              data: (prices) {
                if (prices.isEmpty) {
                  return const Center(child: Text('No stations found for this fuel type'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: prices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final posting = prices[index];
                    final isCheapest = index == 0;
                    return _PriceCard(
                      posting: posting,
                      isCheapest: isCheapest,
                      onTap: posting.availability
                          ? () => context.pushNamed(
                                AppRoute.preOrder,
                                extra: PreOrderArgs(
                                  stationId: posting.stationId,
                                  stationName: posting.stationName,
                                  fuelType: posting.fuelType,
                                  pricePerLiter: posting.price,
                                ),
                              )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.posting, required this.isCheapest, this.onTap});

  final FuelPostingModel posting;
  final bool isCheapest;
  final VoidCallback? onTap;

  Color _brandColor() {
    switch (posting.fuelBrand.toLowerCase()) {
      case 'shell': return const Color(0xFFFFD100);
      case 'petron': return const Color(0xFF003DA5);
      case 'caltex': return const Color(0xFFD8232A);
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isCheapest ? Border.all(color: AppColors.primary, width: 2) : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44, height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: _brandColor(), borderRadius: BorderRadius.circular(10)),
                child: Text(posting.fuelBrand.substring(0, 1),
                    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(posting.stationName, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('${posting.fuelBrand} · ${posting.fuelType}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        if (isCheapest)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                            child: const Text('Best price', style: TextStyle(color: AppColors.white, fontSize: 10)),
                          ),
                      ],
                    ),
                    if (!posting.availability) ...[
                      const SizedBox(height: 4),
                      const Text('Currently unavailable', style: TextStyle(color: AppColors.error, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₱${posting.price.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}