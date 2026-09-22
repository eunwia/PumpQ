import 'package:pumpq/models/fuel_posting_model.dart';

class PriceRepository {
  // TODO: replace with GET /api/fuel once the backend endpoint exists.
  Future<List<FuelPostingModel>> getFuelPrices() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      FuelPostingModel(
        priceId: 1,
        stationId: 1,
        stationName: 'Shell Cebu IT Park',
        fuelBrand: 'Shell',
        fuelType: 'Diesel',
        price: 58.50,
        availability: true,
      ),
      FuelPostingModel(
        priceId: 2,
        stationId: 1,
        stationName: 'Shell Cebu IT Park',
        fuelBrand: 'Shell',
        fuelType: 'RON 95',
        price: 62.30,
        availability: true,
      ),
      FuelPostingModel(
        priceId: 3,
        stationId: 2,
        stationName: 'Petron Ayala Center',
        fuelBrand: 'Petron',
        fuelType: 'Diesel',
        price: 57.90,
        availability: true,
      ),
      FuelPostingModel(
        priceId: 4,
        stationId: 2,
        stationName: 'Petron Ayala Center',
        fuelBrand: 'Petron',
        fuelType: 'RON 95',
        price: 61.80,
        availability: false,
      ),
      FuelPostingModel(
        priceId: 5,
        stationId: 3,
        stationName: 'Caltex Gorordo Ave',
        fuelBrand: 'Caltex',
        fuelType: 'Diesel',
        price: 58.10,
        availability: true,
      ),
    ];
  }
}