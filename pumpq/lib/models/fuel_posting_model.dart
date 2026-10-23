class FuelPostingModel {
  final int priceId;
  final int stationId;
  final String stationName;
  final String fuelBrand;
  final String fuelType;
  final double price;
  final bool availability;

  const FuelPostingModel({
    required this.priceId,
    required this.stationId,
    required this.stationName,
    required this.fuelBrand,
    required this.fuelType,
    required this.price,
    required this.availability,
  });

  factory FuelPostingModel.fromJson(Map<String, dynamic> json) {
    return FuelPostingModel(
      priceId: (json['price_id'] as num?)?.toInt() ?? 0,
      stationId: (json['station_id'] as num?)?.toInt() ?? 0,
      stationName: (json['station_name'] as String?)?.trim().isNotEmpty == true ? json['station_name'] as String : 'Gas Station',
      fuelBrand: (json['fuel_brand'] as String?)?.trim().isNotEmpty == true ? json['fuel_brand'] as String : 'PumpQ',
      fuelType: (json['fuel_type'] as String?) ?? 'Fuel',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      availability: json['availability'] as bool? ?? true,
    );
  }
}