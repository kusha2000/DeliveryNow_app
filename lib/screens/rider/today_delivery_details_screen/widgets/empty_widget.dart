import 'package:delivery_now_app/utils/colors.dart';
import 'package:flutter/material.dart';

Widget emptyWidget() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.inventory_2,
          size: 80,
          color: AppColors.greyColor.withOpacity(0.5),
        ),
        SizedBox(height: 16),
        Text(
          'No deliveries found',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.grey600,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'There are no deliveries matching your filter',
          style: TextStyle(
            color: AppColors.grey600,
          ),
        ),
      ],
    ),
  );
}
