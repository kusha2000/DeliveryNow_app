import 'package:delivery_now_app/utils/show_toast.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'package:delivery_now_app/screens/Staff/alert_panel_screen/widgets/missed_delivery_widget.dart';
import 'package:delivery_now_app/screens/Staff/alert_panel_screen/widgets/reschedule_widget.dart';
import 'package:delivery_now_app/screens/Staff/alert_panel_screen/widgets/sos_widget.dart';
import 'package:delivery_now_app/services/firebase_services.dart';
import 'package:delivery_now_app/models/delivery_model.dart';
import 'package:delivery_now_app/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AlertsPanelScreen extends StatefulWidget {
  const AlertsPanelScreen({super.key});

  @override
  State<AlertsPanelScreen> createState() => _AlertsPanelScreenState();
}

class _AlertsPanelScreenState extends State<AlertsPanelScreen>
    with TickerProviderStateMixin {
  final FirebaseServices _firebaseServices = FirebaseServices();
  bool _showAllMissedDeliveries = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 70,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.backgroundColor,
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
              child: FlexibleSpaceBar(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Back button
                    Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_rounded,
                          color: AppColors.whiteColor,
                          size: 15,
                        ),
                      ),
                    ),
                    // Icon and text

                    const SizedBox(width: 12),
                    const Text(
                      "Alerts",
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.whiteColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                centerTitle: true,
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Modern Section Header for Missed Deliveries
                      _buildModernSectionHeader(
                        "Missed Delivery Warnings",
                        Icons.warning_amber_rounded,
                        AppColors.warningColor,
                      ),
                      const SizedBox(height: 16),

                      // Missed Deliveries Stream
                      StreamBuilder<QuerySnapshot>(
                        stream: _firebaseServices.getAllDeliveriesStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildLoadingCard();
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return _buildEmptyCard(
                              "No missed deliveries",
                              Icons.check_circle_outline_rounded,
                              AppColors.successColor,
                            );
                          }

                          final allDeliveries = snapshot.data!.docs
                              .map((doc) => DeliveryModel.fromMap(
                                  doc.data() as Map<String, dynamic>))
                              .toList();

                          final deliveries = allDeliveries
                              .where((d) => ![
                                    'delivered',
                                    'returned',
                                    'cancelled'
                                  ].contains(d.status))
                              .toList();

                          final displayedDeliveries = _showAllMissedDeliveries
                              ? deliveries
                              : deliveries.take(3).toList();

                          return Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.surfaceColor,
                                      AppColors.cardColor,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        AppColors.borderColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.shadowColor,
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    if (displayedDeliveries.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          children: displayedDeliveries
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                            final index = entry.key;
                                            final delivery = entry.value;
                                            return Column(
                                              children: [
                                                if (index > 0)
                                                  Divider(
                                                    color: AppColors.borderColor
                                                        .withOpacity(0.3),
                                                    height: 24,
                                                  ),
                                                missedDeliveryWidget(
                                                  delivery.packageId,
                                                  delivery.customerName,
                                                  delivery.riderName,
                                                  DateFormat('MMM dd, yyyy')
                                                      .format(delivery
                                                          .assignedDate
                                                          .toDate()),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    if (deliveries.length > 3)
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                              color: AppColors.borderColor
                                                  .withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                _showAllMissedDeliveries =
                                                    !_showAllMissedDeliveries;
                                              });
                                            },
                                            borderRadius:
                                                const BorderRadius.only(
                                              bottomLeft: Radius.circular(20),
                                              bottomRight: Radius.circular(20),
                                            ),
                                            child: Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 16),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    _showAllMissedDeliveries
                                                        ? "Show Less"
                                                        : "View All (${deliveries.length})",
                                                    style: const TextStyle(
                                                      color: AppColors
                                                          .primaryColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Icon(
                                                    _showAllMissedDeliveries
                                                        ? Icons
                                                            .keyboard_arrow_up_rounded
                                                        : Icons
                                                            .keyboard_arrow_down_rounded,
                                                    color:
                                                        AppColors.primaryColor,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // SOS Alerts Section
                      _buildModernSectionHeader(
                        "Rider SOS Alerts",
                        Icons.emergency_rounded,
                        AppColors.errorColor,
                      ),
                      const SizedBox(height: 16),

                      StreamBuilder<QuerySnapshot>(
                        stream: _firebaseServices.getAllSOSStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildLoadingCard();
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return _buildEmptyCard(
                              "No SOS alerts",
                              Icons.shield_rounded,
                              AppColors.successColor,
                            );
                          }

                          return Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.errorColor,
                                  AppColors.deepOrangeColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.errorColor.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceColor,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: snapshot.data!.docs
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final index = entry.key;
                                  final doc = entry.value;
                                  final sos =
                                      doc.data() as Map<String, dynamic>;
                                  return Column(
                                    children: [
                                      if (index > 0)
                                        Divider(
                                          color: AppColors.borderColor
                                              .withOpacity(0.3),
                                          height: 24,
                                        ),
                                      sosWidget(
                                        sos['riderName'],
                                        DateFormat('MMM dd, yyyy HH:mm')
                                            .format(sos['dateTime'].toDate()),
                                        () async {
                                          final rider = await _firebaseServices
                                              .getUserData(sos['riderId']);
                                          if (rider?.phoneNumber != null) {
                                            final Uri phoneUri = Uri(
                                                scheme: 'tel',
                                                path: rider!.phoneNumber);
                                            if (await canLaunchUrl(phoneUri)) {
                                              await launchUrl(phoneUri);
                                            }
                                          }
                                        },
                                        () async {
                                          bool confirmDelete = await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return _buildModernDialog(
                                                "Confirm Delete",
                                                "Are you sure you want to delete this SOS alert?",
                                                "Cancel",
                                                "Delete",
                                                AppColors.errorColor,
                                              );
                                            },
                                          );

                                          if (confirmDelete == true) {
                                            await _firebaseServices
                                                .deleteSOS(sos['sosID']);
                                          }
                                        },
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // Reschedule Requests Section
                      _buildModernSectionHeader(
                        "Reschedule Requests",
                        Icons.schedule_rounded,
                        AppColors.infoColor,
                      ),
                      const SizedBox(height: 16),

                      StreamBuilder<QuerySnapshot>(
                        stream: _firebaseServices.getAllRescheduleStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildLoadingCard();
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return _buildEmptyCard(
                              "No reschedule requests",
                              Icons.event_available_rounded,
                              AppColors.successColor,
                            );
                          }

                          return Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.infoColor,
                                  AppColors.cyanColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.infoColor.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceColor,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: snapshot.data!.docs
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final index = entry.key;
                                  final doc = entry.value;
                                  final request =
                                      doc.data() as Map<String, dynamic>;
                                  return Column(
                                    children: [
                                      if (index > 0)
                                        Divider(
                                          color: AppColors.borderColor
                                              .withOpacity(0.3),
                                          height: 24,
                                        ),
                                      rescheduleWidget(
                                        request['riderName'],
                                        request['deliveryId'],
                                        DateFormat('MMM dd, yyyy').format(
                                            request['requestedDate'].toDate()),
                                        () => _showRescheduleDialog(
                                            context, request),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSectionHeader(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: AppColors.whiteColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceColor,
            AppColors.cardColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceColor,
            AppColors.cardColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: AppColors.textSecondaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernDialog(
    String title,
    String content,
    String cancelText,
    String confirmText,
    Color confirmColor,
  ) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
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
            color: AppColors.borderColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    content,
                    style: TextStyle(
                      color: AppColors.textSecondaryColor,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.borderColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(false),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            cancelText,
                            style: TextStyle(
                              color: AppColors.textSecondaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: AppColors.borderColor.withOpacity(0.3),
                  ),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(true),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(24),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            confirmText,
                            style: TextStyle(
                              color: confirmColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRescheduleDialog(
      BuildContext context, Map<String, dynamic> request) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Container(
        color: AppColors.backgroundColor.withOpacity(0.8),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
        ),
      ),
    );

    try {
      final results = await Future.wait([
        _firebaseServices.getDeliveryById(request['deliveryId']),
        _firebaseServices.getAllRiders(),
      ]);

      final delivery = results[0] as DeliveryModel?;
      final riders = results[1] as List<UserModel>;
      UserModel? selectedRider = riders.firstWhere(
        (rider) => rider.uid == request['riderId'],
        orElse: () => riders.first,
      );
      DateTime selectedDate = request['requestedDate'].toDate();

      Navigator.of(context).pop();

      showDialog(
        context: context,
        barrierColor: AppColors.backgroundColor.withOpacity(0.8),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.all(20),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
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
                      color: AppColors.borderColor.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Modern Header
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryColor,
                              AppColors.violetColor,
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
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
                                Icons.calendar_month_rounded,
                                color: AppColors.whiteColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                "Reschedule Request",
                                style: TextStyle(
                                  color: AppColors.whiteColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.whiteColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: AppColors.whiteColor,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Delivery Info Section
                              _buildModernInfoSection(
                                context,
                                "Delivery Information",
                                Icons.local_shipping_rounded,
                                AppColors.infoColor,
                                [
                                  _buildModernInfoRow(
                                      "ID", request['deliveryId']),
                                  _buildModernInfoRow(
                                      "Customer", delivery?.customerName ?? ""),
                                  _buildModernInfoRow(
                                      "Current Rider", request['riderName']),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Request Details Section
                              _buildModernInfoSection(
                                context,
                                "Request Details",
                                Icons.info_outline_rounded,
                                AppColors.warningColor,
                                [
                                  _buildModernInfoRow(
                                      "Reason", request['reason']),
                                  _buildModernInfoRow(
                                      "Requested Date",
                                      DateFormat('MMM dd, yyyy')
                                          .format(selectedDate)),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Reassignment Section
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primaryColor.withOpacity(0.1),
                                      AppColors.violetColor.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        AppColors.primaryColor.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                AppColors.primaryColor,
                                                AppColors.violetColor,
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.assignment_ind_rounded,
                                            color: AppColors.whiteColor,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          "Reassignment",
                                          style: TextStyle(
                                            color: AppColors.textPrimaryColor,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Rider Selection
                                    const Text(
                                      "Select Rider",
                                      style: TextStyle(
                                        color: AppColors.textSecondaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.backgroundColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.borderColor
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<UserModel>(
                                          value: selectedRider,
                                          isExpanded: true,
                                          icon: const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: AppColors.textSecondaryColor,
                                          ),
                                          dropdownColor: AppColors.surfaceColor,
                                          style: const TextStyle(
                                            color: AppColors.textPrimaryColor,
                                            fontSize: 16,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 4),
                                          items: riders.map((rider) {
                                            return DropdownMenuItem(
                                              value: rider,
                                              child: Text(
                                                "${rider.firstName} ${rider.lastName}",
                                                style: const TextStyle(
                                                  color: AppColors
                                                      .textPrimaryColor,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              selectedRider = value;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Date Selection
                                    const Text(
                                      "Select New Date",
                                      style: TextStyle(
                                        color: AppColors.textSecondaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () async {
                                          final DateTime? pickedDate =
                                              await showDatePicker(
                                            context: context,
                                            initialDate: selectedDate
                                                    .isBefore(DateTime.now())
                                                ? DateTime.now()
                                                : selectedDate,
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime.now()
                                                .add(const Duration(days: 30)),
                                            builder: (context, child) {
                                              return Theme(
                                                data:
                                                    Theme.of(context).copyWith(
                                                  colorScheme:
                                                      const ColorScheme.dark(
                                                    primary:
                                                        AppColors.primaryColor,
                                                    onPrimary:
                                                        AppColors.whiteColor,
                                                    surface:
                                                        AppColors.surfaceColor,
                                                    onSurface: AppColors
                                                        .textPrimaryColor,
                                                  ),
                                                  dialogBackgroundColor:
                                                      AppColors.surfaceColor,
                                                ),
                                                child: child!,
                                              );
                                            },
                                          );

                                          if (pickedDate != null) {
                                            setState(() {
                                              selectedDate = pickedDate;
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: AppColors.backgroundColor,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: AppColors.borderColor
                                                  .withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  DateFormat(
                                                          'EEEE, MMM dd, yyyy')
                                                      .format(selectedDate),
                                                  style: const TextStyle(
                                                    color: AppColors
                                                        .textPrimaryColor,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              const Icon(
                                                Icons.calendar_today_rounded,
                                                color: AppColors.primaryColor,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Action Buttons
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: AppColors.borderColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        AppColors.borderColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => Navigator.pop(context),
                                    borderRadius: BorderRadius.circular(12),
                                    child: const Center(
                                      child: Text(
                                        "Cancel",
                                        style: TextStyle(
                                          color: AppColors.textSecondaryColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      AppColors.primaryColor,
                                      AppColors.violetColor,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryColor
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (BuildContext context) {
                                          return Container(
                                            color: AppColors.backgroundColor
                                                .withOpacity(0.8),
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                            Color>(
                                                        AppColors.primaryColor),
                                              ),
                                            ),
                                          );
                                        },
                                      );

                                      try {
                                        await _firebaseServices
                                            .updateDeliveryWithRiderDetails(
                                          deliveryId: request['deliveryId'],
                                          assignedDate:
                                              Timestamp.fromDate(selectedDate),
                                          riderId: selectedRider!.uid,
                                          riderName:
                                              "${selectedRider!.firstName} ${selectedRider!.lastName}",
                                        );

                                        await _firebaseServices
                                            .updateRequestedDeliveryDetails(
                                          requestId: request['requestId'],
                                          assignedDate:
                                              Timestamp.fromDate(selectedDate),
                                          newRiderId: selectedRider!.uid,
                                          newRiderName:
                                              "${selectedRider!.firstName} ${selectedRider!.lastName}",
                                        );

                                        Navigator.pop(context);
                                        Navigator.pop(context);

                                        showToast(
                                            "Delivery successfully rescheduled",
                                            AppColors.successColor);
                                      } catch (e) {
                                        Navigator.pop(context);
                                        showToast("Error: ${e.toString()}",
                                            AppColors.errorColor);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: const Center(
                                      child: Text(
                                        "Confirm Reschedule",
                                        style: TextStyle(
                                          color: AppColors.whiteColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
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
          );
        },
      );
    } catch (e) {
      Navigator.of(context).pop();
      showToast("Error loading data: ${e.toString()}", AppColors.errorColor);
    }
  }

  // Helper widget for modern info sections
  Widget _buildModernInfoSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: AppColors.whiteColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for modern info rows
  Widget _buildModernInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryColor,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimaryColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
