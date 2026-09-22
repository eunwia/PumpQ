import 'package:pumpq/core/services/api_service.dart';
import 'package:pumpq/models/station_model.dart';

class StationRepository {
  StationRepository(this._api);
  final ApiService _api;

  Future<List<StationModel>> getNearbyStations() async {
    final response = await _api.client.get('/stations');
    final data = response.data['data']['stations'] as List;
    return data
        .map((e) => StationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}