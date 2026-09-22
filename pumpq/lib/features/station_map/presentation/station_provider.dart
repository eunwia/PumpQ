import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pumpq/features/station_map/data/station_repository.dart';
import 'package:pumpq/models/station_model.dart';

final stationRepositoryProvider = Provider<StationRepository>((ref) {
  return StationRepository();
});

final nearbyStationsProvider = FutureProvider<List<StationModel>>((ref) {
  return ref.watch(stationRepositoryProvider).getNearbyStations();
});