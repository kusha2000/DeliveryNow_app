// ignore_for_file: unused_field

import 'dart:async';
import 'package:delivery_now_app/screens/Customer/packageQualityScreen.dart';
import 'package:delivery_now_app/screens/Customer/voiceFeedback.dart';
import 'package:delivery_now_app/screens/Customer/widgets/signature_pad.dart';
import 'package:delivery_now_app/utils/show_toast.dart';
import 'package:flutter/material.dart';
import 'package:delivery_now_app/services/firebase_services.dart';
import 'package:delivery_now_app/models/delivery_model.dart';
import 'package:delivery_now_app/utils/colors.dart';

class OneDeliveryDetailScreen extends StatefulWidget {
  final String deliveryId;

  const OneDeliveryDetailScreen({super.key, required this.deliveryId});

  @override
  State<OneDeliveryDetailScreen> createState() =>
      _OneDeliveryDetailScreenState();
}

class _OneDeliveryDetailScreenState extends State<OneDeliveryDetailScreen> {
  final FirebaseServices _firebaseServices = FirebaseServices();
  String _currentStatus = 'pending';
  DeliveryModel? _selectedDelivery;
  bool _isLoading = true;
  bool _isCheckingImages = true;
  bool _isUpdatingStatus = false;
  bool _hasImages = false;
  bool _hasVoiceFeedback = false;

  // For text feedback
  final _feedbackController = TextEditingController();
  double _selectedStars = 0.0;

  // Stream subscription
  StreamSubscription<DeliveryModel?>? _selectedDeliveryStreamSubscription;

  @override
  void initState() {
    super.initState();
    _loadDeliveryDetails();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _selectedDeliveryStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDeliveryDetails() async {
    setState(() {
      _isLoading = true;
      _isCheckingImages = true;
    });

    try {
      print("Package ID:${widget.deliveryId}");
      String? riderId = _firebaseServices.getCurrentUserID();
      if (riderId != null) {
        // Subscribe to the specific delivery stream
        _selectedDeliveryStreamSubscription?.cancel();
        _selectedDeliveryStreamSubscription = _firebaseServices
            .getDeliveryByIdStream(widget.deliveryId)
            .listen((delivery) {
          if (delivery != null) {
            setState(() {
              _selectedDelivery = delivery;
              _currentStatus = delivery.status;
              _selectedStars = delivery.stars ?? 0.0;
              _feedbackController.text = delivery.feedback ?? '';
              _hasVoiceFeedback = delivery.voiceFeedback != null &&
                  delivery.voiceFeedback!.isNotEmpty;
              _isLoading = false;
            });
            print("Delivery Details:$delivery");
            _checkForDeliveryImages();
          } else {
            setState(() {
              _isLoading = false;
              _isCheckingImages = false;
            });
            showToast('Delivery not found', AppColors.errorColor);
          }
        }, onError: (error) {
          setState(() {
            _isLoading = false;
            _isCheckingImages = false;
          });
          showToast('Error loading delivery: $error', AppColors.errorColor);
        });
      } else {
        setState(() {
          _isLoading = false;
          _isCheckingImages = false;
        });
        showToast('Rider ID not found', AppColors.errorColor);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isCheckingImages = false;
      });
      showToast('Error loading delivery: $e', AppColors.errorColor);
    }
  }

  Future<void> _checkForDeliveryImages() async {
    if (_selectedDelivery != null) {
      setState(() => _isCheckingImages = true);

      try {
        bool hasImages = await _firebaseServices
            .checkDeliveryHasImages(_selectedDelivery!.id);
        setState(() {
          _hasImages = hasImages;
          _isCheckingImages = false;
        });
      } catch (e) {
        setState(() => _isCheckingImages = false);
        showToast('Error checking for images: $e', AppColors.errorColor);
      }
    } else {
      setState(() => _isCheckingImages = false);
    }
  }

  Future<void> _saveSignature(String signatureBase64) async {
    if (_selectedDelivery == null) return;

    try {
      await _firebaseServices.updateDeliverySignature(
        deliveryId: _selectedDelivery!.id,
        signatureBase64: signatureBase64,
      );

      showToast('Signature saved successfully', AppColors.successColor);
    } catch (e) {
      showToast('Error saving signature: $e', AppColors.errorColor);
    }
  }

  Future<void> _showSignatureDialog() async {
    final signature = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.modalColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: CustomerSignaturePad(
          onSave: (signature) => Navigator.pop(context, signature),
          existingSignature: _selectedDelivery?.signature,
        ),
      ),
    );

    if (signature != null) {
      await _saveSignature(signature);
    }
  }

  Future<void> _saveTextFeedback() async {
    if (_selectedDelivery == null) return;

    try {
      if (_selectedStars > 0 && _feedbackController.text.isNotEmpty) {
        await _firebaseServices.updateDeliveryFeedback(
          deliveryId: _selectedDelivery!.id,
          stars: _selectedStars,
          feedback: _feedbackController.text,
        );
        showToast('Feedback saved successfully', AppColors.successColor);
      } else {
        showToast(
            'Please provide both rating and feedback', AppColors.warningColor);
      }
    } catch (e) {
      showToast('Error saving feedback: $e', AppColors.errorColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            )
          : _selectedDelivery == null
              ? Center(
                  child: Text(
                    'Delivery not found',
                    style: TextStyle(
                      color: AppColors.textSecondaryColor,
                      fontSize: 16,
                    ),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(
                      child: _buildDeliveryDetails(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.backgroundColor,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor, width: 1),
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimaryColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor, width: 1),
          ),
          child: IconButton(
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.primaryColor,
              size: 22,
            ),
            onPressed: () {
              if (_selectedDelivery!.customerId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Unregistered users can\'t use the chat feature.',
                      style: TextStyle(color: AppColors.textPrimaryColor),
                    ),
                    backgroundColor: AppColors.errorColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                return;
              }
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          "Delivery Details",
          style: TextStyle(
            color: AppColors.textPrimaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.backgroundColor,
                AppColors.surfaceColor,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryDetails() {
    bool hasSignature = _selectedDelivery?.signature != null &&
        _selectedDelivery!.signature!.isNotEmpty;
    bool hasTextFeedback = _selectedDelivery?.feedback != null &&
        _selectedDelivery!.feedback!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              "Package Information", Icons.inventory_2_outlined),
          const SizedBox(height: 16),
          _buildPackageInfoCard(),
          const SizedBox(height: 24),
          _buildSectionHeader("Package Condition", Icons.camera_alt_outlined),
          const SizedBox(height: 16),
          _buildPackageConditionCard(),
          const SizedBox(height: 24),
          _buildSectionHeader("Feedback & Rating", Icons.rate_review_outlined),
          const SizedBox(height: 16),
          _buildFeedbackCard(hasTextFeedback),
          const SizedBox(height: 24),
          _buildSectionHeader(
              "Delivery Confirmation", Icons.check_circle_outline),
          const SizedBox(height: 16),
          _buildConfirmationCard(hasSignature),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPackageInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.local_shipping_outlined,
            "Package ID",
            _selectedDelivery!.packageId,
            AppColors.tealColor,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.person_outline_rounded,
            "Customer",
            _selectedDelivery!.customerName,
            AppColors.indigoColor,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.location_on_outlined,
            "Address",
            _selectedDelivery!.address,
            AppColors.pinkColor,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.attach_money_rounded,
            "Price",
            'Rs. ${_selectedDelivery!.price.toStringAsFixed(2)}',
            AppColors.emeraldColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackageConditionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Document package condition with photos",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.violetColor, AppColors.primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomerPackageQualityCheckScreen(
                        deliveryId: _selectedDelivery!.id,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_rounded,
                        color: AppColors.whiteColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Take Photos",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.whiteColor,
                        ),
                      ),
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

  Widget _buildFeedbackCard(bool hasTextFeedback) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Star Rating",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLightColor, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedStars = (index + 1).toDouble();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      index < _selectedStars
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: index < _selectedStars
                          ? AppColors.amberColor
                          : AppColors.grey500,
                      size: 32,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Feedback",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLightColor, width: 1),
            ),
            child: TextField(
              controller: _feedbackController,
              maxLines: 4,
              style: TextStyle(
                color: AppColors.textPrimaryColor,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: "Share your experience with this delivery...",
                hintStyle: TextStyle(
                  color: AppColors.textMutedColor,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasTextFeedback
                    ? [AppColors.successColor, AppColors.emeraldColor]
                    : [AppColors.errorColor, AppColors.deepOrangeColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (hasTextFeedback
                          ? AppColors.successColor
                          : AppColors.errorColor)
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _saveTextFeedback,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasTextFeedback
                            ? Icons.check_circle_outline
                            : Icons.save_outlined,
                        color: AppColors.whiteColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasTextFeedback ? "Feedback Saved" : "Save Feedback",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.whiteColor,
                        ),
                      ),
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

  Widget _buildConfirmationCard(bool hasSignature) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Complete delivery confirmation",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: hasSignature
                          ? [AppColors.successColor, AppColors.emeraldColor]
                          : [AppColors.cyanColor, AppColors.tealColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (hasSignature
                                ? AppColors.successColor
                                : AppColors.cyanColor)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showSignatureDialog,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            Icon(
                              hasSignature
                                  ? Icons.check_circle
                                  : Icons.draw_rounded,
                              color: AppColors.whiteColor,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              hasSignature ? "Signed" : "Signature",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.whiteColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _hasVoiceFeedback
                          ? [AppColors.successColor, AppColors.emeraldColor]
                          : [AppColors.pinkColor, AppColors.deepOrangeColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (_hasVoiceFeedback
                                ? AppColors.successColor
                                : AppColors.pinkColor)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerVoiceFeedbackScreen(
                              deliveryId: _selectedDelivery!.id,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            Icon(
                              _hasVoiceFeedback
                                  ? Icons.check_circle
                                  : Icons.mic_rounded,
                              color: AppColors.whiteColor,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _hasVoiceFeedback ? "Recorded" : "Voice",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.whiteColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
