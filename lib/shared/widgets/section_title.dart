import 'package:delivery_now_app/utils/colors.dart';
import 'package:flutter/material.dart';

Widget buildSectionTitle(String title) {
  return Text(
    title,
    style: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryColor,
    ),
  );
}
