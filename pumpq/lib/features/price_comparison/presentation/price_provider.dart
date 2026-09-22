import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pumpq/features/auth/presentation/auth_provider.dart';
import 'package:pumpq/features/price_comparison/data/price_repository.dart';
import 'package:pumpq/models/fuel_posting_model.dart';

final priceRepositoryProvider = Provider<PriceRepository>((ref) {
  return PriceRepository(ref.watch(apiServiceProvider));
});

final fuelPricesProvider = FutureProvider<List<FuelPostingModel>>((ref) {
  return ref.watch(priceRepositoryProvider).getFuelPrices();
});

enum FuelTypeFilter { all, diesel, ron95 }

class FuelTypeFilterNotifier extends Notifier<FuelTypeFilter> {
  @override
  FuelTypeFilter build() => FuelTypeFilter.all;

  void select(FuelTypeFilter filter) => state = filter;
}

final fuelTypeFilterProvider =
    NotifierProvider<FuelTypeFilterNotifier, FuelTypeFilter>(FuelTypeFilterNotifier.new);

final filteredFuelPricesProvider = Provider<AsyncValue<List<FuelPostingModel>>>((ref) {
  final pricesAsync = ref.watch(fuelPricesProvider);
  final filter = ref.watch(fuelTypeFilterProvider);

  return pricesAsync.whenData((prices) {
    final filtered = filter == FuelTypeFilter.all
        ? prices
        : prices.where((p) {
            return filter == FuelTypeFilter.diesel
                ? p.fuelType == 'Diesel'
                : p.fuelType == 'RON 95';
          }).toList();

    filtered.sort((a, b) => a.price.compareTo(b.price));
    return filtered;
  });
});