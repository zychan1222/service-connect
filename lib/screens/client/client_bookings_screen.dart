import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'review_screen.dart';
import '../../services/notification_service.dart';

class ClientBookingsScreen extends StatelessWidget {
  const ClientBookingsScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted': return Colors.green;
      case 'declined': return Colors.red;
      case 'cancelled': return Colors.grey;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Bookings',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2563EB),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('clientId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final bookings = snapshot.data!.docs;
          if (bookings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No bookings yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Book a service to get started',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final data = bookings[index].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(data['providerName'] ?? 'Provider',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(status.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _statusColor(status))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.handyman,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(data['category'] ?? '',
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${data['date']} at ${data['time']}',
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.attach_money,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('RM ${data['price']}/hr',
                              style: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                      if ((data['notes'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Notes: ${data['notes']}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                      ],
                      if (status == 'accepted' &&
                          (data['reviewed'] != true)) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReviewScreen(
                                  providerId: data['providerId'],
                                  providerName: data['providerName'],
                                  bookingId: bookings[index].id,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.star,
                                color: Colors.white, size: 16),
                            label: const Text('Leave a Review',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[700],
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                      if (status == 'pending') ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Cancel Booking?'),
                                content: const Text(
                                    'Are you sure you want to cancel this booking?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await FirebaseFirestore.instance
                                          .collection('bookings')
                                          .doc(bookings[index].id)
                                          .update({'status': 'cancelled'});
                                      await NotificationService
                                          .sendNotification(
                                        toUserId: data['providerId'],
                                        title: 'Booking Cancelled',
                                        body:
                                            '${data['clientName']} has cancelled their booking on ${data['date']}',
                                        type: 'booking_cancelled',
                                        bookingId: bookings[index].id,
                                      );
                                    },
                                    child: const Text('Yes, Cancel',
                                        style:
                                            TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            ),
                            icon: const Icon(Icons.cancel_outlined,
                                color: Colors.red),
                            label: const Text('Cancel Booking',
                                style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}