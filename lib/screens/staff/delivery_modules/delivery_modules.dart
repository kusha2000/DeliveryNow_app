// ignore_for_file: unused_local_variable

import 'package:delivery_now_app/shared/widgets/customer_delivery_item_with_chat_widget.dart';
import 'package:delivery_now_app/utils/show_toast.dart';
import 'package:flutter/material.dart';
import 'package:delivery_now_app/models/delivery_model.dart';
import 'package:delivery_now_app/models/user_model.dart';
import 'package:delivery_now_app/screens/Staff/delivery_modules/all_delivery_history_screen.dart';
import 'package:delivery_now_app/screens/Staff/delivery_modules/assign_new_delivery_screen.dart';
import 'package:delivery_now_app/screens/Staff/delivery_modules/edit_delivery_screen.dart';
import 'package:delivery_now_app/services/firebase_services.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'package:delivery_now_app/utils/styles.dart';

class DeliveriesModuleScreen extends StatefulWidget {
  const DeliveriesModuleScreen({super.key});

  @override
  State<DeliveriesModuleScreen> createState() => _DeliveriesModuleScreenState();
}

class _DeliveriesModuleScreenState extends State<DeliveriesModuleScreen>
    with TickerProviderStateMixin {
  UserModel? _selectedDriver;
  List<UserModel> _drivers = [];
  final FirebaseServices _firebaseServices = FirebaseServices();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Add missing prediction state variables
  final Map<String, bool> _loadingPredictions = {};
  final Map<String, double> _deliveryPredictions = {};

  @override
  void initState() {
    super.initState();
    _loadDrivers();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDrivers() async {
    try {
      final drivers = await _firebaseServices.getAllRiders();
      setState(() {
        _drivers = drivers;
      });
    } catch (e) {
      print('Error loading drivers: $e');
      showToast('Error loading drivers', AppColors.redColor);
    }
  }

  Widget _buildModernDriverCard() {
    if (_selectedDriver == null) return const SizedBox.shrink();

    // Determine if driver is offline/absent
    bool isOfflineOrAbsent =
        _selectedDriver?.availabilityStatus.toUpperCase() == "OFFLINE" ||
            _selectedDriver?.availabilityStatus.toUpperCase() == "ABSENT";

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: isOfflineOrAbsent
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.errorColor,
                  AppColors.redColor.withOpacity(0.8),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.successColor,
                  AppColors.emeraldColor,
                ],
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isOfflineOrAbsent
                ? AppColors.errorColor.withOpacity(0.4)
                : AppColors.successColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.whiteColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.person_rounded,
                color: AppColors.whiteColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedDriver!.firstName} ${_selectedDriver!.lastName}',
                    style: const TextStyle(
                      color: AppColors.whiteColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _selectedDriver?.availabilityStatus.toUpperCase() ??
                          'UNKNOWN',
                      style: const TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.whiteColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getStatusIcon(_selectedDriver?.availabilityStatus),
                color: AppColors.whiteColor,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'available':
        return Icons.check_circle_rounded;
      case 'busy':
        return Icons.access_time_rounded;
      case 'offline':
      case 'absent':
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  Widget _buildModernActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required bool isEnabled,
    required LinearGradient gradient,
    String? subtitle,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isEnabled ? gradient : null,
              color: isEnabled ? null : AppColors.grey300,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: AppColors.grey400.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        AppColors.whiteColor.withOpacity(isEnabled ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: isEnabled ? AppColors.whiteColor : AppColors.grey600,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isEnabled
                              ? AppColors.whiteColor
                              : AppColors.grey600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: isEnabled
                                ? AppColors.whiteColor.withOpacity(0.8)
                                : AppColors.grey500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isEnabled
                      ? AppColors.whiteColor.withOpacity(0.8)
                      : AppColors.grey500,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: AppDecorations.containerVioletGradientDecoration(
        borderRadius: 24,
        boxShadow: [
          BoxShadow(
            color: AppColors.violetColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.whiteColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.my_location_rounded,
                  color: AppColors.whiteColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Track Rider Location',
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monitor real-time delivery progress',
                      style: TextStyle(
                        color: AppColors.whiteColor.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(
                Icons.location_searching_rounded,
                color: AppColors.violetColor,
                size: 24,
              ),
              label: Text(
                'Start Live Tracking',
                style: TextStyle(
                  color: AppColors.violetColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.whiteColor,
                foregroundColor: AppColors.violetColor,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () {
                if (_selectedDriver == null) {
                  showToast("Select the Driver First", AppColors.redColor);
                  return;
                }
                // Add tracking functionality here
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          if (onViewAll != null)
            TextButton.icon(
              onPressed: onViewAll,
              icon: Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primaryColor,
                size: 20,
              ),
              label: Text(
                "View All",
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryItemWithPredict(DeliveryModel delivery) {
    final isLoading = _loadingPredictions[delivery.id] ?? false;
    final prediction = _deliveryPredictions[delivery.id];

    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'pending':
          return AppColors.orangeColor;
        case 'in_progress':
        case 'picked_up':
          return AppColors.primaryColor;
        case 'delivered':
          return AppColors.greenColor;
        case 'cancelled':
          return AppColors.redColor;
        default:
          return AppColors.greyColor;
      }
    }

    return customerDeliveryItemWithChatWidget(
      id: delivery.packageId,
      name: delivery.customerName,
      address: delivery.address,
      status: delivery.status,
      date: delivery.assignedDate,
      statusColor: getStatusColor(delivery.status),
      context: context,
      customerId: delivery.customerId,
      customerName: delivery.customerName,
      orderId: delivery.packageId,
      isCustomer: false,
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: AppDecorations.containerWhiteDecoration(
        borderRadius: 24,
        boxShadow: [
          BoxShadow(
            color: AppColors.lightShadowColor,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.tealColor.withOpacity(0.1),
                  AppColors.cyanColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.local_shipping_outlined,
              size: 64,
              color: AppColors.tealColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No pending deliveries',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedDriver == null
                ? 'Select a driver to view their deliveries'
                : 'All deliveries have been completed successfully',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern App Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.backgroundColor,
                      AppColors.surfaceColor,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.backgroundColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Back Button
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.whiteColor,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Title
                    Expanded(
                      child: Text(
                        "Delivery Hub",
                        style: TextStyle(
                          color: AppColors.whiteColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    // Driver Selector
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: AppColors.whiteColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: DropdownButton<UserModel>(
                        value: _selectedDriver,
                        hint: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.whiteColor,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Driver",
                              style: TextStyle(
                                color: AppColors.whiteColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        icon: Icon(
                          Icons.expand_more_rounded,
                          color: AppColors.whiteColor,
                          size: 18,
                        ),
                        underline: Container(),
                        dropdownColor: AppColors.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        items: _drivers.map((UserModel driver) {
                          return DropdownMenuItem<UserModel>(
                            value: driver,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.person_rounded,
                                      color: AppColors.primaryColor,
                                      size: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '${driver.firstName} ${driver.lastName}',
                                      style: TextStyle(
                                        color: AppColors.textPrimaryColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (UserModel? newValue) {
                          setState(() {
                            _selectedDriver = newValue;
                            _loadingPredictions.clear();
                            _deliveryPredictions.clear();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Driver Card
                          _buildModernDriverCard(),

                          // Action Cards
                          _buildModernActionCard(
                            title: "Assign New Delivery",
                            subtitle: "Create and assign delivery orders",
                            icon: Icons.add_circle_rounded,
                            gradient:
                                AppDecorations.containerProfessionalDarkDecoration()
                                    .gradient as LinearGradient,
                            isEnabled: _selectedDriver?.availabilityStatus !=
                                    'absent' &&
                                _selectedDriver != null,
                            onTap: () {
                              if (_selectedDriver?.availabilityStatus ==
                                      'offline' ||
                                  _selectedDriver?.availabilityStatus ==
                                      'absent') {
                                showToast("The Driver is not Available",
                                    AppColors.redColor);
                              } else if (_selectedDriver == null) {
                                showToast("Select the Driver First",
                                    AppColors.redColor);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AssignNewDelivery(
                                      selectedRider: _selectedDriver,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),

                          _buildModernActionCard(
                            title: "Edit/Cancel Deliveries",
                            subtitle: "Modify existing delivery orders",
                            icon: Icons.edit_rounded,
                            gradient:
                                AppDecorations.containerProfessionalMediumDecoration()
                                    .gradient as LinearGradient,
                            isEnabled: _selectedDriver != null,
                            onTap: () {
                              if (_selectedDriver == null) {
                                showToast("Select the Driver First",
                                    AppColors.redColor);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditDeliveryScreen(
                                      selectedRider: _selectedDriver,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),

                          // Tracking Section
                          _buildTrackingSection(),

                          // Deliveries Section
                          _buildSectionHeader(
                            "Pending Deliveries",
                            onViewAll: _selectedDriver != null
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AllDeliveryHistoryScreen(
                                          selectedRider: _selectedDriver,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                          ),

                          // Deliveries List
                          StreamBuilder<List<DeliveryModel>>(
                            stream: _firebaseServices
                                .getRiderDeliveries(_selectedDriver?.uid ?? ''),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration:
                                      AppDecorations.containerWhiteDecoration(
                                    borderRadius: 20,
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        size: 64,
                                        color: AppColors.errorColor,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Error loading deliveries',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: AppColors.errorColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (!snapshot.hasData) {
                                return Container(
                                  padding: const EdgeInsets.all(40),
                                  decoration:
                                      AppDecorations.containerWhiteDecoration(
                                    borderRadius: 20,
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: AppColors.primaryGradient,
                                            borderRadius:
                                                BorderRadius.circular(50),
                                          ),
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              AppColors.whiteColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'Loading deliveries...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: AppColors.textSecondaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final allDeliveries = snapshot.data!;
                              final pendingDeliveries = allDeliveries
                                  .where((delivery) =>
                                      delivery.status == 'pending')
                                  .toList();

                              if (pendingDeliveries.isEmpty) {
                                return _buildEmptyState();
                              }

                              return Column(
                                children: pendingDeliveries
                                    .map((delivery) => Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 12),
                                          child: _buildDeliveryItemWithPredict(
                                              delivery),
                                        ))
                                    .toList(),
                              );
                            },
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
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
