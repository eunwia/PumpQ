class StationModel {
  final int stationId;
  final String name;
  final String fuelBrand;
  final String location;
  final double latitude;
  final double longitude;
  final bool isOpen;

  const StationModel({
    required this.stationId,
    required this.name,
    required this.fuelBrand,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.isOpen,
  });

  factory StationModel.fromJson(Map<String, dynamic> json) {
    return StationModel(
      stationId: (json['station_id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?)?.trim().isNotEmpty == true ? json['name'] as String : 'Gas Station',
      fuelBrand: (json['fuel_brand'] as String?)?.trim().isNotEmpty == true ? json['fuel_brand'] as String : 'PumpQ',
      location: (json['location'] as String?) ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      isOpen: json['is_open'] as bool? ?? true,
    );
  }
}