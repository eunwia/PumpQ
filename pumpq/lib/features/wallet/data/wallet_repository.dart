import 'package:pumpq/core/services/api_service.dart';
import 'package:pumpq/models/wallet_model.dart';

class WalletRepository {
  WalletRepository(this._api);
  final ApiService _api;

  Future<WalletModel> getWallet() async {
    final response = await _api.client.get('/wallet');
    final data = response.data['data']['wallet'] as Map<String, dynamic>;
    return WalletModel.fromJson(data);
  }

  Future<double> topUp({required double amount, required String method}) async {
    final response = await _api.client.post('/wallet/topup', data: {
      'amount': amount,
      'method': method,
    });
    return (response.data['data']['balance'] as num).toDouble();
  }

  Future<List<WalletTransactionModel>> getHistory() async {
    final response = await _api.client.get('/wallet/history');
    final data = response.data['data']['transactions'] as List;
    return data
        .map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}