import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'review_screen.dart';
import '../../services/notification_service.dart';

class ClientBookingsScreen extends StatelessWidget {
  const ClientBookingsScreen({super.key});

  static const _primary = Color(0xFF2563EB);
  static const _bg = Color(0xFFF7F8FA);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted': return const Color(0xFF10B981);
      case 'completed': return const Color(0xFF2563EB);
      case 'declined': return Colors.red;
      case 'cancelled': return Colors.grey;
      default: return const Color(0xFFF59E0B);
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'accepted': return const Color(0xFFECFDF5);
      case 'completed': return const Color(0xFFEFF6FF);
      case 'declined': return const Color(0xFFFEF2F2);
      case 'cancelled': return const Color(0xFFF1F5F9);
      default: return const Color(0xFFFFFBEB);
    }
  }

  Color _urgencyColor(String u) {
    switch (u) {
      case 'Urgent': return const Color(0xFFF59E0B);
      case 'Emergency': return Colors.red;
      default: return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('My Bookings',
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
            .collection('bookings')
            .where('clientId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: _primary));
          }
          final bookings = snapshot.data!.docs;
          if (bookings.isEmpty) {
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
                    child: const Icon(Icons.calendar_month_rounded,
                        color: _primary, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text('No bookings yet',
                      style: TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('Book a service to get started',
                      style: TextStyle(
                          color: _textSecondary, fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final data =
                  bookings[index].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';
              final urgency = data['urgency'] ?? 'Normal';
              final budgetMin = data['budgetMin'] ?? 0;
              final budgetMax = data['budgetMax'] ?? 0;
              final hasBudget = budgetMin > 0 || budgetMax > 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: _primary,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    (data['providerName'] ?? 'P')[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      data['providerName'] ??
                                          'Provider',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: _textPrimary)),
                                  Text(data['category'] ?? '',
                                      style: const TextStyle(
                                          color: _textSecondary,
                                          fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _statusBg(status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(status.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _statusColor(status),
                                    letterSpacing: 0.5)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Date + price
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 13, color: _textSecondary),
                            const SizedBox(width: 6),
                            Text(
                                '${data['date']} at ${data['time']}',
                                style: const TextStyle(
                                    color: _textSecondary,
                                    fontSize: 12)),
                            const Spacer(),
                            const Icon(Icons.attach_money_rounded,
                                size: 13, color: _primary),
                            Text('RM ${data['price']}/hr',
                                style: const TextStyle(
                                    color: _primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Tags
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (urgency != 'Normal')
                            _tag(urgency,
                                _urgencyColor(urgency).withOpacity(0.12),
                                _urgencyColor(urgency)),
                          if ((data['estimatedDuration'] ?? '')
                              .isNotEmpty)
                            _tag(data['estimatedDuration'],
                                _primary.withOpacity(0.08), _primary),
                          if ((data['siteType'] ?? '').isNotEmpty)
                            _tag(data['siteType'],
                                const Color(0xFFF1F5F9), _textSecondary),
                          if (data['providerSupplyParts'] == true)
                            _tag('Provider supplies parts',
                                const Color(0xFFFFFBEB),
                                const Color(0xFFF59E0B)),
                        ],
                      ),

                      // Budget
                      if (hasBudget) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 13,
                                color: _textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'Budget: RM $budgetMin — RM $budgetMax',
                              style: const TextStyle(
                                  color: _textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ],

                      // Job description
                      if ((data['jobDescription'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Job Description',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _textSecondary)),
                              const SizedBox(height: 4),
                              Text(data['jobDescription'],
                                  style: const TextStyle(
                                      color: _textPrimary,
                                      fontSize: 13,
                                      height: 1.4),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],

                      // Completed — leave review
                      if (status == 'completed' &&
                          (data['reviewed'] != true)) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF2563EB)
                                    .withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF2563EB), size: 16),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Job completed! Share your experience.',
                                  style: TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
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
                            icon: const Icon(Icons.star_rounded,
                                color: Colors.white, size: 16),
                            label: const Text('Leave a Review',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],

                      // Completed and reviewed
                      if (status == 'completed' &&
                          data['reviewed'] == true) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_rounded,
                                  color: Color(0xFF10B981), size: 16),
                              SizedBox(width: 8),
                              Text('Review submitted — thank you!',
                                  style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],

                      // Pending — cancel
                      if (status == 'pending') ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(20)),
                                title: const Text('Cancel booking?',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700)),
                                content: const Text(
                                    'This will notify the provider and cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context),
                                    child: const Text('Keep it'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await FirebaseFirestore.instance
                                          .collection('bookings')
                                          .doc(bookings[index].id)
                                          .update(
                                              {'status': 'cancelled'});
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
                                    child: const Text('Cancel booking',
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontWeight:
                                                FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                            icon: const Icon(Icons.cancel_outlined,
                                color: Colors.red, size: 16),
                            label: const Text('Cancel Booking',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
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

  Widget _tag(String label, Color bg, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color)),
      );
}