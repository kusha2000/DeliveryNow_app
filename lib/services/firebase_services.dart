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

  Stream<QuerySnapshot> getAllDeliveriesStream() {
    return FirebaseFirestore.instance
        .collection('deliveries')
        .orderBy('assignedDate', descending: true)
        .snapshots();
  }

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

  Future<void> updateDeliveryWithRiderDetails({
    required String deliveryId,
    required Timestamp assignedDate,
    required String riderId,
    required String riderName,
  }) async {
    try {
      await _firestore.collection('deliveries').doc(deliveryId).update({
        'assignedDate': assignedDate,
        'riderId': riderId,
        'riderName': riderName,
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

  // Fetch all deliveries for the rider
  Future<List<DeliveryModel>> fetchAllDeliveriesForOneRider(
      {required String riderId}) async {
    try {
      print('Fetching deliveries for rider: $riderId');
      final snapshot = await FirebaseFirestore.instance
          .collection('deliveries')
          .where('riderId', isEqualTo: riderId)
          .orderBy('assignedDate', descending: false)
          .get();

      print('Query returned ${snapshot.docs.length} documents');

      List<DeliveryModel> deliveries = snapshot.docs
          .map((doc) => DeliveryModel.fromMap(doc.data()))
          .toList();

      print('Converted ${deliveries.length} deliveries');
      return deliveries;
    } catch (e) {
      print('Error fetching all deliveries: $e');
      return [];
    }
  }

  Future<DeliveryModel?> fetchSpecificDelivery({
    required String deliveryId,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('deliveries')
          .doc(deliveryId)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final delivery = DeliveryModel.fromMap(data);
        print('Fetched delivery with ID: $deliveryId');
        return delivery;
      } else {
        print('No delivery found with ID: $deliveryId');
        return null;
      }
    } catch (e) {
      print('Error fetching delivery: $e');
      return null;
    }
  }

  // Update delivery status
  Future<void> updateDeliveryStatus({
    required String deliveryId,
    required String status,
  }) async {
    try {
      await _firestore.collection('deliveries').doc(deliveryId).update({
        'status': status,
        'deliveryDate': status == 'delivered' ? Timestamp.now() : null,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating delivery status: $e');
      rethrow;
    }
  }

  // Stream deliveries by date for a specific rider
  Stream<List<DeliveryModel>> getDeliveriesByDateStream({
    required String riderId,
    required DateTime date,
  }) {
    // Get start and end of the selected date
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection('deliveries')
        .where('riderId', isEqualTo: riderId)
        .where('assignedDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('assignedDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DeliveryModel.fromMap(doc.data()))
          .toList();
    });
  }

  Stream<List<DeliveryModel>> getAllDeliveriesByDateStream({
    required DateTime date,
  }) {
    // Get start and end of the selected date
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection('deliveries')
        .where('assignedDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('assignedDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DeliveryModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<bool> checkDeliveryHasImages(String deliveryId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('deliveries')
          .doc(deliveryId)
          .collection('images')
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking images: $e');
      return false;
    }
  }

  // Stream a specific delivery by its ID
  Stream<DeliveryModel?> getDeliveryByIdStream(String deliveryId) {
    return _firestore
        .collection('deliveries')
        .doc(deliveryId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return DeliveryModel.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  Future<void> updateDeliveriesCount() async {
    try {
      String? userId = getCurrentUserID();
      DocumentReference userDoc = _firestore.collection('users').doc(userId);

      DocumentSnapshot snapshot = await userDoc.get();

      int currentCount =
          (snapshot.data() as Map<String, dynamic>?)?['deliveriesCount'] ?? 0;

      await userDoc.update({
        'deliveriesCount': currentCount + 1,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get deliveries by date for a rider
  Future<List<DeliveryModel>> getDeliveriesByDate({
    required String riderId,
    required DateTime date,
  }) async {
    try {
      // Get start and end of the selected date
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('deliveries')
          .where('riderId', isEqualTo: riderId)
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

  // Update delivery signature
  Future<void> updateDeliverySignature({
    required String deliveryId,
    required String signatureBase64,
  }) async {
    try {
      await _firestore.collection('deliveries').doc(deliveryId).update({
        'signature': signatureBase64,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating signature: $e');
      rethrow;
    }
  }

  // Update delivery feedback
  Future<void> updateDeliveryFeedback({
    required String deliveryId,
    required double stars,
    required String feedback,
  }) async {
    try {
      await _firestore.collection('deliveries').doc(deliveryId).update({
        'feedback': feedback,
        'stars': stars,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating feedback: $e');
      rethrow;
    }
  }

  // Delivery-package Images
  Future<void> uploadDeliveryImage({
    required String deliveryId,
    required String imageBase64,
    required int imageIndex,
  }) async {
    try {
      await _firestore
          .collection('deliveries')
          .doc(deliveryId)
          .collection('images')
          .doc(imageIndex.toString())
          .set({
        'imageData': imageBase64,
        'uploadedAt': Timestamp.now(),
      });

      await _firestore.collection('deliveries').doc(deliveryId).update({
        'imageRefs': FieldValue.arrayUnion([imageIndex.toString()]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error uploading image $imageIndex: $e');
      rethrow;
    }
  }

  Future<List<String>> getDeliveryImages(String deliveryId) async {
    try {
      // Get the collection of images
      final snapshot = await _firestore
          .collection('deliveries')
          .doc(deliveryId)
          .collection('images')
          .orderBy('uploadedAt')
          .get();

      List<String> images = [];
      for (var doc in snapshot.docs) {
        images.add(doc.data()['imageData'] as String);
      }

      return images;
    } catch (e) {
      print('Error getting delivery images: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> loadExistingImages(
      String deliveryId) async {
    try {
      final snapshot = await _firestore
          .collection('deliveries')
          .doc(deliveryId)
          .collection('images')
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'image': data['imageData'] as String,
            'prediction': data['isDamaged'] == true ? 'Damage' : 'No Damage',
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error loading existing images: $e');
      rethrow;
    }
  }

  // Add these methods to your FirebaseServices class

  Future<int> getExistingImageCount(String deliveryId) async {
    try {
      final snapshot = await _firestore
          .collection('deliveries')
          .doc(deliveryId)
          .collection('images')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting existing image count: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> loadSingleExistingImage(
      String deliveryId, int index) async {
    try {
      final snapshot = await _firestore
          .collection('deliveries')
          .doc(deliveryId)
          .collection('images')
          .get();

      if (snapshot.docs.isEmpty || index >= snapshot.docs.length) {
        throw Exception('Image not found at index $index');
      }

      // Sort documents by their ID or a timestamp field if you have one
      // This ensures consistent ordering across calls
      final sortedDocs = snapshot.docs..sort((a, b) => a.id.compareTo(b.id));

      final doc = sortedDocs[index];
      final data = doc.data();

      return {
        'image': data['imageData'] as String,
        'prediction': data['isDamaged'] == true ? 'Damage' : 'No Damage',
      };
    } catch (e) {
      print('Error loading single existing image at index $index: $e');
      rethrow;
    }
  }

  Future<void> clearDeliveryImages(String deliveryId) async {
    try {
      // Get existing image references
      DocumentSnapshot deliveryDoc =
          await _firestore.collection('deliveries').doc(deliveryId).get();

      // Delete all existing images in the subcollection
      if (deliveryDoc.exists) {
        final data = deliveryDoc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('imageRefs')) {
          List<String> imageRefs = List<String>.from(data['imageRefs'] ?? []);

          // Delete each image document
          for (String imageRef in imageRefs) {
            await _firestore
                .collection('deliveries')
                .doc(deliveryId)
                .collection('images')
                .doc(imageRef)
                .delete();
          }
        }

        // Reset image references in the main document
        await _firestore.collection('deliveries').doc(deliveryId).update({
          'imageRefs': [],
          'images': [], // Clear legacy field if exists
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error clearing delivery images: $e');
      rethrow;
    }
  }

// Delivery - Voice Feedbacks

// Update delivery voice feedback
  Future<void> updateDeliveryVoiceFeedback({
    required String deliveryId,
    required String voiceFeedbackBase64,
  }) async {
    try {
      final updateData = {
        'voiceFeedback': voiceFeedbackBase64,
        'updatedAt': Timestamp.now(),
      };
      await _firestore
          .collection('deliveries')
          .doc(deliveryId)
          .update(updateData);
    } catch (e) {
      print('Error updating voice feedback: $e');
      rethrow;
    }
  }

  Future<DeliveryModel?> getDeliveryById(String deliveryId) async {
    try {
      final doc =
          await _firestore.collection('deliveries').doc(deliveryId).get();

      if (doc.exists) {
        return DeliveryModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting delivery by ID: $e');
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

  Future<void> updateAttendanceStatus(String status) async {
    try {
      String? userId = getCurrentUserID();
      if (userId == null) throw Exception('User not logged in');

      String dateKey = DateTime.now().toIso8601String().split('T')[0];
      Timestamp startTime = Timestamp.now();

      // Reference to the attendance log document for the current date
      DocumentReference attendanceLogRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('attendance_logs')
          .doc(dateKey);

      // Check if the attendance log already exists for the date
      DocumentSnapshot attendanceLogSnapshot = await attendanceLogRef.get();

      // Update attendanceRecords in the user document
      await _firestore.collection('users').doc(userId).update({
        'attendanceRecords.$dateKey': status,
        'availabilityStatus': status == 'absent' ? 'absent' : 'offline',
      });

      // Store detailed attendance log only if it doesn't already exist and status is "present"
      if (status == "present" && !attendanceLogSnapshot.exists) {
        await attendanceLogRef.set({
          'startTime': startTime,
          'date': dateKey,
        }, SetOptions(merge: false));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAvailabilityStatus(String status) async {
    try {
      String? userId = getCurrentUserID();
      if (userId == null) throw Exception('User not logged in');

      String dateKey = DateTime.now().toIso8601String().split('T')[0];
      Timestamp currentTime = Timestamp.now();

      // Get the current attendance status
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      String currentAttendanceStatus = (userDoc.data()
              as Map<String, dynamic>?)?['attendanceRecords']?[dateKey] ??
          'normal';

      // Prevent availability changes if absent
      if (currentAttendanceStatus == 'absent' && status != 'absent') {
        throw Exception('Cannot change availability while absent');
      }

      // Update availabilityStatus in the user document
      await _firestore.collection('users').doc(userId).update({
        'availabilityStatus': status,
      });

      // Get the latest availability log for the current date
      QuerySnapshot availabilityLogs = await _firestore
          .collection('users')
          .doc(userId)
          .collection('attendance_logs')
          .doc(dateKey)
          .collection('availability_logs')
          .orderBy('startTime', descending: true)
          .limit(1)
          .get();

      if (status == 'available') {
        // Create a new availability log entry for online status
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('attendance_logs')
            .doc(dateKey)
            .collection('availability_logs')
            .add({
          'status': 'online',
          'startTime': currentTime,
          'endTime': null,
        });
      } else if (status == 'offline' && availabilityLogs.docs.isNotEmpty) {
        // Update the latest availability log with endTime
        DocumentSnapshot latestLog = availabilityLogs.docs.first;
        if (latestLog['status'] == 'online' && latestLog['endTime'] == null) {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('attendance_logs')
              .doc(dateKey)
              .collection('availability_logs')
              .doc(latestLog.id)
              .update({
            'endTime': currentTime,
          });
        }
      }
    } catch (e) {
      rethrow;
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

  //users

  Future<void> updateProfileImage(String base64Image) async {
    try {
      String? userId = getCurrentUserID();
      await _firestore.collection('users').doc(userId).update({
        'profileImage': base64Image,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Update user details in Firestore
  Future<void> updateUserDetails({
    required String uid,
    required String firstName,
    required String lastName,
    required int? age,
    required String? phoneNumber,
    required String? gender,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'firstName': firstName,
        'lastName': lastName,
        'age': age,
        'phoneNumber': phoneNumber,
        'gender': gender,
      });
    } catch (e) {
      rethrow;
    }
  }

  // SOS Services

  Stream<QuerySnapshot> getAllSOSStream() {
    return FirebaseFirestore.instance
        .collection('sos')
        .orderBy('dateTime', descending: true)
        .snapshots();
  }

  Future deleteSOS(String sosId) async {
    await FirebaseFirestore.instance.collection('sos').doc(sosId).delete();
  }

  Future<String> createSOSRequest() async {
    try {
      final docRef = _firestore.collection('sos').doc();
      String? userId = getCurrentUserID();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      UserModel? userData = await getUserData(userId);
      if (userData == null) {
        throw Exception('User data not found');
      }

      final sosData = {
        'sosID': docRef.id,
        'riderId': userId,
        'riderName': '${userData.firstName} ${userData.lastName}',
        'actionTaken': false,
        'dateTime': Timestamp.now(),
      };

      await docRef.set(sosData);
      return docRef.id;
    } catch (e) {
      print('Error creating SOS request: $e');
      rethrow;
    }
  }

  // Reschedule Request Service

  Stream<QuerySnapshot> getAllRescheduleStream() {
    return FirebaseFirestore.instance
        .collection('reschedule_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<String> createRescheduleRequest({
    required String deliveryId,
    required String riderId,
    required String reason,
    required Timestamp requestedDate,
  }) async {
    try {
      final docRef = _firestore.collection('reschedule_requests').doc();
      UserModel? userData = await getUserData(riderId);
      if (userData == null) {
        throw Exception('User data not found');
      }

      final rescheduleData = {
        'requestId': docRef.id,
        'deliveryId': deliveryId,
        'riderId': riderId,
        'riderName': '${userData.firstName} ${userData.lastName}',
        'reason': reason,
        'requestedDate': requestedDate,
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'approved': false,
        'reviewedBy': null,
        'reviewedAt': null,
      };

      await docRef.set(rescheduleData);
      return docRef.id;
    } catch (e) {
      print('Error creating reschedule request: $e');
      rethrow;
    }
  }

  // Check if a pending reschedule request exists for a delivery
  Future<bool> hasPendingRescheduleRequest(String deliveryId) async {
    try {
      final snapshot = await _firestore
          .collection('reschedule_requests')
          .where('deliveryId', isEqualTo: deliveryId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking reschedule request: $e');
      return false;
    }
  }

  Future<void> updateRequestedDeliveryDetails({
    required String requestId,
    required Timestamp assignedDate,
    required String newRiderId,
    required String newRiderName,
  }) async {
    try {
      String? userId = getCurrentUserID();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      await _firestore.collection('reschedule_requests').doc(requestId).update({
        'status': 'approved',
        'approved': true,
        'reviewedBy': userId,
        'reviewedAt': Timestamp.now(),
        'newRiderId': newRiderId,
        'newRiderName': newRiderName,
        'newDate': assignedDate,
      });
    } catch (e) {
      print('Error updating delivery details: $e');
      rethrow;
    }
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

  Stream<UserModel?> getUserDataStream() {
    return _firestore
        .collection('users')
        .doc(getCurrentUserID())
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  Stream<List<DeliveryModel>> streamDeliveriesByDate({
    required String riderId,
    required DateTime date,
  }) {
    try {
      // Get start and end of the selected date
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);

      return _firestore
          .collection('deliveries')
          .where('riderId', isEqualTo: riderId)
          .where('assignedDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('assignedDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => DeliveryModel.fromMap(doc.data()))
              .toList());
    } catch (e) {
      print('Error streaming deliveries by date: $e');
      rethrow;
    }
  }

  // Stream latest 3 deliveries for a specific rider (all statuses)
  Stream<List<DeliveryModel>> getLatestRiderDeliveries(String riderId) {
    return _firestore
        .collection('deliveries')
        .where('riderId', isEqualTo: riderId)
        .limit(3)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryModel.fromMap(doc.data()))
            .toList());
  }
}
