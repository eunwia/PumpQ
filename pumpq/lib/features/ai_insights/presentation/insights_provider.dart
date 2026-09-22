import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pumpq/features/ai_insights/data/insights_repository.dart';
import 'package:pumpq/features/auth/presentation/auth_provider.dart';
import 'package:pumpq/models/insights_model.dart';

final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  return InsightsRepository(ref.watch(apiServiceProvider));
});

final budgetProvider = FutureProvider<BudgetInsightModel>((ref) {
  return ref.watch(insightsRepositoryProvider).getBudget();
});

final reminderProvider = FutureProvider<RefuelReminderModel>((ref) {
  return ref.watch(insightsRepositoryProvider).getReminder();
});

class SetBudgetNotifier extends Notifier<bool> {
  @override
  bool build() => false; // isLoading

  Future<void> setBudget(double budget) async {
    state = true;
    try {
      await ref.read(insightsRepositoryProvider).setBudget(budget);
      ref.invalidate(budgetProvider);
    } finally {
      state = false;
    }
  }
}

final setBudgetProvider = NotifierProvider<SetBudgetNotifier, bool>(SetBudgetNotifier.new);