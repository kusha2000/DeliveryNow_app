import 'dart:async';
import 'dart:ui';
import 'package:delivery_now_app/utils/show_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:delivery_now_app/services/firebase_services.dart';
import 'package:delivery_now_app/services/location_services.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/rider_location_model.dart';

class RiderTrackingScreen extends StatefulWidget {
  final String? userId;

  const RiderTrackingScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<RiderTrackingScreen> createState() => _RiderTrackingScreenState();
}

class _RiderTrackingScreenState extends State<RiderTrackingScreen> {
  final LocationService _locationService = LocationService();
  final FirebaseServices _firebaseService = FirebaseServices();
  final Completer<GoogleMapController> _controller = Completer();
  final Map<String, String> _riderNames = {};
  final Map<String, String> _riderStatuses = {};
  final Map<String, BitmapDescriptor> _markerIcons = {};

  int _currentRiderIndex = 0;
  List<RiderLocationModel> _riders = [];

  // Current selected rider ID for highlighting
  String? _selectedRiderId;

  // Store the current camera position to prevent reset
  CameraPosition _currentCameraPosition = CameraPosition(
    target: LatLng(7.478099823, 80.3601989746),
    zoom: 15,
  );

  bool _isMapInitialized = false;

  @override
  void dispose() {
    _markerIcons.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_rounded, color: AppColors.whiteColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.userId != null ? 'Tracking Rider' : 'All Riders',
          style: TextStyle(
            color: AppColors.whiteColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          StreamBuilder<List<RiderLocationModel>>(
            stream: widget.userId != null
                ? _locationService.getRiderLocation(widget.userId!)
                : _locationService.getAllRidersLocations(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                    child: Text(widget.userId != null
                        ? 'Rider not found or offline'
                        : 'No riders online'));
              }

              _riders = snapshot.data!;

              // Set selected rider ID if not set yet
              if (_selectedRiderId == null && _riders.isNotEmpty) {
                _selectedRiderId = _riders[0].riderId;

                // Also set the camera position to the first rider if not yet initialized
                if (!_isMapInitialized) {
                  _currentCameraPosition = CameraPosition(
                    target: LatLng(_riders[0].latitude, _riders[0].longitude),
                    zoom: 15,
                  );
                }
              }

              // Process rider data and ensure we have names and markers
              return FutureBuilder(
                future: _prepareMarkerData(snapshot.data!),
                builder: (context, markerPrepSnapshot) {
                  if (!markerPrepSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return FutureBuilder(
                    future: _createMarkers(snapshot.data!),
                    builder: (context, markerSnapshot) {
                      if (!markerSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return GoogleMap(
                        mapType: MapType.normal,
                        initialCameraPosition: _currentCameraPosition,
                        onMapCreated: (GoogleMapController controller) {
                          _controller.complete(controller);
                          _isMapInitialized = true;

                          if (snapshot.data!.isNotEmpty) {
                            // Find the currently selected rider
                            final selectedRider = snapshot.data!.firstWhere(
                              (rider) => rider.riderId == _selectedRiderId,
                              orElse: () => snapshot.data![0],
                            );

                            // Move camera to selected rider's position
                            _moveCamera(
                              selectedRider.latitude,
                              selectedRider.longitude,
                            );
                          }
                        },
                        markers: markerSnapshot.data!,
                        onCameraMove: (CameraPosition position) {
                          // Save the current camera position
                          _currentCameraPosition = position;
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
          // Show selected rider name and status as an overlay
          if (_selectedRiderId != null)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Current Rider: ${_riderNames[_selectedRiderId] ?? 'Loading...'}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.orangeColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Status: ${_riderStatuses[_selectedRiderId] ?? 'Unknown'}",
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              _getStatusColor(_riderStatuses[_selectedRiderId]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _buildCycleRidersButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  // Helper method to get the color based on status
  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    if (status.toLowerCase() == 'offline') return Colors.red;
    if (status.toLowerCase() == 'absent') return Colors.red;
    if (status.toLowerCase() == 'available') return Colors.green;
    return AppColors.orangeColor; // Default for other statuses
  }

  Widget _buildCycleRidersButton() {
    return FloatingActionButton(
      heroTag: "cycleRiders",
      backgroundColor: Colors.blue,
      child: const Icon(Icons.people),
      onPressed: () {
        if (_riders.isNotEmpty) {
          setState(() {
            _currentRiderIndex = (_currentRiderIndex + 1) % _riders.length;
            _selectedRiderId = _riders[_currentRiderIndex].riderId;
          });

          // Get the current rider
          final currentRider = _riders[_currentRiderIndex];

          // Move camera to rider's location with proper zoom level
          _moveCamera(currentRider.latitude, currentRider.longitude);

          final riderName = _riderNames[currentRider.riderId] ?? 'Rider';
          final riderStatus = _riderStatuses[currentRider.riderId] ?? 'Unknown';
          showToast('Showing $riderName ($riderStatus)', AppColors.orangeColor);
        }
      },
    );
  }

  // New method to ensure all marker data is loaded before map creation
  Future<bool> _prepareMarkerData(List<RiderLocationModel> riders) async {
    List<Future> futures = [];

    for (var rider in riders) {
      if (!_riderNames.containsKey(rider.riderId) ||
          !_riderStatuses.containsKey(rider.riderId)) {
        futures.add(_fetchRiderInfo(rider.riderId));
      }
    }

    // Wait for all rider data to be fetched
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    return true;
  }

  Future<void> _fetchRiderInfo(String riderId) async {
    try {
      final userData = await _firebaseService.getUserData(riderId);
      if (userData != null && mounted) {
        setState(() {
          _riderNames[riderId] = userData.firstName;
          _riderStatuses[riderId] = userData.availabilityStatus;
        });
      }
    } catch (e) {
      print('Error fetching rider info: $e');
      if (mounted) {
        setState(() {
          _riderNames[riderId] = 'Rider';
          _riderStatuses[riderId] = 'Unknown';
        });
      }
    }
  }

  Future<Set<Marker>> _createMarkers(List<RiderLocationModel> riders) async {
    final markers = <Marker>{};

    for (var rider in riders) {
      final riderName = _riderNames[rider.riderId] ?? 'Rider';
      final riderStatus = _riderStatuses[rider.riderId] ?? 'Unknown';
      final isSelected = _selectedRiderId == rider.riderId;
      final isOffline = riderStatus.toLowerCase() == 'offline';
      final isAbsent = riderStatus.toLowerCase() == 'absent';

      // Create custom marker with name label above it
      final marker = Marker(
        markerId: MarkerId(rider.riderId),
        position: LatLng(rider.latitude, rider.longitude),
        icon:
            await _getMarkerIcon(riderName, isSelected, isOffline || isAbsent),
        anchor: const Offset(0.5, 1.0),
        onTap: () {
          setState(() {
            _selectedRiderId = rider.riderId;
            // Find the index of the tapped rider
            final index = _riders.indexWhere((r) => r.riderId == rider.riderId);
            if (index != -1) {
              _currentRiderIndex = index;
            }
          });

          // Move camera to this rider when tapped
          _moveCamera(rider.latitude, rider.longitude);
        },
      );

      markers.add(marker);
    }

    return markers;
  }

  Future<BitmapDescriptor> _getMarkerIcon(
      String riderName, bool isSelected, bool isOfflineOrAbsent) async {
    // Create a key to use for caching
    final String cacheKey =
        '${riderName}_${isSelected ? 'selected' : 'normal'}_${isOfflineOrAbsent ? 'offlineOrAbsent' : 'online'}';

    // Check if we already have this icon cached
    if (_markerIcons.containsKey(cacheKey)) {
      return _markerIcons[cacheKey]!;
    }

    // Create a custom icon with text above it
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // Define marker size and text style
    const double markerSize = 6000.0;

    // Draw text above marker
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: riderName,
        style: TextStyle(
          fontSize: 50,
          fontWeight: FontWeight.bold,
          color: isSelected ? AppColors.orangeColor : Colors.black,
          backgroundColor: Colors.white.withOpacity(0.8),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Calculate position to center the text
    final double xCenter = (markerSize - textPainter.width) / 2;

    // Draw text background
    final Paint bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
        Rect.fromLTWH(
            xCenter - 4, 0, textPainter.width + 8, textPainter.height + 4),
        bgPaint);

    // Draw text
    textPainter.paint(canvas, Offset(xCenter, 2));

    // Draw pin/marker at bottom
    final iconData = Icons.location_on;

    // Set color based on selected and offline/absent status
    Color iconColor;
    if (isOfflineOrAbsent) {
      iconColor = Colors.red;
    } else if (isSelected) {
      iconColor = AppColors.orangeColor;
    } else {
      iconColor = Colors.blue;
    }

    final TextPainter iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: 120,
          fontFamily: iconData.fontFamily,
          color: iconColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        (markerSize - iconPainter.width) / 2,
        textPainter.height + 5,
      ),
    );

    // Convert to ByteData
    final picture = recorder.endRecording();
    final img = await picture.toImage(markerSize.toInt(),
        (textPainter.height + iconPainter.height + 20).toInt());
    final byteData = await img.toByteData(format: ImageByteFormat.png);

    if (byteData == null) {
      // Fallback to default marker if we couldn't create a custom one
      return isOfflineOrAbsent
          ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
          : isSelected
              ? BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }

    // Create a BitmapDescriptor and cache it
    final icon = BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
    _markerIcons[cacheKey] = icon;

    return icon;
  }

  Future<void> _moveCamera(double latitude, double longitude) async {
    if (!_controller.isCompleted) {
      return; // Controller not ready yet
    }

    try {
      final controller = await _controller.future;

      // Use a higher zoom level to actually see the rider
      const double targetZoom = 15.0;

      // Create the new camera position
      final newPosition = CameraPosition(
        target: LatLng(latitude, longitude),
        zoom: targetZoom,
        tilt: 0,
      );

      // Update the stored camera position
      _currentCameraPosition = newPosition;

      await controller.animateCamera(
        CameraUpdate.newCameraPosition(newPosition),
      );
    } catch (e) {
      print('Error moving camera: $e');
    }
  }
}
