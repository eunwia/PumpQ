class OrderModel {
  final int orderId;
  final int stationId;
  final String fuelType;
  final double liters;
  final double amount;
  final String status;
  final String paymentStatus;
  final String? qrCode;
  final DateTime createdAt;

  const OrderModel({
    required this.orderId,
    required this.stationId,
    required this.fuelType,
    required this.liters,
    required this.amount,
    required this.status,
    required this.paymentStatus,
    this.qrCode,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['order_id'] as int,
      stationId: json['station_id'] as int,
      fuelType: json['fuel_type'] as String,
      liters: (json['liters'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      qrCode: json['qr_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}