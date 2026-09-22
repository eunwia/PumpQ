import 'package:pumpq/core/services/api_service.dart';
import 'package:pumpq/models/insights_model.dart';

class InsightsRepository {
  InsightsRepository(this._api);
  final ApiService _api;

  Future<BudgetInsightModel> getBudget() async {
    final response = await _api.client.get('/insights/budget');
    return BudgetInsightModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> setBudget(double budget) async {
    await _api.client.put('/insights/budget', data: {'budget': budget});
  }

  Future<RefuelReminderModel> getReminder() async {
    final response = await _api.client.get('/insights/reminder');
    return RefuelReminderModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}