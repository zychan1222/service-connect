import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> sendNotification({
    required String toUserId,
    required String title,
    required String body,
    required String type,
    String? bookingId,
  }) async {
    await _db.collection('notifications').add({
      'toUserId': toUserId,
      'title': title,
      'body': body,
      'type': type,
      'bookingId': bookingId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> markAllRead() async {
    final user = FirebaseAuth.instance.currentUser!;
    final unread = await _db
        .collection('notifications')
        .where('toUserId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in unread.docs) {
      await doc.reference.update({'isRead': true});
    }
  }
}