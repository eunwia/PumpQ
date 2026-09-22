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
      priceId: json['price_id'] as int,
      stationId: json['station_id'] as int,
      stationName: json['station_name'] as String,
      fuelBrand: json['fuel_brand'] as String,
      fuelType: json['fuel_type'] as String,
      price: (json['price'] as num).toDouble(),
      availability: json['availability'] as bool,
    );
  }
}