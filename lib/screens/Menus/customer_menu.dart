import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_now_app/models/delivery_model.dart';
import 'package:delivery_now_app/services/auth_service.dart';
import 'package:delivery_now_app/services/firebase_services.dart';
import 'package:delivery_now_app/services/notification_services.dart';
import 'package:delivery_now_app/shared/widgets/customer_delivery_item_with_chat_widget.dart';
import 'package:flutter/material.dart';
import 'package:delivery_now_app/models/user_model.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'dart:convert';
import 'dart:typed_data';

class CustomerMenu extends StatefulWidget {
  const CustomerMenu({super.key});

  @override
  State<CustomerMenu> createState() => _CustomerMenuState();
}

class _CustomerMenuState extends State<CustomerMenu>
    with TickerProviderStateMixin {
  final FirebaseServices _firebaseServices = FirebaseServices();
  late AnimationController _animationController;
  late AnimationController _bottomSheetController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bottomSlideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _bottomSheetController = AnimationController(
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
      curve: Curves.easeOutBack,
    ));

    _bottomSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bottomSheetController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      _bottomSheetController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bottomSheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: FutureBuilder<UserModel?>(
            future: _firebaseServices
                .getUserData(_firebaseServices.getCurrentUser()?.uid ?? ''),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (userSnapshot.hasError || !userSnapshot.hasData) {
                return const Center(child: Text('Error loading user data'));
              }

              final user = userSnapshot.data!;
              final capitalizedFirstName = user.firstName.isNotEmpty
                  ? '${user.firstName[0].toUpperCase()}${user.firstName.substring(1).toLowerCase()}'
                  : '';
              final capitalizedLastName = user.lastName.isNotEmpty
                  ? '${user.lastName[0].toUpperCase()}${user.lastName.substring(1).toLowerCase()}'
                  : '';

              return Stack(
                children: [
                  // Welcome Text
                  _buildWelcomeText(),

                  // Main Content Area
                  Padding(
                    padding: const EdgeInsets.only(top: 100, bottom: 180),
                    child: StreamBuilder<List<DeliveryModel>>(
                      stream:
                          FirebaseServices().getCustomerDeliveries(user.uid),
                      builder: (context, deliverySnapshot) {
                        if (deliverySnapshot.hasError) {
                          return const Center(
                              child: Text('Error loading deliveries'));
                        }
                        if (!deliverySnapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final deliveries = deliverySnapshot.data!;

                        if (deliveries.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No deliveries found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: deliveries.length,
                          itemBuilder: (context, index) {
                            final delivery = deliveries[index];
                            return GestureDetector(
                              onTap: () {
                                // Handle delivery item tap
                              },
                              child: customerDeliveryItemWithChatWidget(
                                id: delivery.packageId,
                                name: delivery.customerName,
                                address: delivery.address,
                                status: delivery.status,
                                date: delivery.assignedDate,
                                statusColor: delivery.status == 'delivered'
                                    ? AppColors.greenColor
                                    : delivery.status == 'pending'
                                        ? AppColors.orangeColor
                                        : AppColors.redColor,
                                context: context,
                                customerId: user.uid,
                                customerName:
                                    "$capitalizedFirstName $capitalizedLastName",
                                orderId: delivery.packageId,
                                isCustomer: true,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Notification Card
                  StreamBuilder<Map<String, dynamic>?>(
                    stream:
                        NotificationServices().getLatestPendingNotification(),
                    builder: (context, notificationSnapshot) {
                      print(
                          "DEBUG: StreamBuilder state: ${notificationSnapshot.connectionState}");
                      print(
                          "DEBUG: StreamBuilder hasData: ${notificationSnapshot.hasData}");
                      print(
                          "DEBUG: StreamBuilder data: ${notificationSnapshot.data}");

                      if (notificationSnapshot.hasError) {
                        print(
                            "DEBUG: StreamBuilder error: ${notificationSnapshot.error}");
                        return const Center(
                            child: Text('Error loading notification'));
                      }

                      if (notificationSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        print("DEBUG: StreamBuilder waiting for data");
                        return const SizedBox.shrink();
                      }

                      if (notificationSnapshot.hasData &&
                          notificationSnapshot.data != null) {
                        print(
                            "DEBUG: Building notification card with data: ${notificationSnapshot.data}");
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!_animationController.isAnimating) {
                            print(
                                "DEBUG: Starting animation for notification card");
                            _animationController.forward();
                          }
                        });
                        return _buildNotificationCard(
                            notificationSnapshot.data!,
                            '$capitalizedFirstName $capitalizedLastName');
                      }

                      print(
                          "DEBUG: No notification data, returning empty widget");
                      return const SizedBox.shrink();
                    },
                  ),

                  // Bottom User Profile Section
                  _buildBottomUserSection(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _closeNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isclosedNotification': true});

      _animationController.reverse();
      print('Notification closed successfully');
    } catch (e) {
      print('Error closing notification: $e');
    }
  }

  Widget _buildNotificationCard(
      Map<String, dynamic> data, String customerName) {
    final notification = data['notification'];
    final notificationId = data['notificationId'];

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value as double),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.9),
                    AppColors.primaryColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -30,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.notifications_active,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delivery Update',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Package #${notification['parcel_tracking_number']}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification['notification_text'] ??
                                    'Delivery update available',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    notification['customer_name'] ?? 'Customer',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    notification['delivery_date'] ?? 'Today',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () async {
                                  await _closeNotification(notificationId);
                                },
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                tooltip: 'Dismiss',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeText() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.primaryGradient.createShader(bounds),
              child: const Text(
                'Go Swift',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.whiteColor,
                  letterSpacing: -1.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Customer Management Portal',
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

  Widget _buildBottomUserSection() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _bottomSlideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _bottomSlideAnimation.value) * 100),
            child: Opacity(
              opacity: _bottomSlideAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.backgroundColor.withOpacity(0.95),
                      AppColors.backgroundColor,
                    ],
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.customerColor.withOpacity(0.9),
                        AppColors.customerColor.withOpacity(0.6),
                        AppColors.customerColor.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, -10),
                      ),
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        blurRadius: 50,
                        offset: const Offset(0, -20),
                      ),
                    ],
                  ),
                  child: _buildUserProfileContent(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserProfileContent() {
    return FutureBuilder<UserModel?>(
      future: _firebaseServices
          .getUserData(_firebaseServices.getCurrentUser()?.uid ?? ''),
      builder: (context, snapshot) {
        return Row(
          children: [
            // Profile Image with Status
            Stack(
              children: [
                _buildProfileImage(snapshot),
                _buildStatusIndicator(snapshot),
              ],
            ),
            const SizedBox(width: 20),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildUserInfo(snapshot),
                  const SizedBox(height: 12),
                  _buildStatusBadge(snapshot),
                ],
              ),
            ),

            // Quick Action Button
            GestureDetector(
              onTap: () {
                AuthService().signOut();
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.settings,
                  color: AppColors.whiteColor,
                  size: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileImage(AsyncSnapshot<UserModel?> snapshot) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentColor,
            AppColors.accentColor.withOpacity(0.8),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.accentColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _getProfileImageContent(snapshot),
    );
  }

  Widget _getProfileImageContent(AsyncSnapshot<UserModel?> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator(
        color: AppColors.whiteColor,
        strokeWidth: 2,
      );
    }

    if (snapshot.hasError || !snapshot.hasData) {
      return const Icon(
        Icons.person_rounded,
        color: AppColors.whiteColor,
        size: 28,
      );
    }

    final user = snapshot.data!;
    if (user.profileImage != null && user.profileImage!.isNotEmpty) {
      try {
        final Uint8List imageBytes = base64Decode(user.profileImage!);
        return ClipOval(
          child: Image.memory(
            imageBytes,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.person_rounded,
              color: AppColors.whiteColor,
              size: 28,
            ),
          ),
        );
      } catch (e) {
        return const Icon(
          Icons.person_rounded,
          color: AppColors.whiteColor,
          size: 28,
        );
      }
    }

    return const Icon(
      Icons.person_rounded,
      color: AppColors.whiteColor,
      size: 28,
    );
  }

  Widget _buildStatusIndicator(AsyncSnapshot<UserModel?> snapshot) {
    Color statusColor = AppColors.successColor;

    if (snapshot.hasData && snapshot.data != null) {
      switch (snapshot.data!.availabilityStatus.toUpperCase()) {
        case 'AVAILABLE':
          statusColor = AppColors.successColor;
          break;
        case 'BUSY':
          statusColor = AppColors.warningColor;
          break;
        case 'OFFLINE':
          statusColor = AppColors.errorColor;
          break;
      }
    }

    return Positioned(
      bottom: 2,
      right: 2,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: statusColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.cardColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(AsyncSnapshot<UserModel?> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 18,
            width: 120,
            decoration: BoxDecoration(
              color: AppColors.grey300.withOpacity(0.3),
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 14,
            width: 80,
            decoration: BoxDecoration(
              color: AppColors.grey400.withOpacity(0.3),
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ],
      );
    }

    if (snapshot.hasError || !snapshot.hasData) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Member',
            style: TextStyle(
              color: AppColors.textPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            'Welcome back',
            style: TextStyle(
              color: AppColors.textSecondaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    final user = snapshot.data!;
    final fullName = '${user.firstName} ${user.lastName}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fullName,
          style: const TextStyle(
            color: AppColors.textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          user.userType.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textSecondaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(AsyncSnapshot<UserModel?> snapshot) {
    Color statusColor = AppColors.successColor;
    String statusText = 'AVAILABLE';

    if (snapshot.hasData && snapshot.data != null) {
      statusText = snapshot.data!.availabilityStatus.toUpperCase();
      switch (statusText) {
        case 'AVAILABLE':
          statusColor = AppColors.successColor;
          break;
        case 'BUSY':
          statusColor = AppColors.warningColor;
          break;
        case 'OFFLINE':
          statusColor = AppColors.errorColor;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.15),
            statusColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
