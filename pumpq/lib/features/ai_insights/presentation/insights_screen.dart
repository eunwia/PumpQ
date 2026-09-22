import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pumpq/core/constants/app_colors.dart';
import 'package:pumpq/features/ai_insights/presentation/insights_provider.dart';
import 'package:pumpq/models/insights_model.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  void _showBudgetDialog(BuildContext context, WidgetRef ref, double current) {
    final controller = TextEditingController(
      text: current > 0 ? current.toStringAsFixed(0) : '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: '₱ '),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = double.tryParse(controller.text);
              if (value != null && value >= 0) {
                await ref.read(setBudgetProvider.notifier).setBudget(value);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetProvider);
    final reminderAsync = ref.watch(reminderProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Insights')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          budgetAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Could not load budget'),
            data: (budget) => _BudgetCard(
              budget: budget,
              onEdit: () => _showBudgetDialog(context, ref, budget.budget),
            ),
          ),
          const SizedBox(height: 20),
          reminderAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Could not load refuel prediction'),
            data: (reminder) => _ReminderCard(reminder: reminder),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget, required this.onEdit});
  final BudgetInsightModel budget;
  final VoidCallback onEdit;

  Color _barColor() {
    switch (budget.alertLevel) {
      case 'exceeded':
        return AppColors.error;
      case 'warning':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Budget', style: Theme.of(context).textTheme.titleMedium),
              IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
            ],
          ),
          if (budget.budget == 0)
            const Text('No budget set yet — tap the pencil to set one.',
                style: TextStyle(color: AppColors.textSecondary))
          else ...[
            const SizedBox(height: 8),
            Text(
              '₱${budget.spent.toStringAsFixed(2)} of ₱${budget.budget.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (budget.percentUsed / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation(_barColor()),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              budget.alertLevel == 'exceeded'
                  ? 'Budget exceeded!'
                  : budget.alertLevel == 'warning'
                      ? "You've used ${budget.percentUsed}% of your budget"
                      : '${budget.percentUsed}% used',
              style: TextStyle(color: _barColor(), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.reminder});
  final RefuelReminderModel reminder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.local_gas_station, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Refuel Prediction', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          if (!reminder.hasEnoughData)
            const Text(
              "Place a couple more orders and we'll start predicting your next refuel.",
              style: TextStyle(color: AppColors.textSecondary),
            )
          else ...[
            Text(
              'Based on your history, you refuel every '
              '${reminder.averageIntervalDays!.toStringAsFixed(1)} days on average.',
            ),
            const SizedBox(height: 8),
            Text(
              (reminder.daysUntilNextRefuel ?? 0) <= 0
                  ? "You're due for a refuel!"
                  : 'Next refuel expected in ${reminder.daysUntilNextRefuel} day(s).',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}