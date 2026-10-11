import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pumpq/core/constants/app_colors.dart';
import 'package:pumpq/features/ai_insights/presentation/insights_provider.dart';
import 'package:pumpq/features/pre_order/presentation/order_provider.dart';
import 'package:pumpq/models/insights_model.dart';
import 'package:pumpq/models/order_model.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  void _showBudgetDialog(BuildContext context, WidgetRef ref, double current) {
    final controller = TextEditingController(text: current > 0 ? current.toStringAsFixed(0) : '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: '₱ ')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
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

  void _exportReport(BuildContext context, List<OrderModel> orders) {
    final completed = orders.where((o) => o.status == 'completed').toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final buffer = StringBuffer();
    buffer.writeln('Order ID,Date,Fuel Type,Liters,Amount,Status,Payment');
    for (final o in completed) {
      buffer.writeln(
        '${o.orderId},${o.createdAt.year}-${o.createdAt.month.toString().padLeft(2, '0')}-${o.createdAt.day.toString().padLeft(2, '0')},'
        '${o.fuelType},${o.liters},${o.amount},${o.status},${o.paymentStatus}',
      );
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report copied to clipboard — paste into Excel/Sheets as CSV')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetProvider);
    final reminderAsync = ref.watch(reminderProvider);
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0, title: const Text('Reports & Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          budgetAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Could not load budget'),
            data: (budget) => _BudgetDonutCard(
              budget: budget,
              onEdit: () => _showBudgetDialog(context, ref, budget.budget),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Expense Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ordersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Could not load expense analytics'),
            data: (orders) => _ExpenseAnalyticsCard(orders: orders),
          ),
          const SizedBox(height: 24),
          const Text('AI Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          reminderAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Could not load refuel prediction'),
            data: (reminder) => _ReminderCard(reminder: reminder),
          ),
          const SizedBox(height: 24),
          const Text('Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ordersAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (orders) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Export your completed order history as a CSV report', style: TextStyle(fontSize: 13)),
                  ),
                  ElevatedButton(
                    onPressed: () => _exportReport(context, orders),
                    child: const Text('Export'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetDonutCard extends StatelessWidget {
  const _BudgetDonutCard({required this.budget, required this.onEdit});
  final BudgetInsightModel budget;
  final VoidCallback onEdit;

  Color _color() {
    switch (budget.alertLevel) {
      case 'exceeded': return AppColors.error;
      case 'warning': return Colors.orange;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          SizedBox(
            width: 100, height: 100,
            child: CustomPaint(
              painter: _DonutPainter(percent: budget.percentUsed / 100, color: _color()),
              child: Center(
                child: Text('${budget.percentUsed}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _color())),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Monthly Budget', style: TextStyle(fontWeight: FontWeight.w600)),
                    IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: onEdit, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  ],
                ),
                const SizedBox(height: 6),
                if (budget.budget == 0)
                  const Text('No budget set', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
                else ...[
                  Text('₱${budget.spent.toStringAsFixed(2)} spent', style: const TextStyle(fontSize: 13)),
                  Text('of ₱${budget.budget.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.percent, required this.color});
  final double percent;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final bgPaint = Paint()..color = AppColors.background..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round;
    final fgPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * percent.clamp(0.0, 1.0), false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.percent != percent || oldDelegate.color != color;
}

class _ExpenseAnalyticsCard extends StatelessWidget {
  const _ExpenseAnalyticsCard({required this.orders});
  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final completed = orders.where((o) => o.status == 'completed').toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final recent = completed.length > 6 ? completed.sublist(completed.length - 6) : completed;

    final Map<String, double> byFuelType = {};
    for (final o in completed) {
      byFuelType[o.fuelType] = (byFuelType[o.fuelType] ?? 0) + o.amount;
    }
    final totalSpent = byFuelType.values.fold(0.0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
      child: recent.isEmpty
          ? const Text('No completed orders yet to analyze', style: TextStyle(color: AppColors.textSecondary))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What you spent on your last ${recent.length} refuel${recent.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 130,
                  child: CustomPaint(size: Size.infinite, painter: _BarChartPainter(values: recent.map((o) => o.amount).toList())),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: recent.map((o) => Text('${o.createdAt.month}/${o.createdAt.day}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))).toList(),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                const Text('Spend by Fuel Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 10),
                ...byFuelType.entries.map((e) {
                  final pct = totalSpent == 0 ? 0.0 : e.value / totalSpent;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key, style: const TextStyle(fontSize: 12)),
                            Text('₱${e.value.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: AppColors.background, valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({required this.values});
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxVal = values.reduce(math.max);
    final barWidth = size.width / (values.length * 2);
    final paint = Paint()..color = AppColors.primary;

    for (var i = 0; i < values.length; i++) {
      final barHeight = maxVal == 0 ? 0.0 : (values[i] / maxVal) * (size.height - 24);
      final x = i * (barWidth * 2) + barWidth / 2;
      final rect = Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight);
      canvas.drawRRect(RRect.fromRectAndCorners(rect, topLeft: const Radius.circular(4), topRight: const Radius.circular(4)), paint);

      final textPainter = TextPainter(
        text: TextSpan(text: values[i].toStringAsFixed(0), style: const TextStyle(color: AppColors.textSecondary, fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(x + barWidth / 2 - textPainter.width / 2, size.height - barHeight - 14));
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) => oldDelegate.values != values;
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.reminder});
  final RefuelReminderModel reminder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.local_gas_station, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Refuel Prediction', style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          if (!reminder.hasEnoughData)
            const Text("Place a couple more orders and we'll start predicting your next refuel.", style: TextStyle(color: AppColors.textSecondary))
          else ...[
            Text('Based on your history, you refuel every ${reminder.averageIntervalDays!.toStringAsFixed(1)} days on average.'),
            const SizedBox(height: 8),
            Text(
              (reminder.daysUntilNextRefuel ?? 0) <= 0 ? "You're due for a refuel!" : 'Next refuel expected in ${reminder.daysUntilNextRefuel} day(s).',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}