import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:delivery_now_app/models/delivery_model.dart';
import 'package:delivery_now_app/services/firebase_services.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class OneDeliveryDetailsScreen extends StatefulWidget {
  final String deliveryId;

  const OneDeliveryDetailsScreen({super.key, required this.deliveryId});

  @override
  State<OneDeliveryDetailsScreen> createState() =>
      _OneDeliveryDetailsScreenState();
}

class _OneDeliveryDetailsScreenState extends State<OneDeliveryDetailsScreen>
    with TickerProviderStateMixin {
  final FirebaseServices _firebaseServices = FirebaseServices();
  bool _isLoading = true;
  DeliveryModel? _delivery;
  List<String> _images = [];
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Sound player
  final FlutterSoundPlayer _soundPlayer = FlutterSoundPlayer();
  bool _isPlaying = false;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePlayer();
    _loadDeliveryDetails();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _initializePlayer() async {
    await _soundPlayer.openPlayer();
    _soundPlayer.onProgress!.listen((event) {
      // Handle player progress if needed
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _soundPlayer.closePlayer();
    _cleanupTempFiles();
    super.dispose();
  }

  Future<void> _cleanupTempFiles() async {
    if (_audioPath != null) {
      try {
        final file = File(_audioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error cleaning up temp files: $e');
      }
    }
  }

  Future<void> _loadDeliveryDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load delivery details
      _delivery = await _firebaseServices.getDeliveryById(widget.deliveryId);

      // Load delivery images
      if (_delivery != null) {
        _images = await _firebaseServices.getDeliveryImages(widget.deliveryId);
      }

      // Start animations
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading delivery details: $e'),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _playVoiceFeedback() async {
    if (_delivery?.voiceFeedback == null) return;

    try {
      if (_isPlaying) {
        await _soundPlayer.stopPlayer();
        setState(() {
          _isPlaying = false;
        });
      } else {
        // Convert base64 to a temporary file
        final bytes = base64Decode(_delivery!.voiceFeedback!);
        final tempDir = await getTemporaryDirectory();
        final tempPath =
            '${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.mp3';

        final file = File(tempPath);
        await file.writeAsBytes(bytes);
        _audioPath = tempPath;

        await _soundPlayer.startPlayer(
          fromURI: tempPath,
          whenFinished: () {
            setState(() {
              _isPlaying = false;
            });
          },
        );

        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing voice feedback: $e'),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  String _getStatusText(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.successColor;
      case 'pending':
        return AppColors.warningColor;
      case 'in_transit':
        return AppColors.primaryColor;
      case 'returned':
        return AppColors.orangeColor;
      case 'cancelled':
        return AppColors.errorColor;
      default:
        return AppColors.grey500;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.access_time_rounded;
      case 'in_transit':
        return Icons.local_shipping_rounded;
      case 'returned':
        return Icons.keyboard_return_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: _isLoading
          ? _buildLoadingScreen()
          : _delivery == null
              ? _buildNotFoundScreen()
              : _buildDeliveryDetails(),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Loading delivery details...',
              style: TextStyle(
                color: AppColors.textSecondaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 80,
              color: AppColors.grey600,
            ),
            SizedBox(height: 24),
            Text(
              'Delivery Not Found',
              style: TextStyle(
                color: AppColors.textPrimaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The requested delivery details could not be found.',
              style: TextStyle(
                color: AppColors.textSecondaryColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDetails() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 24),
                      _buildPackageInfoCard(),
                      const SizedBox(height: 20),
                      _buildCustomerInfoCard(),
                      const SizedBox(height: 20),
                      if (_delivery!.packageDetails != null &&
                          _delivery!.packageDetails!.isNotEmpty) ...[
                        _buildPackageDetailsCard(),
                        const SizedBox(height: 20),
                      ],
                      if (_delivery!.items.isNotEmpty) ...[
                        _buildItemsCard(),
                        const SizedBox(height: 20),
                      ],
                      if (_images.isNotEmpty) ...[
                        _buildImagesCard(),
                        const SizedBox(height: 20),
                      ],
                      if (_delivery!.voiceFeedback != null) ...[
                        _buildVoiceFeedbackCard(),
                        const SizedBox(height: 20),
                      ],
                      if (_delivery!.feedback != null &&
                          _delivery!.feedback!.isNotEmpty) ...[
                        _buildFeedbackCard(),
                        const SizedBox(height: 20),
                      ],
                      if (_delivery!.signature != null) ...[
                        _buildSignatureCard(),
                        const SizedBox(height: 20),
                      ],
                      _buildRiderInfoCard(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.surfaceColor,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.cardColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimaryColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Delivery Details',
          style: TextStyle(
            color: AppColors.textPrimaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor.withOpacity(0.3),
                AppColors.surfaceColor,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getStatusColor(_delivery!.status).withOpacity(0.2),
            _getStatusColor(_delivery!.status).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(_delivery!.status).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(_delivery!.status).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(_delivery!.status),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getStatusIcon(_delivery!.status),
                  color: AppColors.whiteColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusText(_delivery!.status),
                    style: TextStyle(
                      color: _getStatusColor(_delivery!.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    'Delivery Status',
                    style: TextStyle(
                      color: AppColors.textSecondaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_delivery!.stars != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Rating: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryColor,
                      fontSize: 16,
                    ),
                  ),
                  _buildRatingStars(_delivery!.stars!),
                  const SizedBox(width: 8),
                  Text(
                    '(${_delivery!.stars!.toStringAsFixed(1)})',
                    style: const TextStyle(
                      color: AppColors.textSecondaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPackageInfoCard() {
    return _buildModernCard(
      title: 'Package Information',
      icon: Icons.inventory_2_rounded,
      children: [
        _buildModernInfoRow(
          'Package ID',
          _delivery!.packageId,
          Icons.qr_code_2_rounded,
        ),
        _buildModernInfoRow(
          'Price',
          'Rs. ${_delivery!.price.toStringAsFixed(2)}',
          Icons.payments_rounded,
        ),
        _buildModernInfoRow(
          'Priority',
          _delivery!.priority.toUpperCase(),
          Icons.priority_high_rounded,
        ),
        _buildModernInfoRow(
          'Assigned Date',
          DateFormat('MMM d, yyyy').format(_delivery!.assignedDate.toDate()),
          Icons.event_rounded,
        ),
        if (_delivery!.deliveryDate != null)
          _buildModernInfoRow(
            'Delivery Date',
            DateFormat('MMM d, yyyy').format(_delivery!.deliveryDate!.toDate()),
            Icons.done_all_rounded,
          ),
      ],
    );
  }

  Widget _buildCustomerInfoCard() {
    return _buildModernCard(
      title: 'Customer Information',
      icon: Icons.person_rounded,
      children: [
        _buildModernInfoRow(
          'Customer Name',
          _delivery!.customerName,
          Icons.account_circle_rounded,
        ),
        _buildModernInfoRow(
          'Address',
          _delivery!.address,
          Icons.location_on_rounded,
        ),
        _buildModernInfoRow(
          'Phone Number',
          _delivery!.phoneNumber,
          Icons.phone_rounded,
        ),
      ],
    );
  }

  Widget _buildPackageDetailsCard() {
    return _buildModernCard(
      title: 'Package Details',
      icon: Icons.description_rounded,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Text(
            _delivery!.packageDetails!,
            style: const TextStyle(
              color: AppColors.textPrimaryColor,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsCard() {
    return _buildModernCard(
      title: 'Items in Package',
      icon: Icons.checklist_rounded,
      children: [
        ...(_delivery!.items
            .map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppColors.whiteColor,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: AppColors.textPrimaryColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList()),
      ],
    );
  }

  Widget _buildImagesCard() {
    return _buildModernCard(
      title: 'Delivery Images',
      icon: Icons.photo_library_rounded,
      children: [
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showFullImage(context, _images[index], index),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          base64Decode(_images[index]),
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${index + 1}/${_images.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
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
  }

  Widget _buildVoiceFeedbackCard() {
    return _buildModernCard(
      title: 'Voice Feedback',
      icon: Icons.record_voice_over_rounded,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor.withOpacity(0.1),
                AppColors.violetColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _playVoiceFeedback,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: AppColors.whiteColor,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer Voice Feedback',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isPlaying ? 'Playing...' : 'Tap to play',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackCard() {
    return _buildModernCard(
      title: 'Customer Feedback',
      icon: Icons.feedback_rounded,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Text(
            _delivery!.feedback!,
            style: const TextStyle(
              color: AppColors.textPrimaryColor,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureCard() {
    return _buildModernCard(
      title: 'Customer Signature',
      icon: Icons.draw_rounded,
      children: [
        Container(
          width: double.infinity,
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.memory(
            base64Decode(_delivery!.signature!),
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  Widget _buildRiderInfoCard() {
    return _buildModernCard(
      title: 'Rider Information',
      icon: Icons.delivery_dining_rounded,
      children: [
        _buildModernInfoRow(
          'Rider ID',
          _delivery!.riderId,
          Icons.badge_rounded,
        ),
        _buildModernInfoRow(
          'Rider Name',
          _delivery!.riderName,
          Icons.person_pin_rounded,
        ),
      ],
    );
  }

  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryColor.withOpacity(0.2),
                  AppColors.primaryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.whiteColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryColor,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryColor,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: Colors.amber,
          size: 22,
        );
      }),
    );
  }

  void _showFullImage(BuildContext context, String imageBase64, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: AppColors.primaryColor,
              title: Text("Image ${index + 1}"),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.memory(
                base64Decode(imageBase64),
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
