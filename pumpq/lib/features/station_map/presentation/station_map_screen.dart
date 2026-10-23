import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pumpq/core/constants/app_colors.dart';
import 'package:pumpq/features/price_comparison/presentation/price_provider.dart';
import 'package:pumpq/features/station_map/presentation/station_provider.dart';
import 'package:pumpq/models/station_model.dart';
import 'package:go_router/go_router.dart';
import 'package:pumpq/app/route_names.dart';
import 'package:pumpq/features/pre_order/presentation/pre_order_screen.dart';
import 'package:pumpq/models/fuel_posting_model.dart';

class StationMapScreen extends ConsumerStatefulWidget {
  const StationMapScreen({super.key});

  @override
  ConsumerState<StationMapScreen> createState() => _StationMapScreenState();
}

class _StationMapScreenState extends ConsumerState<StationMapScreen> {
  static const _cebuCity = LatLng(10.3157, 123.8854);
  GoogleMapController? _mapController;
  String _filter = 'All';
  String _search = '';

  StationModel? _pendingStation;

  @override
  void initState() {
    super.initState();
    _centerOnUserLocation();
  }

  Future<void> _centerOnUserLocation() async {
    if (!await _ensureLocationPermission()) return;
    try {
      final position = await Geolocator.getCurrentPosition();
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 14),
      );
    } catch (_) {}
  }

  Future<bool> _ensureLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Set<Marker> _buildMarkers(List<StationModel> stations, List<FuelPostingModel> prices) {
    return stations.map((s) {
      return Marker(
        markerId: MarkerId(s.stationId.toString()),
        position: LatLng(s.latitude, s.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          s.isOpen ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
        onTap: () => _showStationSheet(s, prices),
      );
    }).toSet();
  }

  void _showStationSheet(StationModel station, List<FuelPostingModel> allPrices) {
    final stationPrices = allPrices.where((p) => p.stationId == station.stationId).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _StationSheet(station: station, prices: stationPrices),
    );
  }

  void _openStation(StationModel station, List<FuelPostingModel> allPrices) {
    if (_mapController != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(station.latitude, station.longitude), 15),
      );
    } else {
      _pendingStation = station;
    }
    _showStationSheet(station, allPrices);
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(nearbyStationsProvider);
    final pricesAsync = ref.watch(fuelPricesProvider);

    final selectedOnEntry = ref.read(selectedStationProvider);
    if (selectedOnEntry != null) {
      final prices = pricesAsync.asData?.value ?? [];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(selectedStationProvider.notifier).clear();
        _openStation(selectedOnEntry, prices);
      });
    }

    ref.listen<StationModel?>(selectedStationProvider, (prev, selected) {
      if (selected != null) {
        final prices = ref.read(fuelPricesProvider).asData?.value ?? [];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(selectedStationProvider.notifier).clear();
          _openStation(selected, prices);
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: stationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Could not load stations')),
          data: (stations) {
            final prices = pricesAsync.asData?.value ?? [];
            final filtered = stations.where((s) {
              final matchesSearch = _search.isEmpty ||
                  s.name.toLowerCase().contains(_search.toLowerCase()) ||
                  s.location.toLowerCase().contains(_search.toLowerCase());
              if (!matchesSearch) return false;
              if (_filter == 'All') return true;
              if (_filter == 'Best Deal') return true;
              return prices.any((p) => p.stationId == s.stationId && p.fuelType == _filter);
            }).toList();

            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Text('Find Stations', style: Theme.of(context).textTheme.headlineSmall),
                ),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: ['All', 'Diesel', 'RON 95', 'Best Deal'].map((f) {
                      final selected = _filter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: selected,
                          onSelected: (_) => setState(() => _filter = f),
                          selectedColor: AppColors.textPrimary,
                          labelStyle: TextStyle(color: selected ? AppColors.white : AppColors.textPrimary),
                          backgroundColor: AppColors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 260,
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: const CameraPosition(target: _cebuCity, zoom: 12),
                          onMapCreated: (c) {
                            _mapController = c;
                            if (_pendingStation != null) {
                              final s = _pendingStation!;
                              _pendingStation = null;
                              c.animateCamera(CameraUpdate.newLatLngZoom(LatLng(s.latitude, s.longitude), 15));
                            } else {
                              _centerOnUserLocation();
                            }
                          },
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          markers: _buildMarkers(filtered, prices),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Material(
                            elevation: 3,
                            borderRadius: BorderRadius.circular(14),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search stations, areas...',
                                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                                filled: true,
                                fillColor: AppColors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (v) => setState(() => _search = v),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Partner Stations Nearby', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 12),
                                ...filtered.map((s) {
                  final stationPrices = prices.where((p) => p.stationId == s.stationId).toList();
                  final price = stationPrices.isEmpty
                      ? null
                      : stationPrices.reduce((a, b) => a.price < b.price ? a : b);
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: GestureDetector(
                      onTap: () => _showStationSheet(s, prices),
                      child: _StationListTile(station: s, price: price?.price),
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StationListTile extends StatelessWidget {
  const _StationListTile({required this.station, required this.price});
  final StationModel station;
  final double? price;

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
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.background),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: _brandColor(), borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text(
              station.fuelBrand.isNotEmpty ? station.fuelBrand.substring(0, 1) : 'P',
              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(station.name, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(station.isOpen ? '✓ Open' : 'Closed',
                    style: TextStyle(color: station.isOpen ? AppColors.success : AppColors.error, fontSize: 12)),
              ],
            ),
          ),
          if (price != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₱${price!.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                const Text('per liter', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
        ],
      ),
    );
  }
}

class _StationSheet extends StatefulWidget {
  const _StationSheet({required this.station, required this.prices});
  final StationModel station;
  final List<FuelPostingModel> prices;

  @override
  State<_StationSheet> createState() => _StationSheetState();
}

class _StationSheetState extends State<_StationSheet> {
  FuelPostingModel? _selected;

  @override
  void initState() {
    super.initState();
    final available = widget.prices.where((p) => p.availability).toList();
    if (available.isNotEmpty) {
      available.sort((a, b) => a.price.compareTo(b.price));
      _selected = available.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.prices.where((p) => p.availability).toList()
      ..sort((a, b) => a.price.compareTo(b.price));
    final cheapestId = available.isNotEmpty ? available.first.fuelType : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(widget.station.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(widget.station.location, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          if (widget.prices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No fuel data for this station', style: TextStyle(color: AppColors.textSecondary)),
            )
          else
            ...widget.prices.map((p) {
              final selected = _selected?.fuelType == p.fuelType;
              final isBest = p.fuelType == cheapestId;
              return GestureDetector(
                onTap: p.availability ? () => setState(() => _selected = p) : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.availability ? AppColors.white : AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.background,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        p.fuelType == 'Diesel' ? Icons.local_gas_station : Icons.local_fire_department,
                        color: p.availability ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(p.fuelType, style: const TextStyle(fontWeight: FontWeight.w600)),
                                if (isBest && p.availability) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                                    child: const Text('Best Price', style: TextStyle(color: AppColors.white, fontSize: 10)),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              p.availability ? 'In stock' : 'Unavailable',
                              style: TextStyle(
                                color: p.availability ? AppColors.success : AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₱${p.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: p.availability ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selected == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      context.pushNamed(
                        AppRoute.preOrder,
                        extra: PreOrderArgs(
                          stationId: widget.station.stationId,
                          stationName: widget.station.name,
                          fuelType: _selected!.fuelType,
                          pricePerLiter: _selected!.price,
                        ),
                      );
                    },
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}