import 'package:delivery_now_app/shared/widgets/customer_delivery_item_with_chat_widget.dart';
import 'package:flutter/material.dart';
import 'package:delivery_now_app/models/delivery_model.dart';
import 'package:delivery_now_app/models/user_model.dart';
import 'package:delivery_now_app/services/firebase_services.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'package:intl/intl.dart';

class AllDeliveryHistoryScreen extends StatefulWidget {
  final UserModel? selectedRider;

  const AllDeliveryHistoryScreen({super.key, this.selectedRider});

  @override
  State<AllDeliveryHistoryScreen> createState() =>
      _AllDeliveryHistoryScreenState();
}

class _AllDeliveryHistoryScreenState extends State<AllDeliveryHistoryScreen> {
  final FirebaseServices _firebaseServices = FirebaseServices();
  DateTime? _filterDate;
  List<DeliveryModel> _allDeliveries = [];
  List<DeliveryModel> _filteredDeliveries = [];

  Future<void> _selectFilterDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryColor,
              onPrimary: AppColors.blackColor,
              surface: AppColors.cardColor,
              onSurface: AppColors.textPrimaryColor,
              background: AppColors.backgroundColor,
              onBackground: AppColors.textPrimaryColor,
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
    }
  }

  void _clearDateFilter() {
    setState(() {
      _filterDate = null;
      _filteredDeliveries = List.from(_allDeliveries);
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderColor,
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.primaryColor,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          "Delivery History",
          style: TextStyle(
            color: AppColors.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // Calendar button to filter by date
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderColor,
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.primaryColor,
                size: 20,
              ),
              onPressed: () => _selectFilterDate(context),
            ),
          ),
          // Clear filter button (only show when filter is active)
          if (_filterDate != null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderColor,
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.filter_alt_off_rounded,
                  color: AppColors.errorColor,
                  size: 20,
                ),
                onPressed: _clearDateFilter,
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show date filter info if active
                if (_filterDate != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryColor.withOpacity(0.15),
                          AppColors.primaryLightColor.withOpacity(0.1),
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
                            color: AppColors.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.filter_alt_rounded,
                            color: AppColors.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Date Filter Active",
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('EEEE, MMM d, yyyy')
                                    .format(_filterDate!),
                                style: TextStyle(
                                  color:
                                      AppColors.primaryColor.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Header Section
                Container(
                  padding: const EdgeInsets.all(20),
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
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryColor.withOpacity(0.2),
                              AppColors.primaryLightColor.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.history_rounded,
                          color: AppColors.primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Delivery History",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${widget.selectedRider?.firstName ?? 'Unknown'} ${widget.selectedRider?.lastName ?? 'Rider'}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: StreamBuilder<List<DeliveryModel>>(
                    stream: _firebaseServices
                        .getRiderDeliveries(widget.selectedRider?.uid ?? ''),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.errorColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: AppColors.errorColor,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Error Loading Deliveries',
                                  style: TextStyle(
                                    color: AppColors.textPrimaryColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please try again later',
                                  style: TextStyle(
                                    color: AppColors.textSecondaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryColor,
                            ),
                          ),
                        );
                      }

                      // Store all deliveries
                      _allDeliveries = snapshot.data!;

                      // Apply filter (this will handle both filtered and unfiltered states)
                      _applyDateFilter();

                      if (_filteredDeliveries.isEmpty) {
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: AppColors.cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.borderColor,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.textMutedColor
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    _filterDate != null
                                        ? Icons.filter_alt_off_rounded
                                        : Icons.local_shipping_outlined,
                                    size: 48,
                                    color: AppColors.textMutedColor,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _filterDate != null
                                      ? 'No deliveries found'
                                      : 'No delivery history',
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
                                      : 'No deliveries found for this rider',
                                  style: const TextStyle(
                                    color: AppColors.textSecondaryColor,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: _filteredDeliveries.length,
                        itemBuilder: (context, index) {
                          final delivery = _filteredDeliveries[index];
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
                        },
                      );
                    },
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
