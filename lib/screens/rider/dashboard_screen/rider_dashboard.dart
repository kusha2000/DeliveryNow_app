import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_now_app/screens/rider/dashboard_screen/all_feedback_screen.dart';
import 'package:delivery_now_app/screens/rider/dashboard_screen/widgets/feedback_widget.dart';
import 'package:delivery_now_app/screens/rider/dashboard_screen/widgets/stat_card_widget.dart';
import 'package:delivery_now_app/shared/screens/all_deliveries.dart';
import 'package:delivery_now_app/shared/screens/one_delivery_details.dart';
import 'package:delivery_now_app/shared/widgets/section_title.dart';
import 'package:flutter/material.dart';
import 'package:delivery_now_app/models/user_model.dart';
import 'package:delivery_now_app/services/firebase_services.dart';
import 'package:delivery_now_app/shared/widgets/delivery_item_widget.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'package:delivery_now_app/models/delivery_model.dart';
import 'package:intl/intl.dart';

class RiderDashboard extends StatefulWidget {
  const RiderDashboard({super.key});

  @override
  State<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard> {
  final FirebaseServices _firebaseServices = FirebaseServices();
  String? _riderId;
  DateTime _selectedDate = DateTime.now();
  List<DeliveryModel> _deliveries = [];
  List<DeliveryModel> _previousDayDeliveries = [];
  bool _isLoading = true;
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _riderId = _firebaseServices.getCurrentUserID();
    _fetchDeliveries();
  }

  Future<void> _fetchDeliveries() async {
    setState(() => _isLoading = true);
    try {
      String? riderId = _firebaseServices.getCurrentUserID();
      if (riderId != null) {
        final deliveries = await _firebaseServices.getDeliveriesByDate(
          riderId: riderId,
          date: _selectedDate,
        );

        // Fetch previous day's deliveries
        final previousDay = _selectedDate.subtract(Duration(days: 1));
        final previousDeliveries = await _firebaseServices.getDeliveriesByDate(
          riderId: riderId,
          date: previousDay,
        );

        double totalRating = 0.0;
        int ratedDeliveries = 0;

        for (var delivery in deliveries) {
          if (delivery.stars != null) {
            totalRating += delivery.stars!;
            ratedDeliveries++;
          }
        }

        setState(() {
          _deliveries = deliveries;
          _previousDayDeliveries = previousDeliveries;
          _averageRating =
              ratedDeliveries > 0 ? totalRating / ratedDeliveries : 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching deliveries: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _fetchDeliveries();
    }
  }

  double _calculateTotalEarnings(List<DeliveryModel> deliveries) {
    return deliveries
        .where((delivery) => delivery.status == 'delivered')
        .fold(0.0, (sum, delivery) => sum + delivery.price);
  }

  int _countCompletedDeliveries(List<DeliveryModel> deliveries) {
    return deliveries
        .where((delivery) => delivery.status == 'delivered')
        .length;
  }

  String _getEarningsSubtitle() {
    final currentEarnings = _calculateTotalEarnings(_deliveries);
    final previousEarnings = _calculateTotalEarnings(_previousDayDeliveries);
    final difference = currentEarnings - previousEarnings;

    if (difference > 0) {
      return '+Rs.${difference.toStringAsFixed(2)} from yesterday';
    } else if (difference < 0) {
      return '-Rs.${(-difference).toStringAsFixed(2)} from yesterday';
    } else {
      return 'Same as yesterday';
    }
  }

  String _getDeliveriesSubtitle() {
    final currentCount = _countCompletedDeliveries(_deliveries);
    final previousCount = _countCompletedDeliveries(_previousDayDeliveries);
    final difference = currentCount - previousCount;

    if (difference > 0) {
      return '+$difference from yesterday';
    } else if (difference < 0) {
      return '$difference from yesterday';
    } else {
      return 'Same as yesterday';
    }
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              Icon(
                Icons.trending_up,
                color: AppColors.textSecondaryColor,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimaryColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: subtitle.contains('+')
                  ? AppColors.successColor
                  : subtitle.contains('-')
                      ? AppColors.errorColor
                      : AppColors.textMutedColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromARGB(255, 62, 5, 97),
            AppColors.surfaceColor,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Feedback Overview',
                style: TextStyle(
                  color: AppColors.textPrimaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppColors.orangeColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.textPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            children: _deliveries
                .asMap()
                .entries
                .where((entry) =>
                    entry.value.feedback != null &&
                    entry.value.feedback!.isNotEmpty)
                .take(3)
                .map((entry) {
              final delivery = entry.value;
              return Column(
                children: [
                  if (entry.key != 0)
                    Divider(height: 1, color: AppColors.borderLightColor),
                  feedbackWidget(
                    name: delivery.customerName,
                    comment: delivery.feedback!,
                    time: formatTimeAgo(delivery.updatedAt),
                    rating: (delivery.stars ?? 0).toInt(),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllFeedbacksScreen(
                      deliveries: _deliveries,
                      date: _selectedDate,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.visibility,
                color: AppColors.primaryColor,
                size: 18,
              ),
              label: const Text(
                'View All Feedback',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_riderId == null) {
      return Scaffold(
        body: Center(child: Text('Please log in to view performance')),
      );
    }

    final dateFormatter = DateFormat.yMMMMd();
    final formattedDate = dateFormatter.format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              StreamBuilder<UserModel?>(
                stream: _firebaseServices.getUserDataStream(),
                builder: (context, snapshot) {
                  String firstName = snapshot.data?.firstName ?? 'Rider';
                  String? profileImageBase64 = snapshot.data?.profileImage;
                  Widget profileImageWidget;

                  if (profileImageBase64 != null &&
                      profileImageBase64.isNotEmpty) {
                    try {
                      profileImageWidget = CircleAvatar(
                        radius: 25,
                        backgroundImage: MemoryImage(
                          base64Decode(profileImageBase64),
                        ),
                      );
                    } catch (e) {
                      profileImageWidget = CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(
                          'https://randomuser.me/api/portraits/men/1.jpg',
                        ),
                      );
                    }
                  } else {
                    profileImageWidget = CircleAvatar(
                      radius: 25,
                      backgroundImage: NetworkImage(
                        'https://randomuser.me/api/portraits/men/1.jpg',
                      ),
                    );
                  }

                  return Container(
                    padding: EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back_rounded,
                                          color: AppColors.textPrimaryColor),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    Text(
                                      'Hello, $firstName',
                                      style: TextStyle(
                                        color: AppColors.whiteColor,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Welcome back to Dashboard',
                                  style: TextStyle(
                                    color:
                                        AppColors.whiteColor.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            profileImageWidget,
                          ],
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),

              // Stats Section
              Padding(
                padding: EdgeInsets.all(20),
                child: StreamBuilder<List<DeliveryModel>>(
                  stream: _firebaseServices.getRiderDeliveries(_riderId!),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final deliveries = snapshot.data!;

                    // Calculate stats
                    int stars = deliveries.fold(
                        0, (sum, d) => sum + (d.stars?.toInt() ?? 0));
                    int reviews =
                        deliveries.where((d) => d.feedback != null).length;
                    int pending =
                        deliveries.where((d) => d.status == 'pending').length;
                    int inTransit = deliveries
                        .where((d) => d.status == 'in_transit')
                        .length;
                    int delivered =
                        deliveries.where((d) => d.status == 'delivered').length;
                    int returned =
                        deliveries.where((d) => d.status == 'returned').length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildSectionTitle("Delivery Stats"),
                        SizedBox(height: 15),
                        Row(
                          children: [
                            statCardWidget(
                              stars.toString(),
                              'Stars',
                              AppColors.orangeColor,
                              Icons.star,
                            ),
                            SizedBox(width: 15),
                            statCardWidget(
                              reviews.toString(),
                              'Reviews',
                              AppColors.purpleColor,
                              Icons.reviews,
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        Row(
                          children: [
                            statCardWidget(
                              pending.toString(),
                              'Pending',
                              AppColors.redColor,
                              Icons.hourglass_empty,
                            ),
                            SizedBox(width: 15),
                            statCardWidget(
                              inTransit.toString(),
                              'In Transit',
                              AppColors.primaryColor,
                              Icons.local_shipping,
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        Row(
                          children: [
                            statCardWidget(
                              delivered.toString(),
                              'Delivered',
                              AppColors.greenColor,
                              Icons.check_circle,
                            ),
                            SizedBox(width: 15),
                            statCardWidget(
                              returned.toString(),
                              'Returned',
                              AppColors.brownColor,
                              Icons.keyboard_return,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Modern Daily Summary Section
              Container(
                margin: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.backgroundColor,
                            AppColors.surfaceColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border:
                            Border.all(color: AppColors.borderColor, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowColor,
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Daily Summary',
                                style: TextStyle(
                                  color: AppColors.textPrimaryColor,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  color: AppColors.textSecondaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.calendar_today,
                                color: AppColors.primaryColor,
                                size: 24,
                              ),
                              onPressed: () => _selectDate(context),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Stats Cards
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernStatCard(
                                      title: 'Total Deliveries',
                                      value:
                                          _countCompletedDeliveries(_deliveries)
                                              .toString(),
                                      subtitle: _getDeliveriesSubtitle(),
                                      icon: Icons.delivery_dining,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildModernStatCard(
                                      title: 'Estimated Earnings',
                                      value:
                                          'Rs.${_calculateTotalEarnings(_deliveries).toStringAsFixed(0)}',
                                      subtitle: _getEarningsSubtitle(),
                                      icon: Icons.attach_money,
                                      color: AppColors.emeraldColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildFeedbackCard(),
                            ],
                          ),
                  ],
                ),
              ),

              // Recent Deliveries
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildSectionTitle("Recent Deliveries"),
                        TextButton(
                          onPressed: () {
                          },
                          child: Text(
                            'View All',
                            style: TextStyle(color: AppColors.primaryColor),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    StreamBuilder<List<DeliveryModel>>(
                      stream:
                          _firebaseServices.getLatestRiderDeliveries(_riderId!),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }
                        final deliveries = snapshot.data!;
                        if (deliveries.isEmpty) {
                          return Text('No recent deliveries');
                        }
                        return Column(
                          children: deliveries.map((delivery) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OneDeliveryDetailsScreen(
                                      deliveryId: delivery.id,
                                    ),
                                  ),
                                );
                              },
                              child: deliveryItemWidget(
                                delivery.packageId,
                                delivery.customerName,
                                delivery.address,
                                delivery.status,
                                delivery.assignedDate,
                                _getStatusColor(delivery.status),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.greenColor;
      case 'pending':
        return AppColors.redColor;
      case 'in_transit':
        return AppColors.primaryColor;
      case 'returned':
        return AppColors.brownColor;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppColors.grey100;
    }
  }
}
