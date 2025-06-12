import 'package:flutter/material.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'package:delivery_now_app/utils/styles.dart';

Widget deliveryCardWidget(String selectedDriver, String? status) {
  // Determine decoration based on status
  BoxDecoration getDecorationByStatus() {
    switch (status?.toLowerCase()) {
      case 'offline':
      case 'absent':
        return AppDecorations.containerPinkGradientDecoration(
          borderRadius: 18,
          boxShadow: [
            BoxShadow(
              color: AppColors.pinkColor.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case 'active':
      case 'on duty':
        return AppDecorations.containerEmeraldGradientDecoration(
          borderRadius: 18,
          boxShadow: [
            BoxShadow(
              color: AppColors.emeraldColor.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        );
      default:
        return AppDecorations.containerGoldGradientDecoration(
          borderRadius: 18,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        );
    }
  }

  // Get status icon based on status
  IconData getStatusIcon() {
    switch (status?.toLowerCase()) {
      case 'offline':
        return Icons.wifi_off_rounded;
      case 'absent':
        return Icons.cancel_rounded;
      case 'active':
      case 'on duty':
        return Icons.check_circle_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  // Get status text with better formatting
  String getStatusText() {
    switch (status?.toLowerCase()) {
      case 'offline':
        return 'Offline';
      case 'absent':
        return 'Absent';
      case 'active':
      case 'on duty':
        return 'Active • On Duty';
      default:
        return 'Available';
    }
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: getDecorationByStatus(),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Beautiful Avatar Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.whiteColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.whiteColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              color: AppColors.whiteColor,
              size: 28,
            ),
          ),
          
          const SizedBox(width: 18),
          
          // Driver Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Driver Name
                Text(
                  selectedDriver,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.whiteColor,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 6),
                
                // Status with Icon
                Row(
                  children: [
                    Icon(
                      getStatusIcon(),
                      color: AppColors.whiteColor.withOpacity(0.9),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      getStatusText(),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.whiteColor.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Status Indicator Dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: AppColors.whiteColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}