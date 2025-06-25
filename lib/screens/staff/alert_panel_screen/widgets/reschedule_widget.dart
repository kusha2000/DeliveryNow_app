import 'package:flutter/material.dart';
import 'package:delivery_now_app/utils/colors.dart';


// Modern Reschedule Widget
Widget rescheduleWidget(String deliveryId, String riderName,
    String requestedDate, VoidCallback onAction) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.cardColor,
          AppColors.modalColor.withOpacity(0.6),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppColors.warningColor.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.lightShadowColor,
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warningColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.schedule_send_outlined,
                  color: AppColors.warningColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        deliveryId,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      riderName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_outlined,
                          size: 14,
                          color: AppColors.textMutedColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Requested: $requestedDate",
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMutedColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor,
                AppColors.primaryColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.whiteColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}