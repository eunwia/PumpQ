import 'package:pumpq/models/station_model.dart';

class StationRepository {
  // TODO: replace with a real call to GET /api/stations/nearby once the
  // backend endpoint exists. Everything else stays the same.
  Future<List<StationModel>> getNearbyStations() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      StationModel(
        stationId: 1,
        name: 'Shell Cebu IT Park',
        fuelBrand: 'Shell',
        location: 'Cebu IT Park, Cebu City',
        latitude: 10.3300,
        longitude: 123.9050,
        isOpen: true,
      ),
      StationModel(
        stationId: 2,
        name: 'Petron Ayala Center',
        fuelBrand: 'Petron',
        location: 'Ayala Center Cebu',
        latitude: 10.3175,
        longitude: 123.9052,
        isOpen: true,
      ),
      StationModel(
        stationId: 3,
        name: 'Caltex Gorordo Ave',
        fuelBrand: 'Caltex',
        location: 'Gorordo Avenue, Cebu City',
        latitude: 10.3245,
        longitude: 123.9030,
        isOpen: false,
      ),
    ];
  }
}