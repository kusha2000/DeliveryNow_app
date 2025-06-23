import 'package:flutter/material.dart';
import 'package:delivery_now_app/models/delivery_model.dart';
import 'package:delivery_now_app/services/firebase_services.dart';
import 'package:delivery_now_app/shared/screens/one_delivery_details.dart';
import 'package:delivery_now_app/shared/widgets/delivery_item_widget.dart';
import 'package:delivery_now_app/utils/colors.dart';

class AllDeliveriesScreen extends StatefulWidget {
  final String riderId;

  const AllDeliveriesScreen({super.key, required this.riderId});

  @override
  State<AllDeliveriesScreen> createState() => _AllDeliveriesScreenState();
}

class _AllDeliveriesScreenState extends State<AllDeliveriesScreen> {
  final FirebaseServices _firebaseServices = FirebaseServices();
  DateTime? _selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.whiteColor, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          "All Delivery Details",
          style: TextStyle(
            color: AppColors.whiteColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        toolbarHeight: 70,
      ),
      body: Column(
        children: [
          // Date Picker
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate == null
                      ? 'All Deliveries'
                      : 'Date: ${_selectedDate!.toString().split(' ')[0]}',
                  style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
                ),
                Row(
                  children: [
                    if (_selectedDate != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedDate = null;
                          });
                        },
                        child: Text(
                          'Clear Filter',
                          style: TextStyle(color: AppColors.redColor),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: () => _selectDate(context),
                      child: Text(
                        'Select Date',
                        style: TextStyle(color: AppColors.primaryColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Deliveries List
          Expanded(
            child: FutureBuilder<List<DeliveryModel>>(
              future: _selectedDate == null
                  ? _firebaseServices.fetchAllDeliveriesForOneRider(
                      riderId: widget.riderId)
                  : _firebaseServices.getDeliveriesByDate(
                      riderId: widget.riderId,
                      date: _selectedDate!,
                    ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                      child: Text(_selectedDate == null
                          ? 'No deliveries found'
                          : 'No deliveries for this date'));
                }
                final deliveries = snapshot.data!;
                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: deliveries.length,
                  itemBuilder: (context, index) {
                    final delivery = deliveries[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OneDeliveryDetailsScreen(
                              deliveryId: delivery.id,
                            ),
                          ),
                        );
                      },
                      child: deliveryItemWidget(
                        delivery.packageId,
                        delivery.customerName,
                        delivery.address,
                        delivery.status,
                        delivery.assignedDate,
                        _getStatusColor(delivery.status),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.greenColor;
      case 'pending':
        return AppColors.redColor;
      case 'in_transit':
        return AppColors.primaryColor;
      case 'returned':
        return AppColors.brownColor;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppColors.grey100;
    }
  }
}
