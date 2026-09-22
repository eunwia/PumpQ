import 'package:pumpq/core/services/api_service.dart';
import 'package:pumpq/models/loyalty_model.dart';

class LoyaltyRepository {
  LoyaltyRepository(this._api);
  final ApiService _api;

  Future<LoyaltyModel> getLoyalty() async {
    final response = await _api.client.get('/loyalty');
    final data = response.data['data']['loyalty'] as Map<String, dynamic>;
    return LoyaltyModel.fromJson(data);
  }

  Future<List<LoyaltyTransactionModel>> getHistory() async {
    final response = await _api.client.get('/loyalty/history');
    final data = response.data['data']['transactions'] as List;
    return data
        .map((e) => LoyaltyTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}