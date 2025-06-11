import 'package:delivery_now_app/services/auth_service.dart';
import 'package:delivery_now_app/services/firebase_services.dart';
import 'package:flutter/material.dart';
import 'package:delivery_now_app/models/user_model.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'dart:convert';
import 'dart:typed_data';

class StaffMenu extends StatefulWidget {
  const StaffMenu({super.key});

  @override
  State<StaffMenu> createState() => _StaffMenuState();
}

class _StaffMenuState extends State<StaffMenu> with TickerProviderStateMixin {
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
          child: Stack(
            children: [
              // Main Content Area
              Column(
                children: [
                  // Main Menu Grid
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Welcome Text
                              _buildWelcomeText(),
                              const SizedBox(height: 32),

                              // Enhanced Menu Grid
                              Expanded(
                                child: GridView.count(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                  childAspectRatio: 0.95,
                                  children: [
                                    _buildEnhancedMenuCard(
                                      icon: Icons.dashboard_customize_rounded,
                                      title: 'Dashboard',
                                      subtitle: 'Overview & Analytics',
                                      gradient: [
                                        AppColors.primaryColor,
                                        AppColors.primaryColor.withOpacity(0.7)
                                      ],
                                      onTap: () {},
                                    ),
                                    _buildEnhancedMenuCard(
                                      icon: Icons.route_sharp,
                                      title: 'New Deliveries',
                                      subtitle: 'Allocate & Schedule',
                                      gradient: [
                                        AppColors.blueGreyColor,
                                        AppColors.blueGreyColor.withOpacity(0.7)
                                      ],
                                      onTap: () {},
                                    ),
                                    _buildEnhancedMenuCard(
                                      icon: Icons.local_shipping_outlined,
                                      title: 'Delivery Details',
                                      subtitle: 'Manage Orders',
                                      gradient: [
                                        AppColors.accentColor,
                                        AppColors.accentColor.withOpacity(0.7)
                                      ],
                                      onTap: () {},
                                    ),
                                    _buildEnhancedMenuCard(
                                      icon: Icons.notifications_none_rounded,
                                      title: 'Alerts',
                                      subtitle: 'Notifications',
                                      gradient: [
                                        AppColors.errorColor,
                                        AppColors.errorColor.withOpacity(0.7)
                                      ],
                                      onTap: () {},
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom User Profile Section
              _buildBottomUserSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Container(
      width: double.infinity,
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
          Text(
            'Staff Management Portal',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.cardColor,
              AppColors.surfaceColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.borderColor.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient.map((c) => c.withOpacity(0.1)).toList(),
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.first.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.whiteColor,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
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
                        AppColors.staffColor.withOpacity(0.9),
                        AppColors.staffColor.withOpacity(0.6),
                        AppColors.staffColor.withOpacity(0.3),
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
        case 'ONLINE':
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
            'Staff Member',
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
          style: TextStyle(
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
    String statusText = 'ONLINE';

    if (snapshot.hasData && snapshot.data != null) {
      statusText = snapshot.data!.availabilityStatus.toUpperCase();
      switch (statusText) {
        case 'ONLINE':
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
