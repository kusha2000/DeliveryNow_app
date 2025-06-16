import 'dart:convert';

import 'package:delivery_now_app/utils/show_toast.dart';
import 'package:flutter/material.dart';
import 'package:delivery_now_app/models/user_model.dart';
import 'package:delivery_now_app/screens/Staff/staff_settings_screen/one_rider_details.dart';
import 'package:delivery_now_app/services/firebase_services.dart';

import 'package:delivery_now_app/utils/colors.dart';

class RiderManagementScreen extends StatefulWidget {
  const RiderManagementScreen({super.key});

  @override
  State<RiderManagementScreen> createState() => _RiderManagementScreenState();
}

class _RiderManagementScreenState extends State<RiderManagementScreen>
    with TickerProviderStateMixin {
  final FirebaseServices _firebaseServices = FirebaseServices();
  List<UserModel> _riders = [];
  List<UserModel> _filteredRiders = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'All';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _statusOptions = ['All', 'Available', 'Offline', 'Absent'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadRiders();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRiders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Smooth loading
      final riders = await _firebaseServices.getAllRiders();
      setState(() {
        _riders = riders;
        _filteredRiders = riders;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showToast('Error loading riders: $e', AppColors.errorColor);
    }
  }

  void _filterRiders() {
    setState(() {
      _filteredRiders = _riders.where((rider) {
        final nameMatch = '${rider.firstName} ${rider.lastName}'
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
        final emailMatch =
            rider.email.toLowerCase().contains(_searchQuery.toLowerCase());
        final phoneMatch = rider.phoneNumber
                ?.toLowerCase()
                .contains(_searchQuery.toLowerCase()) ??
            false;

        final statusMatch = _statusFilter == 'All' ||
            (rider.availabilityStatus.toLowerCase() ==
                _statusFilter.toLowerCase());

        return (nameMatch || emailMatch || phoneMatch) && statusMatch;
      }).toList();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return AppColors.successColor;
      case 'offline':
        return AppColors.warningColor;
      case 'absent':
        return AppColors.errorColor;
      default:
        return AppColors.grey500;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Icons.check_circle;
      case 'offline':
        return Icons.pause_circle;
      case 'absent':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildStatsCard() {
    final totalRiders = _riders.length;
    final availableRiders = _riders
        .where((r) => r.availabilityStatus.toLowerCase() == 'available')
        .length;
    final offlineRiders = _riders
        .where((r) => r.availabilityStatus.toLowerCase() == 'offline')
        .length;
    final absentRiders = _riders
        .where((r) => r.availabilityStatus.toLowerCase() == 'absent')
        .length;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined,
                  color: AppColors.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Rider Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Total', totalRiders.toString(),
                    AppColors.infoColor, Icons.people),
              ),
              Expanded(
                child: _buildStatItem('Available', availableRiders.toString(),
                    AppColors.successColor, Icons.check_circle),
              ),
              Expanded(
                child: _buildStatItem('Offline', offlineRiders.toString(),
                    AppColors.warningColor, Icons.pause_circle),
              ),
              Expanded(
                child: _buildStatItem('Absent', absentRiders.toString(),
                    AppColors.errorColor, Icons.cancel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRiderCard(UserModel rider, int index) {
    final initials = '${rider.firstName[0]}${rider.lastName[0]}'.toUpperCase();
    final statusColor = _getStatusColor(rider.availabilityStatus);
    final statusIcon = _getStatusIcon(rider.availabilityStatus);

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 16,
                top: index == 0 ? 8 : 0,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OneRiderDetails(rider: rider),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Profile Section
                        Stack(
                          children: [
                            Container(
                              width: 65,
                              height: 65,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryColor.withOpacity(0.2),
                                    AppColors.primaryLightColor
                                        .withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      AppColors.primaryColor.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: rider.profileImage != null
                                    ? Image.memory(
                                        base64Decode(rider.profileImage!),
                                        fit: BoxFit.cover,
                                      )
                                    : Center(
                                        child: Text(
                                          initials,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryColor,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.cardColor,
                                    width: 3,
                                  ),
                                ),
                                child: Icon(
                                  statusIcon,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),

                        // Info Section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${rider.firstName} ${rider.lastName}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.email_outlined,
                                      size: 14,
                                      color: AppColors.textSecondaryColor),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      rider.email,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondaryColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.phone_outlined,
                                      size: 14,
                                      color: AppColors.textSecondaryColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    rider.phoneNumber ?? 'No phone',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Status and Delivery Count Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon,
                                      size: 14, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    rider.availabilityStatus.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      AppColors.primaryColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_shipping_outlined,
                                      size: 16, color: AppColors.primaryColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${rider.deliveriesCount ?? 0}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.lightShadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _filterRiders();
              },
              style: TextStyle(color: AppColors.textPrimaryColor),
              decoration: InputDecoration(
                hintText: 'Search riders by name, email, or phone...',
                hintStyle: TextStyle(color: AppColors.textMutedColor),
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppColors.primaryColor, size: 24),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded,
                            color: AppColors.textMutedColor),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                          _filterRiders();
                        },
                      )
                    : null,
                filled: false,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusOptions.map((status) {
                final isSelected = _statusFilter == status;
                final statusColor = status == 'All'
                    ? AppColors.primaryColor
                    : _getStatusColor(status);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _statusFilter = status;
                    });
                    _filterRiders();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                statusColor,
                                statusColor.withOpacity(0.8)
                              ],
                            )
                          : null,
                      color: isSelected ? null : AppColors.cardColor,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected ? statusColor : AppColors.borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: statusColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (status != 'All') ...[
                          Icon(
                            _getStatusIcon(status),
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondaryColor,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          status,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondaryColor,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Icon(
              Icons.person_search_rounded,
              size: 60,
              color: AppColors.textMutedColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No riders found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter criteria',
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
      backgroundColor: AppColors.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_rounded,
                            color: AppColors.textPrimaryColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rider Management',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryColor,
                            ),
                          ),
                          Text(
                            'Manage and monitor your delivery team',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.refresh_rounded,
                            color: AppColors.primaryColor),
                        onPressed: () {
                          _animationController.reset();
                          _loadRiders();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Loading riders...',
                              style: TextStyle(
                                color: AppColors.textSecondaryColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          _buildStatsCard(),
                          const SizedBox(height: 8),
                          _buildSearchAndFilter(),
                          const SizedBox(height: 20),
                          Expanded(
                            child: _filteredRiders.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                                    itemCount: _filteredRiders.length,
                                    physics: const BouncingScrollPhysics(),
                                    itemBuilder: (context, index) =>
                                        _buildRiderCard(
                                            _filteredRiders[index], index),
                                  ),
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
}
