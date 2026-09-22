class LoyaltyModel {
  final int pointsBalance;
  final String tier;
  final int streakCount;

  const LoyaltyModel({
    required this.pointsBalance,
    required this.tier,
    required this.streakCount,
  });

  factory LoyaltyModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyModel(
      pointsBalance: json['points_balance'] as int,
      tier: json['tier'] as String,
      streakCount: json['streak_count'] as int,
    );
  }

  int get pointsToNextTier {
    if (tier == 'Bronze') return 500 - pointsBalance;
    if (tier == 'Silver') return 1500 - pointsBalance;
    return 0; // already Gold
  }

  double get tierProgress {
    if (tier == 'Gold') return 1.0;
    final floor = tier == 'Silver' ? 500 : 0;
    final ceiling = tier == 'Silver' ? 1500 : 500;
    return (pointsBalance - floor) / (ceiling - floor);
  }
}

class LoyaltyTransactionModel {
  final int ltId;
  final int? orderId;
  final int pointsEarned;
  final int pointsRedeemed;
  final DateTime createdAt;

  const LoyaltyTransactionModel({
    required this.ltId,
    this.orderId,
    required this.pointsEarned,
    required this.pointsRedeemed,
    required this.createdAt,
  });

  factory LoyaltyTransactionModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransactionModel(
      ltId: json['lt_id'] as int,
      orderId: json['order_id'] as int?,
      pointsEarned: json['points_earned'] as int,
      pointsRedeemed: json['points_redeemed'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}