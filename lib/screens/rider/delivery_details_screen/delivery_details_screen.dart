import 'dart:async';
import 'package:delivery_now_app/screens/rider/delivery_details_screen/packageQualityScreen.dart';
import 'package:delivery_now_app/screens/rider/delivery_details_screen/voiceFeedback.dart';
import 'package:delivery_now_app/screens/rider/delivery_details_screen/widgets/signature_pad.dart';
import 'package:delivery_now_app/utils/show_toast.dart';
import 'package:flutter/material.dart';
import 'package:delivery_now_app/services/firebase_services.dart';
import 'package:delivery_now_app/models/delivery_model.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'package:intl/intl.dart';

class DeliveryDetailScreen extends StatefulWidget {
  const DeliveryDetailScreen({super.key});

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  final FirebaseServices _firebaseServices = FirebaseServices();
  String _currentStatus = 'pending';
  DateTime _selectedDate = DateTime.now();
  DeliveryModel? _selectedDelivery;
  List<DeliveryModel> _deliveries = [];
  bool _isLoading = true;
  bool _isUpdatingStatus = false;

  // For customer selection
  String? _selectedCustomerName;
  List<String> _customerNames = [];
  // ignore: unused_field
  Map<String, String> _customerAddresses = {};

  // Stream subscriptions
  StreamSubscription<List<DeliveryModel>>? _deliveriesStreamSubscription;
  StreamSubscription<DeliveryModel?>? _selectedDeliveryStreamSubscription;

  @override
  void initState() {
    super.initState();
    _loadDeliveriesForDate(_selectedDate);
  }

  @override
  void dispose() {
    _deliveriesStreamSubscription?.cancel();
    _selectedDeliveryStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDeliveriesForDate(DateTime date) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? riderId = _firebaseServices.getCurrentUserID();
      if (riderId != null) {
        // Cancel existing subscription if any
        _deliveriesStreamSubscription?.cancel();

        // Subscribe to deliveries stream for the selected date
        _deliveriesStreamSubscription = _firebaseServices
            .getDeliveriesByDateStream(riderId: riderId, date: date)
            .listen((deliveries) {
          // Extract unique customer names and addresses
          final customerMap = <String, String>{};
          for (var delivery in deliveries) {
            customerMap[delivery.customerName] = delivery.address;
          }

          setState(() {
            _deliveries = deliveries;
            _customerNames = customerMap.keys.toList();
            _customerAddresses = customerMap;

            if (_selectedDelivery == null) {
              _selectedDelivery =
                  deliveries.isNotEmpty ? deliveries.first : null;
              _selectedCustomerName = _selectedDelivery?.customerName;

              if (_selectedDelivery != null) {
                _currentStatus = _selectedDelivery!.status;
              }
            } else {
              final String currentId = _selectedDelivery!.id;
              final int index = deliveries.indexWhere((d) => d.id == currentId);

              if (index >= 0) {
                _selectedDelivery = deliveries[index];
                _currentStatus = _selectedDelivery!.status;
              } else if (deliveries.isNotEmpty) {
                _selectedDelivery = deliveries.first;
                _selectedCustomerName = _selectedDelivery!.customerName;
                _currentStatus = _selectedDelivery!.status;
              } else {
                _selectedDelivery = null;
                _selectedCustomerName = null;
              }
            }

            _isLoading = false;
          });
        }, onError: (error) {
          setState(() {
            _isLoading = false;
          });
          showToast('Error loading deliveries: $error', AppColors.redColor);
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showToast('Error loading deliveries: $e', AppColors.redColor);
    }
  }

  void _subscribeToSelectedDelivery() {
    if (_selectedDelivery == null) return;

    // Cancel existing subscription if any
    _selectedDeliveryStreamSubscription?.cancel();

    // Subscribe to selected delivery updates
    _selectedDeliveryStreamSubscription = _firebaseServices
        .getDeliveryByIdStream(_selectedDelivery!.id)
        .listen((delivery) {
      if (delivery != null) {
        setState(() {
          _selectedDelivery = delivery;
          _currentStatus = delivery.status;
        });
      }
    }, onError: (error) {
      showToast('Error getting delivery updates: $error', AppColors.redColor);
    });
  }

  void _onPackageSelected(DeliveryModel? delivery) {
    if (delivery == null) return;

    setState(() {
      _selectedDelivery = delivery;
      _currentStatus = delivery.status;
      _selectedCustomerName = delivery.customerName;
    });

    _subscribeToSelectedDelivery();
  }

  void _onCustomerSelected(String? customerName) {
    if (customerName == null) return;

    final delivery = _deliveries.firstWhere(
      (d) => d.customerName == customerName,
      orElse: () => _deliveries.first,
    );

    setState(() {
      _selectedCustomerName = customerName;
      _selectedDelivery = delivery;
      _currentStatus = delivery.status;
    });

    _subscribeToSelectedDelivery();
  }

  Future<void> _updateDeliveryStatus(String newStatus) async {
    if (_selectedDelivery == null) return;

    setState(() => _isUpdatingStatus = true);

    try {
      await _firebaseServices.updateDeliveryStatus(
        deliveryId: _selectedDelivery!.id,
        status: newStatus,
      );

      String? riderId = _firebaseServices.getCurrentUserID();
      if (riderId != null) {
        String availability =
            newStatus == 'delivered' || newStatus == 'returned'
                ? 'available'
                : 'busy';
        await _firebaseServices.updateAvailabilityStatus(availability);

        if (newStatus == 'delivered') {
          await _firebaseServices.updateDeliveriesCount();
        }
      }

      setState(() {
        _currentStatus = newStatus;
        _isUpdatingStatus = false;
      });
      showToast('Delivery Status Updated', AppColors.greenColor);
    } catch (e) {
      setState(() => _isUpdatingStatus = false);
      showToast('Error updating status: $e', AppColors.redColor);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _selectedDate) {
      // Cancel existing subscriptions
      _deliveriesStreamSubscription?.cancel();
      _selectedDeliveryStreamSubscription?.cancel();

      setState(() {
        _selectedDate = picked;
        _selectedDelivery = null;
        _selectedCustomerName = null;
      });

      await _loadDeliveriesForDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_rounded, color: AppColors.whiteColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text(
              "Delivery Details",
              style: TextStyle(
                color: AppColors.whiteColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              icon:
                  const Icon(Icons.calendar_today, color: AppColors.whiteColor),
              onPressed: () => _selectDate(context),
              tooltip: 'Select Date',
            ),
            Text(
              DateFormat('MMM d').format(_selectedDate),
              style: const TextStyle(
                color: AppColors.whiteColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            )
          : _deliveries.isEmpty
              ? _buildEmptyState()
              : _buildDeliveryDetails(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 80,
            color: AppColors.grey500,
          ),
          const SizedBox(height: 16),
          Text(
            'No deliveries for selected date',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different date',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMutedColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryDetails() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPackageSelection(),
              const SizedBox(height: 24),
              _buildDeliveryInfo(),
              const SizedBox(height: 32),
              _buildStatusSection(),
              const SizedBox(height: 32),
              _buildFeedbackSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageSelection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                "Package Selection",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Package ID Dropdown
          _buildDropdownField(
            label: "Package ID",
            icon: Icons.inventory_rounded,
            value: _selectedDelivery?.id,
            items: _deliveries
                .map((delivery) => DropdownMenuItem<String>(
                      value: delivery.id,
                      child: Text(
                        delivery.packageId,
                        style: TextStyle(color: AppColors.textPrimaryColor),
                      ),
                    ))
                .toList(),
            onChanged: (String? deliveryId) {
              if (deliveryId != null) {
                final delivery =
                    _deliveries.firstWhere((d) => d.id == deliveryId);
                _onPackageSelected(delivery);
              }
            },
          ),

          const SizedBox(height: 16),

          // Customer Dropdown
          _buildDropdownField(
            label: "Customer",
            icon: Icons.person_rounded,
            value: _selectedCustomerName,
            items: _customerNames
                .map((customer) => DropdownMenuItem<String>(
                      value: customer,
                      child: Text(
                        customer,
                        style: TextStyle(color: AppColors.textPrimaryColor),
                      ),
                    ))
                .toList(),
            onChanged: _onCustomerSelected,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<T>(
                  value: value,
                  icon: Icon(Icons.arrow_drop_down,
                      color: AppColors.primaryColor),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryColor,
                  ),
                  dropdownColor: AppColors.surfaceColor,
                  onChanged: onChanged,
                  items: items,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    if (_selectedDelivery == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tealColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.tealColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                "Delivery Information",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            icon: Icons.location_on_rounded,
            title: "Delivery Address",
            content: _selectedDelivery!.address,
            color: AppColors.emeraldColor,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.attach_money_rounded,
            title: "Package Price",
            content: 'Rs. ${_selectedDelivery!.price.toStringAsFixed(2)}',
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.schedule_rounded,
            title: "Delivery Date",
            content: DateFormat('MMM dd, HH:mm')
                .format(_selectedDelivery!.createdAt.toDate()),
            color: AppColors.infoColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.update_rounded,
                  color: AppColors.warningColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                "Update Status",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isUpdatingStatus)
            const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusButton(
                        "Pending",
                        "pending",
                        Icons.pending,
                        AppColors.customerColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusButton(
                        "In Transit",
                        "in_transit",
                        Icons.local_shipping_rounded,
                        AppColors.infoColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatusButton(
                        "On the Way",
                        "on_the_way",
                        Icons.directions_run_rounded,
                        AppColors.warningColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusButton(
                        "Delivered",
                        "delivered",
                        Icons.check_circle_rounded,
                        AppColors.successColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatusButton(
                        "Returned",
                        "returned",
                        Icons.undo_rounded,
                        AppColors.errorColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(
      String label, String status, IconData icon, Color color) {
    final bool isSelected = _currentStatus == status;

    return GestureDetector(
      onTap: () => _updateDeliveryStatus(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.borderColor,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.whiteColor : color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? AppColors.whiteColor
                    : AppColors.textPrimaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSignatureDialog() async {
    await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        child: SignaturePad(
          onSave: (signature) => Navigator.pop(context, signature),
          existingSignature: _selectedDelivery?.signature,
        ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    if (_selectedDelivery == null) return const SizedBox.shrink();

    final bool hasStars =
        _selectedDelivery!.stars != null && _selectedDelivery!.stars! > 0;
    final bool hasTextFeedback = _selectedDelivery!.feedback != null &&
        _selectedDelivery!.feedback!.isNotEmpty;
    final bool hasVoiceFeedback = _selectedDelivery!.voiceFeedback != null &&
        _selectedDelivery!.voiceFeedback!.isNotEmpty;
    final bool hasSignature = _selectedDelivery!.signature != null &&
        _selectedDelivery!.signature!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.pinkColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.feedback_rounded,
                  color: AppColors.pinkColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                "Customer Feedback",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Rating Section
          _buildFeedbackItem(
            icon: Icons.star_rounded,
            title: "Rating",
            content: hasStars
                ? Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < _selectedDelivery!.stars!
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 24,
                      );
                    }),
                  )
                : Text(
                    "No rating provided",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textMutedColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
            color: Colors.amber,
          ),
          const SizedBox(height: 16),

          // Text Feedback Section
          _buildFeedbackItem(
            icon: Icons.comment_rounded,
            title: "Text Feedback",
            content: hasTextFeedback
                ? Text(
                    _selectedDelivery!.feedback!,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Text(
                    "No written feedback provided",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textMutedColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
            color: AppColors.indigoColor,
          ),
          const SizedBox(height: 16),

          // Interactive Features Row
          Row(
            children: [
              // Voice Feedback
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VoiceFeedbackScreen(
                          deliveryId: _selectedDelivery!.id,
                        ),
                      ),
                    );
                  },
                  child: _buildFeatureIndicator(
                    icon: Icons.mic_rounded,
                    label: "Voice Feedback",
                    isAvailable: hasVoiceFeedback,
                    color: AppColors.violetColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Signature
              Expanded(
                child: GestureDetector(
                  onTap: _showSignatureDialog,
                  child: _buildFeatureIndicator(
                    icon: Icons.draw_rounded,
                    label: "Signature",
                    isAvailable: hasSignature,
                    color: AppColors.cyanColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Package Images
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PackageQualityCheckScreen(
                          deliveryId: _selectedDelivery!.id,
                        ),
                      ),
                    );
                  },
                  child: _buildFeatureIndicator(
                    icon: Icons.photo_library_rounded,
                    label: "Package Images",
                    isAvailable: true, // You can check if images exist
                    color: AppColors.emeraldColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackItem({
    required IconData icon,
    required String title,
    required Widget content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildFeatureIndicator({
    required IconData icon,
    required String label,
    required bool isAvailable,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
