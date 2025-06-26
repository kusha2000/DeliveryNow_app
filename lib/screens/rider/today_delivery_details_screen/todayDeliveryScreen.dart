import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_now_app/utils/show_toast.dart';
import 'package:flutter/material.dart';
import 'package:delivery_now_app/screens/Rider/today_delivery_details_screen/mapScreen.dart';
import 'package:delivery_now_app/screens/Rider/today_delivery_details_screen/widgets/empty_widget.dart';
import 'package:delivery_now_app/screens/Rider/today_delivery_details_screen/widgets/summary_item_widget.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'package:delivery_now_app/models/delivery_model.dart';
import 'package:delivery_now_app/services/firebase_services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class TodayDeliveryScreen extends StatefulWidget {
  const TodayDeliveryScreen({super.key});

  @override
  State<TodayDeliveryScreen> createState() => _TodayDeliveryScreenState();
}

class _TodayDeliveryScreenState extends State<TodayDeliveryScreen> {
  final FirebaseServices _firebaseServices = FirebaseServices();
  List<DeliveryModel> _deliveries = [];
  Map<String, bool> _rescheduleRequested = {};
  int totalDeliveries = 0;
  int delivered = 0;
  int inTransit = 0;
  int onTheWay = 0;
  int pending = 0;
  int returned = 0;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
  }

  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Pending',
    'On The Way',
    'In Transit',
    'Delivered',
    'Returned'
  ];

  List<DeliveryModel> get _filteredDeliveries {
    List<DeliveryModel> nonCancelled = _deliveries
        .where((delivery) => delivery.status != 'cancelled')
        .toList();
    if (_selectedFilter == 'All') {
      return nonCancelled;
    } else {
      String filterStatus = _selectedFilter.toLowerCase().replaceAll(' ', '_');
      return nonCancelled
          .where((delivery) => delivery.status == filterStatus)
          .toList();
    }
  }

  Future<void> _handleCallButton(DeliveryModel delivery) async {
    String phoneNumber = delivery.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+94$phoneNumber';
    }

    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);

    if (await Permission.phone.request().isGranted) {
      try {
        if (await canLaunchUrl(callUri)) {
          await launchUrl(callUri);
        } else {
          showToast('Cannot make a call to $phoneNumber', AppColors.redColor);
        }
      } catch (e) {
        showToast('Error making call: $e', AppColors.redColor);
      }
    } else {
      showToast('Call permission denied', AppColors.redColor);
    }
  }

  Future<void> _handleMessageButton(DeliveryModel delivery) async {
    String phoneNumber = delivery.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+94$phoneNumber';
    }

    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        showToast('Cannot send message to $phoneNumber', AppColors.redColor);
      }
    } catch (e) {
      showToast('Error sending message: $e', AppColors.redColor);
    }
  }

  void _handleSOSButton() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        title: Text('Emergency SOS',
            style: TextStyle(color: AppColors.textPrimaryColor)),
        content: Text('Are you sure you want to send an emergency SOS signal?',
            style: TextStyle(color: AppColors.textSecondaryColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondaryColor)),
          ),
          TextButton(
            onPressed: () async {
              await _firebaseServices.createSOSRequest();
              Navigator.pop(context);
              showToast('SOS signal sent. Help is on the way!',
                  AppColors.primaryColor);
            },
            child: Text(
              'Send SOS',
              style: TextStyle(color: AppColors.redColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(DeliveryModel delivery) {
    final TextEditingController reasonController = TextEditingController();
    DateTime? requestedDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Reschedule Delivery',
            style: TextStyle(color: AppColors.textPrimaryColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonController,
                style: TextStyle(color: AppColors.textPrimaryColor),
                decoration: InputDecoration(
                  labelText: 'Reason for Rescheduling',
                  labelStyle: TextStyle(color: AppColors.textSecondaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryColor),
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setDialogState) => InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 30)),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: ColorScheme.dark(
                              primary: AppColors.primaryColor,
                              onPrimary: AppColors.blackColor,
                              surface: AppColors.cardColor,
                              onSurface: AppColors.textPrimaryColor,
                            ),
                            dialogBackgroundColor: AppColors.cardColor,
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setDialogState(() {
                        requestedDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Requested Date',
                      labelStyle:
                          TextStyle(color: AppColors.textSecondaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.borderColor),
                      ),
                    ),
                    child: Text(
                      requestedDate != null
                          ? DateFormat('MMM d, yyyy').format(requestedDate!)
                          : 'Select Date',
                      style: TextStyle(
                        color: requestedDate != null
                            ? AppColors.textPrimaryColor
                            : AppColors.textMutedColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty || requestedDate == null) {
                showToast('Please fill all fields', AppColors.redColor);
                return;
              }
              try {
                await _firebaseServices.createRescheduleRequest(
                  deliveryId: delivery.id,
                  riderId: _firebaseServices.getCurrentUserID()!,
                  reason: reasonController.text.trim(),
                  requestedDate: Timestamp.fromDate(requestedDate!),
                );
                setState(() {
                  _rescheduleRequested[delivery.id] = true;
                });
                Navigator.pop(context);
                showToast('Reschedule request submitted', AppColors.greenColor);
              } catch (e) {
                showToast('Error submitting request: $e', AppColors.redColor);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.blackColor,
            ),
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primaryColor,
              onPrimary: AppColors.blackColor,
              surface: AppColors.cardColor,
              onSurface: AppColors.textPrimaryColor,
            ),
            dialogBackgroundColor: AppColors.cardColor,
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

  @override
  Widget build(BuildContext context) {
    String? riderId = _firebaseServices.getCurrentUserID();
    if (riderId == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(
            child: Text('Error: No rider ID found',
                style: TextStyle(color: AppColors.textPrimaryColor))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Set to transparent
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor,
                AppColors.violetColor,
                AppColors.indigoColor,
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_rounded, color: AppColors.whiteColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                "Delivery - ${DateFormat('MMM d, yyyy').format(_selectedDate)}",
                style: TextStyle(
                  color: AppColors.whiteColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.calendar_today, color: AppColors.whiteColor),
              onPressed: _showDatePicker,
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<DeliveryModel>>(
        stream: _firebaseServices.streamDeliveriesByDate(
          riderId: riderId,
          date: _selectedDate,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryColor));
          }

          if (snapshot.hasError) {
            showToast('Error fetching deliveries: ${snapshot.error}',
                AppColors.redColor);
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: TextStyle(color: AppColors.textPrimaryColor)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  color: AppColors.surfaceColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM d, yyyy').format(_selectedDate),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          summaryItemWidget('Total', 0, Icons.inventory_2,
                              AppColors.primaryColor),
                          summaryItemWidget('Delivered', 0, Icons.check_circle,
                              AppColors.greenColor),
                          summaryItemWidget('In Transit', 0,
                              Icons.local_shipping, AppColors.orangeColor),
                          summaryItemWidget('On The Way', 0,
                              Icons.directions_bike, AppColors.primaryColor),
                          summaryItemWidget(
                              'Pending', 0, Icons.schedule, AppColors.redColor),
                          summaryItemWidget('Returned', 0,
                              Icons.keyboard_return, AppColors.brownColor),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildFilterCards(),
                Expanded(child: emptyWidget()),
              ],
            );
          }

          // Process deliveries
          _deliveries =
              snapshot.data!.where((d) => d.status != 'cancelled').toList();

          // Update summary counts
          totalDeliveries = _deliveries.length;
          delivered = _deliveries.where((d) => d.status == 'delivered').length;
          inTransit = _deliveries.where((d) => d.status == 'in_transit').length;
          onTheWay = _deliveries.where((d) => d.status == 'on_the_way').length;
          pending = _deliveries.where((d) => d.status == 'pending').length;
          returned = _deliveries.where((d) => d.status == 'returned').length;

          // Check reschedule requests
          return FutureBuilder<Map<String, bool>>(
            future: Future.wait(_deliveries.map((delivery) async {
              bool hasRequested = await _firebaseServices
                  .hasPendingRescheduleRequest(delivery.id);
              return MapEntry(delivery.id, hasRequested);
            })).then((entries) => Map.fromEntries(entries)),
            builder: (context, rescheduleSnapshot) {
              if (rescheduleSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryColor));
              }

              if (rescheduleSnapshot.hasError) {
                showToast(
                    'Error checking reschedule requests: ${rescheduleSnapshot.error}',
                    AppColors.redColor);
                return Center(
                    child: Text('Error: ${rescheduleSnapshot.error}',
                        style: TextStyle(color: AppColors.textPrimaryColor)));
              }

              _rescheduleRequested = rescheduleSnapshot.data ?? {};

              return Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    color: AppColors.surfaceColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMMM d, yyyy').format(_selectedDate),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            summaryItemWidget('Total', totalDeliveries,
                                Icons.inventory_2, AppColors.primaryColor),
                            summaryItemWidget('Delivered', delivered,
                                Icons.check_circle, AppColors.greenColor),
                            summaryItemWidget('In Transit', inTransit,
                                Icons.local_shipping, AppColors.orangeColor),
                            summaryItemWidget('On The Way', onTheWay,
                                Icons.directions_bike, AppColors.primaryColor),
                            summaryItemWidget('Pending', pending,
                                Icons.schedule, AppColors.redColor),
                            summaryItemWidget('Returned', returned,
                                Icons.keyboard_return, AppColors.brownColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildFilterCards(),
                  Expanded(
                    child: _filteredDeliveries.isEmpty
                        ? emptyWidget()
                        : ListView.builder(
                            padding: EdgeInsets.all(12),
                            itemCount: _filteredDeliveries.length,
                            itemBuilder: (context, index) {
                              final delivery = _filteredDeliveries[index];
                              return _buildDeliveryCard(delivery);
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: ElevatedButton.icon(
        icon: Icon(Icons.emergency, color: AppColors.whiteColor),
        label: Text('SOS', style: TextStyle(color: AppColors.whiteColor)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.redColor,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
        onPressed: _handleSOSButton,
      ),
    );
  }

  Widget _buildFilterCards() {
    return Container(
      color: AppColors.backgroundColor,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFilterCard(_filters[0]),
                SizedBox(width: 8),
                _buildFilterCard(_filters[1]),
                SizedBox(width: 8),
                _buildFilterCard(_filters[2]),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFilterCard(_filters[3]),
                SizedBox(width: 8),
                _buildFilterCard(_filters[4]),
                SizedBox(width: 8),
                _buildFilterCard(_filters[5]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard(String filter) {
    bool isSelected = _selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryColor.withOpacity(0.2)
                : AppColors.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isSelected ? AppColors.primaryColor : AppColors.borderColor,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              filter,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primaryColor
                    : AppColors.textSecondaryColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(DeliveryModel delivery) {
    Color statusColor;
    IconData statusIcon;

    switch (delivery.status) {
      case 'delivered':
        statusColor = AppColors.greenColor;
        statusIcon = Icons.check_circle;
        break;
      case 'in_transit':
        statusColor = AppColors.orangeColor;
        statusIcon = Icons.local_shipping;
        break;
      case 'on_the_way':
        statusColor = AppColors.primaryColor;
        statusIcon = Icons.directions_bike;
        break;
      case 'returned':
        statusColor = AppColors.brownColor;
        statusIcon = Icons.keyboard_return;
        break;
      default:
        statusColor = AppColors.redColor;
        statusIcon = Icons.schedule;
    }

    bool isRequested = _rescheduleRequested[delivery.id] ?? false;

    return Card(
      color: AppColors.cardColor,
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: delivery.priority == 'high'
              ? AppColors.redColor.withOpacity(0.5)
              : AppColors.transparentColor,
          width: delivery.priority == 'high' ? 1.5 : 0,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: AppColors.transparentColor,
          unselectedWidgetColor: AppColors.textMutedColor,
        ),
        child: ExpansionTile(
          iconColor: AppColors.textSecondaryColor,
          collapsedIconColor: AppColors.textMutedColor,
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: EdgeInsets.all(16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory_2,
              color: AppColors.primaryColor,
            ),
          ),
          title: Text(
            delivery.customerName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimaryColor,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 14, color: AppColors.textMutedColor),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      delivery.address,
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondaryColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        SizedBox(width: 4),
                        Text(
                          delivery.status.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing:
              Icon(Icons.keyboard_arrow_down, color: AppColors.textMutedColor),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: AppColors.dividerColor),
                Text(
                  'Package Items:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: delivery.items.map<Widget>((item) {
                    return Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(item,
                          style:
                              TextStyle(color: AppColors.textSecondaryColor)),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(
                          Icons.directions,
                          color: AppColors.blackColor,
                        ),
                        label: Text(
                          'Navigate',
                          style: TextStyle(color: AppColors.blackColor),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DeliveryLocationMap(
                                        deliveryId: delivery.id,
                                      )));
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.call, color: AppColors.whiteColor),
                        label: Text('Call',
                            style: TextStyle(color: AppColors.whiteColor)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.greenColor,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _handleCallButton(delivery),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.message, color: AppColors.whiteColor),
                        label: Text('Message',
                            style: TextStyle(color: AppColors.whiteColor)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orangeColor,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _handleMessageButton(delivery),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.calendar_today,
                            color: AppColors.whiteColor),
                        label: Text(
                          isRequested ? 'Requested' : 'Reschedule',
                          style: TextStyle(color: AppColors.whiteColor),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brownColor,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: isRequested
                            ? null
                            : () => _showRescheduleDialog(delivery),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
