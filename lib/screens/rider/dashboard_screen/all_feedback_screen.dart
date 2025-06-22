import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_now_app/models/delivery_model.dart';
import 'package:delivery_now_app/screens/rider/dashboard_screen/widgets/feedback_widget.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AllFeedbacksScreen extends StatelessWidget {
  final List<DeliveryModel> deliveries;
  final DateTime date;

  const AllFeedbacksScreen({
    super.key,
    required this.deliveries,
    required this.date,
  });

  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat.yMMMMd();
    final formattedDate = dateFormatter.format(date);

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
        title: Text(
          'All Feedback - $formattedDate',
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
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: deliveries
            .where((delivery) =>
                delivery.feedback != null && delivery.feedback!.isNotEmpty)
            .length,
        itemBuilder: (context, index) {
          final filteredDeliveries = deliveries
              .where((delivery) =>
                  delivery.feedback != null && delivery.feedback!.isNotEmpty)
              .toList();
          final delivery = filteredDeliveries[index];
          return Column(
            children: [
              feedbackWidget(
                name: delivery.customerName,
                comment: delivery.feedback!,
                time: _formatTimeAgo(delivery.updatedAt),
                rating: (delivery.stars ?? 0).toInt(),
              ),
              Divider(height: 1),
            ],
          );
        },
      ),
    );
  }
}
