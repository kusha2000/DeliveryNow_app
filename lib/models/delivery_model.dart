import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryModel {
  final String id;
  final String packageId;
  final String customerName;
  final String customerId;
  final String address;
  final String riderId;
  final String riderName;
  final Timestamp assignedDate;
  final Timestamp? deliveryDate;
  final String status;
  final String? packageDetails;
  final String? voiceFeedback;
  final String? voiceFeedbackText;
  final String? voiceFeedbackPrediction;
  final String? voiceFeedbackSuggestion;
  final String? typeOfOrder;
  final String? deliveryTime;
  final String? feedback;
  final String? signature;
  final List<String> images;
  final List<String> items;
  final double? rating;
  final double? stars;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final String priority;
  final String phoneNumber;
  final double price;

  DeliveryModel({
    required this.id,
    required this.packageId,
    required this.customerName,
    required this.customerId,
    required this.address,
    required this.riderId,
    required this.riderName,
    required this.assignedDate,
    this.deliveryDate,
    required this.status,
    this.packageDetails,
    this.voiceFeedback,
    this.voiceFeedbackText,
    this.voiceFeedbackPrediction,
    this.voiceFeedbackSuggestion,
    this.typeOfOrder,
    this.deliveryTime,
    this.feedback,
    this.signature,
    this.images = const [],
    this.items = const [],
    this.rating,
    this.stars,
    required this.createdAt,
    this.updatedAt,
    required this.priority,
    required this.phoneNumber,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageId': packageId,
      'customerName': customerName,
      'customerId': customerId,
      'address': address,
      'riderId': riderId,
      'riderName': riderName,
      'assignedDate': assignedDate,
      'deliveryDate': deliveryDate,
      'status': status,
      'packageDetails': packageDetails,
      'voiceFeedback': voiceFeedback,
      'voiceFeedbackText': voiceFeedbackText,
      'voiceFeedbackPrediction': voiceFeedbackPrediction,
      'voiceFeedbackSuggestion': voiceFeedbackSuggestion,
      'typeOfOrder': typeOfOrder,
      'deliveryTime': deliveryTime,
      'feedback': feedback,
      'signature': signature,
      'images': images,
      'items': items,
      'rating': rating,
      'stars': stars,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'priority': priority,
      'phoneNumber': phoneNumber,
      'price': price,
    };
  }

  factory DeliveryModel.fromMap(Map<String, dynamic> map) {
    return DeliveryModel(
      id: map['id'] as String? ?? '',
      packageId: map['packageId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      address: map['address'] as String? ?? '',
      riderId: map['riderId'] as String? ?? '',
      riderName: map['riderName'] as String? ?? '',
      assignedDate: map['assignedDate'] as Timestamp? ?? Timestamp.now(),
      deliveryDate: map['deliveryDate'] as Timestamp?,
      status: map['status'] as String? ?? 'pending',
      packageDetails: map['packageDetails'] as String?,
      voiceFeedback: map['voiceFeedback'] as String?,
      voiceFeedbackText: map['voiceFeedbackText'] as String?,
      voiceFeedbackPrediction: map['voiceFeedbackPrediction'] as String?,
      voiceFeedbackSuggestion: map['voiceFeedbackSuggestion'] as String?,
      typeOfOrder: map['typeOfOrder'] as String?,
      deliveryTime: map['deliveryTime'] as String?,
      feedback: map['feedback'] as String?,
      signature: map['signature'] as String?,
      images: List<String>.from(map['images'] as List? ?? []),
      items: List<String>.from(map['items'] as List? ?? []),
      rating: (map['rating'] as num?)?.toDouble(),
      stars: (map['stars'] as num?)?.toDouble(),
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: map['updatedAt'] as Timestamp?,
      priority: map['priority'] as String? ?? 'medium',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
