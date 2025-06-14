import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_now_app/utils/show_toast.dart';
import 'package:flutter/material.dart';
import 'package:delivery_now_app/models/user_model.dart';
import 'package:delivery_now_app/services/firebase_services.dart';
import 'package:delivery_now_app/utils/colors.dart';

class AssignNewDelivery extends StatefulWidget {
  final UserModel? selectedRider;
  const AssignNewDelivery({super.key, this.selectedRider});

  @override
  State<AssignNewDelivery> createState() => _AssignNewDeliveryState();
}

class _AssignNewDeliveryState extends State<AssignNewDelivery>
    with TickerProviderStateMixin {
  final FirebaseServices _firebaseServices = FirebaseServices();
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _packageDetailsController = TextEditingController();
  final _itemController = TextEditingController();
  final _priceController = TextEditingController();
  List<String> _items = [];
  DateTime? _selectedDate;
  String _selectedPriority = 'medium';
  String _selectedOrder = 'small';
  bool _isLoading = false;

  // Customer selection variables
  List<UserModel> _customers = [];
  UserModel? _selectedCustomer;
  bool _isLoadingCustomers = false;
  bool _useExistingCustomer = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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

    _fadeController.forward();
    _slideController.forward();
  }

  String _generatePackageId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return 'GS${List.generate(6, (_) => chars[random.nextInt(chars.length)]).join()}';
  }

  String _generateCustomerId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return 'CUST${List.generate(8, (_) => chars[random.nextInt(chars.length)]).join()}';
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoadingCustomers = true;
    });

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 'customer')
          .get();

      _customers = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      showToast('Error loading customers: $e', AppColors.errorColor);
    } finally {
      setState(() {
        _isLoadingCustomers = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: AppColors.blackColor,
              onSurface: AppColors.blackColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Map<String, String> _parseAddress(String address) {
    final parts = address.split(',').map((e) => e.trim()).toList();
    return {
      'street': parts.isNotEmpty ? parts[0] : '',
      'city': parts.length > 1 ? parts[1] : '',
      'state': parts.length > 2 ? parts[2] : '',
      'zip': parts.length > 3 ? parts[3] : '',
    };
  }

  void _addItem() {
    if (_itemController.text.isNotEmpty) {
      setState(() {
        _items.add(_itemController.text);
        _itemController.clear();
      });
    }
  }

  String _getCustomerName() {
    if (_useExistingCustomer && _selectedCustomer != null) {
      return '${_selectedCustomer!.firstName} ${_selectedCustomer!.lastName}';
    } else {
      return _customerNameController.text;
    }
  }

  String _getCustomerId() {
    if (_useExistingCustomer && _selectedCustomer != null) {
      return _selectedCustomer!.uid;
    } else {
      return _generateCustomerId();
    }
  }

  Future<void> _assignDelivery() async {
    // Validate customer selection/input
    bool customerValid = false;
    if (_useExistingCustomer) {
      customerValid = _selectedCustomer != null;
      if (!customerValid) {
        showToast('Please select a customer', AppColors.errorColor);
        return;
      }
    } else {
      customerValid = _customerNameController.text.isNotEmpty;
      if (!customerValid) {
        showToast('Please enter customer name', AppColors.errorColor);
        return;
      }
    }

    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        customerValid) {
      setState(() {
        _isLoading = true;
      });

      try {
        final packageId = _generatePackageId();
        final customerId = _getCustomerId();
        final customerName = _getCustomerName();

        await _firebaseServices.assignNewDelivery(
          packageId: packageId,
          customerName: customerName,
          address: _addressController.text,
          riderId: widget.selectedRider!.uid,
          riderName:
              '${widget.selectedRider!.firstName} ${widget.selectedRider!.lastName}',
          assignedDate: Timestamp.fromDate(_selectedDate!),
          packageDetails: _packageDetailsController.text,
          items: _items,
          priority: _selectedPriority,
          typeOfOrder: _selectedOrder,
          phoneNumber: _phoneNumberController.text,
          price: double.parse(_priceController.text),
          customerId: customerId,
        );

        final deliveryAddress = _parseAddress(_addressController.text);

        await _firebaseServices.saveDeliveryNotification(
          customerName: customerName,
          parcelTrackingNumber: packageId,
          deliveryDate: _selectedDate!.toString(),
          timeWindow: {'start_time': '8:00 AM', 'end_time': '5:00 PM'},
          deliveryAddress: deliveryAddress,
          courierInfo: 'DeliveryNow Delivery Services',
          parcelContents: _packageDetailsController.text,
          riderId: widget.selectedRider!.uid,
          notificationText: '',
          confirmationResult: '',
          customerId: customerId,
        );

        showToast('Delivery Assigned successfully', AppColors.successColor);
        Navigator.pop(context);
      } catch (e) {
        showToast('Error assigning delivery: $e', AppColors.errorColor);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else if (_selectedDate == null) {
      showToast('Please select a delivery date', AppColors.warningColor);
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _packageDetailsController.dispose();
    _itemController.dispose();
    _priceController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedCard({
    required Widget child,
    required int index,
    Color? gradientStart,
    Color? gradientEnd,
  }) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value.dy * (index + 1) * 20),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                color: gradientStart == null ? AppColors.cardColor : null,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (gradientStart ?? AppColors.primaryColor)
                        .withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomerSelection() {
    return _buildAnimatedCard(
      index: 0,
      gradientStart: AppColors.customerColor,
      gradientEnd: AppColors.violetColor,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_pin,
                    color: AppColors.whiteColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Customer Selection",
                  style: TextStyle(
                    color: AppColors.whiteColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.whiteColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _useExistingCustomer = true;
                          _customerNameController.clear();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _useExistingCustomer
                              ? AppColors.whiteColor.withOpacity(0.25)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "Select Existing",
                            style: TextStyle(
                              color: AppColors.whiteColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _useExistingCustomer = false;
                          _selectedCustomer = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_useExistingCustomer
                              ? AppColors.whiteColor.withOpacity(0.25)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "Add New",
                            style: TextStyle(
                              color: AppColors.whiteColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_useExistingCustomer) ...[
              if (_isLoadingCustomers)
                const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.whiteColor,
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonFormField<UserModel>(
                    value: _selectedCustomer,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      hintText: 'Select Customer',
                      hintStyle: TextStyle(color: AppColors.whiteColor),
                      prefixIcon: Icon(
                        Icons.person_search,
                        color: AppColors.whiteColor,
                      ),
                    ),
                    dropdownColor: AppColors.borderLightColor,
                    style: const TextStyle(color: AppColors.whiteColor),
                    items: _customers.map((UserModel customer) {
                      return DropdownMenuItem<UserModel>(
                        value: customer,
                        child: Text(
                          '${customer.firstName} ${customer.lastName}',
                          style: const TextStyle(color: AppColors.whiteColor),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCustomer = value;
                      });
                    },
                  ),
                ),
            ] else ...[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.whiteColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _customerNameController,
                  style: const TextStyle(color: AppColors.whiteColor),
                  decoration: const InputDecoration(
                    hintText: "Enter Customer Name",
                    hintStyle: TextStyle(color: AppColors.whiteColor),
                    prefixIcon: Icon(
                      Icons.person_add,
                      color: AppColors.whiteColor,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    required int index,
    required Color gradientStart,
    required Color gradientEnd,
  }) {
    return _buildAnimatedCard(
      index: index,
      gradientStart: gradientStart,
      gradientEnd: gradientEnd,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.whiteColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: AppColors.whiteColor),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.whiteColor),
              prefixIcon: Icon(icon, color: AppColors.whiteColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageItems() {
    return _buildAnimatedCard(
      index: 5,
      gradientStart: AppColors.riderColor,
      gradientEnd: AppColors.indigoColor,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.whiteColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Package Items",
                  style: TextStyle(
                    color: AppColors.whiteColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.whiteColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _itemController,
                      style: const TextStyle(color: AppColors.whiteColor),
                      decoration: const InputDecoration(
                        hintText: "Add item",
                        hintStyle: TextStyle(color: AppColors.whiteColor),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: AppColors.whiteColor,
                      ),
                      onPressed: _addItem,
                    ),
                  ),
                ],
              ),
            ),
            if (_items.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _items.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item,
                          style: const TextStyle(
                            color: AppColors.whiteColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _items.remove(item);
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            color: AppColors.whiteColor,
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

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
    required int index,
    required Color gradientStart,
    required Color gradientEnd,
  }) {
    return _buildAnimatedCard(
      index: index,
      gradientStart: gradientStart,
      gradientEnd: gradientEnd,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.whiteColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              border: InputBorder.none,
              labelText: label,
              labelStyle: const TextStyle(color: AppColors.whiteColor),
              prefixIcon: Icon(icon, color: AppColors.whiteColor),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            dropdownColor: gradientStart,
            style: const TextStyle(color: AppColors.whiteColor),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item.capitalize(),
                  style: const TextStyle(color: AppColors.whiteColor),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return _buildAnimatedCard(
      index: 8,
      gradientStart: AppColors.riderColor,
      gradientEnd: AppColors.indigoColor,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.whiteColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.whiteColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'Select Delivery Date'
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    style: TextStyle(
                      color: _selectedDate == null
                          ? AppColors.whiteColor.withOpacity(0.7)
                          : AppColors.whiteColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.whiteColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
          ),
          // Content
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.whiteColor,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    "Assign New Delivery",
                    style: TextStyle(
                      color: AppColors.whiteColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryColor.withOpacity(0.8),
                          AppColors.violetColor.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildCustomerSelection(),
                        _buildTextField(
                          controller: _addressController,
                          hint: "Delivery Address",
                          icon: Icons.location_on_rounded,
                          index: 1,
                          gradientStart: AppColors.riderColor,
                          gradientEnd: AppColors.indigoColor,
                        ),
                        _buildTextField(
                          controller: _phoneNumberController,
                          hint: "Phone Number",
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          index: 2,
                          gradientStart: AppColors.riderColor,
                          gradientEnd: AppColors.indigoColor,
                        ),
                        _buildTextField(
                          controller: _packageDetailsController,
                          hint: "Package Details",
                          icon: Icons.description_rounded,
                          index: 3,
                          gradientStart: AppColors.riderColor,
                          gradientEnd: AppColors.indigoColor,
                        ),
                        _buildTextField(
                          controller: _priceController,
                          hint: "Price (Rs.)",
                          icon: Icons.monetization_on_rounded,
                          keyboardType: TextInputType.number,
                          index: 4,
                          gradientStart: AppColors.riderColor,
                          gradientEnd: AppColors.indigoColor,
                        ),
                        _buildPackageItems(),
                        _buildDropdownField(
                          value: _selectedPriority,
                          items: ['medium', 'high'],
                          label: 'Priority Level',
                          icon: Icons.priority_high_rounded,
                          onChanged: (value) {
                            setState(() {
                              _selectedPriority = value!;
                            });
                          },
                          index: 6,
                          gradientStart: AppColors.riderColor,
                          gradientEnd: AppColors.indigoColor,
                        ),
                        _buildDropdownField(
                          value: _selectedOrder,
                          items: ['small', 'medium', 'large'],
                          label: 'Package Size',
                          icon: Icons.inventory_2_rounded,
                          onChanged: (value) {
                            setState(() {
                              _selectedOrder = value!;
                            });
                          },
                          index: 7,
                          gradientStart: AppColors.riderColor,
                          gradientEnd: AppColors.indigoColor,
                        ),
                        _buildDateSelector(),
                        const SizedBox(height: 30),
                        _buildAnimatedCard(
                          index: 9,
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primaryColor,
                                  AppColors.primaryDarkColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primaryColor.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: _isLoading ? null : _assignDelivery,
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: AppColors.whiteColor,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons
                                                  .assignment_turned_in_rounded,
                                              color: AppColors.whiteColor,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              "Assign Delivery",
                                              style: TextStyle(
                                                color: AppColors.whiteColor,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
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

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
