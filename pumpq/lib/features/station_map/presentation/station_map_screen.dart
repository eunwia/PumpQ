import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pumpq/core/constants/app_colors.dart';
import 'package:pumpq/features/station_map/presentation/station_provider.dart';
import 'package:pumpq/models/station_model.dart';

class StationMapScreen extends ConsumerStatefulWidget {
  const StationMapScreen({super.key});

  @override
  ConsumerState<StationMapScreen> createState() => _StationMapScreenState();
}

class _StationMapScreenState extends ConsumerState<StationMapScreen> {
  static const _cebuCity = LatLng(10.3157, 123.8854);
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _centerOnUserLocation();
  }

  Future<void> _centerOnUserLocation() async {
    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14,
        ),
      );
    } catch (_) {
      // Keep the default Cebu City view if location can't be read.
    }
  }

  Future<bool> _ensureLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Set<Marker> _buildMarkers(List<StationModel> stations) {
    return stations.map((station) {
      return Marker(
        markerId: MarkerId(station.stationId.toString()),
        position: LatLng(station.latitude, station.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          station.isOpen ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(
          title: station.name,
          snippet: '${station.fuelBrand} · ${station.isOpen ? "Open" : "Closed"}',
        ),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(nearbyStationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Station Map')),
      body: stationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Could not load stations', style: TextStyle(color: AppColors.error)),
        ),
        data: (stations) => GoogleMap(
          initialCameraPosition: const CameraPosition(target: _cebuCity, zoom: 12),
          onMapCreated: (controller) {
            _mapController = controller;
            _centerOnUserLocation();
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          markers: _buildMarkers(stations),
        ),
      ),
    );
  }
}