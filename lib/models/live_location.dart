class LiveOrderLocation {
  final bool available;
  final bool deliveryActive;
  final bool locationAvailable;
  final bool isLive;
  final bool isStale;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final DateTime? updatedAt;

  const LiveOrderLocation({
    required this.available,
    required this.deliveryActive,
    required this.locationAvailable,
    required this.isLive,
    required this.isStale,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.updatedAt,
  });

  factory LiveOrderLocation.fromJson(Map<String, dynamic> json) {
    final latitude = (json['latitude'] as num?)?.toDouble();
    final longitude = (json['longitude'] as num?)?.toDouble();
    final coordinatesValid = latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
    final live = json['isLive'] == true && coordinatesValid;
    return LiveOrderLocation(
      available: json['available'] != false,
      deliveryActive: json['deliveryActive'] == true,
      locationAvailable: json['locationAvailable'] == true && live,
      isLive: live,
      isStale: json['isStale'] == true,
      latitude: live ? latitude : null,
      longitude: live ? longitude : null,
      accuracy: live ? (json['accuracy'] as num?)?.toDouble() : null,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

class LiveDriverLocation {
  final String driverId;
  final String username;
  final String displayName;
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime? updatedAt;
  final List<String> activeOrderIds;

  const LiveDriverLocation({
    required this.driverId,
    required this.username,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.updatedAt,
    required this.activeOrderIds,
  });

  factory LiveDriverLocation.fromJson(Map<String, dynamic> json) {
    final latitude = (json['latitude'] as num?)?.toDouble();
    final longitude = (json['longitude'] as num?)?.toDouble();
    final accuracy = (json['accuracy'] as num?)?.toDouble();
    if (latitude == null ||
        longitude == null ||
        accuracy == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        !accuracy.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        accuracy < 0) {
      throw const FormatException('Invalid live driver location.');
    }
    final ids = json['activeOrderIds'] is List
        ? (json['activeOrderIds'] as List)
            .map((value) => value.toString())
            .toList()
        : const <String>[];
    return LiveDriverLocation(
      driverId: json['driverId']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      activeOrderIds: List.unmodifiable(ids),
    );
  }
}

class LiveDriversSnapshot {
  final bool enabled;
  final List<LiveDriverLocation> drivers;

  const LiveDriversSnapshot({required this.enabled, required this.drivers});

  factory LiveDriversSnapshot.fromJson(Map<String, dynamic> json) {
    final rows = json['drivers'];
    return LiveDriversSnapshot(
      enabled: json['enabled'] == true,
      drivers: rows is List
          ? rows
              .whereType<Map>()
              .map((row) => LiveDriverLocation.fromJson(
                    Map<String, dynamic>.from(row),
                  ))
              .toList(growable: false)
          : const <LiveDriverLocation>[],
    );
  }
}
