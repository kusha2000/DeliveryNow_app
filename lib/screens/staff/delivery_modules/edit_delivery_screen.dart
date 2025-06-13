import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_now_app/utils/show_toast.dart';
import 'package:flutter/material.dart';
import 'package:delivery_now_app/models/delivery_model.dart';
import 'package:delivery_now_app/models/user_model.dart';
import 'package:delivery_now_app/services/firebase_services.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'package:intl/intl.dart';

class EditDeliveryScreen extends StatefulWidget {
  final UserModel? selectedRider;

  const EditDeliveryScreen({super.key, this.selectedRider});

  @override
  State<EditDeliveryScreen> createState() => _EditDeliveryScreenState();
}

class _EditDeliveryScreenState extends State<EditDeliveryScreen>
    with TickerProviderStateMixin {
  final FirebaseServices _firebaseServices = FirebaseServices();
  DeliveryModel? _selectedDelivery;
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _packageDetailsController = TextEditingController();
  final _itemController = TextEditingController();
  final _priceController = TextEditingController();
  List<String> _items = [];
  DateTime? _assignedDate;
  String _selectedPriority = 'medium';
  String _selectedOrder = 'small';

  // Add a filter date
  DateTime? _filterDate;
  List<DeliveryModel> _allDeliveries = [];
  List<DeliveryModel> _filteredDeliveries = [];

  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _packageDetailsController.dispose();
    _itemController.dispose();
    _priceController.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  // Select date for a new delivery assignment
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _assignedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: AppColors.whiteColor,
              surface: AppColors.surfaceColor,
              onSurface: AppColors.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _assignedDate = picked;
      });
    }
  }

  // Select filter date from app bar
  Future<void> _selectFilterDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: AppColors.whiteColor,
              surface: AppColors.surfaceColor,
              onSurface: AppColors.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _filterDate = picked;
        _applyDateFilter();
      });
      _filterAnimationController.forward();

      showToast(
          'Showing deliveries for ${DateFormat('MMM d, yyyy').format(_filterDate!)}',
          AppColors.primaryColor);
    }
  }

  // Clear the date filter
  void _clearDateFilter() {
    setState(() {
      _filterDate = null;
      _filteredDeliveries = List.from(_allDeliveries);
    });
    _filterAnimationController.reverse();
    showToast('Date filter cleared', AppColors.primaryColor);
  }

  // Apply date filter to deliveries
  void _applyDateFilter() {
    if (_filterDate == null) {
      _filteredDeliveries = List.from(_allDeliveries);
      return;
    }

    // Create date range for the selected date (entire day)
    final startOfDay =
        DateTime(_filterDate!.year, _filterDate!.month, _filterDate!.day);
    final endOfDay = DateTime(
        _filterDate!.year, _filterDate!.month, _filterDate!.day, 23, 59, 59);

    _filteredDeliveries = _allDeliveries.where((delivery) {
      DateTime deliveryDate = delivery.assignedDate.toDate();
      return deliveryDate
              .isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
          deliveryDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
    }).toList();
  }

  void _selectDelivery(DeliveryModel delivery) {
    setState(() {
      _selectedDelivery = delivery;
      _customerNameController.text = delivery.customerName;
      _addressController.text = delivery.address;
      _phoneNumberController.text = delivery.phoneNumber;
      _packageDetailsController.text = delivery.packageDetails ?? '';
      _priceController.text = delivery.price.toString();
      _items = List.from(delivery.items);
      _assignedDate = delivery.assignedDate.toDate();
      _selectedPriority = delivery.priority;
      _selectedOrder = delivery.typeOfOrder ?? 'small';
    });
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate() &&
        _selectedDelivery != null &&
        _assignedDate != null) {
      try {
        // Show modern loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Container(
            decoration: BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                strokeWidth: 3,
              ),
            ),
          ),
        );

        // Convert DateTime to Timestamp
        final assignedTimestamp = Timestamp.fromDate(_assignedDate!);

        // Update delivery in Firestore
        await _firebaseServices.updateDeliveryDetails(
          deliveryId: _selectedDelivery!.id,
          customerName: _customerNameController.text,
          address: _addressController.text,
          phoneNumber: _phoneNumberController.text,
          packageDetails: _packageDetailsController.text,
          items: _items,
          assignedDate: assignedTimestamp,
          priority: _selectedPriority,
          typeOfOrder: _selectedOrder,
          price: double.parse(_priceController.text),
        );

        // Close loading indicator
        if (mounted) Navigator.of(context).pop();

        // Show success message
        showToast('Delivery updated successfully', AppColors.successColor);

        // Reset form and state
        setState(() {
          _selectedDelivery = null;
          _customerNameController.clear();
          _addressController.clear();
          _phoneNumberController.clear();
          _packageDetailsController.clear();
          _itemController.clear();
          _priceController.clear();
          _items.clear();
          _assignedDate = null;
          _selectedPriority = 'medium';
          _selectedOrder = 'small';
        });

        // Close the edit dialog
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) Navigator.of(context).pop();

        // Show error message
        showToast('Error updating delivery: $e', AppColors.errorColor);
        debugPrint('Error updating delivery: $e');
      }
    } else {
      // Show validation error if date is not selected
      if (_assignedDate == null) {
        showToast('Please select a delivery date', AppColors.warningColor);
      }
    }
  }

  Future<void> _cancelDelivery() async {
    if (_selectedDelivery != null) {
      try {
        await _firebaseServices.cancelDelivery(_selectedDelivery!.id);

        setState(() {
          _selectedDelivery = null;
          _customerNameController.clear();
          _addressController.clear();
          _phoneNumberController.clear();
          _packageDetailsController.clear();
          _itemController.clear();
          _priceController.clear();
          _items.clear();
          _assignedDate = null;
          _selectedPriority = 'medium';
          _selectedOrder = 'small';
        });
        if (mounted) Navigator.of(context).pop();
        showToast('Delivery cancelled successfully', AppColors.successColor);
      } catch (e) {
        if (mounted) Navigator.of(context).pop();
        showToast('Error cancelling delivery: $e', AppColors.errorColor);
      }
    }
  }

  void _showEditDeliveryDialog() {
    showDialog(
      context: context,
      barrierColor: AppColors.blackColor.withOpacity(0.7),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceColor,
                  AppColors.cardColor,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setDialogState) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.edit_note_rounded,
                                color: AppColors.whiteColor,
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Text(
                                "Edit Delivery Details",
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

                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildModernTextField(
                                controller: _customerNameController,
                                hint: "Customer Name",
                                icon: Icons.person_rounded,
                                validator: (value) => value?.isEmpty == true
                                    ? 'Please enter customer name'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              _buildModernTextField(
                                controller: _addressController,
                                hint: "Address",
                                icon: Icons.location_on_rounded,
                                validator: (value) => value?.isEmpty == true
                                    ? 'Please enter address'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              _buildModernTextField(
                                controller: _phoneNumberController,
                                hint: "Phone Number",
                                icon: Icons.phone_rounded,
                                validator: (value) => value?.isEmpty == true
                                    ? 'Please enter phone number'
                                    : null,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),
                              _buildModernTextField(
                                controller: _packageDetailsController,
                                hint: "Package Details",
                                icon: Icons.description_rounded,
                              ),
                              const SizedBox(height: 16),
                              _buildModernTextField(
                                controller: _priceController,
                                hint: "Price (Rs.)",
                                icon: Icons.payments_rounded,
                                validator: (value) {
                                  if (value?.isEmpty == true)
                                    return 'Please enter price';
                                  if (double.tryParse(value ?? '') == null ||
                                      (double.tryParse(value!) ?? 0) <= 0)
                                    return 'Please enter a valid price';
                                  return null;
                                },
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 20),

                              // Items section
                              _buildItemsSection(setDialogState),
                              const SizedBox(height: 20),
                              _buildModernDropdown(
                                value: _selectedPriority,
                                items: ['low', 'medium', 'high'],
                                icon: Icons.priority_high_rounded,
                                label: 'Priority',
                                onChanged: (value) {
                                  setDialogState(() {
                                    _selectedPriority = value ?? 'medium';
                                  });
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildModernDropdown(
                                value: _selectedOrder,
                                items: ['small', 'medium', 'large'],
                                icon: Icons.inventory_2_rounded,
                                label: 'Order Size',
                                onChanged: (value) {
                                  setDialogState(() {
                                    _selectedOrder = value ?? 'small';
                                  });
                                },
                              ),
                              SizedBox(height: 20),

                              // Date selector
                              _buildDateSelector(setDialogState),
                              const SizedBox(height: 20),

                              // Action buttons
                              _buildActionButton(
                                onPressed: _saveChanges,
                                text: "Save Changes",
                                icon: Icons.save_rounded,
                                gradient: AppColors.primaryGradient,
                              ),
                              const SizedBox(height: 20),
                              _buildActionButton(
                                onPressed: _cancelDelivery,
                                text: "Cancel Delivery",
                                icon: Icons.cancel_rounded,
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.errorColor,
                                    Color(0xFFD32F2F),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern App Bar
              _buildModernAppBar(),

              // Filter indicator
              if (_filterDate != null)
                AnimatedBuilder(
                  animation: _filterAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _filterAnimation.value,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryColor.withOpacity(0.2),
                              AppColors.accentColor.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.filter_alt_rounded,
                                color: AppColors.whiteColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Filtered by: ${DateFormat('MMM d, yyyy').format(_filterDate!)}",
                                style: const TextStyle(
                                  color: AppColors.textPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: AppColors.textSecondaryColor,
                                size: 20,
                              ),
                              onPressed: _clearDateFilter,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Section header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.tealColor.withOpacity(0.2),
                              AppColors.cyanColor.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.tealColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.list_alt_rounded,
                              color: AppColors.tealColor,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Select Delivery to Edit",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Deliveries list
                      Expanded(
                        child: StreamBuilder<List<DeliveryModel>>(
                          stream: _firebaseServices.getRiderDeliveries(
                              widget.selectedRider?.uid ?? ''),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return _buildErrorState();
                            }
                            if (!snapshot.hasData) {
                              return _buildLoadingState();
                            }

                            // Store all deliveries
                            _allDeliveries = snapshot.data!;

                            // Apply filter
                            _applyDateFilter();

                            if (_filteredDeliveries.isEmpty) {
                              return _buildEmptyState();
                            }

                            return ListView.builder(
                              itemCount: _filteredDeliveries.length,
                              itemBuilder: (context, index) {
                                final delivery = _filteredDeliveries[index];
                                return GestureDetector(
                                  onTap: () {
                                    _selectDelivery(delivery);
                                    _showEditDeliveryDialog();
                                  },
                                  child:
                                      _buildModernDeliveryCard(delivery, index),
                                );
                              },
                            );
                          },
                        ),
                      ),
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

  Widget _buildModernAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardColor.withOpacity(0.9),
            AppColors.surfaceColor.withOpacity(0.9),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.primaryColor,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Edit Deliveries",
                  style: TextStyle(
                    color: AppColors.textPrimaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Manage your delivery assignments",
                  style: TextStyle(
                    color: AppColors.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primaryColor,
                  ),
                  onPressed: () => _selectFilterDate(context),
                ),
              ),
              if (_filterDate != null) ...[
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.errorColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.errorColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.filter_alt_off_rounded,
                      color: AppColors.errorColor,
                    ),
                    onPressed: _clearDateFilter,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernDeliveryCard(DeliveryModel delivery, int index) {
    Color statusColor;
    IconData statusIcon;
    final status = delivery.status;

    switch (status) {
      case 'pending':
        statusColor = AppColors.warningColor;
        statusIcon = Icons.pending_rounded;
        break;
      case 'in_transit':
        statusColor = AppColors.infoColor;
        statusIcon = Icons.local_shipping_rounded;
        break;
      case 'delivered':
        statusColor = AppColors.successColor;
        statusIcon = Icons.check_circle_rounded;
        break;
      default:
        statusColor = AppColors.errorColor;
        statusIcon = Icons.cancel_rounded;
    }

    // Get gradient based on priority
    LinearGradient cardGradient;
    switch (delivery.priority) {
      case 'high':
        cardGradient = LinearGradient(
          colors: [
            AppColors.errorColor.withOpacity(0.1),
            AppColors.pinkColor.withOpacity(0.05),
          ],
        );
        break;
      case 'medium':
        cardGradient = LinearGradient(
          colors: [
            AppColors.warningColor.withOpacity(0.1),
            AppColors.primaryColor.withOpacity(0.05),
          ],
        );
        break;
      default:
        cardGradient = LinearGradient(
          colors: [
            AppColors.successColor.withOpacity(0.1),
            AppColors.tealColor.withOpacity(0.05),
          ],
        );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(20),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _selectDelivery(delivery);
            _showEditDeliveryDialog();
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "ID: ${delivery.packageId}",
                        style: const TextStyle(
                          color: AppColors.whiteColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            color: statusColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status.replaceAll('_', ' ').capitalize(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Customer info
                _buildInfoRow(
                  Icons.person_rounded,
                  "Customer",
                  delivery.customerName,
                  AppColors.tealColor,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.location_on_rounded,
                  "Address",
                  delivery.address,
                  AppColors.indigoColor,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.payments_rounded,
                  "Price",
                  "Rs. ${delivery.price.toStringAsFixed(2)}",
                  AppColors.emeraldColor,
                ),

                // Rating if available
                if (delivery.stars != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${delivery.stars!.toStringAsFixed(1)} stars",
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Bottom row with date and priority
                Row(
                  children: [
                    // Date
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.infoColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.infoColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.infoColor,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('MMM d, yyyy')
                                .format(delivery.assignedDate.toDate()),
                            style: const TextStyle(
                              color: AppColors.infoColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Priority
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: _getPriorityGradient(delivery.priority),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPriorityIcon(delivery.priority),
                            color: AppColors.whiteColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            delivery.priority.capitalize(),
                            style: const TextStyle(
                              color: AppColors.whiteColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  LinearGradient _getPriorityGradient(String priority) {
    switch (priority) {
      case 'high':
        return const LinearGradient(
          colors: [AppColors.errorColor, Color(0xFFD32F2F)],
        );
      case 'medium':
        return const LinearGradient(
          colors: [AppColors.warningColor, Color(0xFFF57C00)],
        );
      default:
        return const LinearGradient(
          colors: [AppColors.successColor, AppColors.emeraldColor],
        );
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return Icons.priority_high_rounded;
      case 'medium':
        return Icons.drag_handle_rounded;
      default:
        return Icons.low_priority_rounded;
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
          SizedBox(height: 16),
          Text(
            "Loading deliveries...",
            style: TextStyle(
              color: AppColors.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.errorColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.errorColor,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Error loading deliveries",
            style: TextStyle(
              color: AppColors.textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Please try again later",
            style: TextStyle(
              color: AppColors.textSecondaryColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor.withOpacity(0.2),
                  AppColors.accentColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _filterDate != null
                  ? Icons.filter_alt_off_rounded
                  : Icons.local_shipping_outlined,
              color: AppColors.primaryColor,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _filterDate != null
                ? 'No deliveries found'
                : 'No active deliveries',
            style: const TextStyle(
              color: AppColors.textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filterDate != null
                ? 'for ${DateFormat('MMM d, yyyy').format(_filterDate!)}'
                : 'All deliveries completed',
            style: const TextStyle(
              color: AppColors.textSecondaryColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardColor.withOpacity(0.8),
            AppColors.surfaceColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          color: AppColors.textPrimaryColor,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textMutedColor,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryColor,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildModernDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required String label,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardColor.withOpacity(0.8),
            AppColors.surfaceColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: AppColors.textSecondaryColor,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryColor,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
        dropdownColor: AppColors.cardColor,
        style: const TextStyle(
          color: AppColors.textPrimaryColor,
          fontWeight: FontWeight.w500,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item.capitalize()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildItemsSection(StateSetter setDialogState) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.tealColor.withOpacity(0.1),
            AppColors.cyanColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.tealColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.inventory_2_rounded,
                  color: AppColors.tealColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  "Items",
                  style: TextStyle(
                    color: AppColors.textPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildModernTextField(
                    controller: _itemController,
                    hint: "Item name",
                    icon: Icons.shopping_bag_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.add_rounded,
                      color: AppColors.whiteColor,
                    ),
                    onPressed: () {
                      if (_itemController.text.isNotEmpty) {
                        setDialogState(() {
                          _items.add(_itemController.text);
                          _itemController.clear();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            if (_items.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item,
                          style: const TextStyle(
                            color: AppColors.textPrimaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              _items.removeAt(index);
                            });
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondaryColor,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(StateSetter setDialogState) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.infoColor.withOpacity(0.1),
              AppColors.indigoColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.infoColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.infoColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: AppColors.infoColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Delivery Date",
                    style: TextStyle(
                      color: AppColors.textSecondaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _assignedDate != null
                        ? DateFormat('EEEE, MMM d, yyyy').format(_assignedDate!)
                        : "Select delivery date",
                    style: TextStyle(
                      color: _assignedDate != null
                          ? AppColors.textPrimaryColor
                          : AppColors.textMutedColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_drop_down_rounded,
              color: AppColors.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: AppColors.whiteColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.whiteColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
