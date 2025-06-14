import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_now_app/models/delivery_model.dart';
import 'package:delivery_now_app/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  String? getCurrentUserID() {
    return _auth.currentUser?.uid;
  }

  //Delivery Functions
  Future<String> assignNewDelivery({
    required String packageId,
    required String customerName,
    required String address,
    required String riderId,
    required String riderName,
    required Timestamp assignedDate,
    required String packageDetails,
    required List<String> items,
    required String priority,
    required String typeOfOrder,
    required String phoneNumber,
    required double price,
    required String customerId,
  }) async {
    try {
      final docRef = _firestore.collection('deliveries').doc();

      // Prepare the delivery data
      final deliveryData = {
        'id': docRef.id,
        'packageId': packageId,
        'customerName': customerName,
        'address': address,
        'riderId': riderId,
        'riderName': riderName,
        'assignedDate': assignedDate,
        'status': 'pending',
        'packageDetails': packageDetails,
        'items': items,
        'createdAt': Timestamp.now(),
        'priority': priority,
        'typeOfOrder': typeOfOrder,
        'phoneNumber': phoneNumber,
        'images': <String>[],
        'price': price,
        'customerId': customerId,
      };

      // Save to Firestore
      await docRef.set(deliveryData);

      return docRef.id;
    } catch (e) {
      print('Error assigning delivery: $e');
      rethrow;
    }
  }

  Future<void> updateDeliveryDetails({
    required String deliveryId,
    required String customerName,
    required String address,
    required String phoneNumber,
    required String packageDetails,
    required List<String> items,
    required Timestamp assignedDate,
    required String priority,
    required String typeOfOrder,
    required double price,
  }) async {
    try {
      await _firestore.collection('deliveries').doc(deliveryId).update({
        'customerName': customerName,
        'address': address,
        'phoneNumber': phoneNumber,
        'packageDetails': packageDetails,
        'items': items,
        'assignedDate': assignedDate,
        'priority': priority,
        'typeOfOrder': typeOfOrder,
        'price': price,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating delivery details: $e');
      rethrow;
    }
  }

  // Cancel delivery
  Future<void> cancelDelivery(String deliveryId) async {
    try {
      await _firestore.collection('deliveries').doc(deliveryId).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get all deliveries
  Future<List<DeliveryModel>> fetchAllDeliveries() async {
    try {
      final snapshot = await _firestore.collection('deliveries').get();

      return snapshot.docs
          .map((doc) => DeliveryModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting deliveries by date: $e');
      rethrow;
    }
  }

  // Get deliveries by date for a rider
  Future<List<DeliveryModel>> fetchAllDeliveriesByDate({
    required DateTime date,
  }) async {
    try {
      // Get start and end of the selected date
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('deliveries')
          .where('assignedDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('assignedDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return snapshot.docs
          .map((doc) => DeliveryModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting deliveries by date: $e');
      rethrow;
    }
  }

  //Riders

  Future<List<UserModel>> getAllRiders() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'rider')
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading riders: $e');
      return [];
    }
  }

  //Notifications

  Future<void> saveDeliveryNotification({
    required String customerName,
    required String parcelTrackingNumber,
    required String deliveryDate,
    required Map<String, String> timeWindow,
    required Map<String, String> deliveryAddress,
    required String courierInfo,
    required String parcelContents,
    required String riderId,
    required String notificationText,
    required String confirmationResult,
    String? customerId, // Add customerId
  }) async {
    final notificationData = {
      'customer_name': customerName,
      'parcel_tracking_number': parcelTrackingNumber,
      'delivery_date': deliveryDate,
      'time_window': timeWindow,
      'delivery_address': deliveryAddress,
      'courier_info': courierInfo,
      'parcel_contents': parcelContents,
      'riderId': riderId,
      'notification_text': notificationText,
      'confirmation_result': confirmationResult,
      'isclosedNotification': false,
      'isclosed': false,
      'created_at': FieldValue.serverTimestamp(),
      'customerId': customerId, // Save customerId
    };

    await FirebaseFirestore.instance
        .collection('notifications')
        .add(notificationData);
  }

  //Streams

  Stream<List<DeliveryModel>> getCustomerDeliveries(String customerId) {
    return FirebaseFirestore.instance
        .collection('deliveries')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryModel.fromMap(doc.data()))
            .toList());
  }

  Stream<List<DeliveryModel>> getRiderDeliveries(String riderId) {
    return _firestore
        .collection('deliveries')
        .where('riderId', isEqualTo: riderId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryModel.fromMap(doc.data()))
            .toList());
  }
}
