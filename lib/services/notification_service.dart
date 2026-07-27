import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> sendNotification({
    required String toUserId,
    required String title,
    required String body,
    required String type,
    String? bookingId,
  }) async {
    try {
      await _db.collection('notifications').add({
        'toUserId': toUserId,
        'title': title,
        'body': body,
        'type': type,
        'bookingId': bookingId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to send notification: $e');
    }
  }

  static Future<void> markAllRead() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final unread = await _db
          .collection('notifications')
          .where('toUserId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();
      if (unread.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Failed to mark notifications as read: $e');
    }
  }
}