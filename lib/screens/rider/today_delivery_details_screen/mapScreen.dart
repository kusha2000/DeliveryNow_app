import 'package:delivery_now_app/screens/rider/delivery_details_screen/delivery_details_screen.dart';
import 'package:delivery_now_app/utils/show_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:delivery_now_app/models/get_places.dart';
import 'package:delivery_now_app/services/firebase_services.dart';
import 'package:delivery_now_app/services/location_services.dart';
import 'package:delivery_now_app/utils/marker_icon.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'package:delivery_now_app/models/delivery_model.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DeliveryLocationMap extends StatefulWidget {
  final String deliveryId;

  const DeliveryLocationMap({
    super.key,
    required this.deliveryId,
  });

  @override
  State<DeliveryLocationMap> createState() => _DeliveryLocationMapState();
}

class _DeliveryLocationMapState extends State<DeliveryLocationMap> {
  GoogleMapController? _mapController;
  CameraPosition? _initialPosition;
  DeliveryModel? _deliveryInfo;
  bool _isLoading = true;
  bool _isDeliveryStarted = false;
  bool _showConfirmDelivery = false;
  bool _isSearching = false;
  String _deliveryStatus = "";
  final LocationService _locationService = LocationService();
  final FirebaseServices _firebaseService = FirebaseServices();
  TextEditingController _searchController = TextEditingController();
  GetPlaces _getPlaces = GetPlaces();

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _polylineCoordinates = [];
  PolylinePoints _polylinePoints = PolylinePoints();

  LatLng? _currentLocation;
  LatLng? _destinationLocation;
  String _distance = "";
  String _duration = "";
  String _destinationAddress = "";
  String riderId = "";

  StreamSubscription<Position>? _positionStreamSubscription;
  BitmapDescriptor? _liveLocationMarker;
  static String? gcpKey = dotenv.env['GCPKEY'];
  static String? weatherApiKey = dotenv.env['OPENWEATHER_API_KEY'];

  // Weather-related variables
  String _weatherCondition = "";
  String _weatherIconPath = "assets/sun.png";

  // Timer-related variables
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  Timestamp? _startTime;
  String? _deliveryTime;

  @override
  void initState() {
    super.initState();
    _loadDeliveryInfo();
    _determinePosition();
    _loadTimerState();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    _searchController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadDeliveryInfo() async {
    try {
      _deliveryInfo = await _firebaseService.fetchSpecificDelivery(
          deliveryId: widget.deliveryId);
      setState(() {
        _destinationAddress = _deliveryInfo?.address ?? '';
        riderId = _deliveryInfo?.riderId ?? "";
        _deliveryStatus = _deliveryInfo?.status ?? '';
        if (_deliveryStatus == "on_the_way") {
          _isDeliveryStarted = true;
        } else if (_deliveryStatus == "delivered" ||
            _deliveryStatus == "returned") {
          _isDeliveryStarted = false;
          _timer?.cancel();
          // Load delivery time if available
          _calculateDeliveryTime();
        }
      });
      await _geocodeDeliveryAddress();
      if (_destinationLocation != null) {
        await _fetchWeather();
      }
    } catch (e) {
      debugPrint('Error loading delivery info: $e');
    }
  }

  Future<void> _calculateDeliveryTime() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('deliveries')
          .doc(widget.deliveryId)
          .get();
      final data = doc.data();
      if (data != null &&
          data.containsKey('startTime') &&
          data.containsKey('endTime')) {
        final startTime = (data['startTime'] as Timestamp?)?.toDate();
        final endTime = (data['endTime'] as Timestamp?)?.toDate();
        if (startTime != null && endTime != null) {
          final duration = endTime.difference(startTime);
          setState(() {
            _deliveryTime =
                '${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
          });
        }
      }
    } catch (e) {
      debugPrint('Error calculating delivery time: $e');
    }
  }

  Future<void> _fetchWeather() async {
    if (_destinationLocation == null || weatherApiKey == null) {
      setState(() {
        _weatherCondition = "Unknown";
        _weatherIconPath = "assets/sun.png";
      });
      return;
    }

    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=${_destinationLocation!.latitude}&lon=${_destinationLocation!.longitude}&appid=$weatherApiKey&units=metric',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weather = data['weather'][0]['main'].toString().toLowerCase();
        setState(() {
          _weatherCondition = weather;
          if (weather.contains('rain') ||
              weather.contains('drizzle') ||
              weather.contains('thunderstorm')) {
            _weatherIconPath = "assets/rain.png";
          } else if (weather.contains('clear')) {
            _weatherIconPath = "assets/sun.png";
          } else if (weather.contains('clouds')) {
            _weatherIconPath = "assets/clouds.png";
          } else {
            _weatherIconPath = "assets/sun.png";
            _weatherCondition = "sun";
          }
        });
      } else {
        setState(() {
          _weatherCondition = "Failed to fetch weather";
          _weatherIconPath = "assets/sun.png";
        });
      }
    } catch (e) {
      debugPrint('Error fetching weather: $e');
      setState(() {
        _weatherCondition = "Error fetching weather";
        _weatherIconPath = "assets/sun.png";
      });
    }
  }

  Future<void> _loadTimerState() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('deliveries')
          .doc(widget.deliveryId)
          .get();
      final data = doc.data();
      if (data != null &&
          data.containsKey('startTime') &&
          data['status'] == "on_the_way") {
        final startTime = data['startTime'] as Timestamp?;
        if (startTime != null) {
          setState(() {
            _isDeliveryStarted = true;
            _startTime = startTime;
            _elapsedTime = DateTime.now().difference(startTime.toDate());
          });
          _startTimer();
        }
      }
    } catch (e) {
      debugPrint('Error loading timer state: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_deliveryStatus == "delivered" || _deliveryStatus == "returned") {
        timer.cancel();
        return;
      }
      setState(() {
        _elapsedTime = DateTime.now().difference(_startTime!.toDate());
      });
    });
  }

  Future<void> _geocodeDeliveryAddress() async {
    if (_destinationAddress.isEmpty) {
      debugPrint('No delivery address available for geocoding');
      return;
    }

    try {
      List<Location> locations = await locationFromAddress(_destinationAddress);
      if (locations.isNotEmpty) {
        setState(() {
          _destinationLocation =
              LatLng(locations.first.latitude, locations.first.longitude);
        });
        if (_currentLocation != null) {
          _updateMarkers();
          _getPolyline();
          _fitBounds();
        }
      }
    } catch (e) {
      debugPrint('Error geocoding address: $e');
      setState(() {
        _destinationLocation = const LatLng(6.9271, 79.8612);
        _destinationAddress = "Unknown address";
      });
      if (_currentLocation != null) {
        _updateMarkers();
        _getPolyline();
        _fitBounds();
      }
    }
  }

  void _fitBounds() {
    if (_currentLocation != null &&
        _destinationLocation != null &&
        _mapController != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          _currentLocation!.latitude < _destinationLocation!.latitude
              ? _currentLocation!.latitude
              : _destinationLocation!.latitude,
          _currentLocation!.longitude < _destinationLocation!.longitude
              ? _currentLocation!.longitude
              : _destinationLocation!.longitude,
        ),
        northeast: LatLng(
          _currentLocation!.latitude > _destinationLocation!.latitude
              ? _currentLocation!.latitude
              : _destinationLocation!.latitude,
          _currentLocation!.longitude > _destinationLocation!.longitude
              ? _currentLocation!.longitude
              : _destinationLocation!.longitude,
        ),
      );
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoading = false);
      _showLocationError("Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        _showLocationError("Location permissions are denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      _showLocationError("Location permissions are permanently denied.");
      return;
    }

    LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 4,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 10),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 4,
        pauseLocationUpdatesAutomatically: true,
        showBackgroundLocationIndicator: false,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );
    }

    await getBytesFromAsset("assets/live_location_icon.png", 150).then((value) {
      setState(() {
        _liveLocationMarker = value;
      });
    });

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        if (_initialPosition == null) {
          _initialPosition =
              CameraPosition(target: _currentLocation!, zoom: 15);
          _isLoading = false;
        }
        _updateMarkers();
        if (_destinationLocation != null) {
          _getPolyline();
          _checkProximityToDestination();
          _fitBounds();
        }
      });

      if (_isDeliveryStarted &&
          _deliveryStatus != "delivered" &&
          _deliveryStatus != "returned") {
        _locationService.updateRiderLocation(
          riderId: riderId,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
    });
  }

  void _updateMarkers() {
    _markers.clear();
    if (_currentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: _currentLocation!,
          icon: _liveLocationMarker ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }
    if (_destinationLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
              title: 'Delivery Address', snippet: _destinationAddress),
        ),
      );
    }
  }

  Future<void> _getPolyline() async {
    if (_currentLocation == null || _destinationLocation == null) return;

    try {
      PolylineResult result = await _polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: gcpKey ?? '',
        request: PolylineRequest(
          origin: PointLatLng(
              _currentLocation!.latitude, _currentLocation!.longitude),
          destination: PointLatLng(
              _destinationLocation!.latitude, _destinationLocation!.longitude),
          mode: TravelMode.driving,
        ),
      );

      _polylineCoordinates.clear();
      if (result.points.isNotEmpty) {
        result.points.forEach((PointLatLng point) {
          _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        });

        double totalDistance = 0.0;
        for (int i = 0; i < _polylineCoordinates.length - 1; i++) {
          totalDistance += Geolocator.distanceBetween(
                _polylineCoordinates[i].latitude,
                _polylineCoordinates[i].longitude,
                _polylineCoordinates[i + 1].latitude,
                _polylineCoordinates[i + 1].longitude,
              ) /
              1000;
        }

        _distance = totalDistance.toStringAsFixed(1);
        _duration = _calculateDuration(totalDistance);
        _destinationAddress = _destinationAddress;

        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('delivery_route'),
              points: _polylineCoordinates,
              color: AppColors.primaryColor,
              width: 8,
            ),
          );
        });
      } else {
        debugPrint("No route points received: ${result.errorMessage}");
        setState(() {
          _polylineCoordinates = [_currentLocation!, _destinationLocation!];
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('delivery_route'),
              points: _polylineCoordinates,
              color: AppColors.primaryColor,
              width: 8,
            ),
          );
          _distance = (Geolocator.distanceBetween(
                    _currentLocation!.latitude,
                    _currentLocation!.longitude,
                    _destinationLocation!.latitude,
                    _destinationLocation!.longitude,
                  ) /
                  1000)
              .toStringAsFixed(1);
          _duration = _calculateDuration(double.parse(_distance));
        });
      }
    } catch (e) {
      debugPrint("Error creating polyline: $e");
      setState(() {
        _polylineCoordinates = [_currentLocation!, _destinationLocation!];
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('delivery_route'),
            points: _polylineCoordinates,
            color: AppColors.primaryColor,
            width: 8,
          ),
        );
        _distance = (Geolocator.distanceBetween(
                  _currentLocation!.latitude,
                  _currentLocation!.longitude,
                  _destinationLocation!.latitude,
                  _destinationLocation!.longitude,
                ) /
                1000)
            .toStringAsFixed(1);
        _duration = _calculateDuration(double.parse(_distance));
      });
    }
  }

  String _calculateDuration(double distanceKm) {
    double timeHours = distanceKm / 30;
    int timeMinutes = (timeHours * 60).round();
    return "$timeMinutes mins";
  }

  void _checkProximityToDestination() {
    if (_currentLocation != null && _destinationLocation != null) {
      double distance = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        _destinationLocation!.latitude,
        _destinationLocation!.longitude,
      );
      if (distance < 50 &&
          _deliveryStatus != "delivered" &&
          _deliveryStatus != "returned") {
        setState(() {
          _showConfirmDelivery = true;
        });
      }
    }
  }

  void _showLocationError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmDeliverStatus(String status) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final endTime = Timestamp.now();
      String? deliveryTime;
      if (_startTime != null) {
        final duration = endTime.toDate().difference(_startTime!.toDate());
        deliveryTime =
            '${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
      }

      await FirebaseFirestore.instance
          .collection('deliveries')
          .doc(widget.deliveryId)
          .update({
        'status': status,
        'endTime': endTime,
        if (deliveryTime != null) 'deliveryTime': deliveryTime,
      });

      _timer?.cancel();

      setState(() {
        _deliveryStatus = status;
        _isDeliveryStarted = false;
        _deliveryTime = deliveryTime;
      });

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DeliveryDetailScreen(),
          ));
    } catch (e) {
      Navigator.pop(context);
      showToast('Failed to confirm delivery: $e', AppColors.redColor);
    }
  }

  Future<void> _onTheWayStatus(String status) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      _firebaseService.updateDeliveryStatus(
          deliveryId: widget.deliveryId, status: status);
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      showToast('Failed to confirm delivery: $e', AppColors.redColor);
    }
  }

  void _startDelivery() {
    setState(() {
      _isDeliveryStarted = true;
      _startTime = Timestamp.now();
      _deliveryStatus = "on_the_way";
      _startTimer();
    });
    _onTheWayStatus("on_the_way");
    FirebaseFirestore.instance
        .collection('deliveries')
        .doc(widget.deliveryId)
        .update({'startTime': _startTime});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSearching
          ? AppBar(
              backgroundColor: AppColors.primaryColor,
              centerTitle: true,
              leading: BackButton(
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                    _getPlaces = GetPlaces();
                  });
                },
              ),
            )
          : AppBar(
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.borderLightColor,
                      AppColors.cardColor,
                      AppColors.backgroundColor,
                    ],
                  ),
                ),
              ),
              foregroundColor: AppColors.whiteColor,
              title: const Text('Delivery Navigation'),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _initialPosition ??
                      const CameraPosition(target: LatLng(0, 0), zoom: 15),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: true,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_currentLocation != null &&
                        _destinationLocation != null) {
                      _fitBounds();
                    }
                  },
                ),
                Visibility(
                  visible: _getPlaces.predictions != null,
                  child: Container(
                    color: Colors.white,
                    child: ListView.builder(
                      itemCount: _getPlaces.predictions?.length ?? 0,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return ListTile(
                          onTap: () {
                            _locationService
                                .getCoordinatesFromPlaceId(
                                    _getPlaces.predictions![index].placeId ??
                                        "")
                                .then((value) {
                              _polylineCoordinates.clear();
                              _searchController.clear();
                              _markers.removeWhere((element) =>
                                  element.markerId.value == 'destination');

                              _destinationLocation = LatLng(
                                value.result?.geometry?.location?.lat ?? 0.0,
                                value.result?.geometry?.location?.lng ?? 0.0,
                              );
                              _destinationAddress =
                                  _getPlaces.predictions![index].description ??
                                      '';
                              _getPlaces = GetPlaces();
                              _isSearching = false;

                              _markers.add(
                                Marker(
                                  markerId: const MarkerId('destination'),
                                  position: _destinationLocation!,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueRed),
                                ),
                              );

                              _getPolyline();
                              _fitBounds();

                              setState(() {});
                            }).onError((error, stackTrace) {
                              debugPrint(error.toString());
                            });
                          },
                          leading: const Icon(Icons.location_on),
                          title: Text(
                              _getPlaces.predictions![index].description ?? ''),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: AppColors.whiteColor,
                    foregroundColor: AppColors.primaryColor,
                    onPressed: () {
                      if (_currentLocation != null) {
                        _mapController?.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(target: _currentLocation!, zoom: 16),
                          ),
                        );
                      }
                    },
                    child: const Icon(Icons.my_location),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomPanel(),
                ),
              ],
            ),
    );
  }

  Widget _buildBottomPanel() {
    final address = _destinationAddress.isNotEmpty
        ? _destinationAddress
        : 'Address not available';
    final customer = _deliveryInfo?.customerName ?? 'Customer Name';
    // final time = _deliveryInfo?.assignedDate != null
    //     ? _formatTimestamp(_deliveryInfo!.assignedDate)
    //     : 'Now';
    final distanceText = _distance.isNotEmpty ? _distance : '0.0';
    final timerText = _elapsedTime.inSeconds > 0
        ? '${_elapsedTime.inHours.toString().padLeft(2, '0')}:${(_elapsedTime.inMinutes % 60).toString().padLeft(2, '0')}:${(_elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}'
        : '00:00:00';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.borderLightColor,
            AppColors.cardColor,
            AppColors.backgroundColor,
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
              color: Colors.black26, blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on,
                    color: AppColors.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Address',
                      style: TextStyle(fontSize: 12, color: AppColors.grey600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.warningColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.person, color: AppColors.grey600, size: 20),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer',
                          style:
                              TextStyle(fontSize: 12, color: AppColors.grey600),
                        ),
                        Text(
                          customer,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.warningColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: AppColors.grey600, size: 20),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Time',
                          style:
                              TextStyle(fontSize: 12, color: AppColors.grey600),
                        ),
                        Text(
                          _deliveryStatus == "delivered" ||
                                  _deliveryStatus == "returned"
                              ? (_deliveryTime ?? 'N/A')
                              : timerText,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.warningColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Route Information',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.whiteColor),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildRouteInfo(
                  icon: Icons.directions,
                  title: 'Distance',
                  value: '$distanceText km',
                ),
              ),
              Expanded(
                child: _buildRouteInfo(
                  icon: Icons.cloud,
                  title: 'Weather',
                  value: _weatherCondition,
                  iconWidget: Image.asset(
                    _weatherIconPath,
                    width: 30,
                    height: 30,
                  ),
                ),
              ),
              Expanded(
                child: _buildRouteInfo(
                  icon: Icons.timer,
                  title: 'ETA',
                  value: _duration,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_deliveryStatus == "delivered")
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Delivery Completed Successfully!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (_deliveryStatus == "returned")
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel, color: Colors.red, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Delivery Returned',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (!_isDeliveryStarted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.whiteColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _startDelivery,
                child: const Text(
                  'START DELIVERY',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            )
          else if (_isDeliveryStarted || _showConfirmDelivery)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.whiteColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      _confirmDeliverStatus("delivered");
                    },
                    child: const Text(
                      'CONFIRM',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.redColor,
                      foregroundColor: AppColors.whiteColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      _confirmDeliverStatus("returned");
                    },
                    child: const Text(
                      'RETURNED',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    Widget? iconWidget,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        iconWidget ?? Icon(icon, color: AppColors.grey600, size: 20),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: AppColors.grey600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.whiteColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
