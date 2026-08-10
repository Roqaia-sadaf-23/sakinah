class LocationData {
  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    required this.capturedAt,
    this.isCached = false,
  });

  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final DateTime capturedAt;
  final bool isCached;

  String get displayName =>
      [city, country].where((part) => part.trim().isNotEmpty).join(', ');

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'city': city,
    'country': country,
    'capturedAt': capturedAt.toIso8601String(),
  };

  factory LocationData.fromJson(Map<String, dynamic> json) => LocationData(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    city: json['city'] as String? ?? '',
    country: json['country'] as String? ?? '',
    capturedAt: DateTime.parse(json['capturedAt'] as String),
    isCached: true,
  );
}
