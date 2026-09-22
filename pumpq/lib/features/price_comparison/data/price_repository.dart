import 'package:pumpq/core/services/api_service.dart';
import 'package:pumpq/models/fuel_posting_model.dart';

class PriceRepository {
  PriceRepository(this._api);
  final ApiService _api;

  Future<List<FuelPostingModel>> getFuelPrices() async {
    final response = await _api.client.get('/stations/fuel');
    final data = response.data['data']['prices'] as List;
    return data
        .map((e) => FuelPostingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}