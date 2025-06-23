import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_now_app/screens/Customer/chat_screen.dart';
import 'package:delivery_now_app/screens/Customer/one_delivery_details_screnn.dart';
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
  String? deliveryId,
  String? customerName,
  String? orderId,
  bool isCustomer = false,
}) {
  return FutureBuilder<Map<String, dynamic>?>(
    future: _getRiderDetails(id),
    builder: (context, snapshot) {
      Map<String, dynamic>? riderData = snapshot.data;

      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    OneDeliveryDetailScreen(deliveryId: deliveryId!)),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
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
              BoxShadow(
                color: AppColors.lightShadowColor,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row with ID and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Order #$id',
                        style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
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
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Main Content Row
                Row(
                  children: [
                    // Beautiful Shipping Icon Container
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
                        Icons.local_shipping_rounded,
                        color: AppColors.primaryColor,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Content Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Customer Name
                          if (name.isNotEmpty)
                            Text(
                              name,
                              style: const TextStyle(
                                color: AppColors.textPrimaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                          const SizedBox(height: 8),

                          // Address with Icon
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.textSecondaryColor,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  address,
                                  style: const TextStyle(
                                    color: AppColors.textSecondaryColor,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Date with Beautiful Styling
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.borderLightColor,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  color: AppColors.textMutedColor,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('MMM d, yyyy • h:mm a')
                                      .format(date.toDate()),
                                  style: const TextStyle(
                                    color: AppColors.textMutedColor,
                                    fontSize: 12,
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
                ),

                // Rider Section
                if (riderData != null) ...[
                  const SizedBox(height: 20),

                  // Beautiful Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.dividerColor.withOpacity(0.3),
                          AppColors.dividerColor,
                          AppColors.dividerColor.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildModernRiderSection(riderData, context, customerId,
                      customerName, name, orderId, id, isCustomer),
                ] else if (snapshot.connectionState ==
                    ConnectionState.waiting) ...[
                  const SizedBox(height: 20),

                  // Beautiful Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.dividerColor.withOpacity(0.3),
                          AppColors.dividerColor,
                          AppColors.dividerColor.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildModernLoadingRiderSection(),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

// Modern Rider Section Widget
Widget _buildModernRiderSection(
  Map<String, dynamic> riderData,
  BuildContext context,
  String? customerId,
  String? customerName,
  String name,
  String? orderId,
  String id,
  bool isCustomer,
) {
  return Row(
    children: [
      // Modern Rider Avatar
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: riderData['profileImage'] != null &&
                  riderData['profileImage'].isNotEmpty
              ? _buildProfileImage(riderData['profileImage'])
              : _buildModernInitialsAvatar(riderData['riderName'] ?? 'Unknown'),
        ),
      ),

      const SizedBox(width: 16),

      // Rider Info
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rider Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.riderColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.riderColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Text(
                'DELIVERY RIDER',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.riderColor,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Rider Name
            Text(
              riderData['riderName'] ?? 'Unknown Rider',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),

      // Modern Chat Button
      _buildModernChatButton(
          context, customerId, customerName, name, orderId, id, isCustomer),
    ],
  );
}

// Modern Chat Button Widget
Widget _buildModernChatButton(
  BuildContext context,
  String? customerId,
  String? customerName,
  String name,
  String? orderId,
  String id,
  bool isCustomer,
) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        if (customerId == null || customerId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Unregistered users cannot use the chat feature.',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimaryColor,
                ),
              ),
              backgroundColor: AppColors.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              customerId: customerId,
              customerName: customerName ?? name,
              orderId: orderId ?? id,
              isCustomer: isCustomer,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.primaryDarkColor,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.chat_bubble_outline_rounded,
          color: AppColors.backgroundColor,
          size: 22,
        ),
      ),
    ),
  );
}

// Modern Loading Rider Section Widget
Widget _buildModernLoadingRiderSection() {
  return Row(
    children: [
      // Modern Loading Avatar
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.surfaceColor,
              AppColors.cardColor,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderColor,
            width: 2,
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryColor.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ),

      const SizedBox(width: 16),

      // Loading Text with Shimmer Effect
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 16,
              width: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 14,
              width: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceColor.withOpacity(0.7),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ],
        ),
      ),
    ],
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
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      width: 52,
      height: 52,
      errorBuilder: (context, error, stackTrace) {
        return _buildModernInitialsAvatar('U');
      },
    );
  } catch (e) {
    return _buildModernInitialsAvatar('U');
  }
}

// Modern Initials Avatar Widget
Widget _buildModernInitialsAvatar(String name) {
  String initials = _getInitials(name);
  return Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.riderColor,
          AppColors.indigoColor,
        ],
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
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
