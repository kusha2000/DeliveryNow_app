import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'package:intl/intl.dart';

Widget customerDeliveryItemWithChatWidget({
  required String id,
  required String name,
  required String address,
  required String status,
  required Timestamp date,
  required Color statusColor,
  required BuildContext context,
  String? customerId,
  String? customerName,
  String? orderId,
  bool isCustomer = false,
}) {
  return FutureBuilder<Map<String, dynamic>?>(
    future: _getRiderDetails(id),
    builder: (context, snapshot) {
      Map<String, dynamic>? riderData = snapshot.data;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.whiteColor,
                  AppColors.primaryColor.withOpacity(0.01),
                  AppColors.whiteColor,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.12),
                  blurRadius: 32,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.blackColor.withOpacity(0.04),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.7),
                  ],
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Header Section
                      Row(
                        children: [
                          // Package Icon with Glassmorphism Effect
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primaryColor.withOpacity(0.2),
                                  AppColors.primaryColor.withOpacity(0.1),
                                ],
                              ),
                              border: Border.all(
                                color: AppColors.primaryColor.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryColor.withOpacity(0.2),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.local_shipping_rounded,
                              color: AppColors.primaryColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Package Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Package ID Chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryColor.withOpacity(0.15),
                                        AppColors.primaryColor.withOpacity(0.08),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primaryColor.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    '#$id',
                                    style: TextStyle(
                                      color: AppColors.primaryColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // Customer Name
                                if (name.isNotEmpty)
                                  Text(
                                    name,
                                    style: TextStyle(
                                      color: AppColors.blackColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          // Status Badge with Modern Design
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  statusColor.withOpacity(0.15),
                                  statusColor.withOpacity(0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Address and Date Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.08),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Address Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryColor.withOpacity(0.1),
                                        AppColors.primaryColor.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    size: 16,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    address,
                                    style: TextStyle(
                                      color: AppColors.grey700,
                                      fontSize: 14,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Date Row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.tealColor.withOpacity(0.1),
                                        AppColors.tealColor.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.schedule_rounded,
                                    size: 16,
                                    color: AppColors.tealColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat('MMM d, yyyy • h:mm a').format(date.toDate()),
                                  style: TextStyle(
                                    color: AppColors.grey700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Rider Section
                      if (riderData != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.riderColor.withOpacity(0.08),
                                AppColors.riderColor.withOpacity(0.04),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.riderColor.withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Rider Avatar with Gradient Border
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.riderColor,
                                      AppColors.riderColor.withOpacity(0.7),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.riderColor.withOpacity(0.3),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: riderData['profileImage'] != null &&
                                            riderData['profileImage'].isNotEmpty
                                        ? _buildProfileImage(riderData['profileImage'])
                                        : _buildInitialsAvatar(riderData['riderName'] ?? 'Unknown'),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // Rider Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.riderColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.delivery_dining_rounded,
                                                size: 14,
                                                color: AppColors.riderColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "Delivery Rider",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.riderColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      riderData['riderName'] ?? 'Unknown Rider',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.blackColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Chat Button with Glassmorphism
                              GestureDetector(
                                onTap: () {
                                  if (customerId == null || customerId.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Unregistered users cant use the chat feature.'),
                                        backgroundColor: AppColors.errorColor,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(
                                  //     builder: (context) => ChatScreen(
                                  //       customerId: customerId,
                                  //       customerName: customerName ?? name,
                                  //       orderId: orderId ?? id,
                                  //       isCustomer: isCustomer,
                                  //     ),
                                  //   ),
                                  // );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.primaryColor.withOpacity(0.15),
                                        AppColors.primaryColor.withOpacity(0.08),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.primaryColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryColor.withOpacity(0.2),
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_rounded,
                                    color: AppColors.primaryColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (snapshot.connectionState == ConnectionState.waiting) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.whiteColor.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primaryColor.withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Loading Avatar
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.grey300.withOpacity(0.3),
                                      AppColors.grey200.withOpacity(0.3),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                "Loading rider details...",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.grey600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

// Helper function to get rider details
Future<Map<String, dynamic>?> _getRiderDetails(String packageId) async {
  try {
    QuerySnapshot orderQuery = await FirebaseFirestore.instance
        .collection('deliveries')
        .where('packageId', isEqualTo: packageId)
        .limit(1)
        .get();

    if (orderQuery.docs.isEmpty) {
      return null;
    }

    DocumentSnapshot orderDoc = orderQuery.docs.first;
    String? riderId = orderDoc.get('riderId');

    if (riderId == null || riderId.isEmpty) {
      return null;
    }

    DocumentSnapshot riderDoc =
        await FirebaseFirestore.instance.collection('users').doc(riderId).get();

    if (!riderDoc.exists) {
      return null;
    }

    Map<String, dynamic> riderData = riderDoc.data() as Map<String, dynamic>;

    String firstName = riderData['firstName'] ?? '';
    String lastName = riderData['lastName'] ?? '';
    String fullName = '$firstName $lastName'.trim();

    return {
      'riderId': riderId,
      'riderName': fullName.isEmpty ? 'Unknown Rider' : fullName,
      'profileImage': riderData['profileImage'],
      'firstName': firstName,
      'lastName': lastName,
      'phone': riderData['phone'],
      'email': riderData['email'],
    };
  } catch (e) {
    print('Error getting rider details: $e');
    return null;
  }
}

// Helper function to build profile image from base64
Widget _buildProfileImage(String base64String) {
  try {
    Uint8List bytes = base64Decode(base64String);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackColor.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: 52,
          height: 52,
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialsAvatar('U');
          },
        ),
      ),
    );
  } catch (e) {
    return _buildInitialsAvatar('U');
  }
}

// Helper function to build initials avatar
Widget _buildInitialsAvatar(String name) {
  String initials = _getInitials(name);
  return Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.riderColor,
          AppColors.riderColor.withOpacity(0.8),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Center(
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.whiteColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

// Helper function to get initials from name
String _getInitials(String name) {
  if (name.isEmpty) return 'U';

  List<String> nameParts = name.trim().split(' ');
  if (nameParts.length >= 2) {
    return '${nameParts[0][0].toUpperCase()}${nameParts[1][0].toUpperCase()}';
  } else {
    return nameParts[0][0].toUpperCase();
  }
}