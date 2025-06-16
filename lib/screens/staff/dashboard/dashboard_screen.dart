import 'dart:convert';

import 'package:delivery_now_app/screens/staff/dashboard/all_feedbacks_screen.dart';
import 'package:flutter/material.dart';

import 'package:delivery_now_app/utils/colors.dart';
import 'package:delivery_now_app/utils/styles.dart';
import 'package:delivery_now_app/services/firebase_services.dart';
import 'package:delivery_now_app/models/delivery_model.dart';
import 'package:delivery_now_app/models/user_model.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final FirebaseServices _firebaseServices = FirebaseServices();
  DateTime _selectedDate = DateTime.now();
  int _absentRiders = 0;
  int _badDeliveries = 0;
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  Map<String, int> _packageStatus = {
    'Total': 0,
    'Delivered': 0,
    'In Transit': 0,
    'On the Way': 0,
    'Pending': 0,
    'Returned': 0,
  };
  Map<String, int> _riderStatus = {
    'Online': 0,
    'Busy': 0,
    'Offline': 0,
    'Absent': 0,
  };
  Map<String, int> _feedbackStatus = {
    '5 Stars': 0,
    '4 Stars': 0,
    '3 Stars': 0,
    '2 Stars': 0,
    '1 Star': 0,
  };
  // ignore: unused_field
  int _offlineRiders = 0;
  bool _isLoading = true;
  bool _isPlayerInitialized = false;
  final Map<String, bool> _isPlayingMap = {};
  List<DeliveryModel> _deliveries = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _initializePlayer();
    _fetchDataForDate(_selectedDate);
    _fetchDeliveries();
    _animationController.forward();
  }

  Future<void> _initializePlayer() async {
    await _player.openPlayer();
    setState(() {
      _isPlayerInitialized = true;
    });
  }

  Future<void> _fetchDeliveries() async {
    try {
      final deliveries = await _firebaseServices.fetchAllDeliveries();
      setState(() {
        _deliveries = deliveries
            .where((d) => d.voiceFeedback != null || d.stars != null)
            .toList();
        for (var delivery in _deliveries) {
          _isPlayingMap[delivery.id] = false;
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching deliveries: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDataForDate(DateTime date) async {
    int badDeliveries = 0;
    setState(() {
      _isLoading = true;
    });

    try {
      List<DeliveryModel> deliveries =
          await _firebaseServices.fetchAllDeliveriesByDate(date: date);

      Map<String, int> packageStatus = {
        'Total': deliveries.length,
        'Delivered': 0,
        'In Transit': 0,
        'On the Way': 0,
        'Pending': 0,
        'Returned': 0,
      };

      Map<String, int> feedbackStatus = {
        '5 Stars': 0,
        '4 Stars': 0,
        '3 Stars': 0,
        '2 Stars': 0,
        '1 Star': 0,
      };

      for (var delivery in deliveries) {
        switch (delivery.status) {
          case 'delivered':
            packageStatus['Delivered'] = packageStatus['Delivered']! + 1;
            break;
          case 'in_transit':
            packageStatus['In Transit'] = packageStatus['In Transit']! + 1;
            break;
          case 'on_the_way':
            packageStatus['On the Way'] = packageStatus['On the Way']! + 1;
            break;
          case 'pending':
            packageStatus['Pending'] = packageStatus['Pending']! + 1;
            break;
          case 'returned':
            packageStatus['Returned'] = packageStatus['Returned']! + 1;
            break;
        }

        if (delivery.stars != null) {
          int stars = delivery.stars!.toInt();
          if (stars >= 1 && stars <= 5) {
            String key = '$stars Star${stars > 1 ? 's' : ''}';
            feedbackStatus[key] = feedbackStatus[key]! + 1;
            if (stars <= 2) {
              badDeliveries++;
            }
          }
        }
      }

      List<UserModel> riders = await _firebaseServices.getAllRiders();
      Map<String, int> riderStatus = {
        'Online': 0,
        'Busy': 0,
        'Offline': 0,
        'Absent': 0,
      };

      String dateKey = DateFormat('yyyy-MM-dd').format(date);
      int absentCount = 0;
      int onlineCount = 0;
      int busyCount = 0;
      int offlineCount = 0;

      for (var rider in riders) {
        if (rider.attendanceRecords != null &&
            rider.attendanceRecords!.containsKey(dateKey) &&
            rider.attendanceRecords![dateKey] == 'absent') {
          absentCount++;
        } else if (DateFormat('yyyy-MM-dd').format(date) ==
            DateFormat('yyyy-MM-dd').format(DateTime.now())) {
          switch (rider.availabilityStatus) {
            case 'available':
              onlineCount++;
              break;
            case 'busy':
              busyCount++;
              break;
            case 'offline':
              offlineCount++;
              break;
            case 'absent':
              absentCount++;
              break;
          }
        } else {
          offlineCount++;
        }
      }

      riderStatus['Online'] = onlineCount;
      riderStatus['Busy'] = busyCount;
      riderStatus['Offline'] = offlineCount;
      riderStatus['Absent'] = absentCount;

      setState(() {
        _packageStatus = packageStatus;
        _riderStatus = riderStatus;
        _feedbackStatus = feedbackStatus;
        _offlineRiders = offlineCount;
        _absentRiders = absentCount;
        _badDeliveries = badDeliveries;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _playAudio(String base64Audio, String deliveryId) async {
    if (!_isPlayerInitialized) return;
    try {
      await _stopAudio();
      final bytes = base64Decode(base64Audio);
      await _player.startPlayer(
        fromDataBuffer: bytes,
        codec: Codec.aacADTS,
        whenFinished: () {
          setState(() {
            _isPlayingMap[deliveryId] = false;
          });
        },
      );
      setState(() {
        _isPlayingMap[deliveryId] = true;
      });
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> _stopAudio() async {
    if (!_isPlayerInitialized) return;
    try {
      await _player.stopPlayer();
      setState(() {
        _isPlayingMap.updateAll((key, value) => false);
      });
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: AppColors.whiteColor,
              surface: AppColors.whiteColor,
              onSurface: AppColors.blackColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _fetchDataForDate(picked);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _player.closePlayer();
    super.dispose();
  }

  // Modern Stats Card Widget
  Widget _buildModernStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required BoxDecoration decoration,
    bool isLarge = false,
  }) {
    return Container(
      height: isLarge ? 150 : 140,
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.whiteColor,
                    size: 20,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.whiteColor,
                    fontSize: isLarge ? 32 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.whiteColor.withOpacity(0.8),
                    fontSize: isLarge ? 16 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Modern Rating Widget
  Widget _buildModernRatingCard({
    required String title,
    required String value,
    required int stars,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.containerWhiteDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => Icon(
                index < stars ? Icons.star : Icons.star_border,
                color: color,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Modern Alert Widget
  Widget _buildModernAlert({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.whiteColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modern Voice Feedback Widget
  Widget _buildModernVoiceFeedback(DeliveryModel delivery) {
    bool isPlaying = _isPlayingMap[delivery.id] ?? false;
    Color ratingColor = delivery.stars != null
        ? (delivery.stars! >= 4
            ? AppColors.greenColor
            : delivery.stars! == 3
                ? AppColors.orangeColor
                : AppColors.redColor)
        : AppColors.greyColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.containerWhiteDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ratingColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person,
                  color: ratingColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delivery.customerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.whiteColor),
                    ),
                    if (delivery.stars != null)
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (index) => Icon(
                              index < delivery.stars!
                                  ? Icons.star
                                  : Icons.star_border,
                              color: ratingColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${delivery.stars}/5',
                            style: TextStyle(
                              color: ratingColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color:
                      isPlaying ? AppColors.redColor : AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    isPlaying ? Icons.stop : Icons.play_arrow,
                    color: AppColors.whiteColor,
                  ),
                  onPressed: () {
                    if (isPlaying) {
                      _stopAudio();
                    } else {
                      _playAudio(delivery.voiceFeedback!, delivery.id);
                    }
                  },
                ),
              ),
            ],
          ),
          if (delivery.voiceFeedbackPrediction != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                delivery.voiceFeedbackPrediction!,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  slivers: [
                    // Modern App Bar
                    SliverAppBar(
                      expandedHeight: 100,
                      floating: false,
                      pinned: true,
                      backgroundColor: AppColors.backgroundColor,
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: AppColors.whiteColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                      title: Text(
                        'Dashboard',
                        style: TextStyle(
                          color: AppColors.whiteColor,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      centerTitle: false,
                      actions: [
                        Container(
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.calendar_today,
                                color: AppColors.whiteColor),
                            onPressed: () => _selectDate(context),
                          ),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.backgroundGradient,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  DateFormat('EEEE, MMMM dd, yyyy')
                                      .format(_selectedDate),
                                  style: TextStyle(
                                    color:
                                        AppColors.whiteColor.withOpacity(0.8),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                'Package Status',
                                style: TextStyle(
                                  color: AppColors.whiteColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildModernStatsCard(
                                    title: 'Total Packages',
                                    value: _packageStatus['Total'].toString(),
                                    icon: Icons.inventory_2,
                                    color: AppColors.primaryColor,
                                    decoration: AppDecorations
                                        .containerMidnightDecoration(),
                                    isLarge: true,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    children: [
                                      _buildModernStatsCard(
                                        title: 'Delivered',
                                        value: _packageStatus['Delivered']
                                            .toString(),
                                        icon: Icons.check_circle,
                                        color: AppColors.greenColor,
                                        decoration: AppDecorations
                                            .containerDarkEleganceDecoration(),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildModernStatsCard(
                                        title: 'Pending',
                                        value: _packageStatus['Pending']
                                            .toString(),
                                        icon: Icons.hourglass_empty,
                                        color: AppColors.orangeColor,
                                        decoration: AppDecorations
                                            .containerLuxuryPurpleDecoration(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Package Status Grid

                            Row(
                              children: [
                                Expanded(
                                  child: _buildModernStatsCard(
                                    title: 'In Transit',
                                    value:
                                        _packageStatus['In Transit'].toString(),
                                    icon: Icons.local_shipping,
                                    color: AppColors.indigoColor,
                                    decoration: AppDecorations
                                        .containerDarkForestDecoration(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildModernStatsCard(
                                    title: 'On the Way',
                                    value:
                                        _packageStatus['On the Way'].toString(),
                                    icon: Icons.directions_bike,
                                    color: AppColors.cyanColor,
                                    decoration: AppDecorations
                                        .containerVioletGradientDecoration(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildModernStatsCard(
                                    title: 'Returned',
                                    value:
                                        _packageStatus['Returned'].toString(),
                                    icon: Icons.keyboard_return,
                                    color: AppColors.greyColor,
                                    decoration: AppDecorations
                                        .containerCrimsonLuxuryDecoration(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Rider Status
                            Center(
                              child: Text(
                                'Rider Status',
                                style: TextStyle(
                                  color: AppColors.whiteColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildModernStatsCard(
                                    title: 'Online',
                                    value: _riderStatus['Online'].toString(),
                                    icon: Icons.cloud_done,
                                    color: AppColors.greenColor,
                                    decoration: AppDecorations
                                        .containerMidnightDecoration(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildModernStatsCard(
                                    title: 'Busy',
                                    value: _riderStatus['Busy'].toString(),
                                    icon: Icons.do_not_disturb_on,
                                    color: AppColors.orangeColor,
                                    decoration: AppDecorations
                                        .containerLuxuryPurpleDecoration(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildModernStatsCard(
                                    title: 'Offline',
                                    value: _riderStatus['Offline'].toString(),
                                    icon: Icons.cloud_off,
                                    color: AppColors.greyColor,
                                    decoration: AppDecorations
                                        .containerDarkEleganceDecoration(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildModernStatsCard(
                                    title: 'Absent',
                                    value: _riderStatus['Absent'].toString(),
                                    icon: Icons.not_interested,
                                    color: AppColors.redColor,
                                    decoration: AppDecorations
                                        .containerCrimsonLuxuryDecoration(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Live Tracking Button
                            Container(
                              width: double.infinity,
                              height: 60,
                              decoration: AppDecorations
                                  .containerGoldGradientDecoration(),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    // Navigate to tracking screen
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.location_searching,
                                        color: AppColors.whiteColor,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Riders Live Tracking',
                                        style: TextStyle(
                                          color: AppColors.whiteColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Alerts Section
                            Center(
                              child: Text(
                                'Staffing Alerts',
                                style: TextStyle(
                                  color: AppColors.whiteColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_absentRiders > 0)
                              _buildModernAlert(
                                message: '$_absentRiders Riders absent today',
                                icon: Icons.warning,
                                color: AppColors.redColor,
                              ),
                            if (_badDeliveries > 0)
                              _buildModernAlert(
                                message:
                                    '$_badDeliveries Bad deliveries reported',
                                icon: Icons.thumb_down,
                                color: AppColors.orangeColor,
                              ),
                            if (_absentRiders == 0 && _badDeliveries == 0)
                              _buildModernAlert(
                                message: 'All systems running smoothly',
                                icon: Icons.check_circle,
                                color: AppColors.greenColor,
                              ),
                            const SizedBox(height: 32),

                            // Feedback Ratings
                            Center(
                              child: Text(
                                'Customer Feedback',
                                style: TextStyle(
                                  color: AppColors.whiteColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildModernRatingCard(
                                    title: '4 Stars',
                                    value:
                                        _feedbackStatus['4 Stars'].toString(),
                                    stars: 4,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildModernRatingCard(
                                    title: '3 Stars',
                                    value:
                                        _feedbackStatus['3 Stars'].toString(),
                                    stars: 3,
                                    color: AppColors.orangeColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Container(
                              width: double.infinity,
                              child: Center(
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      0.6, // Make it larger
                                  child: _buildModernRatingCard(
                                    title: '5 Stars',
                                    value:
                                        _feedbackStatus['5 Stars'].toString(),
                                    stars: 5,
                                    color: AppColors.greenColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildModernRatingCard(
                                    title: '2 Stars',
                                    value:
                                        _feedbackStatus['2 Stars'].toString(),
                                    stars: 2,
                                    color: AppColors.greyColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildModernRatingCard(
                                    title: '1 Star',
                                    value: _feedbackStatus['1 Star'].toString(),
                                    stars: 1,
                                    color: AppColors.redColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Voice Feedback Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Center(
                                  child: Text(
                                    'Voice Feedback',
                                    style: TextStyle(
                                      color: AppColors.whiteColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AllFeedbacksScreen(
                                                deliveries: _deliveries),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'View All',
                                    style: TextStyle(
                                        color: AppColors.primaryColor),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Voice Feedback List
                            if (_deliveries
                                .where((d) => d.voiceFeedback != null)
                                .isEmpty)
                              Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(24),
                                decoration:
                                    AppDecorations.containerWhiteDecoration(),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.mic_off,
                                      size: 48,
                                      color: AppColors.greyColor,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No voice feedback available',
                                      style: TextStyle(
                                        color: AppColors.textSecondaryColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Column(
                                children: _deliveries
                                    .where((d) => d.voiceFeedback != null)
                                    .take(3)
                                    .map((delivery) =>
                                        _buildModernVoiceFeedback(delivery))
                                    .toList(),
                              ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
