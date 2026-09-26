import 'package:pumpq/core/services/api_service.dart';
import 'package:pumpq/models/promotion_model.dart';

class PromotionRepository {
  PromotionRepository(this._api);
  final ApiService _api;

  Future<List<PromotionModel>> getPromotions() async {
    final response = await _api.client.get('/promotions');
    final data = response.data['data']['promotions'] as List;
    return data.map((e) => PromotionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> applyCoupon(int orderId, String couponCode) async {
    final response = await _api.client.post('/promotions/apply', data: {
      'order_id': orderId,
      'coupon_code': couponCode,
    });
    return response.data['data']['order'] as Map<String, dynamic>;
  }
}