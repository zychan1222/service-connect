import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _primary = Color(0xFF2563EB);
  static const _bg = Color(0xFFF7F8FA);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      NotificationService.markAllRead();
    });
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'booking_received': return Icons.calendar_today_rounded;
      case 'booking_accepted': return Icons.check_circle_rounded;
      case 'booking_declined': return Icons.cancel_rounded;
      case 'booking_cancelled': return Icons.cancel_outlined;
      case 'time_proposed': return Icons.schedule_rounded;
      case 'time_accepted': return Icons.event_available_rounded;
      case 'time_declined': return Icons.event_busy_rounded;
      case 'provider_verified': return Icons.verified_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'booking_received': return _primary;
      case 'booking_accepted': return const Color(0xFF10B981);
      case 'booking_declined': return Colors.red;
      case 'booking_cancelled': return const Color(0xFFF59E0B);
      case 'time_proposed': return const Color(0xFFF59E0B);
      case 'time_accepted': return const Color(0xFF10B981);
      case 'time_declined': return Colors.red;
      case 'provider_verified': return const Color(0xFF10B981);
      default: return _textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16)),
        backgroundColor: _primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('toUserId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: _primary));
          }
          final notifications = snapshot.data!.docs;
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.notifications_rounded,
                        color: _primary, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text('No notifications yet',
                      style: TextStyle(
                          color: _textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('You are all caught up',
                      style:
                          TextStyle(color: _textSecondary, fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data =
                  notifications[index].data() as Map<String, dynamic>;
              final isRead = data['isRead'] ?? false;
              final type = data['type'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isRead
                      ? Colors.white
                      : _primary.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isRead
                        ? const Color(0xFFE2E8F0)
                        : _primary.withOpacity(0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getColor(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getIcon(type),
                          color: _getColor(type), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['title'] ?? '',
                              style: TextStyle(
                                  fontWeight: isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  fontSize: 14,
                                  color: _textPrimary)),
                          const SizedBox(height: 3),
                          Text(data['body'] ?? '',
                              style: const TextStyle(
                                  color: _textSecondary,
                                  fontSize: 12,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 4, left: 8),
                        decoration: const BoxDecoration(
                          color: _primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}