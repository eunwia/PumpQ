import 'package:pumpq/core/services/api_service.dart';
import 'package:pumpq/models/order_model.dart';

class OrderRepository {
  OrderRepository(this._api);
  final ApiService _api;

  Future<OrderModel> createOrder({
    required int stationId,
    required String fuelType,
    required double liters,
  }) async {
    final response = await _api.client.post('/orders', data: {
      'station_id': stationId,
      'fuel_type': fuelType,
      'liters': liters,
    });
    final data = response.data['data']['order'] as Map<String, dynamic>;
    return OrderModel.fromJson(data);
  }

  Future<List<OrderModel>> getOrders() async {
    final response = await _api.client.get('/orders');
    final data = response.data['data']['orders'] as List;
    return data
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  Future<OrderModel> cancelOrder(int orderId) async {
    final response = await _api.client.put('/orders/$orderId/cancel');
    final data = response.data['data']['order'] as Map<String, dynamic>;
    return OrderModel.fromJson(data);
  }
    Future<OrderModel> generateQr(int orderId) async {
    final response = await _api.client.post('/qr/generate', data: {
      'order_id': orderId,
    });
    final data = response.data['data']['order'] as Map<String, dynamic>;
    return OrderModel.fromJson(data);
  }
}