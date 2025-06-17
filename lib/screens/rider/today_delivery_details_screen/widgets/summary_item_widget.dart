import 'package:delivery_now_app/utils/colors.dart';
import 'package:flutter/material.dart';

Widget summaryItemWidget(String label, int count, IconData icon, Color color) {
  return Column(
    children: [
      Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
      SizedBox(height: 8),
      Text(
        count.toString(),
        style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.whiteColor),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.grey600,
        ),
      ),
    ],
  );
}
