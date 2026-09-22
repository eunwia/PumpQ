class BudgetInsightModel {
  final double budget;
  final double spent;
  final int percentUsed;
  final String alertLevel; // 'none' | 'warning' | 'exceeded'

  const BudgetInsightModel({
    required this.budget,
    required this.spent,
    required this.percentUsed,
    required this.alertLevel,
  });

  factory BudgetInsightModel.fromJson(Map<String, dynamic> json) {
    return BudgetInsightModel(
      budget: (json['budget'] as num).toDouble(),
      spent: (json['spent'] as num).toDouble(),
      percentUsed: json['percent_used'] as int,
      alertLevel: json['alert_level'] as String,
    );
  }
}

class RefuelReminderModel {
  final bool hasEnoughData;
  final double? averageIntervalDays;
  final DateTime? predictedNextRefuel;
  final int? daysUntilNextRefuel;

  const RefuelReminderModel({
    required this.hasEnoughData,
    this.averageIntervalDays,
    this.predictedNextRefuel,
    this.daysUntilNextRefuel,
  });

  factory RefuelReminderModel.fromJson(Map<String, dynamic> json) {
    return RefuelReminderModel(
      hasEnoughData: json['has_enough_data'] as bool,
      averageIntervalDays: (json['average_interval_days'] as num?)?.toDouble(),
      predictedNextRefuel: json['predicted_next_refuel'] != null
          ? DateTime.parse(json['predicted_next_refuel'] as String)
          : null,
      daysUntilNextRefuel: json['days_until_next_refuel'] as int?,
    );
  }
}