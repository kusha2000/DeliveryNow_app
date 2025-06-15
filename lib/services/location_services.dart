import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:delivery_now_app/models/get_coordinates_from_placeId.dart';
import 'package:delivery_now_app/models/get_places.dart';
import 'package:delivery_now_app/models/nearby_search_model.dart';
import 'package:delivery_now_app/models/place_from_coordinates.dart';
import '../models/rider_location_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  // ignore: unused_field
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String? gcpKey = dotenv.env['GCPKEY'];

  // Reference to rider_locations collection
  final CollectionReference _locationsCollection =
      FirebaseFirestore.instance.collection('rider_locations');

  // Update rider's location in Firebase
  Future<void> updateRiderLocation({
    required String riderId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      RiderLocationModel locationData = RiderLocationModel(
        riderId: riderId,
        latitude: latitude,
        longitude: longitude,
        lastUpdated: Timestamp.now(),
      );

      await _locationsCollection.doc(riderId).set(locationData.toMap());
      print("Location Updated");
    } catch (e) {
      debugPrint('Error updating rider location: $e');
      rethrow;
    }
  }

  // Stream to listen to all riders' locations
  Stream<List<RiderLocationModel>> getAllRidersLocations() {
    return _locationsCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              RiderLocationModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Stream<List<RiderLocationModel>> getRiderLocation(String riderId) {
    // Use the same _locationsCollection reference as getAllRidersLocations
    return _locationsCollection
        .where('riderId', isEqualTo: riderId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              RiderLocationModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Request location permission and get current position
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Get the current position
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  // Start location tracking for a rider
  void startLocationTracking({
    required String riderId,
  }) {
    // Listen for position changes
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update if moved at least 10 meters
      ),
    ).listen((Position position) async {
      await updateRiderLocation(
        riderId: riderId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    });
  }

  Future<PlaceFromCoordinates> placeFromCoordinates(
      double lat, double lng) async {
    Uri url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=${gcpKey}');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      return PlaceFromCoordinates.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('API ERROR: placeFromCoordinates');
    }
  }

  Future<GetPlaces> getPlaces(String placeName) async {
    Uri url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=${gcpKey}');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      return GetPlaces.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('API ERROR: getPlaces');
    }
  }

  Future<GetCoordinatesFromPlaceId> getCoordinatesFromPlaceId(
      String placeId) async {
    Uri url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&key=${gcpKey}');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      return GetCoordinatesFromPlaceId.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('API ERROR: getPlaces');
    }
  }

  Future<NearBySearchModel> getNearbySearch(
      double lat, double lng, String text) async {
    Uri url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=1000&types=$text&key=${gcpKey}');
    var response = await http.get(url);

    print('Response: ${jsonDecode(response.body)}');
    if (response.statusCode == 200) {
      return NearBySearchModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('API ERROR: getNearbySearch');
    }
  }
}
