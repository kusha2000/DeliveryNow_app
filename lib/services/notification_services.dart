import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_now_app/services/firebase_services.dart';

class NotificationServices {
  Stream<Map<String, dynamic>?> getLatestPendingNotification() {
    final currentUserId = FirebaseServices().getCurrentUser()?.uid;
    print("DEBUG: Current User ID: $currentUserId");
    if (currentUserId == null) {
      print("DEBUG: User ID is null, returning null stream");
      return Stream.value(null);
    }
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('customerId', isEqualTo: currentUserId)
        .where('isclosedNotification', isEqualTo: false)
        .limit(1)
        .snapshots()
        .asyncMap((notificationSnapshot) async {
      print(
          "DEBUG: Notification snapshot docs length: ${notificationSnapshot.docs.length}");
      if (notificationSnapshot.docs.isEmpty) {
        print("DEBUG: No notifications found for user $currentUserId");
        return null;
      }

      final notificationDoc = notificationSnapshot.docs.first;
      final notificationData = notificationDoc.data();
      print("DEBUG: Notification data: $notificationData");

      final isclosedNotification =
          notificationData['isclosedNotification'] ?? false;
      print("DEBUG: Notification isclosedNotification: $isclosedNotification");
      if (isclosedNotification) {
        print("DEBUG: Notification is closed, returning null");
        return null;
      }

      final parcelTrackingNumber = notificationData['parcel_tracking_number'];
      print("DEBUG: Parcel tracking number: $parcelTrackingNumber");

      final deliveryQuery = await FirebaseFirestore.instance
          .collection('deliveries')
          .where('packageId', isEqualTo: parcelTrackingNumber)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      print("DEBUG: Delivery query docs length: ${deliveryQuery.docs.length}");
      if (deliveryQuery.docs.isEmpty) {
        print(
            "DEBUG: No pending deliveries found for parcel $parcelTrackingNumber");
        return null;
      }

      final deliveryData = deliveryQuery.docs.first.data();
      print("DEBUG: Delivery data: $deliveryData");

      return {
        'notification': notificationData,
        'notificationId': notificationDoc.id,
        'delivery': deliveryData,
      };
    }).handleError((error) {
      print("DEBUG: Error in notification stream: $error");
      return null;
    });
  }
}
