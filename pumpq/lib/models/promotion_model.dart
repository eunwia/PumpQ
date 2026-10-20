class PromotionModel {
  final int promoId;
  final int? stationId;
  final String? stationName;
  final String promoName;
  final String promoType;
  final double discountValue;
  final String promoTag;
  final String couponCode;
  final DateTime expiresAt;

  const PromotionModel({
    required this.promoId,
    this.stationId,
    this.stationName,
    required this.promoName,
    required this.promoType,
    required this.discountValue,
    required this.promoTag,
    required this.couponCode,
    required this.expiresAt,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      promoId: json['promo_id'] as int,
      stationId: json['station_id'] as int?,
      stationName: json['station_name'] as String?,
      promoName: json['promo_name'] as String,
      promoType: json['promo_type'] as String,
      discountValue: (json['discount_value'] as num).toDouble(),
      promoTag: json['promo_tag'] as String? ?? '',
      couponCode: json['coupon_code'] as String,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now().add(const Duration(days: 365)),
    );
  }

  String get discountLabel =>
      promoType == 'percentage' ? '${discountValue.toStringAsFixed(0)}% OFF' : '₱${discountValue.toStringAsFixed(0)} OFF';
}