import 'package:cloud_firestore/cloud_firestore.dart';

class RiderLocationModel {
  final String riderId;
  final double latitude;
  final double longitude;
  final Timestamp lastUpdated;

  RiderLocationModel({
    required this.riderId,
    required this.latitude,
    required this.longitude,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'riderId': riderId,
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdated': lastUpdated,
    };
  }

  factory RiderLocationModel.fromMap(Map<String, dynamic> map) {
    return RiderLocationModel(
      riderId: map['riderId'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: map['lastUpdated'] as Timestamp? ?? Timestamp.now(),
    );
  }
}
