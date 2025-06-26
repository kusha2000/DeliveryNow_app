import 'dart:convert';
import 'package:delivery_now_app/services/auth_service.dart';
import 'package:delivery_now_app/shared/screens/all_deliveries.dart';
import 'package:delivery_now_app/shared/widgets/setting_item_widget.dart';
import 'package:delivery_now_app/utils/show_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:delivery_now_app/screens/Auth/login_screen.dart';
import 'package:delivery_now_app/screens/Menus/rider_menu.dart';
import 'package:delivery_now_app/services/firebase_services.dart';
import 'package:delivery_now_app/models/user_model.dart';
import 'package:delivery_now_app/services/location_services.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class RiderSettingsScreen extends StatefulWidget {
  const RiderSettingsScreen({super.key});

  @override
  State<RiderSettingsScreen> createState() => _RiderSettingsScreenState();
}

class _RiderSettingsScreenState extends State<RiderSettingsScreen>
    with TickerProviderStateMixin {
  final FirebaseServices _firebaseServices = FirebaseServices();
  final LocationService _locationService = LocationService();
  final ImagePicker _picker = ImagePicker();

  // Controllers for the dialog form
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  String? _selectedGender;

  // Stream subscription for real-time updates
  Stream<UserModel?>? _userStream;

  // Animation controllers
  late AnimationController _profileAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _profileAnimation;
  late Animation<double> _cardAnimation;

  // ignore: unused_field
  bool _isLoading = true;
  double _averageRating = 0.0;
  int totalCompletedDeliveries = 0;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _profileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _profileAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _profileAnimationController, curve: Curves.easeOutBack),
    );
    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimationController, curve: Curves.easeOut),
    );

    String? uid = _firebaseServices.getCurrentUser()?.uid;
    if (uid != null) {
      _userStream = _firebaseServices.getUserDataStream();
    }

    _fetchDeliveries();

    // Start animations
    _profileAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardAnimationController.forward();
    });
  }

  Future<void> _fetchDeliveries() async {
    setState(() => _isLoading = true);
    try {
      String? riderId = _firebaseServices.getCurrentUserID();
      if (riderId != null) {
        final deliveries =
            await _firebaseServices.fetchAllDeliveriesForOneRider(
          riderId: riderId,
        );

        double totalRating = 0.0;
        int ratedDeliveries = 0;
        int totalDeliveries = 0;

        for (var delivery in deliveries) {
          if (delivery.stars != null) {
            totalRating += delivery.stars!;
            ratedDeliveries++;
          }
          if (delivery.status == "delivered") {
            totalDeliveries = totalDeliveries + 1;
          }
        }

        setState(() {
          _averageRating =
              ratedDeliveries > 0 ? totalRating / ratedDeliveries : 0.0;
          totalCompletedDeliveries = totalDeliveries;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching deliveries: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _phoneNumberController.dispose();
    _profileAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  // Method to pick and upload profile image
  Future<void> _pickAndUploadImage(String uid) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minHeight: 200,
          minWidth: 200,
          quality: 50,
        );
        final base64Image = base64Encode(compressedBytes);
        await _firebaseServices.updateProfileImage(base64Image);
        showToast('Profile image updated successfully', AppColors.successColor);
      }
    } catch (e) {
      showToast('Error uploading image: $e', AppColors.errorColor);
    }
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.errorColor,
                AppColors.errorColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.blackColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.errorColor,
                          AppColors.errorColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.emergency,
                          color: AppColors.whiteColor,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Emergency Support',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.whiteColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSupportOption(
                    icon: Icons.phone,
                    title: 'Call Support',
                    subtitle: '24/7 emergency hotline',
                    onTap: () => _launchUrl('tel:+941234567890'),
                  ),
                  const SizedBox(height: 12),
                  _buildSupportOption(
                    icon: Icons.emergency,
                    title: 'SOS',
                    subtitle: 'Get Help Now with SOS Support',
                    onTap: () async {
                      await _firebaseServices.createSOSRequest();
                      Navigator.pop(context);
                      showToast('SOS signal sent. Help is on the way!',
                          AppColors.successColor);
                    },
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: AppColors.borderColor),
                            ),
                          ),
                          child: Text(
                            'Close',
                            style: TextStyle(
                              color: AppColors.textSecondaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.whiteColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.whiteColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.whiteColor.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.whiteColor),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.whiteColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.whiteColor.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.whiteColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      showToast('Could not launch $url', AppColors.errorColor);
    }
  }

  void _showUpdatePersonalInfoDialog(UserModel user) {
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _phoneNumberController.text = user.phoneNumber ?? '';
    _ageController.text = user.age?.toString() ?? '';
    _selectedGender = user.gender;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surfaceColor,
                AppColors.cardColor,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.blackColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primaryColor,
                          AppColors.primaryLightColor
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          color: AppColors.whiteColor,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.whiteColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildModernTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildModernTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildModernTextField(
                    controller: _phoneNumberController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildModernTextField(
                    controller: _ageController,
                    label: 'Age',
                    icon: Icons.cake_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildModernDropdown(),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: AppColors.borderColor),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.textSecondaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await _firebaseServices.updateUserDetails(
                                uid: user.uid,
                                firstName: _firstNameController.text.trim(),
                                lastName: _lastNameController.text.trim(),
                                phoneNumber: _phoneNumberController.text.trim(),
                                age: int.tryParse(_ageController.text.trim()),
                                gender: _selectedGender,
                              );
                              showToast(
                                  'Personal information updated successfully',
                                  AppColors.successColor);
                              Navigator.pop(context);
                            } catch (e) {
                              showToast('Error updating information: $e',
                                  AppColors.errorColor);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: AppColors.blackColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Save',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.modalColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: AppColors.textPrimaryColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textSecondaryColor),
          prefixIcon: Icon(icon, color: AppColors.primaryColor),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildModernDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.modalColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.3)),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        style: TextStyle(color: AppColors.textPrimaryColor),
        dropdownColor: AppColors.modalColor,
        decoration: InputDecoration(
          labelText: 'Gender',
          labelStyle: TextStyle(color: AppColors.textSecondaryColor),
          prefixIcon:
              Icon(Icons.people_outline_rounded, color: AppColors.primaryColor),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        items: ['Male', 'Female', 'Other']
            .map((gender) => DropdownMenuItem(
                  value: gender,
                  child: Text(gender,
                      style: TextStyle(color: AppColors.textPrimaryColor)),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedGender = value;
          });
        },
        icon: Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.primaryColor),
      ),
    );
  }

  Future<void> _updateLocation(String riderId) async {
    try {
      Position position = await _locationService.getCurrentPosition();
      await _locationService.updateRiderLocation(
        riderId: riderId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      showToast('Location updated successfully', AppColors.successColor);
    } catch (e) {
      showToast('Error updating location: $e', AppColors.errorColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: StreamBuilder<UserModel?>(
          stream: _userStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                ),
              );
            } else if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Text(
                  'Error loading user data',
                  style: TextStyle(color: AppColors.textPrimaryColor),
                ),
              );
            }

            final user = snapshot.data!;
            final initials =
                '${user.firstName[0]}${user.lastName[0]}'.toUpperCase();

            bool isAvailable = user.availabilityStatus == 'available';
            bool isBusy = user.availabilityStatus == 'busy';
            bool isAbsent = user.availabilityStatus == 'absent';
            String dateKey = DateTime.now().toIso8601String().split('T')[0];
            String attendanceStatus =
                user.attendanceRecords?[dateKey] ?? 'normal';

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 350,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppColors.backgroundColor,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: AppColors.textPrimaryColor,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (context) => RiderMenu()));
                    },
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: AnimatedBuilder(
                      animation: _profileAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _profileAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.backgroundColor,
                                  AppColors.surfaceColor,
                                  AppColors.cardColor,
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 60),
                                Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primaryColor
                                                .withOpacity(0.3),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 60,
                                        backgroundColor: AppColors.cardColor,
                                        backgroundImage:
                                            user.profileImage != null
                                                ? MemoryImage(base64Decode(
                                                    user.profileImage!))
                                                : null,
                                        child: user.profileImage == null
                                            ? Text(
                                                initials,
                                                style: TextStyle(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryColor,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 5,
                                      right: 5,
                                      child: GestureDetector(
                                        onTap: () =>
                                            _pickAndUploadImage(user.uid),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                AppColors.primaryColor,
                                                AppColors.primaryLightColor,
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primaryColor
                                                    .withOpacity(0.4),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.camera_alt_rounded,
                                            color: AppColors.blackColor,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '${user.firstName} ${user.lastName}',
                                  style: TextStyle(
                                    color: AppColors.textPrimaryColor,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.riderColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color:
                                          AppColors.riderColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'Rider',
                                    style: TextStyle(
                                      color: AppColors.riderColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  user.email,
                                  style: TextStyle(
                                    color: AppColors.textSecondaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.whiteColor
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.star,
                                              color: AppColors.orangeColor,
                                              size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            _averageRating.toStringAsFixed(1),
                                            style: TextStyle(
                                              color: AppColors.textPrimaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.whiteColor
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$totalCompletedDeliveries Deliveries',
                                        style: TextStyle(
                                          color: AppColors.textPrimaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _cardAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - _cardAnimation.value)),
                        child: Opacity(
                          opacity: _cardAnimation.value,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Settings',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Attendance Toggle
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.cardColor,
                                        AppColors.surfaceColor,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.blackColor
                                            .withOpacity(0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: attendanceStatus ==
                                                      'present'
                                                  ? AppColors.successColor
                                                      .withOpacity(0.1)
                                                  : attendanceStatus == 'absent'
                                                      ? AppColors.errorColor
                                                          .withOpacity(0.1)
                                                      : AppColors.borderColor
                                                          .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              attendanceStatus == 'present'
                                                  ? Icons.check_circle
                                                  : attendanceStatus == 'absent'
                                                      ? Icons.cancel
                                                      : Icons.hourglass_empty,
                                              color: attendanceStatus ==
                                                      'present'
                                                  ? AppColors.successColor
                                                  : attendanceStatus == 'absent'
                                                      ? AppColors.errorColor
                                                      : AppColors
                                                          .textSecondaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Attendance',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors
                                                      .textPrimaryColor,
                                                ),
                                              ),
                                              Text(
                                                attendanceStatus == 'present'
                                                    ? 'You are present'
                                                    : attendanceStatus ==
                                                            'absent'
                                                        ? 'You are absent'
                                                        : 'Set attendance status',
                                                style: TextStyle(
                                                  color: AppColors
                                                      .textSecondaryColor,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          try {
                                            String? riderId = _firebaseServices
                                                .getCurrentUserID();
                                            if (riderId != null) {
                                              if (attendanceStatus ==
                                                  'normal') {
                                                await _firebaseServices
                                                    .updateAttendanceStatus(
                                                        'present');
                                                showToast(
                                                    'Attendance set to present',
                                                    AppColors.successColor);
                                                await _updateLocation(riderId);
                                              } else if (attendanceStatus ==
                                                  'present') {
                                                await _firebaseServices
                                                    .updateAttendanceStatus(
                                                        'absent');
                                                showToast(
                                                    'Attendance set to absent',
                                                    AppColors.errorColor);
                                              } else {
                                                await _firebaseServices
                                                    .updateAttendanceStatus(
                                                        'present');
                                                showToast(
                                                    'Attendance set to present',
                                                    AppColors.successColor);
                                                await _updateLocation(riderId);
                                              }
                                            }
                                          } catch (e) {
                                            showToast(
                                                'Error updating attendance: $e',
                                                AppColors.errorColor);
                                          }
                                        },
                                        child: Container(
                                          width: 60,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: attendanceStatus == 'present'
                                                ? AppColors.successColor
                                                : attendanceStatus == 'absent'
                                                    ? AppColors.errorColor
                                                    : AppColors.borderColor,
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          child: Stack(
                                            children: [
                                              Positioned(
                                                left:
                                                    attendanceStatus == 'absent'
                                                        ? 2
                                                        : null,
                                                right: attendanceStatus ==
                                                        'present'
                                                    ? 2
                                                    : null,
                                                top: 2,
                                                bottom: 2,
                                                child: Container(
                                                  width: 26,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.whiteColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Availability Toggle
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.cardColor,
                                        AppColors.surfaceColor,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.blackColor
                                            .withOpacity(0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: isAbsent
                                                  ? AppColors.errorColor
                                                      .withOpacity(0.1)
                                                  : isBusy
                                                      ? AppColors.orangeColor
                                                          .withOpacity(0.1)
                                                      : isAvailable
                                                          ? AppColors
                                                              .successColor
                                                              .withOpacity(0.1)
                                                          : AppColors.errorColor
                                                              .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              isAbsent
                                                  ? Icons.cancel
                                                  : isBusy
                                                      ? Icons.directions_bike
                                                      : isAvailable
                                                          ? Icons.check_circle
                                                          : Icons.cancel,
                                              color: isAbsent
                                                  ? AppColors.errorColor
                                                  : isBusy
                                                      ? AppColors.orangeColor
                                                      : isAvailable
                                                          ? AppColors
                                                              .successColor
                                                          : AppColors
                                                              .errorColor,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Availability',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors
                                                      .textPrimaryColor,
                                                ),
                                              ),
                                              Text(
                                                isAbsent
                                                    ? 'You are absent'
                                                    : isBusy
                                                        ? 'You are busy with a delivery'
                                                        : isAvailable
                                                            ? 'You are available for deliveries'
                                                            : 'You are offline',
                                                style: TextStyle(
                                                  color: AppColors
                                                      .textSecondaryColor,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      isAbsent
                                          ? Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppColors.errorColor
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                'Absent',
                                                style: TextStyle(
                                                  color: AppColors.errorColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )
                                          : isBusy
                                              ? Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.orangeColor
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Text(
                                                    'On Delivery',
                                                    style: TextStyle(
                                                      color:
                                                          AppColors.orangeColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                )
                                              : Switch(
                                                  value: isAvailable,
                                                  activeColor:
                                                      AppColors.primaryColor,
                                                  onChanged: (value) async {
                                                    try {
                                                      String? riderId =
                                                          _firebaseServices
                                                              .getCurrentUserID();
                                                      if (riderId != null) {
                                                        await _firebaseServices
                                                            .updateAvailabilityStatus(
                                                                value
                                                                    ? 'available'
                                                                    : 'offline');
                                                        showToast(
                                                            value
                                                                ? 'You are now available'
                                                                : 'You are now offline',
                                                            value
                                                                ? AppColors
                                                                    .successColor
                                                                : AppColors
                                                                    .errorColor);
                                                        if (value) {
                                                          await _updateLocation(
                                                              riderId);
                                                        }
                                                      }
                                                    } catch (e) {
                                                      showToast(
                                                          'Error updating status: $e',
                                                          AppColors.errorColor);
                                                    }
                                                  },
                                                ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Settings Items
                                buildModernSettingItem(
                                  icon: Icons.history_rounded,
                                  title: 'Delivery History',
                                  subtitle: 'View your past deliveries',
                                  iconColor: AppColors.tealColor,
                                  gradientStart:
                                      AppColors.tealColor.withOpacity(0.1),
                                  gradientEnd: AppColors.cardColor,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AllDeliveriesScreen(
                                                riderId: user.uid),
                                      ),
                                    );
                                  },
                                ),
                                buildModernSettingItem(
                                  icon: Icons.person_rounded,
                                  title: 'Personal Information',
                                  subtitle: 'Update your profile details',
                                  iconColor: AppColors.indigoColor,
                                  gradientStart:
                                      AppColors.indigoColor.withOpacity(0.1),
                                  gradientEnd: AppColors.cardColor,
                                  onTap: () =>
                                      _showUpdatePersonalInfoDialog(user),
                                ),
                                buildModernSettingItem(
                                  icon: Icons.support_agent_rounded,
                                  title: 'Support',
                                  subtitle: 'Get help with any issues',
                                  iconColor: AppColors.orangeColor,
                                  gradientStart:
                                      AppColors.orangeColor.withOpacity(0.1),
                                  gradientEnd: AppColors.cardColor,
                                  onTap: _showSupportDialog,
                                ),
                                const SizedBox(height: 32),
                                // Logout Button
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.errorColor,
                                        AppColors.errorColor.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.errorColor
                                            .withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        await AuthService().signOut();
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginScreen(),
                                          ),
                                        );
                                      } catch (e) {
                                        showToast('Error signing out: $e',
                                            AppColors.errorColor);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: AppColors.whiteColor,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 18),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.logout_rounded, size: 22),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Sign Out',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
